#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HangoDialogueItemType) {
    HangoDialogueItemTypeText = 0,
    HangoDialogueItemTypeAudio,
    HangoDialogueItemTypeImage
};

NS_ASSUME_NONNULL_BEGIN

@interface HangoDialogueItem : NSObject

@property (nonatomic, copy) NSString *itemId;
@property (nonatomic, copy) NSString *senderName;
@property (nonatomic, copy) NSString *senderAvatarName;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *timeText;
@property (nonatomic, assign) HangoDialogueItemType itemType;
@property (nonatomic, assign) BOOL isOutgoing;
@property (nonatomic, assign) NSInteger audioDuration;
@property (nonatomic, copy, nullable) NSString *audioFilePath;

@end

NS_ASSUME_NONNULL_END
