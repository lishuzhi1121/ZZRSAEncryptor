# ZZRSAEncryptor

基于RSA公钥算法的加密解密工具库iOS OC语言实现，不依赖iOS系统Keychain和Security.framework。


## 一、理论基础


### 1. RSA算法原理

关于RSA算法原理网上资料有很多，这里推荐阮老师的两篇博客 [RSA算法原理（一）](https://www.ruanyifeng.com/blog/2013/06/rsa_algorithm_part_one.html) 和 [RSA算法原理（二）](https://www.ruanyifeng.com/blog/2013/06/rsa_algorithm_part_two.html) 。认真看完基本就明白RSA是怎么回事儿了。这里只讲加密解密过程涉及到的三个元素：

- 模（n）：用于加密解密过程求余的模数，模的长度决定了密钥的大小（一般1024位或者2048位）

- 公钥（e）：用于加密过程中的指数运算（准确的来说，e只是公钥的一部分，但基于本库的实现方式，暂且称之为公钥）

- 私钥（d）：用于解密过程中的指数运算（同理，d只是私钥的一部分，暂且称之为私钥）

  

### 2. 密钥文件类型

实现RSA加解密除了使用给定的密钥字符串以外，更常用的方式是采用密钥文件的形式。RSA密钥文件常见的有der、pem两种格式：

- der：密钥的二进制表述格式，遵守[ASN.1编码格式](https://docs.microsoft.com/en-us/windows/win32/seccertenroll/about-asn-1-type-system) 。

- pem：就是将der文件内容对应的16进制字符串进行Base64编码后的字符格式，可通过解码还原为der格式。pem格式常见的有两种标准：

  - PKCS#1：专门为 RSA 密钥进行定义的，其对应的 PEM 文件格式如下：

    ~~~tex
    -----BEGIN RSA PUBLIC KEY-----
    BASE64 ENCODED DATA
    -----END RSA PUBLIC KEY-----
    ~~~

    上面的内容 *BASE64 ENCODED DATA* 指的就是 ANS.1 的 DER 的 Base64 编码，其内容类似于：

    ~~~tex
    MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQChHmaw+WUhWrStdxWBcAR39i2e  
    3yz+vfLiDALeTpWIH1jKiYtvw4nMg6453pXAJSvPn7mKaiGiC3USIt8qTL4eCPi9  
    yNRDpZ1JRHI8M87VYB4c9KMk6IuVFiYyZ4MBTP87t89yeL9EOrAD0eFgi5fPx3g8  
    b9QrmnyPhMVjP7ct+wIDAQAB
    ~~~

    

  - PKCS#8：定义了一个密钥格式的通用方案，它不仅仅为 RSA 所使用，同样也可以被其它密钥所使用，其所对应的 PEM 格式定义如下：

    ~~~tex
    -----BEGIN PUBLIC KEY-----
    BASE64 ENCODED DATA
    -----END PUBLIC KEY-----
    ~~~

    注意，这里就没有 RSA 字样了，因为 PKCS#8 是一个通用型的密钥格式方案。



### 3. ASN.1 编码格式

关于ASN.1的编码格式，[微软官方文档](https://docs.microsoft.com/en-us/windows/win32/seccertenroll/about-der-encoding-of-asn-1-types)有非常详细的描述，为了从密钥文件中解析出对应的n、e、d，本库实现了 **ZZASNOne** 部分（目前只实现了openssl生成的密钥文件中使用到的类型节点），用于解析ASN.1编码格式。



## 二、项目结构

本项目有三个部分：

1. ZZASNOne：主要用于解析密钥文件内容；
2. ZZASNEncryptor：实现RSA算法的核心库，依赖于ZZASNOne；
3. ZZASNEncryptorDemo：示例程序，主要用于演示ZZASNEncryptor如何使用；



## 三、接入方式

1. 将 `ZZASNEncryptor/Package` 目录下的 `ZZASNEncryptor.framework` 拖到你的项目中并选择copy
2. 添加 `ZZRSAEncryptor.framework` 的系统依赖库 `libc++.tbd`

完成后如下图：
![install](https://github.com/lishuzhi1121/ZZRSAEncryptor/raw/main/images/2021-11-18-lc5J3t-tE7YHB.png)


## 四、使用方式



### 1. 密钥生成

RSA公钥加密算法使用的密钥生成方式有两种，一种是直接使用该库提供的方法生成，另一种是借助 `openssl` 命令行工具生成。一般采用后者，主要是因为密钥生成多在后端完成，所以不会采用客户端代码来生成密钥。

#### 1.1 使用该库方法生成密钥

示例代码如下：

~~~objective-c
#import "ViewController.h"
#import <ZZRSAEncryptor/ZZRSAEncryptor.h>

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *plainText = @"Sands@1992.11.21哈哈哈";
    
    // MARK: - 内部生成密钥方式加密解密（不建议使用！）
    ZZRSAEncryptor *encryptor = [ZZRSAEncryptor encryptorWithKeySize:1024];
    // 加密
    NSData *enData = [encryptor encryptWithData:[plainText dataUsingEncoding:NSUTF8StringEncoding]];
    if (enData.length > 0) {
        // 解密
        NSData *deData = [encryptor decryptWithData:enData];
        NSString *deStr = [[NSString alloc] initWithData:deData encoding:NSUTF8StringEncoding];
        NSLog(@"解密后: %@", deStr);
    }
    
}

~~~



#### 1.2 使用 openssl 生成密钥

需要明确的是：openssl 生成密钥的流程是先生成一个私钥，然后从私钥中导出公钥。（公钥信息包含在私钥中）

生成私钥命令如下：

~~~shell
openssl genrsa -out rsa_1024_private.pem 1024
~~~

导出公钥命令如下：

~~~shell
openssl rsa -in rsa_1024_private_key.pem -pubout -out rsa_1024_public_key.pem
~~~


### 2. 加密解密

加密解密的方法调用非常简单，接口注释也比较详细，示例代码如下：

~~~objective-c
#import "ViewController.h"
#import <ZZRSAEncryptor/ZZRSAEncryptor.h>

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *plainText = @"Sands@1992.11.21哈哈哈";
    
    // MARK: - 密钥文件方式加密解密
    // MARK: - 公钥加密私钥解密
    // 公钥加密
    NSString *pubFilePath = [[NSBundle mainBundle] pathForResource:@"rsa_1024_public_key" ofType:@"pem"];
    ZZRSAEncryptor *pubEncryptor = [ZZRSAEncryptor encryptorWithPublicKeyFile:pubFilePath
                                                               privateKeyFile:nil];
    NSData *enData = [pubEncryptor encryptWithData:[plainText dataUsingEncoding:NSUTF8StringEncoding]];
    if (enData.length > 0) {
        // 私钥解密
        NSString *privFilePath = [[NSBundle mainBundle] pathForResource:@"rsa_1024_private_key_pkcs8" ofType:@"pem"];
        ZZRSAEncryptor *privEncryptor = [ZZRSAEncryptor encryptorWithPublicKeyFile:nil
                                                                    privateKeyFile:privFilePath];
        NSData *deData = [privEncryptor decryptWithData:enData];
        NSString *deStr = [[NSString alloc] initWithData:deData encoding:NSUTF8StringEncoding];
        NSLog(@"私钥解密后: %@", deStr);
    }
    
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

}

~~~



## 五、其他说明

暂无。

