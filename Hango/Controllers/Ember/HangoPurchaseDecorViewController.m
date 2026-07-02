#import "HangoDisplayString.h"
#import "HangoPurchaseDecorViewController.h"
#import "HangoDataStore.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HGXAnchor.h"

static const NSInteger kHangoDecorationPurchaseSparkleCost = 50;
static const CGFloat kHangoPurchaseDecorSheetHeight = 320.0;

@implementation HangoPurchaseDecorViewController {
    UIButton *_dimmingView;
    UIView *_sheet;
}

- (BOOL)hangoShouldApplyRootBackground {
    return NO;
}

- (void)setupUI {
    self.view.backgroundColor = UIColor.clearColor;

    _dimmingView = [UIButton buttonWithType:UIButtonTypeCustom];
    _dimmingView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.35];
    _dimmingView.alpha = 0;
    [_dimmingView addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_dimmingView];

    _sheet = [HangoDesignKit bottomSheetWithTitle:HangoDisplayString(HangoDisplayStringKeyPurchaseDecorations)];
    _sheet.backgroundColor = [UIColor colorWithRed:0.88 green:0.96 blue:1 alpha:1];
    [self.view addSubview:_sheet];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:self.decorImageName ?: @"artboard_46"]];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.backgroundColor = UIColor.blackColor;
    icon.layer.cornerRadius = 40;
    icon.clipsToBounds = YES;
    [_sheet addSubview:icon];

    UIImageView *sparkleIcon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"sparkle_icon"]];
    sparkleIcon.contentMode = UIViewContentModeScaleAspectFit;
    [_sheet addSubview:sparkleIcon];

    UILabel *cost = [[UILabel alloc] init];
    cost.text = @"× 50";
    cost.font = [HangoTheme headlineFont];
    cost.textColor = [HangoTheme primaryDarkColor];
    [_sheet addSubview:cost];

    UIButton *cancel = [HangoDesignKit pillButtonWithTitle:@"Cancel" style:HangoPillButtonStyleAccent];
    cancel.layer.cornerRadius = 24;
    [cancel addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [_sheet addSubview:cancel];

    UIButton *purchase = [HangoDesignKit pillButtonWithTitle:HangoDisplayString(HangoDisplayStringKeyPurchase) style:HangoPillButtonStyleDark];
    purchase.layer.cornerRadius = 24;
    [purchase addTarget:self action:@selector(purchaseTapped) forControlEvents:UIControlEventTouchUpInside];
    [_sheet addSubview:purchase];

    [_dimmingView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [_sheet hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.hgx_equalTo(kHangoPurchaseDecorSheetHeight);
    }];
    [icon hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_sheet).offset(72);
        make.centerX.equalTo(_sheet);
        make.width.height.hgx_equalTo(80);
    }];
    [sparkleIcon hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(icon.hgx_bottom).offset(12);
        make.centerX.equalTo(_sheet).offset(-18);
        make.width.height.hgx_equalTo(22);
    }];
    [cost hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(sparkleIcon);
        make.left.equalTo(sparkleIcon.hgx_right).offset(4);
    }];
    [cancel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(_sheet).offset(24);
        make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom).offset(-20);
        make.height.hgx_equalTo(48);
        make.right.equalTo(_sheet.hgx_centerX).offset(-8);
    }];
    [purchase hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.right.equalTo(_sheet).offset(-24);
        make.centerY.height.width.equalTo(cancel);
    }];

    _sheet.transform = CGAffineTransformMakeTranslation(0, kHangoPurchaseDecorSheetHeight);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.isBeingPresented && !self.isMovingToParentViewController) {
        return;
    }
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

- (void)dismissBottomSheetWithCompletion:(void (^)(void))completion {
    [UIView animateWithDuration:0.25 animations:^{
        self->_dimmingView.alpha = 0;
        self->_sheet.transform = CGAffineTransformMakeTranslation(0, kHangoPurchaseDecorSheetHeight);
    } completion:^(__unused BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:completion];
    }];
}

- (void)cancelTapped {
    if (self.onCancel) {
        self.onCancel();
    }
    [self dismissBottomSheetWithCompletion:nil];
}

- (void)purchaseTapped {
    if ([HangoDataStore shared].currentPersona.sparkleBalance < kHangoDecorationPurchaseSparkleCost) {
        [self openvalueForRecharge];
        return;
    }
    if (self.onPurchase) {
        self.onPurchase();
    }
}

- (void)openvalueForRecharge {
    __weak typeof(self) weakSelf = self;
    [self dismissBottomSheetWithCompletion:^{
        if (weakSelf.onRecharge) {
            weakSelf.onRecharge();
        }
    }];
}

@end
