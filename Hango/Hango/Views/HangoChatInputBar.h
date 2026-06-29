#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoChatInputBar : UIView
@property (nonatomic, strong, readonly) UITextField *textField;
@property (nonatomic, copy, nullable) void (^onSend)(NSString *text);
@property (nonatomic, copy, nullable) void (^onVoice)(void);
@property (nonatomic, copy, nullable) void (^onVoiceSend)(NSInteger duration);
@property (nonatomic, copy, nullable) void (^onPhoto)(void);
@property (nonatomic, copy, nullable) void (^onModeChanged)(BOOL voiceMode);
@end

NS_ASSUME_NONNULL_END
