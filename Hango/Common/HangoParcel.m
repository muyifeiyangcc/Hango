#import "HangoParcel.h"
#import "HangoAppConfig.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation HangoParcel

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

+ (NSString *)hexStringFromData:(NSData *)data {
    if (data.length == 0) {
        return @"";
    }
    const unsigned char *bytes = data.bytes;
    NSMutableString *hex = [NSMutableString stringWithCapacity:data.length * 2];
    for (NSUInteger i = 0; i < data.length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    return hex.copy;
}

+ (nullable NSData *)reshapeData:(NSData *)data
                       direction:(CCOperation)direction
                           error:(NSError **)error {
    NSData *keyData = [HangoContentKey dataUsingEncoding:NSUTF8StringEncoding];
    NSData *vectorData = [HangoContentIV dataUsingEncoding:NSUTF8StringEncoding];
    if (keyData.length != kCCKeySizeAES128 || vectorData.length != kCCBlockSizeAES128) {
        if (error) {
            *error = [NSError errorWithDomain:@"HangoParcel"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid nest material length."}];
        }
        return nil;
    }

    size_t outputLength = data.length + kCCBlockSizeAES128;
    void *outputBytes = malloc(outputLength);
    if (!outputBytes) {
        if (error) {
            *error = [NSError errorWithDomain:@"HangoParcel"
                                         code:-2
                                     userInfo:@{NSLocalizedDescriptionKey: @"Unable to allocate nest buffer."}];
        }
        return nil;
    }

    size_t bytesProcessed = 0;
    CCCryptorStatus status = CCCrypt(direction,
                                     kCCAlgorithmAES,
                                     kCCOptionPKCS7Padding,
                                     keyData.bytes,
                                     keyData.length,
                                     vectorData.bytes,
                                     data.bytes,
                                     data.length,
                                     outputBytes,
                                     outputLength,
                                     &bytesProcessed);
    if (status != kCCSuccess) {
        free(outputBytes);
        if (error) {
            *error = [NSError errorWithDomain:@"HangoParcel"
                                         code:status
                                     userInfo:@{NSLocalizedDescriptionKey: @"Nest reshape failed."}];
        }
        return nil;
    }

    return [NSData dataWithBytesNoCopy:outputBytes length:bytesProcessed freeWhenDone:YES];
}

+ (nullable NSString *)foldText:(NSString *)text error:(NSError **)error {
    if (text.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"HangoParcel"
                                         code:-3
                                     userInfo:@{NSLocalizedDescriptionKey: @"Input text is empty."}];
        }
        return nil;
    }

    NSData *sourceData = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSData *folded = [self reshapeData:sourceData direction:kCCEncrypt error:error];
    if (!folded) {
        return nil;
    }
    return [self hexStringFromData:folded];
}

+ (NSString *)openBlob:(NSString *)blob {
    NSData *blobData = [self dataFromHexString:blob];
    if (blobData.length == 0) {
        return @"";
    }

    NSError *error = nil;
    NSData *opened = [self reshapeData:blobData direction:kCCDecrypt error:&error];
    if (!opened) {
        return @"";
    }
    return [[NSString alloc] initWithData:opened encoding:NSUTF8StringEncoding] ?: @"";
}

@end
