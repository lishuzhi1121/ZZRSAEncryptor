//
//  ZZRSAEncryptor.m
//  ZZRSAEncryptor
//
//  Created by SandsLee on 2021/11/17.
//

#import "ZZRSAEncryptor.h"
#import "ZZBigInt.h"
#import <ZZASNOne/ZZASNOne.h>

// 生成类型, 仅内部生成密钥时使用
static ZZRSAKeyType ZZRSAKeyTypeGenerated = ZZRSAKeyTypePrivate + 1;

@interface ZZRSAEncryptor ()

/// 密钥信息
@property (nonatomic, strong) ZZRSAKey *key;

@end

@implementation ZZRSAEncryptor

+ (instancetype)encryptorWithKeySize:(int)keySize {
    ZZRSAEncryptor *encryptor = [[ZZRSAEncryptor alloc] initWithKeySize:keySize];
    return encryptor;
}

- (instancetype)initWithKeySize:(int)keySize {
    if (self = [self init]) {
        self.key.bits = keySize;
        if (![self _zzGenKey]) {
            return nil;
        }
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        self.key = [[ZZRSAKey alloc] init];
    }
    return self;
}

+ (instancetype)encryptorWithKeySize:(int)keySize
                           publicKey:(NSString *)publicKey
                          privateKey:(NSString *)privateKey
                              module:(NSString *)module {
    ZZRSAEncryptor *encryptor = [[ZZRSAEncryptor alloc] initWithKeySize:keySize
                                                              publicKey:publicKey
                                                             privateKey:privateKey
                                                                 module:module];
    return encryptor;
}

- (instancetype)initWithKeySize:(int)keySize
                      publicKey:(NSString *)publicKey
                     privateKey:(NSString *)privateKey
                         module:(NSString *)module {
    if (self = [self init]) {
        if (privateKey) {
            self.key.keyType = ZZRSAKeyTypePrivate;
        } else {
            self.key.keyType = ZZRSAKeyTypePublic;
        }
        self.key.bits = keySize;
        self.key.e = [[ZZBigInt alloc] initWithString:publicKey radix:16];
        self.key.d = [[ZZBigInt alloc] initWithString:privateKey radix:16];
        self.key.n = [[ZZBigInt alloc] initWithString:module radix:16];
    }
    
    return self;
}

+ (instancetype)encryptorWithPublicKeyFile:(NSString *)pubKeyFile
                            privateKeyFile:(NSString *)privKeyFile {
    ZZRSAEncryptor *encryptor = [[ZZRSAEncryptor alloc] initWithPublicKeyFile:pubKeyFile
                                                               privateKeyFile:privKeyFile];
    return encryptor;
}

- (instancetype)initWithPublicKeyFile:(NSString *)pubKeyFile
                       privateKeyFile:(NSString *)privKeyFile {
    if (self = [self init]) {
        // 优先读取私钥文件,因为私钥文件中是可以获得公钥、私钥和模数的,而公钥文件只能获得公钥和模数
        if ([privKeyFile isKindOfClass:[NSString class]] && privKeyFile.length > 0) {
            self.key.keyType = ZZRSAKeyTypePrivate;
            // 解析私钥文件
            ZZASNOne *privASN = [ZZASNOne loadWithContentsOfFile:privKeyFile];
            // 私钥文件数据存放在 asn->sequence->octet string->sequence->integers
            NSArray<ZZASNInteger *> *integers = privASN.sequence.octetString.sequence.integers;
            if (integers.count >= 4) { // [0,模数n,公钥e,私钥d,...] 至少包含这4个元素
                NSString *module = integers[1].integerHexStr;
                NSString *pubKey = integers[2].integerHexStr;
                NSString *privKey = integers[3].integerHexStr;
                self.key.bits = (int)(module.length * 4); // 16进制的每个字符=4个二进制位
                self.key.n = [[ZZBigInt alloc] initWithString:module radix:16];
                self.key.e = [[ZZBigInt alloc] initWithString:pubKey radix:16];
                self.key.d = [[ZZBigInt alloc] initWithString:privKey radix:16];
            }
        } else if ([pubKeyFile isKindOfClass:[NSString class]] && pubKeyFile.length > 0) {
            self.key.keyType = ZZRSAKeyTypePublic;
            // 解析公钥
            ZZASNOne *pubASN = [ZZASNOne loadWithContentsOfFile:pubKeyFile];
            // 公钥文件数据存放在 asn->sequence->bit string->sequence->integers
            NSArray<ZZASNInteger *> *integers = pubASN.sequence.bitString.sequence.integers;
            if (integers.count >= 2) { // [模数n,公钥e,...] 至少包含这2个元素
                NSString *module = integers[0].integerHexStr;
                NSString *pubKey = integers[1].integerHexStr;
                self.key.bits = (int)(module.length * 4); // 16进制的每个字符=4个二进制位
                self.key.n = [[ZZBigInt alloc] initWithString:module radix:16];
                self.key.e = [[ZZBigInt alloc] initWithString:pubKey radix:16];
                // 如果只传入了公钥文件,则认为公钥既是e又是d,目的是为了让公钥可以进行加密解密
                self.key.d = [[ZZBigInt alloc] initWithString:pubKey radix:16];
            }
        }
    }
    return self;
}

