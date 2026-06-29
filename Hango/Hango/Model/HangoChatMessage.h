#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HangoChatMessageType) {
    HangoChatMessageTypeText = 0,
    HangoChatMessageTypeAudio,
    HangoChatMessageTypeImage
};

NS_ASSUME_NONNULL_BEGIN

@interface HangoChatMessage : NSObject

@property (nonatomic, copy) NSString *messageId;
@property (nonatomic, copy) NSString *senderName;
@property (nonatomic, copy) NSString *senderAvatarName;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *timeText;
@property (nonatomic, assign) HangoChatMessageType messageType;
@property (nonatomic, assign) BOOL isOutgoing;
@property (nonatomic, assign) NSInteger audioDuration;

@end

NS_ASSUME_NONNULL_END
