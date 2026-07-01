#import "HangoTheme.h"
#import "HangoPersona.h"

@implementation HangoTheme

+ (UIColor *)backgroundTopColor {
    return [UIColor colorWithRed:0.72 green:0.91 blue:0.98 alpha:1.0];
}

+ (UIColor *)backgroundBottomColor {
    return [UIColor colorWithRed:0.88 green:0.97 blue:0.98 alpha:1.0];
}

+ (UIColor *)primaryDarkColor {
    return [UIColor colorWithRed:0.14 green:0.20 blue:0.27 alpha:1.0];
}

+ (UIColor *)mintBubbleColor {
    return [UIColor colorWithRed:0.78 green:0.93 blue:0.86 alpha:1.0];
}

+ (UIColor *)cardBackgroundColor {
    return UIColor.whiteColor;
}

+ (UIColor *)secondaryTextColor {
    return [UIColor colorWithWhite:0.55 alpha:1.0];
}

+ (UIColor *)accentBlueColor {
    return [UIColor colorWithRed:0.35 green:0.72 blue:0.95 alpha:1.0];
}

+ (UIFont *)titleFont {
    return [UIFont boldSystemFontOfSize:28.0];
}

+ (UIFont *)headlineFont {
    return [UIFont boldSystemFontOfSize:20.0];
}

+ (UIFont *)bodyFont {
    return [UIFont systemFontOfSize:16.0];
}

+ (UIFont *)monoFont {
    return [UIFont monospacedSystemFontOfSize:15.0 weight:UIFontWeightMedium];
}

+ (UIFont *)captionFont {
    return [UIFont systemFontOfSize:12.0];
}

+ (CAGradientLayer *)backgroundGradientForBounds:(CGRect)bounds {
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.frame = bounds;
    layer.colors = @[
        (id)[self backgroundTopColor].CGColor,
        (id)[self backgroundBottomColor].CGColor
    ];
    layer.startPoint = CGPointMake(0.5, 0.0);
    layer.endPoint = CGPointMake(0.5, 1.0);
    return layer;
}

+ (void)applyGradientBackgroundToView:(UIView *)view {
    view.backgroundColor = UIColor.clearColor;
    CAGradientLayer *existing = nil;
    for (CALayer *layer in view.layer.sublayers.copy) {
        if ([layer.name isEqualToString:@"hango.gradient"]) {
            existing = (CAGradientLayer *)layer;
            break;
        }
    }
    if (existing) {
        existing.frame = view.bounds;
        return;
    }
    CAGradientLayer *gradient = [self backgroundGradientForBounds:view.bounds];
    gradient.name = @"hango.gradient";
    [view.layer insertSublayer:gradient atIndex:0];
}

+ (UIImage *)imageNamed:(NSString *)name {
    if (name.length == 0) {
        return nil;
    }
    UIImage *image = [UIImage imageNamed:name];
    if (image) {
        return image;
    }
    if ([name hasSuffix:@".png"]) {
        return [UIImage imageNamed:[name stringByDeletingPathExtension]];
    }
    return nil;
}

+ (NSSet<NSString *> *)realPersonAvatarNames {
    static NSSet<NSString *> *names;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        names = [NSSet setWithArray:@[@"Palmer", @"Norris", @"Dillon", @"Lillie", @"Sophia", @"Faith"]];
    });
    return names;
}

+ (BOOL)isRealPersonAvatarName:(NSString *)name {
    return name.length > 0 && [[self realPersonAvatarNames] containsObject:name];
}

+ (NSString *)resolvedPartyAvatarName:(NSString *)name {
    if ([self isRealPersonAvatarName:name]) {
        return name;
    }
    return name ?: @"";
}

+ (NSString *)partyDisplayAvatarNameForHostName:(NSString *)hostName fallbackAvatarName:(NSString *)fallbackAvatarName {
    if ([self isRealPersonAvatarName:hostName]) {
        return hostName;
    }
    if ([self isRealPersonAvatarName:fallbackAvatarName]) {
        return fallbackAvatarName;
    }
    return fallbackAvatarName.length > 0 ? fallbackAvatarName : hostName;
}

+ (UIImage *)avatarImageNamed:(NSString *)name {
    if (name.length == 0) {
        name = @"edit_avatar";
    }
    return [self imageNamed:name];
}

+ (UIImage *)avatarImageForPersona:(HangoPersona *)persona {
    if (!persona) {
        return nil;
    }
    if (persona.avatarLocalPath.length > 0) {
        UIImage *localImage = [UIImage imageWithContentsOfFile:persona.avatarLocalPath];
        if (localImage) {
            return localImage;
        }
    }
    if (persona.avatarName.length > 0) {
        return [self avatarImageNamed:persona.avatarName];
    }
    return nil;
}

+ (UIImage *)resourceImageNamed:(NSString *)name {
    return [self imageNamed:name];
}

@end
