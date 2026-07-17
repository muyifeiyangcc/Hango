#import "HangoBridgeString.h"
#import "HangoLexicon.h"

NSString *HangoBridgePrimaryChannel(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"44ba55074f14f0bac19d2cff8bf8bed3"];
    });
    return value;
}
NSString *HangoBridgeCloseChannel(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"d0425d7f90de3a274348e514ebbc69ea"];
    });
    return value;
}
NSString *HangoBridgeOpenBrowserChannel(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"b0675703e6caa96f9d5cf045edfbb5df"];
    });
    return value;
}
NSString *HangoBridgeResultEvent(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"197ee20ceabe8d9c2cff52757f753a32"];
    });
    return value;
}
NSString *HangoBridgeFailureCode(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"5f65d7ab730d3ed093a8fd1580b34513"];
    });
    return value;
}
NSString *HangoBridgeWelcomePageOpenStateEvent(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"66fe8dd3eab706b2cdbac39293f29b8a"];
    });
    return value;
}
NSString *HangoBridgeTraceKey(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"375f67d82c0085d332e4ea380f1a3c64"];
    });
    return value;
}
NSString *HangoBridgeBatchKey(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"22d2c2ed80ad201fc3e2f95b624a09a5"];
    });
    return value;
}
NSString *HangoBridgeOpenURLKey(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"2935f9aaa359854f686e9f48aa62ac7c"];
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
