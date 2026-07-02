#import <UIKit/UIKit.h>

@class HangoParty;
@class HangoDialogueItem;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HangoPillButtonStyle) {
    HangoPillButtonStyleDark = 0,
    HangoPillButtonStyleLight,
    HangoPillButtonStyleAccent,
    HangoPillButtonStyleOutline
};

@interface HangoDesignKit : NSObject

+ (UIButton *)backButtonWithTarget:(id)target action:(SEL)action;
+ (UIButton *)termsNavButtonWithTarget:(id)target action:(SEL)action;
+ (UIButton *)pillButtonWithTitle:(NSString *)title style:(HangoPillButtonStyle)style;
+ (UIButton *)circleButtonWithImageName:(NSString *)imageName size:(CGFloat)size;

+ (UIView *)inputFieldWithPlaceholder:(NSString *)placeholder iconName:(NSString *)iconName;
+ (UIView *)searchBarWithPlaceholder:(NSString *)placeholder;
+ (UIView *)cardView;
+ (UIView *)statsPanelView;

+ (UIImageView *)avatarWithName:(NSString *)name size:(CGFloat)size bordered:(BOOL)bordered;
+ (UIImageView *)avatarForSenderName:(NSString *)senderName senderAvatarName:(NSString *)senderAvatarName size:(CGFloat)size bordered:(BOOL)bordered;
+ (UIImageView *)avatarForDialogueItem:(HangoDialogueItem *)item size:(CGFloat)size bordered:(BOOL)bordered;
+ (UIImageView *)placeholderAvatarWithSize:(CGFloat)size bordered:(BOOL)bordered;
+ (void)populatePartyMemberAvatarsInStack:(UIStackView *)stack party:(HangoParty *)party size:(CGFloat)size;
+ (UILabel *)titleLabel:(NSString *)text;
+ (UILabel *)subtitleLabel:(NSString *)text;
+ (UILabel *)linkLabel:(NSString *)text;

+ (UIButton *)menuRowWithIcon:(NSString *)iconName title:(NSString *)title target:(id)target action:(SEL)action;
+ (UIView *)albumCardWithImageName:(NSString *)imageName dateText:(NSString *)dateText;
+ (UIView *)albumCardWithImage:(nullable UIImage *)image fallbackImageName:(NSString *)imageName dateText:(NSString *)dateText;
+ (UIView *)homeAlbumMaskOverlayView;
+ (UIView *)bottomSheetWithTitle:(NSString *)title;

+ (void)applyCardShadow:(UIView *)view;
+ (void)applyReceiveButtonStyle:(UIButton *)button;

+ (CGFloat)voiceBubbleWidthForDuration:(NSInteger)duration screenWidth:(CGFloat)screenWidth;
+ (CGFloat)voiceBubbleWidthForDuration:(NSInteger)duration screenWidth:(CGFloat)screenWidth horizontalReserved:(CGFloat)horizontalReserved;

+ (void)startVoicePlaybackRippleOnView:(UIView *)view color:(UIColor *)color;
+ (void)stopVoicePlaybackRippleOnView:(UIView *)view;

+ (void)presentReportBlockActionSheetInView:(UIView *)view
                               reportAction:(void (^)(void))reportAction
                                blockAction:(void (^)(void))blockAction;
+ (void)dismissReportBlockActionSheetInView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
