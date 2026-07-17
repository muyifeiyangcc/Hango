#import "HangoBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface HangoWelcomeViewController : HangoBaseViewController

/// When YES, only the primary Login action is shown (secondary signup / guest / agreement UI hidden).
@property (nonatomic, assign) BOOL showsMemberLoginOnly;
/// Cold-start welcome only: refresh featured home content once after appear.
@property (nonatomic, assign) BOOL refreshFeaturedContentOnAppear;

@end

NS_ASSUME_NONNULL_END
