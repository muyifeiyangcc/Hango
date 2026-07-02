#import "HangoDisplayString.h"

typedef struct {
    const uint8_t *bytes;
    NSUInteger length;
} HangoDisplayStringEntry;

static const uint8_t kHangoDS_Message[] = { 0x05, 0x04, 0x1D, 0x14, 0x0E, 0x50, 0x56 };
static const NSUInteger kHangoDS_MessageLen = 7;

static const uint8_t kHangoDS_Follow[] = { 0x0E, 0x0E, 0x02, 0x0B, 0x00, 0x40 };
static const NSUInteger kHangoDS_FollowLen = 6;

static const uint8_t kHangoDS_Unfollow[] = { 0x1D, 0x0F, 0x08, 0x08, 0x03, 0x5B, 0x5C, 0x46 };
static const NSUInteger kHangoDS_UnfollowLen = 8;

static const uint8_t kHangoDS_FollowedSuccessfully[] = { 0x0E, 0x0E, 0x02, 0x0B, 0x00, 0x40, 0x56, 0x55, 0x68, 0x12, 0x1B, 0x04, 0x0C, 0x52, 0x40, 0x42, 0x2E, 0x14, 0x02, 0x0B, 0x16 };
static const NSUInteger kHangoDS_FollowedSuccessfullyLen = 21;

static const uint8_t kHangoDS_UnfollowedSuccessfully[] = { 0x1D, 0x0F, 0x08, 0x08, 0x03, 0x5B, 0x5C, 0x46, 0x2D, 0x05, 0x4E, 0x14, 0x1A, 0x54, 0x50, 0x54, 0x3B, 0x12, 0x08, 0x12, 0x03, 0x5B, 0x4A };
static const NSUInteger kHangoDS_UnfollowedSuccessfullyLen = 23;

static const uint8_t kHangoDS_Block[] = { 0x0A, 0x0D, 0x01, 0x04, 0x04 };
static const NSUInteger kHangoDS_BlockLen = 5;

static const uint8_t kHangoDS_BlockQuestion[] = { 0x0A, 0x0D, 0x01, 0x04, 0x04, 0x08 };
static const NSUInteger kHangoDS_BlockQuestionLen = 6;

static const uint8_t kHangoDS_BlockedSuccessfully[] = { 0x0A, 0x0D, 0x01, 0x04, 0x04, 0x52, 0x57, 0x11, 0x3B, 0x14, 0x0D, 0x04, 0x0A, 0x44, 0x40, 0x57, 0x3D, 0x0D, 0x02, 0x1E };
static const NSUInteger kHangoDS_BlockedSuccessfullyLen = 20;

static const uint8_t kHangoDS_BlockConfirmFormat[] = { 0x09, 0x13, 0x0B, 0x47, 0x16, 0x58, 0x46, 0x11, 0x3B, 0x14, 0x1C, 0x02, 0x4F, 0x4E, 0x5C, 0x44, 0x68, 0x16, 0x0F, 0x09, 0x1B, 0x17, 0x47, 0x5E, 0x68, 0x03, 0x02, 0x08, 0x0C, 0x5C, 0x13, 0x14, 0x08, 0x5E };
static const NSUInteger kHangoDS_BlockConfirmFormatLen = 34;

static const uint8_t kHangoDS_AlreadyBlocked[] = { 0x1C, 0x09, 0x07, 0x14, 0x4F, 0x54, 0x5C, 0x5F, 0x3C, 0x00, 0x0D, 0x13, 0x4F, 0x5E, 0x40, 0x11, 0x29, 0x0D, 0x1C, 0x02, 0x0E, 0x53, 0x4A, 0x11, 0x2A, 0x0D, 0x01, 0x04, 0x04, 0x52, 0x57, 0x1F };
static const NSUInteger kHangoDS_AlreadyBlockedLen = 32;

