#import "HangoBaseViewController.h"
@class HangoParty;

NS_ASSUME_NONNULL_BEGIN

@interface HangoDecoratePhotoViewController : HangoBaseViewController
@property (nonatomic, strong, nullable) HangoParty *party;
@property (nonatomic, strong, nullable) UIImage *selectedImage;
@end

NS_ASSUME_NONNULL_END
