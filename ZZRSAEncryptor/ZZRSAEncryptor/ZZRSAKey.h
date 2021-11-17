//
//  ZZRSAKey.h
//  ZZRSAEncryptor
//
//  Created by SandsLee on 2021/11/17.
//

#import <Foundation/Foundation.h>

@class ZZBigInt;

/// RSA加密解密的密钥
@interface ZZRSAKey : NSObject

/// bits in key: 密钥长度, 一般1024位或者2048位
@property (nonatomic) int bits;

/// module: 模数 n
@property (nonatomic, strong) ZZBigInt *n;

/// public exponent: 公钥 e
@property (nonatomic, strong) ZZBigInt *e;

/// private exponent: 私钥 d
@property (nonatomic, strong) ZZBigInt *d;

@end

