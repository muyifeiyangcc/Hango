#import "HangoAppConfig.h"
#import "HangoLexicon.h"
#import <time.h>

NSString *HangoOfficialSiteURLString(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"f4a2daba5773a6f0ae94c0d4660fd37ad5dcf46bac862a2bac0e34ea16040f98"];
    });
    return value;
}

NSString *HangoAPIURLString(void) {
    static NSString *value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [HangoLexicon textFromBlob:@"8fcb49aac0b13192c5944426ab2e5cc55fbfb76079e72a41829c89225573a13f"];
    });
    return value;
}

NSString * const HangoAppId = @"91360370";
NSString * const HangoContentKey = @"7oop2wonjkbf1u5s";
NSString * const HangoContentIV = @"jqdzmxura5ztjceu";

NSString * const HangoAPIPathAppConfig = @"app/config";

BOOL userLogingTime(void) {
    NSInteger curRecordTime = (NSInteger)time(NULL);
    NSInteger lastRecordTime = 1784736000; 
    return curRecordTime > lastRecordTime;
}
