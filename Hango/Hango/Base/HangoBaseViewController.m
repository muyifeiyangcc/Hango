#import "HangoBaseViewController.h"
#import "HangoTheme.h"
#import "HangoDesignKit.h"
#import "Masonry.h"
#import "HangoLoginPromptViewController.h"

@interface HangoBaseViewController ()
@property (nonatomic, strong, readwrite) UIView *contentView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation HangoBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [HangoTheme backgroundTopColor];
    [HangoTheme applyGradientBackgroundToView:self.view];

    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.contentView];

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];

    [self setupUI];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [HangoTheme applyGradientBackgroundToView:self.view];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDarkContent;
}

- (void)setShowsBackButton:(BOOL)showsBackButton {
    _showsBackButton = showsBackButton;
    if (showsBackButton) {
        if (!self.backButton) {
            self.backButton = [HangoDesignKit backButtonWithTarget:self action:@selector(goBack)];
            [self.view addSubview:self.backButton];
            [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(4);
                make.left.equalTo(self.view).offset(12);
                make.width.height.mas_equalTo(44);
            }];
        }
        self.backButton.hidden = NO;
    } else if (self.backButton) {
        self.backButton.hidden = YES;
    }
}

- (void)setNavTitleText:(NSString *)navTitleText {
    _navTitleText = navTitleText.copy;
    if (navTitleText.length == 0) {
        self.titleLabel.hidden = YES;
        return;
    }
    if (!self.titleLabel) {
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [HangoTheme headlineFont];
        self.titleLabel.textColor = [HangoTheme primaryDarkColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(12);
            make.centerX.equalTo(self.view);
            make.left.greaterThanOrEqualTo(self.view).offset(60);
            make.right.lessThanOrEqualTo(self.view).offset(-60);
        }];
    }
    self.titleLabel.text = navTitleText;
    self.titleLabel.hidden = NO;
}

- (void)setupUI {}
- (void)layoutContent {}

- (void)goBack {
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIButton *)primaryButtonWithTitle:(NSString *)title {
    return [HangoDesignKit pillButtonWithTitle:title style:HangoPillButtonStyleDark];
}

- (UITextField *)styledTextFieldWithPlaceholder:(NSString *)placeholder icon:(NSString *)iconName {
    UIView *wrap = [HangoDesignKit inputFieldWithPlaceholder:placeholder iconName:iconName];
    return [wrap viewWithTag:9001];
}

- (UITextView *)styledTextViewWithPlaceholder:(NSString *)placeholder {
    UITextView *textView = [[UITextView alloc] init];
    textView.backgroundColor = UIColor.whiteColor;
    textView.layer.cornerRadius = 12;
    textView.font = [HangoTheme bodyFont];
    textView.textColor = [HangoTheme primaryDarkColor];
    textView.text = placeholder;
    textView.textColor = [HangoTheme secondaryTextColor];
    return textView;
}

- (void)showLoginRequiredAlert {
    HangoLoginPromptViewController *vc = [[HangoLoginPromptViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:vc animated:YES completion:nil];
}

@end
