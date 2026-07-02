#import "HangoBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface HangoEULAViewController : HangoBaseViewController

/// Pre-check the footer agreement row when opening from Welcome with outside consent.
@property (nonatomic, assign) BOOL initialAgreementChecked;
/// When YES, EULA is the first launch gate (no back/cancel; I agree continues to Welcome).
@property (nonatomic, assign) BOOL isLaunchGate;
@property (nonatomic, copy, nullable) void (^onAgreementConfirmed)(void);

@end

NS_ASSUME_NONNULL_END