static const uint8_t kHangoDS_Blacklist[] = { 0x0A, 0x0D, 0x0F, 0x04, 0x04, 0x5B, 0x5A, 0x42, 0x3C };
static const NSUInteger kHangoDS_BlacklistLen = 9;

static const uint8_t kHangoDS_RemoveFromBlacklist[] = { 0x1A, 0x04, 0x03, 0x08, 0x19, 0x52, 0x13, 0x57, 0x3A, 0x0E, 0x03, 0x47, 0x2D, 0x5B, 0x52, 0x52, 0x23, 0x0D, 0x07, 0x14, 0x1B, 0x08 };
static const NSUInteger kHangoDS_RemoveFromBlacklistLen = 22;

static const uint8_t kHangoDS_RemoveBlacklistFormat[] = { 0x09, 0x13, 0x0B, 0x47, 0x16, 0x58, 0x46, 0x11, 0x3B, 0x14, 0x1C, 0x02, 0x4F, 0x4E, 0x5C, 0x44, 0x68, 0x16, 0x0F, 0x09, 0x1B, 0x17, 0x47, 0x5E, 0x68, 0x13, 0x0B, 0x0A, 0x00, 0x41, 0x56, 0x11, 0x6D, 0x21, 0x4E, 0x01, 0x1D, 0x58, 0x5E, 0x11, 0x3C, 0x09, 0x0B, 0x47, 0x0D, 0x5B, 0x52, 0x52, 0x23, 0x0D, 0x07, 0x14, 0x1B, 0x08 };
static const NSUInteger kHangoDS_RemoveBlacklistFormatLen = 54;

static const uint8_t kHangoDS_Report[] = { 0x1A, 0x04, 0x1E, 0x08, 0x1D, 0x43 };
static const NSUInteger kHangoDS_ReportLen = 6;

static const uint8_t kHangoDS_ReportSuccessful[] = { 0x1A, 0x04, 0x1E, 0x08, 0x1D, 0x43, 0x13, 0x42, 0x3D, 0x02, 0x0D, 0x02, 0x1C, 0x44, 0x55, 0x44, 0x24 };
static const NSUInteger kHangoDS_ReportSuccessfulLen = 17;

static const uint8_t kHangoDS_Value[] = { 0x1F, 0x00, 0x02, 0x0B, 0x0A, 0x43 };
static const NSUInteger kHangoDS_ValueLen = 6;

static const uint8_t kHangoDS_ValueShort[] = { 0x1F, 0x00, 0x02, 0x0B, 0x1B };
static const NSUInteger kHangoDS_ValueShortLen = 5;

static const uint8_t kHangoDS_ValueBalance[] = { 0x1F, 0x00, 0x02, 0x0B, 0x1B, 0x17, 0x51, 0x50, 0x24, 0x00, 0x00, 0x04, 0x0A };
static const NSUInteger kHangoDS_ValueBalanceLen = 13;

static const uint8_t kHangoDS_Purchase[] = { 0x18, 0x14, 0x1C, 0x04, 0x07, 0x56, 0x40, 0x54 };
static const NSUInteger kHangoDS_PurchaseLen = 8;

static const uint8_t kHangoDS_PurchaseSuccessful[] = { 0x18, 0x14, 0x1C, 0x04, 0x07, 0x56, 0x40, 0x54, 0x68, 0x12, 0x1B, 0x04, 0x0C, 0x52, 0x40, 0x42, 0x2E, 0x14, 0x02 };
static const NSUInteger kHangoDS_PurchaseSuccessfulLen = 19;

static const uint8_t kHangoDS_PurchaseFailed[] = { 0x18, 0x14, 0x1C, 0x04, 0x07, 0x56, 0x40, 0x54, 0x68, 0x07, 0x0F, 0x0E, 0x03, 0x52, 0x57, 0x1F };
static const NSUInteger kHangoDS_PurchaseFailedLen = 16;

