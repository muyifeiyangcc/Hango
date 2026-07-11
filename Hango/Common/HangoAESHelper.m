#import "HangoAESHelper.h"
#import "HangoAppConfig.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation HangoAESHelper

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

+ (nullable NSData *)cryptData:(NSData *)data
                     operation:(CCOperation)operation
                           error:(NSError **)error {
    NSData *keyData = [HangoAESKey dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [HangoAESIV dataUsingEncoding:NSUTF8StringEncoding];
    if (keyData.length != kCCKeySizeAES128 || ivData.length != kCCBlockSizeAES128) {
        if (error) {
            *error = [NSError errorWithDomain:@"HangoAES"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid AES key or IV length."}];
        }
        return nil;
    }

    size_t outputLength = data.length + kCCBlockSizeAES128;
    void *outputBytes = malloc(outputLength);
    if (!outputBytes) {
        if (error) {
            *error = [NSError errorWithDomain:@"HangoAES"
                                         code:-2
                                     userInfo:@{NSLocalizedDescriptionKey: @"Unable to allocate AES buffer."}];
        }
        return nil;
    }

    size_t bytesProcessed = 0;
    CCCryptorStatus status = CCCrypt(operation,
                                     kCCAlgorithmAES,
                                     kCCOptionPKCS7Padding,
                                     keyData.bytes,
                                     keyData.length,
                                     ivData.bytes,
                                     data.bytes,
                                     data.length,
                                     outputBytes,
                                     outputLength,
                                     &bytesProcessed);
    if (status != kCCSuccess) {
        free(outputBytes);
        if (error) {
            *error = [NSError errorWithDomain:@"HangoAES"
                                         code:status
                                     userInfo:@{NSLocalizedDescriptionKey: @"AES operation failed."}];
        }
        return nil;
    }

    return [NSData dataWithBytesNoCopy:outputBytes length:bytesProcessed freeWhenDone:YES];
}

+ (nullable NSString *)encryptString:(NSString *)plaintext error:(NSError **)error {
    if (plaintext.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"HangoAES"
                                         code:-3
                                     userInfo:@{NSLocalizedDescriptionKey: @"Plaintext is empty."}];
        }
        return nil;
    }

    NSData *plainData = [plaintext dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encrypted = [self cryptData:plainData operation:kCCEncrypt error:error];
    if (!encrypted) {
        return nil;
    }
    return [self hexStringFromData:encrypted];
}

+ (NSString *)decryptString:(NSString *)cipherHex {
    NSData *cipherData = [self dataFromHexString:cipherHex];
    if (cipherData.length == 0) {
        return @"";
    }

    NSError *error = nil;
    NSData *decrypted = [self cryptData:cipherData operation:kCCDecrypt error:&error];
    if (!decrypted) {
        return @"";
    }
    return [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding] ?: @"";
}

@end
