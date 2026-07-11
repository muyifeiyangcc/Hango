#import "HangoBridgeString.h"

static NSString *HangoDecodeBridgeBytes(const uint8_t *bytes, NSUInteger length) {
    if (length == 0) {
        return @"";
    }
    NSMutableData *data = [NSMutableData dataWithLength:length];
    uint8_t *out = data.mutableBytes;
    const uint8_t key = 0x5A;
    for (NSUInteger i = 0; i < length; i++) {
        out[i] = bytes[i] ^ key;
    }
    return [[NSString alloc] initWithBytes:out length:length encoding:NSUTF8StringEncoding] ?: @"";
}

NSString *HangoBridgePrimaryChannel(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static const uint8_t bytes[] = { 0x28, 0x3F, 0x39, 0x32, 0x3B, 0x28, 0x3D, 0x3F, 0x0A, 0x3B, 0x23 };
        value = HangoDecodeBridgeBytes(bytes, sizeof(bytes));
    });
    return value;
}

NSString *HangoBridgeCloseChannel(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static const uint8_t bytes[] = { 0x19, 0x36, 0x35, 0x29, 0x3F };
        value = HangoDecodeBridgeBytes(bytes, sizeof(bytes));
    });
    return value;
}

NSString *HangoBridgeOpenBrowserChannel(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static const uint8_t bytes[] = { 0x35, 0x2A, 0x3F, 0x34, 0x18, 0x28, 0x35, 0x2D, 0x29, 0x3F, 0x28 };
        value = HangoDecodeBridgeBytes(bytes, sizeof(bytes));
    });
    return value;
}

NSArray<NSString *> *HangoBridgeRegisteredChannelNames(void) {
    return @[
        HangoBridgePrimaryChannel(),
        HangoBridgeCloseChannel(),
        HangoBridgeOpenBrowserChannel(),
    ];
}

NSString *HangoBridgeResultEvent(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static const uint8_t bytes[] = { 0x33, 0x35, 0x29, 0x0A, 0x3B, 0x23, 0x08, 0x3F, 0x29, 0x2F, 0x36, 0x2E };
        value = HangoDecodeBridgeBytes(bytes, sizeof(bytes));
    });
    return value;
}

NSString *HangoBridgeFailureCode(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static const uint8_t bytes[] = { 0x2A, 0x3B, 0x23, 0x05, 0x3F, 0x28, 0x28, 0x35, 0x28 };
        value = HangoDecodeBridgeBytes(bytes, sizeof(bytes));
    });
    return value;
}

NSString *HangoBridgeNativeOpenStateEvent(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static const uint8_t bytes[] = { 0x34, 0x3B, 0x2E, 0x33, 0x2C, 0x3F, 0x15, 0x2A, 0x3F, 0x34, 0x09, 0x2E, 0x3B, 0x2E, 0x3F };
        value = HangoDecodeBridgeBytes(bytes, sizeof(bytes));
    });
    return value;
}

NSString *HangoBridgeTraceKey(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static const uint8_t bytes[] = { 0x35, 0x28, 0x3E, 0x3F, 0x28, 0x19, 0x35, 0x3E, 0x3F };
        value = HangoDecodeBridgeBytes(bytes, sizeof(bytes));
    });
    return value;
}

NSString *HangoBridgeBatchKey(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static const uint8_t bytes[] = { 0x38, 0x3B, 0x2E, 0x39, 0x32, 0x14, 0x35 };
        value = HangoDecodeBridgeBytes(bytes, sizeof(bytes));
    });
    return value;
}

NSString *HangoBridgeOpenURLKey(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static const uint8_t bytes[] = { 0x2F, 0x28, 0x36 };
        value = HangoDecodeBridgeBytes(bytes, sizeof(bytes));
    });
    return value;
}
