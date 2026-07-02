#import "UIView+HangoViewController.h"
#import "HangoGuestGuard.h"

@implementation UIView (HangoViewController)

- (UIViewController *)hango_nearestViewController {
    UIResponder *responder = self;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = responder.nextResponder;
    }
    return nil;
}

- (BOOL)hango_requireLoginForAction {
    return [HangoGuestGuard requireLogin];
}

@end
