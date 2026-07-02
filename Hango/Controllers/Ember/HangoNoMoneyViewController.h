#import "HangoBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface HangoNoMoneyViewController : HangoBaseViewController
@property (nonatomic, copy, nullable) NSString *previewImageName;
@property (nonatomic, copy, nullable) void (^onRecharge)(void);
@property (nonatomic, copy, nullable) void (^onCancel)(void);

- (void)dismissBottomSheetWithCompletion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