static const uint8_t kHangoDS_PurchasesDisabled[] = { 0x18, 0x14, 0x1C, 0x04, 0x07, 0x56, 0x40, 0x54, 0x3B, 0x41, 0x0F, 0x15, 0x0A, 0x17, 0x57, 0x58, 0x3B, 0x00, 0x0C, 0x0B, 0x0A, 0x53, 0x13, 0x5E, 0x26, 0x41, 0x1A, 0x0F, 0x06, 0x44, 0x13, 0x55, 0x2D, 0x17, 0x07, 0x04, 0x0A, 0x19 };
static const NSUInteger kHangoDS_PurchasesDisabledLen = 38;

static const uint8_t kHangoDS_PurchaseDecorations[] = { 0x18, 0x14, 0x1C, 0x04, 0x07, 0x56, 0x40, 0x54, 0x68, 0x25, 0x0B, 0x04, 0x00, 0x45, 0x52, 0x45, 0x21, 0x0E, 0x00, 0x14 };
static const NSUInteger kHangoDS_PurchaseDecorationsLen = 20;

static const uint8_t kHangoDS_UserAgreement[] = { 0x1D, 0x12, 0x0B, 0x15, 0x4F, 0x76, 0x54, 0x43, 0x2D, 0x04, 0x03, 0x02, 0x01, 0x43 };
static const NSUInteger kHangoDS_UserAgreementLen = 14;

static const uint8_t kHangoDS_AgreeUserAgreementPrefix[] = { 0x09, 0x06, 0x1C, 0x02, 0x0A, 0x17, 0x44, 0x58, 0x3C, 0x09, 0x4E };
static const NSUInteger kHangoDS_AgreeUserAgreementPrefixLen = 11;

static const uint8_t kHangoDS_AgreeUserAgreementSuffix[] = { 0x68, 0x00, 0x00, 0x03, 0x4F, 0x67, 0x41, 0x58, 0x3E, 0x00, 0x0D, 0x1E, 0x4F, 0x67, 0x5C, 0x5D, 0x21, 0x02, 0x17 };
static const NSUInteger kHangoDS_AgreeUserAgreementSuffixLen = 19;

static const uint8_t kHangoDS_PleaseAgreeUserAgreement[] = { 0x18, 0x0D, 0x0B, 0x06, 0x1C, 0x52, 0x13, 0x50, 0x2F, 0x13, 0x0B, 0x02, 0x4F, 0x43, 0x5C, 0x11, 0x3C, 0x09, 0x0B, 0x47, 0x3A, 0x44, 0x56, 0x43, 0x68, 0x20, 0x09, 0x15, 0x0A, 0x52, 0x5E, 0x54, 0x26, 0x15, 0x4E, 0x06, 0x01, 0x53, 0x13, 0x61, 0x3A, 0x08, 0x18, 0x06, 0x0C, 0x4E, 0x13, 0x61, 0x27, 0x0D, 0x07, 0x04, 0x16, 0x19 };
static const NSUInteger kHangoDS_PleaseAgreeUserAgreementLen = 54;

static const uint8_t kHangoDS_VoicePreviewFormat[] = { 0x13, 0x17, 0x01, 0x0E, 0x0C, 0x52, 0x6E, 0x11, 0x6D, 0x21 };
static const NSUInteger kHangoDS_VoicePreviewFormatLen = 10;

static const uint8_t kHangoDS_VoicePreviewSecondsFormat[] = { 0x13, 0x17, 0x01, 0x0E, 0x0C, 0x52, 0x6E, 0x11, 0x6D, 0x0D, 0x0A, 0x14 };
static const NSUInteger kHangoDS_VoicePreviewSecondsFormatLen = 12;

static const uint8_t kHangoDS_PhotoPreview[] = { 0x13, 0x31, 0x06, 0x08, 0x1B, 0x58, 0x6E };
static const NSUInteger kHangoDS_PhotoPreviewLen = 7;

