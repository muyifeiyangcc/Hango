#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoHUD : UIView

@property (nonatomic, copy, nullable) NSString *labelText;

+ (instancetype)showHUDAddedTo:(UIView *)view animated:(BOOL)animated;
+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated;
+ (void)showSuccessMessage:(NSString *)message;
+ (void)showErrorMessage:(NSString *)message;
+ (void)showActivityMessageInWindow:(NSString *)message;
+ (void)hideHUD;
- (void)hide:(BOOL)animated;

@end

@interface MBProgressHUD : HangoHUD
+ (void)hideHUD;
@end

NS_ASSUME_NONNULL_END
