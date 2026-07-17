#import "HangoLexicon.h"
#import "HangoAppConfig.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation HangoLexicon

+ (NSData *)dataFromHexString:(NSString *)hex {
    if (hex.length == 0) {
        return [NSData data];
    }
    NSMutableData *data = [NSMutableData data];
    NSString *remaining = hex;
    while (remaining.length >= 2) {
        NSString *byteString = [remaining substringToIndex:2];
        remaining = [remaining substringFromIndex:2];
        unsigned int byte = 0;
        NSScanner *scanner = [NSScanner scannerWithString:byteString];
        if (![scanner scanHexInt:&byte]) {
            continue;
        }
        uint8_t value = (uint8_t)(byte & 0xFF);
        [data appendBytes:&value length:1];
    }
    return data;
}

+ (NSString *)textFromBlob:(NSString *)blob {
    NSData *blobData = [self dataFromHexString:blob];
    if (blobData.length == 0) {
        return @"";
    }
    NSData *keyData = [HangoContentKey dataUsingEncoding:NSUTF8StringEncoding];
    NSData *vectorData = [HangoContentIV dataUsingEncoding:NSUTF8StringEncoding];
    if (keyData.length != kCCKeySizeAES128 || vectorData.length != kCCBlockSizeAES128) {
        return @"";
    }
    size_t outputLength = blobData.length + kCCBlockSizeAES128;
    void *outputBytes = malloc(outputLength);
    if (!outputBytes) {
        return @"";
    }
    size_t bytesProcessed = 0;
    CCCryptorStatus status = CCCrypt(kCCDecrypt,
                                     kCCAlgorithmAES,
                                     kCCOptionPKCS7Padding,
                                     keyData.bytes,
                                     keyData.length,
                                     vectorData.bytes,
                                     blobData.bytes,
                                     blobData.length,
                                     outputBytes,
                                     outputLength,
                                     &bytesProcessed);
    if (status != kCCSuccess) {
        free(outputBytes);
        return @"";
    }
    NSData *opened = [NSData dataWithBytesNoCopy:outputBytes length:bytesProcessed freeWhenDone:YES];
    return [[NSString alloc] initWithData:opened encoding:NSUTF8StringEncoding] ?: @"";
}

@end
