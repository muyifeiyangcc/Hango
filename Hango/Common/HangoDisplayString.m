#import "HangoDisplayString.h"
#import "HangoLexicon.h"

static NSString *HangoDisplayStringResolve(HangoDisplayStringKey key) {
    switch (key) {
        case HangoDisplayStringKeyMessage:
            return [HangoLexicon textFromBlob:@"0dc6c0c4ee806f4ff996255845475f42"];
        case HangoDisplayStringKeyFollow:
            return [HangoLexicon textFromBlob:@"bf74457072085021910aa9e7d5660240"];
        case HangoDisplayStringKeyUnfollow:
            return [HangoLexicon textFromBlob:@"d27c07af83fcab668d5464bcacd89ee5"];
        case HangoDisplayStringKeyFollowedSuccessfully:
            return [HangoLexicon textFromBlob:@"1d212bad19b85ea36707fd5340e0789a95865b15b9053bf33b47f8e75742aa6d"];
        case HangoDisplayStringKeyUnfollowedSuccessfully:
            return [HangoLexicon textFromBlob:@"a09888a712b15e52260cb3054ae6c5f5a5129b6284feb2cc5eefa8528b4641c0"];
        case HangoDisplayStringKeyBlock:
            return [HangoLexicon textFromBlob:@"f6b90b9d1e5541904b9ea902660e39f9"];
        case HangoDisplayStringKeyBlockQuestion:
            return [HangoLexicon textFromBlob:@"4c36a19e035b4ad524edd0da2b8a944b"];
        case HangoDisplayStringKeyBlockedSuccessfully:
            return [HangoLexicon textFromBlob:@"4eebc85ac2bcdcbbda3a3f846599aca6d04db9db3a4042d1be7af56c975f4789"];
        case HangoDisplayStringKeyBlockConfirmFormat:
            return [HangoLexicon textFromBlob:@"1e7ba6e34d5d436827cff072acd8dd349e52f27a2383afc6649c80170b000d69f0ccdff74d42cacdf2f5d347f07fd412"];
        case HangoDisplayStringKeyAlreadyBlocked:
            return [HangoLexicon textFromBlob:@"5b183b9f05d369406539f8673814d72ba3009be6af3d2335c2a46316cfbf3f01fed27435106438c469a808757e55fef0"];
        case HangoDisplayStringKeyBlacklist:
            return [HangoLexicon textFromBlob:@"20f83c2c42ce548a840c10cba9c1ad88"];
        case HangoDisplayStringKeyRemoveFromBlacklist:
            return [HangoLexicon textFromBlob:@"bae2fcc218ccf3d70f863bf4f2b409d4e79abd668f999fa87949db71f1736466"];
        case HangoDisplayStringKeyRemoveBlacklistFormat:
            return [HangoLexicon textFromBlob:@"1e7ba6e34d5d436827cff072acd8dd34367ce77a83c9ec5c7a71445689e704fd4360cd440471f2399e61d60a764f1814c19a2c2e1f65efaefa45692c38bd65b4"];
        case HangoDisplayStringKeyReport:
            return [HangoLexicon textFromBlob:@"7229976c248a260e94dee344f0a91801"];
        case HangoDisplayStringKeyReportSuccessful:
            return [HangoLexicon textFromBlob:@"4022ff1f9bb8643f459c11e8f796b5ea725292a601ce9c316358916a30340370"];
        case HangoDisplayStringKeyValue:
            return [HangoLexicon textFromBlob:@"41fdf3130ba6c982fafd80c64dc1ddc7"];
        case HangoDisplayStringKeyValueShort:
            return [HangoLexicon textFromBlob:@"57686a96b87b6e9a761a42f8b1537392"];
        case HangoDisplayStringKeyValueBalance:
            return [HangoLexicon textFromBlob:@"d399bc1ccb645b51238b7e92adfa17cd"];
        case HangoDisplayStringKeyPurchase:
            return [HangoLexicon textFromBlob:@"9c3c094cfcfce5fc86e0b3b35b258556"];
        case HangoDisplayStringKeyPurchaseSuccessful:
            return [HangoLexicon textFromBlob:@"47974ba519539e41af0691f904f33033029708f2e174a66c0a2e1d49a356f725"];
        case HangoDisplayStringKeyPurchaseFailed:
            return [HangoLexicon textFromBlob:@"e8f829e88518eaea6860e343b98802b2709567a98e73911705d17d121230540c"];
        case HangoDisplayStringKeyPurchasesDisabled:
            return [HangoLexicon textFromBlob:@"338de3b93c9a8accfacfe84ac9a9abfa9104ae99180abd31a6cce3d7c697549d988eeb1d4ab2771990b002cd8abb041b"];
        case HangoDisplayStringKeyPurchaseDecorations:
            return [HangoLexicon textFromBlob:@"2de1f2243cd29bd2fc6c6cefd7ce6e7f5d3f492949727e575385f9f6b0b5d076"];
        case HangoDisplayStringKeyUserAgreement:
            return [HangoLexicon textFromBlob:@"a1cd58b115036a5227bb1797e38ac302"];
        case HangoDisplayStringKeyAgreeUserAgreementPrefix:
            return [HangoLexicon textFromBlob:@"82f2e77ef14aed4baccdbbd2fd0f1966"];
        case HangoDisplayStringKeyAgreeUserAgreementSuffix:
            return [HangoLexicon textFromBlob:@"506b21c91b688f7c7748086cdfe853afa9d0194910026661c236f21240f48de3"];
        case HangoDisplayStringKeyPleaseAgreeUserAgreement:
            return [HangoLexicon textFromBlob:@"5a12f3ab163e77a7f7c0ebeeef1f21201272dc8639688e4b8aecef28cf530193f438d09967d17c4d04e57801b18310903da4fb98fe227f556c559d05dab84e2b"];
        case HangoDisplayStringKeyVoicePreviewFormat:
            return [HangoLexicon textFromBlob:@"69d2aae38a5f5bdbfdb37008e41cf842"];
        case HangoDisplayStringKeyVoicePreviewSecondsFormat:
            return [HangoLexicon textFromBlob:@"9d22dc5107044d2ea72040fd826f2923"];
        case HangoDisplayStringKeyPhotoPreview:
            return [HangoLexicon textFromBlob:@"a2f4a025d63c18222e52a4195c198fcc"];
    }
    return @"";
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
    NSString *text = HangoDisplayStringResolve(key);
    cache[cacheKey] = text;
    return text;
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
