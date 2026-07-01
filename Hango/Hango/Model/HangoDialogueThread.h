#import <Foundation/Foundation.h>

@class HangoContact;
@class HangoParty;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HangoDialogueThreadKind) {
    HangoDialogueThreadKindPrivate = 0,
    HangoDialogueThreadKindParty,
};

@interface HangoDialogueThread : NSObject

@property (nonatomic, assign) HangoDialogueThreadKind kind;
@property (nonatomic, copy) NSString *threadId;
@property (nonatomic, strong, nullable) HangoContact *contact;
@property (nonatomic, strong, nullable) HangoParty *party;

@end

NS_ASSUME_NONNULL_END