#pragma mark - 加密

- (NSData *)encryptWithData:(NSData *)data {
    int blockSize = self.key.bits / 8;
    int inBlockSize = blockSize - 11;
    int offSet = 0;
    
    NSMutableData *encryptData = [NSMutableData data];
    while (data.length > offSet) {
        int inputLen = (int)MIN(data.length - offSet, inBlockSize);
        SignedByte *encryptByts = NULL;
        int size = 0;
        if ([self encodeBlockWithBytes:data.bytes
                                offset:offSet
                                  size:inputLen
                             blockSize:blockSize
                             destBytes:&encryptByts
                               outSize:&size]) {
            SignedByte value[4] = {0};
            value [0] = size >> 24 & 0xff;
            value [1] = size >> 16 & 0xff;
            value [2] = size >> 8 & 0xff;
            value [3] = size & 0xff;
            
            [encryptData appendBytes:&value length:4];
            [encryptData appendBytes:encryptByts length:size];
            free(encryptByts);
        }
        else {
            //发生异常
            encryptData = nil;
            break;
        }
        
        offSet += inputLen;
    }
    
    return encryptData;
}

- (BOOL)encodeBlockWithBytes:(const Byte *)bytes
                      offset:(int)offset
                        size:(int)size
                   blockSize:(int)blockSize
                   destBytes:(SignedByte **)destBytes
                     outSize:(int *)outSize {
    Byte *source = (Byte *)malloc(size);
    memset(source, 0, size);
    memcpy(source, bytes + offset, size);
    
    Byte *padding = NULL;
    if ([self paddingBlockWithBytes:source
                               size:size
                          blockSize:blockSize
                          destBytes:&padding]) {
        ZZBigInt *message = [[ZZBigInt alloc] initWithUnsignedBytes:padding size:blockSize];
        if ([message compare:self.key.n] == NSOrderedDescending) {
            free(padding);
            free(source);
            return NO;
        }
        // 加密， 计算(message ^ key) % module
        ZZBigInt *key = self.key.keyType == ZZRSAKeyTypePublic ? self.key.e : self.key.d;
        if (self.key.keyType == ZZRSAKeyTypeGenerated) {
            key = self.key.d; // 生成密钥的方式采用d加密，e解密
        }
        ZZBigInt *encrypt = [message pow:key mod:self.key.n];
        [encrypt getBytes:(void **)destBytes length:outSize];
        
        free(padding);
    }
    
    free(source);
    
    return YES;
}

- (BOOL)paddingBlockWithBytes:(const Byte *)bytes
                         size:(int)size
                    blockSize:(int)blockSize
                    destBytes:(Byte **)destBytes {
    if (size > blockSize - 1) {
        return NO;
    }
    
    *destBytes = (Byte *)malloc(blockSize);
    memset(*destBytes, 0, blockSize);
    
    (*destBytes)[0] = 1;
    (*destBytes)[1] = size >> 24 & 0xff;
    (*destBytes)[2] = size >> 16 & 0xff;
    (*destBytes)[3] = size >> 8 & 0xff;
    (*destBytes)[4] = size & 0xff;
    
    memcpy(*destBytes + (blockSize - size), bytes, size);
    
    return YES;
}

#pragma mark - 解密

