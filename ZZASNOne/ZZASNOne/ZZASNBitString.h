//
//  ZZASNBitString.h
//  ZZRSADemo
//
//  Created by SandsLee on 2021/11/16.
//

#import <Foundation/Foundation.h>
#import <ZZASNOne/ZZASNNodeProtocol.h>

@class ZZASNSequence;

@interface ZZASNBitString : NSObject<ZZASNNodeProtocol>

/// 一个 BIT STRING 中暂定只允许包含一个 SEQUENCE
@property (nonatomic, strong) ZZASNSequence *sequence;

@end

