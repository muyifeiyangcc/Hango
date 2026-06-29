#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HangoPillButtonStyle) {
    HangoPillButtonStyleDark = 0,
    HangoPillButtonStyleLight,
    HangoPillButtonStyleAccent,
    HangoPillButtonStyleOutline
};

@interface HangoDesignKit : NSObject

+ (UIButton *)backButtonWithTarget:(id)target action:(SEL)action;
+ (UIButton *)pillButtonWithTitle:(NSString *)title style:(HangoPillButtonStyle)style;
+ (UIButton *)circleButtonWithImageName:(NSString *)imageName size:(CGFloat)size;

+ (UIView *)inputFieldWithPlaceholder:(NSString *)placeholder iconName:(NSString *)iconName;
+ (UIView *)searchBarWithPlaceholder:(NSString *)placeholder;
+ (UIView *)cardView;
+ (UIView *)statsPanelView;

+ (UIImageView *)avatarWithName:(NSString *)name size:(CGFloat)size bordered:(BOOL)bordered;
+ (UILabel *)titleLabel:(NSString *)text;
+ (UILabel *)subtitleLabel:(NSString *)text;
+ (UILabel *)linkLabel:(NSString *)text;

+ (UIButton *)menuRowWithIcon:(NSString *)iconName title:(NSString *)title target:(id)target action:(SEL)action;
+ (UIView *)albumCardWithImageName:(NSString *)imageName dateText:(NSString *)dateText;
+ (UIView *)bottomSheetWithTitle:(NSString *)title;

+ (void)applyCardShadow:(UIView *)view;
+ (void)applyReceiveButtonStyle:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
