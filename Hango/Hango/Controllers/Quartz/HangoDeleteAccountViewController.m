#import "HangoDeleteAccountViewController.h"
#import "HangoSessionManager.h"
#import "HangoRequestManager.h"
#import "HangoAppRouter.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HGXAnchor.h"

@implementation HangoDeleteAccountViewController {
    UIView *_dimmingView;
    UIView *_sheet;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.view.backgroundColor = UIColor.clearColor;
    for (CALayer *layer in self.view.layer.sublayers.copy) {
        if ([layer.name isEqualToString:@"hango.gradient"]) {
            [layer removeFromSuperlayer];
        }
    }
}

- (void)setupUI {
    self.view.backgroundColor = UIColor.clearColor;
    self.contentView.userInteractionEnabled = NO;

    _dimmingView = [[UIView alloc] init];
    _dimmingView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    _dimmingView.alpha = 0;
    [_dimmingView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelTapped)]];
    [self.view addSubview:_dimmingView];

    _sheet = [HangoDesignKit bottomSheetWithTitle:@"Delete Account"];
    _sheet.backgroundColor = [UIColor colorWithRed:0.88 green:0.96 blue:1 alpha:1];
    _sheet.layer.cornerRadius = 20;
    _sheet.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.view addSubview:_sheet];

    UIView *warningBox = [[UIView alloc] init];
    warningBox.backgroundColor = [UIColor colorWithRed:0.78 green:0.95 blue:0.86 alpha:1];
    warningBox.layer.cornerRadius = 14;
    [_sheet addSubview:warningBox];

    UILabel *hint = [[UILabel alloc] init];
    hint.text = @"Once deleted, you will not be able to recover your personal data.";
    hint.font = [HangoTheme bodyFont];
    hint.textColor = [HangoTheme primaryDarkColor];
    hint.textAlignment = NSTextAlignmentCenter;
    hint.numberOfLines = 0;
    [warningBox addSubview:hint];

    UIButton *cancel = [HangoDesignKit pillButtonWithTitle:@"Cancel" style:HangoPillButtonStyleAccent];
    cancel.layer.cornerRadius = 24;
    [cancel addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [_sheet addSubview:cancel];

    UIButton *confirm = [HangoDesignKit pillButtonWithTitle:@"Confirm" style:HangoPillButtonStyleDark];
    confirm.layer.cornerRadius = 24;
    [confirm addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [_sheet addSubview:confirm];

    [_dimmingView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [_sheet hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.hgx_equalTo(300);
    }];
    [warningBox hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_sheet).offset(68);
        make.left.right.equalTo(_sheet).inset(24);
    }];
    [hint hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(warningBox).insets(UIEdgeInsetsMake(16, 16, 16, 16));
    }];
    [cancel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(_sheet).offset(24);
        make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom).offset(-20);
        make.height.hgx_equalTo(48);
        make.right.equalTo(_sheet.hgx_centerX).offset(-8);
    }];
    [confirm hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.right.equalTo(_sheet).offset(-24);
        make.centerY.height.width.equalTo(cancel);
    }];

    _sheet.transform = CGAffineTransformMakeTranslation(0, 320);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIView animateWithDuration:0.32
                          delay:0
         usingSpringWithDamping:0.92
          initialSpringVelocity:0.5
                        options:0
                     animations:^{
        self->_dimmingView.alpha = 1;
        self->_sheet.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismissSheetWithCompletion:(void (^)(void))completion {
    [UIView animateWithDuration:0.25 animations:^{
        self->_dimmingView.alpha = 0;
        self->_sheet.transform = CGAffineTransformMakeTranslation(0, 320);
    } completion:^(__unused BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:completion];
    }];
}

- (void)cancelTapped {
    [self dismissSheetWithCompletion:nil];
}

- (void)confirmTapped {
    __weak typeof(self) weakSelf = self;
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:YES completion:^{
        [[HangoSessionManager shared] deleteAccount];
        [weakSelf dismissSheetWithCompletion:^{
            [HangoAppRouter showAuthEntry];
        }];
    }];
}

@end
