//
//  ZZRSAEncryptor.h
//  ZZRSAEncryptor
//
//  Created by SandsLee on 2021/11/17.
//

#import <Foundation/Foundation.h>

//! Project version number for ZZRSAEncryptor.
FOUNDATION_EXPORT double ZZRSAEncryptorVersionNumber;

//! Project version string for ZZRSAEncryptor.
FOUNDATION_EXPORT const unsigned char ZZRSAEncryptorVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ZZRSAEncryptor/PublicHeader.h>

#import <ZZRSAEncryptor/ZZBigInt.h>
#import <ZZRSAEncryptor/ZZRSAKey.h>






/// RSA加密解密器
@interface ZZRSAEncryptor : NSObject

/// 密钥信息
@property (nonatomic, strong, readonly) ZZRSAKey *key;


/// 初始化RSA加密器
/// @param keySize 密钥长度
+ (instancetype)encryptorWithKeySize:(int)keySize;

/// 初始化RSA加密器
/// @param keySize 密钥长度
/// @param publicKey 公钥
/// @param privateKey 私钥
/// @param module 模数
+ (instancetype)encryptorWithKeySize:(int)keySize
                           publicKey:(NSString *)publicKey
                          privateKey:(NSString *)privateKey
                              module:(NSString *)module;

/// 加密数据
/// @param data 数据
/// @return 加密后的数据
- (NSData *)encryptWithData:(NSData *)data;

/// 解密数据
/// @param data 加密后数据
/// @return 解密后数据
- (NSData *)decryptWithData:(NSData *)data;

@end
