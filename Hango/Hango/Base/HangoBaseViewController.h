#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoBaseViewController : UIViewController

@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, assign) BOOL showsBackButton;
@property (nonatomic, copy, nullable) NSString *navTitleText;

- (void)setupUI;
- (void)layoutContent;
- (void)goBack;
- (UIButton *)primaryButtonWithTitle:(NSString *)title;
- (UITextField *)styledTextFieldWithPlaceholder:(NSString *)placeholder icon:(NSString *)iconName;
- (UITextView *)styledTextViewWithPlaceholder:(NSString *)placeholder;
- (void)showLoginRequiredAlert;

@end

NS_ASSUME_NONNULL_END
