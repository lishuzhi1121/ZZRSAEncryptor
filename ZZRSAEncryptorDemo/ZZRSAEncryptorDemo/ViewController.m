//
//  ViewController.m
//  ZZRSAEncryptorDemo
//
//  Created by SandsLee on 2021/11/17.
//

#import "ViewController.h"
#import <ZZRSAEncryptor/ZZRSAEncryptor.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *plainText = @"Sands@1992.11.21哈哈哈";
    
    // MARK: - 内部生成密钥方式加密解密
    ZZRSAEncryptor *encryptor = [ZZRSAEncryptor encryptorWithKeySize:1024];
    // 加密
    NSData *enData = [encryptor encryptWithData:[plainText dataUsingEncoding:NSUTF8StringEncoding]];
    if (enData.length > 0) {
        // 解密
        NSData *deData = [encryptor decryptWithData:enData];
        NSString *deStr = [[NSString alloc] initWithData:deData encoding:NSUTF8StringEncoding];
        NSLog(@"解密后: %@", deStr);
    }
    
    // MARK: - 密钥字符串方式加密解密
//    NSString *pubKey = @"010001";
//    NSString *priKey = @"55195FB49842573F123F0557B1EB040FEEB5956930735CE2983CF215B722BE22B13B067668F866F026D3E2D9F01714299700F874B565D19DF15D3BC862D96E596AA51E763C78181616B02C1328D8F92A27311F4301EAE0F4FF7B0DACC6E8452CD68F8E45DED7A40C711CF4CAEC7341847FF23A1ED426E349891B27846B5D8EF1";
//    NSString *module = @"DFBF7814C97407A7DAADA5D00CD865AA89A3915045A39482721431E680386B08457C93A979F043CA5311403FF403BDB37F5BD51643C4FF27C6EDDFCF044546A2A248BD71D05FE72EE0C00C8D8648481D4B3895B802AFD6F1C4462402311F0C9651CE0E15748E804A455B04CCD254CB26047962A08BDCC3751357111FCB4F7557";
//    ZZRSAEncryptor *encryptor = [ZZRSAEncryptor encryptorWithKeySize:1024
//                                                           publicKey:pubKey
//                                                          privateKey:priKey
//                                                              module:module];
//    // 加密
//    NSData *enData = [encryptor encryptWithData:[plainText dataUsingEncoding:NSUTF8StringEncoding]];
//    if (enData.length > 0) {
//        // 解密
//        NSData *deData = [encryptor decryptWithData:enData];
//        NSString *deStr = [[NSString alloc] initWithData:deData encoding:NSUTF8StringEncoding];
//        NSLog(@"解密后: %@", deStr);
//    }
    
    
    // MARK: - 密钥文件方式加密解密
    // MARK: - 公钥加密私钥解密
    // 公钥加密
//    NSString *pubFilePath = [[NSBundle mainBundle] pathForResource:@"rsa_1024_public_key" ofType:@"pem"];
//    ZZRSAEncryptor *pubEncryptor = [ZZRSAEncryptor encryptorWithPublicKeyFile:pubFilePath
//                                                               privateKeyFile:nil];
//    NSData *enData = [pubEncryptor encryptWithData:[plainText dataUsingEncoding:NSUTF8StringEncoding]];
//    if (enData.length > 0) {
//        // 私钥解密
//        NSString *privFilePath = [[NSBundle mainBundle] pathForResource:@"rsa_1024_private_key_pkcs8" ofType:@"pem"];
//        ZZRSAEncryptor *privEncryptor = [ZZRSAEncryptor encryptorWithPublicKeyFile:nil
//                                                                    privateKeyFile:privFilePath];
//        NSData *deData = [privEncryptor decryptWithData:enData];
//        NSString *deStr = [[NSString alloc] initWithData:deData encoding:NSUTF8StringEncoding];
//        NSLog(@"私钥解密后: %@", deStr);
//    }
    
    // MARK: - 私钥加密公钥解密
//    // 私钥加密
//    NSString *privFilePath = [[NSBundle mainBundle] pathForResource:@"rsa_1024_private_key_pkcs8" ofType:@"pem"];
//    ZZRSAEncryptor *privEncryptor = [ZZRSAEncryptor encryptorWithPublicKeyFile:nil
//                                                                privateKeyFile:privFilePath];
//    NSData *enData = [privEncryptor encryptWithData:[plainText dataUsingEncoding:NSUTF8StringEncoding]];
//    if (enData.length > 0) {
//        // 公钥解密
//        NSString *pubFilePath = [[NSBundle mainBundle] pathForResource:@"rsa_1024_public_key" ofType:@"pem"];
//        ZZRSAEncryptor *pubEncryptor = [ZZRSAEncryptor encryptorWithPublicKeyFile:pubFilePath
//                                                                   privateKeyFile:nil];
//        NSData *deData = [pubEncryptor decryptWithData:enData];
//        NSString *deStr = [[NSString alloc] initWithData:deData encoding:NSUTF8StringEncoding];
//        NSLog(@"公钥解密后: %@", deStr);
//    }
    
    
    
    
}


@end