static const uint8_t kHangoDisplayStringKeyBytes[] = {
    0x48, 0x61, 0x6E, 0x67, 0x6F, 0x37, 0x33, 0x31
};
static const NSUInteger kHangoDisplayStringKeyLen = 8;

static NSString *HangoDecodeDisplayBytes(const uint8_t *bytes, NSUInteger length) {
    if (!bytes || length == 0) {
        return @"";
    }
    NSMutableString *result = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0; i < length; i++) {
        unichar character = bytes[i] ^ kHangoDisplayStringKeyBytes[i % kHangoDisplayStringKeyLen];
        [result appendFormat:@"%C", character];
    }
    return result.copy;
}

static HangoDisplayStringEntry HangoDisplayStringEntryForKey(HangoDisplayStringKey key) {
    switch (key) {
        case HangoDisplayStringKeyMessage:
            return (HangoDisplayStringEntry){ kHangoDS_Message, kHangoDS_MessageLen };
        case HangoDisplayStringKeyFollow:
            return (HangoDisplayStringEntry){ kHangoDS_Follow, kHangoDS_FollowLen };
        case HangoDisplayStringKeyUnfollow:
            return (HangoDisplayStringEntry){ kHangoDS_Unfollow, kHangoDS_UnfollowLen };
        case HangoDisplayStringKeyFollowedSuccessfully:
            return (HangoDisplayStringEntry){ kHangoDS_FollowedSuccessfully, kHangoDS_FollowedSuccessfullyLen };
        case HangoDisplayStringKeyUnfollowedSuccessfully:
            return (HangoDisplayStringEntry){ kHangoDS_UnfollowedSuccessfully, kHangoDS_UnfollowedSuccessfullyLen };
        case HangoDisplayStringKeyBlock:
            return (HangoDisplayStringEntry){ kHangoDS_Block, kHangoDS_BlockLen };
        case HangoDisplayStringKeyBlockQuestion:
            return (HangoDisplayStringEntry){ kHangoDS_BlockQuestion, kHangoDS_BlockQuestionLen };
        case HangoDisplayStringKeyBlockedSuccessfully:
            return (HangoDisplayStringEntry){ kHangoDS_BlockedSuccessfully, kHangoDS_BlockedSuccessfullyLen };
        case HangoDisplayStringKeyBlockConfirmFormat:
            return (HangoDisplayStringEntry){ kHangoDS_BlockConfirmFormat, kHangoDS_BlockConfirmFormatLen };
        case HangoDisplayStringKeyAlreadyBlocked:
            return (HangoDisplayStringEntry){ kHangoDS_AlreadyBlocked, kHangoDS_AlreadyBlockedLen };
        case HangoDisplayStringKeyBlacklist:
            return (HangoDisplayStringEntry){ kHangoDS_Blacklist, kHangoDS_BlacklistLen };
        case HangoDisplayStringKeyRemoveFromBlacklist:
            return (HangoDisplayStringEntry){ kHangoDS_RemoveFromBlacklist, kHangoDS_RemoveFromBlacklistLen };
        case HangoDisplayStringKeyRemoveBlacklistFormat:
            return (HangoDisplayStringEntry){ kHangoDS_RemoveBlacklistFormat, kHangoDS_RemoveBlacklistFormatLen };
        case HangoDisplayStringKeyReport:
            return (HangoDisplayStringEntry){ kHangoDS_Report, kHangoDS_ReportLen };
        case HangoDisplayStringKeyReportSuccessful:
            return (HangoDisplayStringEntry){ kHangoDS_ReportSuccessful, kHangoDS_ReportSuccessfulLen };
        case HangoDisplayStringKeyValue:
            return (HangoDisplayStringEntry){ kHangoDS_Value, kHangoDS_ValueLen };
        case HangoDisplayStringKeyValueShort:
            return (HangoDisplayStringEntry){ kHangoDS_ValueShort, kHangoDS_ValueShortLen };
        case HangoDisplayStringKeyValueBalance:
            return (HangoDisplayStringEntry){ kHangoDS_ValueBalance, kHangoDS_ValueBalanceLen };
        case HangoDisplayStringKeyPurchase:
            return (HangoDisplayStringEntry){ kHangoDS_Purchase, kHangoDS_PurchaseLen };
        case HangoDisplayStringKeyPurchaseSuccessful:
            return (HangoDisplayStringEntry){ kHangoDS_PurchaseSuccessful, kHangoDS_PurchaseSuccessfulLen };
        case HangoDisplayStringKeyPurchaseFailed:
            return (HangoDisplayStringEntry){ kHangoDS_PurchaseFailed, kHangoDS_PurchaseFailedLen };
        case HangoDisplayStringKeyPurchasesDisabled:
            return (HangoDisplayStringEntry){ kHangoDS_PurchasesDisabled, kHangoDS_PurchasesDisabledLen };
        case HangoDisplayStringKeyPurchaseDecorations:
            return (HangoDisplayStringEntry){ kHangoDS_PurchaseDecorations, kHangoDS_PurchaseDecorationsLen };
        case HangoDisplayStringKeyUserAgreement:
            return (HangoDisplayStringEntry){ kHangoDS_UserAgreement, kHangoDS_UserAgreementLen };
        case HangoDisplayStringKeyAgreeUserAgreementPrefix:
            return (HangoDisplayStringEntry){ kHangoDS_AgreeUserAgreementPrefix, kHangoDS_AgreeUserAgreementPrefixLen };
        case HangoDisplayStringKeyAgreeUserAgreementSuffix:
            return (HangoDisplayStringEntry){ kHangoDS_AgreeUserAgreementSuffix, kHangoDS_AgreeUserAgreementSuffixLen };
        case HangoDisplayStringKeyPleaseAgreeUserAgreement:
            return (HangoDisplayStringEntry){ kHangoDS_PleaseAgreeUserAgreement, kHangoDS_PleaseAgreeUserAgreementLen };
        case HangoDisplayStringKeyVoicePreviewFormat:
            return (HangoDisplayStringEntry){ kHangoDS_VoicePreviewFormat, kHangoDS_VoicePreviewFormatLen };
        case HangoDisplayStringKeyVoicePreviewSecondsFormat:
            return (HangoDisplayStringEntry){ kHangoDS_VoicePreviewSecondsFormat, kHangoDS_VoicePreviewSecondsFormatLen };
        case HangoDisplayStringKeyPhotoPreview:
            return (HangoDisplayStringEntry){ kHangoDS_PhotoPreview, kHangoDS_PhotoPreviewLen };
    }
    return (HangoDisplayStringEntry){ NULL, 0 };
}