- (NSData *)decryptWithData:(NSData *)data {
    int offset = 0;
    
    NSMutableData *destData = [NSMutableData data];
    while (offset < data.length) {
        if (offset + 4 > data.length) {
            [destData setData:[NSData data]];
            break;
        }
        
        SignedByte lenBytes[4] = {0};
        [data getBytes:&lenBytes range:NSMakeRange(offset, 4)];
        
        int len = ((lenBytes[0] & 0xff) << 24) + ((lenBytes[1] & 0xff) << 16) + ((lenBytes[2] & 0xff) << 8) + (lenBytes[3] & 0xff);
        offset += 4;
        
        if (offset + len > data.length) {
            [destData setData:[NSData data]];
            break;
        }
        
        SignedByte *buffer = (SignedByte *)malloc(len);
        memset(buffer, 0, len);
        [data getBytes:buffer range:NSMakeRange(offset, len)];
        
        Byte *decryptBytes = NULL;
        int size = 0;
        if ([self decodeBlockWithBytes:buffer
                                  size:len
                             destBytes:&decryptBytes
                               outSize:&size]) {
            [destData appendBytes:decryptBytes length:size];
            free(decryptBytes);
        }
        else {
            free(buffer);
            destData = nil;
            break;
        }
        
        free(buffer);
        offset += len;
    }
    
    return destData;
}

- (BOOL)decodeBlockWithBytes:(const SignedByte *)bytes
                        size:(int)size
                   destBytes:(Byte **)destBytes
                     outSize:(int *)outSize {
    ZZBigInt *cipherMessage = [[ZZBigInt alloc] initWithUnsignedBytes:bytes size:size];
    // 解密， 计算(cipher ^ key) % module
    ZZBigInt *key = self.key.keyType == ZZRSAKeyTypePublic ? self.key.e : self.key.d;
    if (self.key.keyType == ZZRSAKeyTypeGenerated) {
        key = self.key.e; // 生成密钥的方式采用d加密，e解密
    }
    ZZBigInt *sourceMessage = [cipherMessage pow:key mod:self.key.n];
    
    
    Byte *decodeBytes = NULL;
    int len = 0;
    [sourceMessage getUnsignedBytes:(void **)&decodeBytes length:&len];
    
    //还原数据
    if (![self recoveryPaddingBlock:decodeBytes
                               size:len
                          destBytes:destBytes
                            outSize:outSize]) {
        free(decodeBytes);
        return NO;
    }
    
    free(decodeBytes);
    
    return YES;
}

- (BOOL)recoveryPaddingBlock:(const Byte *)padding
                        size:(int)size
                   destBytes:(Byte **)destBytes
                     outSize:(int *)outSize {
    if (padding [0] != 1) {
        return NO;
    }
    
    *outSize = ((padding[1] & 0xff) << 24) + ((padding[2] & 0xff) << 16) + ((padding[3] & 0xff) << 8) + (padding[4] & 0xff);
    *destBytes = (Byte *)malloc(*outSize);
    memset(*destBytes, 0, *outSize);
    memcpy(*destBytes, padding + (size - *outSize), *outSize);
    
    return YES;
}

#pragma mark - Private

/// 生成密钥
/// @return YES 表示生成成功，NO 表示失败
- (BOOL)_zzGenKey {
    ZZBigInt *p = [[ZZBigInt alloc] initWithRandomPremeBits:self.key.bits / 2];
    ZZBigInt *q = [[ZZBigInt alloc] initWithRandomPremeBits:self.key.bits / 2];
    
    ZZBigInt *sp = [p subByInt:1];
    ZZBigInt *sq = [q subByInt:1];
    
    self.key.n = [p multiplyByBigInt:q];
    ZZBigInt *m = [sp multiplyByBigInt:sq];
    
    //    self.key.e = [[ZZBigInt alloc] initWithInt:127];
    self.key.e = [[ZZBigInt alloc] initWithRandomPremeBits:self.key.bits / 2];
    ZZBigInt *t = [self.key.e gcdByBigInt:m];
    while ([t compare:[ZZBigInt one]] == NSOrderedDescending) {
        self.key.e = [self.key.e addByInt:2];
        t = [self.key.e gcdByBigInt:m];
    }
    
    self.key.d = [self.key.e modInverseByBigInt:m];
    // 如果是生成的密钥，默认私钥加密，公钥解密
    self.key.keyType = ZZRSAKeyTypeGenerated;
    
    return YES;
}

@end
