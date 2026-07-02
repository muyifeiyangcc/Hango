#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HangoDisplayStringKey) {
    HangoDisplayStringKeyMessage,
    HangoDisplayStringKeyFollow,
    HangoDisplayStringKeyUnfollow,
    HangoDisplayStringKeyFollowedSuccessfully,
    HangoDisplayStringKeyUnfollowedSuccessfully,
    HangoDisplayStringKeyBlock,
    HangoDisplayStringKeyBlockQuestion,
    HangoDisplayStringKeyBlockedSuccessfully,
    HangoDisplayStringKeyBlockConfirmFormat,
    HangoDisplayStringKeyAlreadyBlocked,
    HangoDisplayStringKeyBlacklist,
    HangoDisplayStringKeyRemoveFromBlacklist,
    HangoDisplayStringKeyRemoveBlacklistFormat,
    HangoDisplayStringKeyReport,
    HangoDisplayStringKeyReportSuccessful,
    HangoDisplayStringKeyValue,
    HangoDisplayStringKeyValueShort,
    HangoDisplayStringKeyValueBalance,
    HangoDisplayStringKeyPurchase,
    HangoDisplayStringKeyPurchaseSuccessful,
    HangoDisplayStringKeyPurchaseFailed,
    HangoDisplayStringKeyPurchasesDisabled,
    HangoDisplayStringKeyPurchaseDecorations,
    HangoDisplayStringKeyUserAgreement,
    HangoDisplayStringKeyAgreeUserAgreementPrefix,
    HangoDisplayStringKeyAgreeUserAgreementSuffix,
    HangoDisplayStringKeyPleaseAgreeUserAgreement,
    HangoDisplayStringKeyVoicePreviewFormat,
    HangoDisplayStringKeyVoicePreviewSecondsFormat,
    HangoDisplayStringKeyPhotoPreview,
};

NSString *HangoDisplayString(HangoDisplayStringKey key);
NSString *HangoDisplayStringAgreeUserAgreementLine(void);
NSRange HangoDisplayStringUserAgreementRangeInAgreeLine(NSString *line);

NS_ASSUME_NONNULL_END