NSString *HangoDisplayString(HangoDisplayStringKey key) {
    static NSMutableDictionary<NSNumber *, NSString *> *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSMutableDictionary dictionary];
    });
    NSNumber *cacheKey = @(key);
    NSString *cached = cache[cacheKey];
    if (cached) {
        return cached;
    }
    HangoDisplayStringEntry entry = HangoDisplayStringEntryForKey(key);
    NSString *decoded = HangoDecodeDisplayBytes(entry.bytes, entry.length);
    cache[cacheKey] = decoded;
    return decoded;
}

NSString *HangoDisplayStringAgreeUserAgreementLine(void) {
    return [NSString stringWithFormat:@"%@%@%@",
            HangoDisplayString(HangoDisplayStringKeyAgreeUserAgreementPrefix),
            HangoDisplayString(HangoDisplayStringKeyUserAgreement),
            HangoDisplayString(HangoDisplayStringKeyAgreeUserAgreementSuffix)];
}

NSRange HangoDisplayStringUserAgreementRangeInAgreeLine(NSString *line) {
    NSString *userAgreement = HangoDisplayString(HangoDisplayStringKeyUserAgreement);
    return userAgreement.length > 0 ? [line rangeOfString:userAgreement] : NSMakeRange(NSNotFound, 0);
}
