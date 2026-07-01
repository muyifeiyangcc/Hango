#import <UIKit/UIKit.h>

@class HangoPersona;

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
+ (BOOL)isRealPersonAvatarName:(NSString *)name;
+ (NSString *)resolvedPartyAvatarName:(NSString *)name;
+ (NSString *)partyDisplayAvatarNameForHostName:(NSString *)hostName fallbackAvatarName:(NSString *)fallbackAvatarName;
+ (nullable UIImage *)avatarImageNamed:(NSString *)name;
+ (nullable UIImage *)avatarImageForPersona:(HangoPersona *)persona;
+ (nullable UIImage *)resourceImageNamed:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
