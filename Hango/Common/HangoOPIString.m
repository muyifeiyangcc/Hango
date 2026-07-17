#import "HangoOPIString.h"
#import "HangoLexicon.h"

NSString *HangoAPIPathAppLaunch(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"b9b4b5678c088a932b101a89179033bb7036a027927308e305cf5952bb369465"];
    });
    return value;
}
NSString *HangoAPIPathAuthEntry(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"06ad3f81f56db62558f4e934e1ce12c618c1a6e8cef8914fa90f8aafc58f7721"];
    });
    return value;
}
NSString *HangoAPIPathOpenTimet(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"944b9a8315cdaba5965d5ec72ce22f20039f27b3a7fa405146a83e110fef27db"];
    });
    return value;
}
NSString *HangoAPIPathIOSPayVerify(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"4999df6f6078e5e542e5ce84e2775ddcedc191fc4a457c0a733488c47a7d8587"];
    });
    return value;
}
NSString *HangoOPIKeyOpenTime(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"c80be4699a10bfcbaa6330f879e5ed0c"];
    });
    return value;
}
NSString *HangoOPIKeyCellularPlan(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"17e85875e58a8ff7508820110f3756b3"];
    });
    return value;
}
NSString *HangoOPIKeyNetworkRoute(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"c077e7abb474ec66eb6a3095fe434574"];
    });
    return value;
}
NSString *HangoOPIKeyLanguage(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"051784941f7df819a707be68554ab749"];
    });
    return value;
}
NSString *HangoOPIKeyOtherAppNames(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"f15ed2051d66742a28c3df018f754e68"];
    });
    return value;
}
NSString *HangoOPIKeyTimezone(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"de6a2dac469c5e7f3da57f3f601da0c0"];
    });
    return value;
}
NSString *HangoOPIKeyKeyboards(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"af372071152fbc57ace4b3d9c1fb7807"];
    });
    return value;
}
NSString *HangoOPIKeyDebug(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"d1902ef06cf025728abab838b10497a3"];
    });
    return value;
}
NSString *HangoOPILoginKeyPassword(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"5c131abbb529d156bd77e5787c7cc2c7"];
    });
    return value;
}
NSString *HangoOPILoginKeyDeviceNo(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"be25c8c3c0c2acce54b02510079a870b"];
    });
    return value;
}
NSString *HangoOPILoginBodyKeyDeviceNo(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"f7e85c44f21484568cdd3bd3af1ede5b"];
    });
    return value;
}
NSString *HangoOPIKeyAppId(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"c2700447da704dc2e5f19b4a9fa3be77"];
    });
    return value;
}
NSString *HangoOPIKeyAppVersion(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"8e2f3f61e1f473d90e81a123e4b25368"];
    });
    return value;
}
NSString *HangoOPIPayKeyPurchaseId(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"3a4b63fdf5c75883872dacd86c06077e"];
    });
    return value;
}
NSString *HangoOPIPayKeyReceipt(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"aaa50bf1a8eb95c1a0d5b73edee60c65"];
    });
    return value;
}
NSString *HangoOPIPayKeyCallback(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"05677e688927333f73e6c78ba8f1bd2c"];
    });
    return value;
}
NSString *HangoOPIHeaderPushToken(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"ab4ca1d4f62a315131df36820ed16375"];
    });
    return value;
}
NSString *HangoOPIHeaderLoginToken(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"e694198074c96becfba862116806bc5e"];
    });
    return value;
}
NSString *HangoOPIHeaderKeyOpenParams(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"268557d95c5ce53a1d810953631a14ad"];
    });
    return value;
}
NSString *HangoOPIHeaderKeyToken(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"52b4005633a9c299f758c9ce3ee71962"];
    });
    return value;
}
NSString *HangoOPIHeaderKeyTimestamp(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"51c9b7c52ba833924c485e19ef82891f"];
    });
    return value;
}
NSString *HangoOPIResponseKeyCode(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"86f04b41ded3c19aab3e2b6f180129b1"];
    });
    return value;
}
NSString *HangoOPIResponseKeyMessage(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"dedc15571e76da8820f4c490a063d117"];
    });
    return value;
}
NSString *HangoOPIResponseKeyData(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"5914d568f02eb4fc626c203c5a024f33"];
    });
    return value;
}
NSString *HangoOPIResponseKeyResult(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"bf65fdfb34649f1699e9ced1d94f96a0"];
    });
    return value;
}
NSString *HangoOPIResponseKeyOpenValue(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"c1a53b5453f1f5203534bf39dd47c6ce"];
    });
    return value;
}
NSString *HangoOPIResponseKeyToken(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"52b4005633a9c299f758c9ce3ee71962"];
    });
    return value;
}
NSString *HangoOPIResponseKeyPassword(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"5c131abbb529d156bd77e5787c7cc2c7"];
    });
    return value;
}
NSString *HangoOPISuccessCode(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"fb53ceff9c48e52c00618966d88c2ed3"];
    });
    return value;
}
