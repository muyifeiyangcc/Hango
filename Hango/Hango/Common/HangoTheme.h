#import <UIKit/UIKit.h>

@class HangoUser;

NS_ASSUME_NONNULL_BEGIN

@interface HangoTheme : NSObject

+ (UIColor *)backgroundTopColor;
+ (UIColor *)backgroundBottomColor;
+ (UIColor *)primaryDarkColor;
+ (UIColor *)mintBubbleColor;
+ (UIColor *)cardBackgroundColor;
+ (UIColor *)secondaryTextColor;
+ (UIColor *)accentBlueColor;

+ (UIFont *)titleFont;
+ (UIFont *)headlineFont;
+ (UIFont *)bodyFont;
+ (UIFont *)monoFont;
+ (UIFont *)captionFont;

+ (CAGradientLayer *)backgroundGradientForBounds:(CGRect)bounds;
+ (void)applyGradientBackgroundToView:(UIView *)view;

+ (nullable UIImage *)imageNamed:(NSString *)name;
+ (nullable UIImage *)avatarImageNamed:(NSString *)name;
+ (nullable UIImage *)avatarImageForUser:(HangoUser *)user;
+ (nullable UIImage *)resourceImageNamed:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
