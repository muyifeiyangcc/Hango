#import "HangoHUD.h"
#import <objc/runtime.h>

static void *kHangoHUDAssociationKey = &kHangoHUDAssociationKey;

@implementation HangoHUD

+ (UIWindow *)keyWindow {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
        return windowScene.windows.firstObject;
    }
    return nil;
}

+ (instancetype)showHUDAddedTo:(UIView *)view animated:(BOOL)animated {
    [self hideHUDForView:view animated:NO];
    HangoHUD *hud = [[HangoHUD alloc] initWithFrame:CGRectZero];
    hud.tag = 0x48414E47;
    [view addSubview:hud];
    hud.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [hud.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [hud.centerYAnchor constraintEqualToAnchor:view.centerYAnchor],
        [hud.widthAnchor constraintGreaterThanOrEqualToConstant:96],
        [hud.heightAnchor constraintGreaterThanOrEqualToConstant:96],
    ]];
    objc_setAssociatedObject(view, kHangoHUDAssociationKey, hud, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (animated) {
        hud.alpha = 0;
        [UIView animateWithDuration:0.2 animations:^{
            hud.alpha = 1;
        }];
    }
    return hud;
}

+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated {
    HangoHUD *hud = objc_getAssociatedObject(view, kHangoHUDAssociationKey);
    if (!hud) {
        hud = [view viewWithTag:0x48414E47];
    }
    if (![hud isKindOfClass:HangoHUD.class]) {
        return NO;
    }
    [hud hide:animated];
    return YES;
}

+ (void)showToastWithMessage:(NSString *)message style:(NSString *)style {
    if (message.length == 0) {
        return;
    }
    UIWindow *window = [self keyWindow];
    if (!window) {
        return;
    }
    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.78];
    container.layer.cornerRadius = 10;
    container.clipsToBounds = YES;
    container.alpha = 0;
    container.tag = 0x48414E48;

    UILabel *label = [[UILabel alloc] init];
    label.text = message;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    [container addSubview:label];

    UIActivityIndicatorView *spinner = nil;
    if ([style isEqualToString:@"activity"]) {
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        spinner.color = UIColor.whiteColor;
        [spinner startAnimating];
        [container addSubview:spinner];
    }

    [window addSubview:container];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    CGFloat maxWidth = MIN(CGRectGetWidth(window.bounds) - 48, 280);
    if (spinner) {
        spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [container.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
            [container.centerYAnchor constraintEqualToAnchor:window.centerYAnchor],
            [container.widthAnchor constraintLessThanOrEqualToConstant:maxWidth],
            [spinner.topAnchor constraintEqualToAnchor:container.topAnchor constant:16],
            [spinner.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
            [label.topAnchor constraintEqualToAnchor:spinner.bottomAnchor constant:8],
            [label.leftAnchor constraintEqualToAnchor:container.leftAnchor constant:16],
            [label.rightAnchor constraintEqualToAnchor:container.rightAnchor constant:-16],
            [label.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-16],
        ]];
    } else {
        [NSLayoutConstraint activateConstraints:@[
            [container.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
            [container.centerYAnchor constraintEqualToAnchor:window.centerYAnchor],
            [container.widthAnchor constraintLessThanOrEqualToConstant:maxWidth],
            [label.topAnchor constraintEqualToAnchor:container.topAnchor constant:12],
            [label.leftAnchor constraintEqualToAnchor:container.leftAnchor constant:16],
            [label.rightAnchor constraintEqualToAnchor:container.rightAnchor constant:-16],
            [label.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-12],
        ]];
    }

    [UIView animateWithDuration:0.2 animations:^{
        container.alpha = 1;
    }];

    if (![style isEqualToString:@"activity"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{
                container.alpha = 0;
            } completion:^(__unused BOOL finished) {
                [container removeFromSuperview];
            }];
        });
    }
}

+ (void)hideHUD {
    UIWindow *window = [self keyWindow];
    [[window viewWithTag:0x48414E48] removeFromSuperview];
    [self hideHUDForView:window animated:YES];
}

+ (void)showSuccessMessage:(NSString *)message {
    [self showToastWithMessage:message style:@"success"];
}

+ (void)showErrorMessage:(NSString *)message {
    [self showToastWithMessage:message style:@"error"];
}

+ (void)showActivityMessageInWindow:(NSString *)message {
    (void)message;
    [self showToastWithMessage:@"Loading" style:@"activity"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = [self keyWindow];
        UIView *toast = [window viewWithTag:0x48414E48];
        [toast removeFromSuperview];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.72];
        self.layer.cornerRadius = 12;
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        spinner.color = UIColor.whiteColor;
        [spinner startAnimating];
        [self addSubview:spinner];
        spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [spinner.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [self.widthAnchor constraintEqualToConstant:96],
            [self.heightAnchor constraintEqualToConstant:96],
        ]];
    }
    return self;
}

- (void)hide:(BOOL)animated {
    void (^removeBlock)(void) = ^{
        [self removeFromSuperview];
        objc_setAssociatedObject(self.superview, kHangoHUDAssociationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    };
    if (!animated) {
        removeBlock();
        return;
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
    } completion:^(__unused BOOL finished) {
        removeBlock();
    }];
}

@end

@implementation MBProgressHUD

+ (void)hideHUD {
    [HangoHUD hideHUD];
}

@end
