#import "HangoLoginPromptViewController.h"
#import "HangoGuestGuard.h"
#import "HangoDesignKit.h"
#import "HGXAnchor.h"

static const CGFloat kHangoLoginPromptSheetHeight = 220.0;

@implementation HangoLoginPromptViewController {
    UIButton *_dimmingView;
    UIView *_sheet;
}

- (BOOL)hangoShouldApplyRootBackground {
    return NO;
}

- (void)setupUI {
    self.view.backgroundColor = UIColor.clearColor;

    _dimmingView = [UIButton buttonWithType:UIButtonTypeCustom];
    _dimmingView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    _dimmingView.alpha = 0;
    [_dimmingView addTarget:self action:@selector(dismissSelf) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_dimmingView];

    _sheet = [HangoDesignKit bottomSheetWithTitle:@"Login Required"];
    _sheet.backgroundColor = [UIColor colorWithRed:0.88 green:0.96 blue:1 alpha:1];
    [self.view addSubview:_sheet];

    UIButton *cancel = [HangoDesignKit pillButtonWithTitle:@"Cancel" style:HangoPillButtonStyleAccent];
    cancel.layer.cornerRadius = 24;
    [cancel addTarget:self action:@selector(dismissSelf) forControlEvents:UIControlEventTouchUpInside];
    [_sheet addSubview:cancel];

    UIButton *login = [HangoDesignKit pillButtonWithTitle:@"Login" style:HangoPillButtonStyleDark];
    login.layer.cornerRadius = 24;
    [login addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [_sheet addSubview:login];

    [_dimmingView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [_sheet hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.hgx_equalTo(kHangoLoginPromptSheetHeight);
    }];
    [cancel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(_sheet).offset(24);
        make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom).offset(-20);
        make.height.hgx_equalTo(48);
        make.right.equalTo(_sheet.hgx_centerX).offset(-8);
    }];
    [login hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.right.equalTo(_sheet).offset(-24);
        make.centerY.height.width.equalTo(cancel);
    }];

    _sheet.transform = CGAffineTransformMakeTranslation(0, kHangoLoginPromptSheetHeight);
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
        self->_sheet.transform = CGAffineTransformMakeTranslation(0, kHangoLoginPromptSheetHeight);
    } completion:^(__unused BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:completion];
    }];
}

- (void)dismissSelf {
    [self dismissBottomSheetWithCompletion:nil];
}

- (void)loginTapped {
    [self dismissBottomSheetWithCompletion:^{
        [HangoGuestGuard requireLogin];
    }];
}

@end
