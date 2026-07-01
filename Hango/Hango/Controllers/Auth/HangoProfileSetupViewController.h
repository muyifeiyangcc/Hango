#import "HangoBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface HangoProfileSetupViewController : HangoBaseViewController

@property (nonatomic, assign) BOOL editingExistingProfile;
@property (nonatomic, copy, nullable) NSString *prefilledDisplayName;
@property (nonatomic, strong, nullable) UIImage *prefilledAvatarImage;

@end

NS_ASSUME_NONNULL_END
