#import "HangoKeyboardManager.h"
#import "HangoFeaturedPageViewController.h"
#import <WebKit/WebKit.h>

@implementation HangoKeyboardManager

+ (void)install {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
        tap.cancelsTouchesInView = NO;
        tap.name = @"HangoDismissKeyboardTap";
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindow *window = [self keyWindow];
            [window addGestureRecognizer:tap];
        });
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    });
}

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

+ (void)dismissKeyboard {
    [UIApplication.sharedApplication sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

+ (UIViewController *)topViewControllerFrom:(UIViewController *)controller {
    if (controller.presentedViewController) {
        return [self topViewControllerFrom:controller.presentedViewController];
    }
    if ([controller isKindOfClass:UINavigationController.class]) {
        return [self topViewControllerFrom:[(UINavigationController *)controller visibleViewController]];
    }
    if ([controller isKindOfClass:UITabBarController.class]) {
        return [self topViewControllerFrom:[(UITabBarController *)controller selectedViewController]];
    }
    return controller;
}

+ (BOOL)isViewInsideHostCanvas:(UIView *)view {
    while (view) {
        if ([view isKindOfClass:WKWebView.class]) {
            return YES;
        }
        view = view.superview;
    }
    return NO;
}

+ (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
  keyboardFrame = [[self keyWindow] convertRect:keyboardFrame toView:nil];
    UIWindow *window = [self keyWindow];
    UIViewController *top = [self topViewControllerFrom:window.rootViewController];
    UIView *firstResponder = [self findFirstResponderInView:top.view];
    if (!firstResponder) {
        return;
    }
    // Host canvas handles keyboard layout itself; shifting the whole window pushes
    // top inputs off-screen and displaces video/chat layouts.
    if ([self isViewInsideHostCanvas:firstResponder]) {
        if (!CGAffineTransformIsIdentity(top.view.transform)) {
            top.view.transform = CGAffineTransformIdentity;
        }
        return;
    }
    CGRect fieldFrame = [firstResponder convertRect:firstResponder.bounds toView:window];
    CGFloat overlap = CGRectGetMaxY(fieldFrame) - CGRectGetMinY(keyboardFrame) + 12;
    if (overlap <= 0) {
        return;
    }
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions options = ([info[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        top.view.transform = CGAffineTransformMakeTranslation(0, -overlap);
    } completion:nil];
}

+ (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    UIWindow *window = [self keyWindow];
    UIViewController *top = [self topViewControllerFrom:window.rootViewController];
    if ([top isKindOfClass:HangoFeaturedPageViewController.class]) {
        top.view.transform = CGAffineTransformIdentity;
        return;
    }
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions options = ([info[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        top.view.transform = CGAffineTransformIdentity;
    } completion:nil];
}

+ (UIView *)findFirstResponderInView:(UIView *)view {
    if (view.isFirstResponder) {
        return view;
    }
    for (UIView *subview in view.subviews) {
        UIView *responder = [self findFirstResponderInView:subview];
        if (responder) {
            return responder;
        }
    }
    return nil;
}

@end
