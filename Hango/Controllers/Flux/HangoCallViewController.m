#import "HangoCallViewController.h"
#import "HangoContact.h"
#import "HangoTheme.h"
#import "HangoDesignKit.h"
#import "HangoDisplayString.h"
#import "HangoReportDetailViewController.h"
#import "HangoRequestManager.h"
#import "HangoDataStore.h"
#import "HangoHUD.h"
#import "HGXAnchor.h"

@interface HangoCallViewController ()
@property (nonatomic, strong) UIView *avatarCircle;
@property (nonatomic, strong) UIView *rippleContainer;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, assign) BOOL callActive;
@end

@implementation HangoCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.showsBackButton = YES;
    [self buildUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startRipple];
    self.callActive = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf.callActive) {
            return;
        }
        [strongSelf handleCallTimeout];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.callActive = NO;
    [self.rippleContainer.layer removeAllAnimations];
    for (CALayer *layer in [self.rippleContainer.layer.sublayers copy]) {
        [layer removeAllAnimations];
    }
}

- (void)handleCallTimeout {
    self.callActive = NO;
    self.statusLabel.text = @"No answer";
    [MBProgressHUD showErrorMessage:@"No answer"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.navigationController.topViewController == self) {
            [self goBack];
        }
    });
}

- (void)buildUI {
    UIButton *more = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *moreIcon = [UIImage systemImageNamed:@"ellipsis"];
    if (moreIcon) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightBold];
        moreIcon = [moreIcon imageByApplyingSymbolConfiguration:config];
        [more setImage:[moreIcon imageWithTintColor:[HangoTheme primaryDarkColor] renderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    } else {
        [more setTitle:@"..." forState:UIControlStateNormal];
        [more setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    }
    [more addTarget:self action:@selector(openMoreMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:more];
    [more hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(12);
        make.right.equalTo(self.contentView).offset(-16);
        make.width.height.hgx_equalTo(36);
    }];

    // Ripple rings behind the avatar circle.
    UIView *rippleContainer = [[UIView alloc] init];
    rippleContainer.userInteractionEnabled = NO;
    [self.contentView addSubview:rippleContainer];
    self.rippleContainer = rippleContainer;

    UIView *circle = [[UIView alloc] init];
    circle.backgroundColor = UIColor.whiteColor;
    circle.layer.cornerRadius = 80;
    circle.layer.shadowColor = UIColor.whiteColor.CGColor;
    circle.layer.shadowOpacity = 0.9;
    circle.layer.shadowRadius = 24;
    circle.layer.shadowOffset = CGSizeZero;
    [self.contentView addSubview:circle];
    self.avatarCircle = circle;

    UIImageView *avatar = [[UIImageView alloc] initWithImage:[HangoTheme avatarImageNamed:self.contact.avatarName]];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    avatar.clipsToBounds = YES;
    avatar.layer.cornerRadius = 76;
    avatar.layer.borderWidth = 4;
    avatar.layer.borderColor = UIColor.whiteColor.CGColor;
    [circle addSubview:avatar];

    [circle hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(200);
        make.width.height.hgx_equalTo(160);
    }];
    [avatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.center.equalTo(circle);
        make.width.height.hgx_equalTo(152);
    }];
    [rippleContainer hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.center.equalTo(circle);
        make.width.height.hgx_equalTo(160);
    }];

    UILabel *name = [[UILabel alloc] init];
    name.text = self.contact.name.length > 0 ? self.contact.name : @"";
    name.font = [UIFont boldSystemFontOfSize:22];
    name.textColor = [HangoTheme primaryDarkColor];
    name.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:name];
    [name hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(circle.hgx_bottom).offset(28);
        make.left.greaterThanOrEqualTo(self.contentView).offset(24);
        make.right.lessThanOrEqualTo(self.contentView).offset(-24);
    }];

    UILabel *status = [[UILabel alloc] init];
    status.text = @"Connecting...";
    status.font = [UIFont systemFontOfSize:16];
    status.textColor = [HangoTheme secondaryTextColor];
    status.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:status];
    self.statusLabel = status;

    UIButton *hangup = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *hangupIcon = [HangoTheme imageNamed:@"guaduandianhua"];
    hangup.backgroundColor = [UIColor colorWithRed:1.0 green:0.20 blue:0.15 alpha:1.0];
    hangup.layer.cornerRadius = 34;
    [hangup setImage:[hangupIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    hangup.imageEdgeInsets = UIEdgeInsetsMake(18, 18, 18, 18);
    hangup.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    hangup.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    [hangup addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:hangup];

    [hangup hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-120);
        make.width.height.hgx_equalTo(68);
    }];
    [status hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.bottom.equalTo(hangup.hgx_top).offset(-24);
    }];
}

- (void)startRipple {
    [self.contentView layoutIfNeeded];
    for (CALayer *layer in [self.rippleContainer.layer.sublayers copy]) {
        [layer removeFromSuperlayer];
    }
    [self addRippleWithDelay:0.0];
    [self addRippleWithDelay:0.9];
    [self addRippleWithDelay:1.8];
}

- (void)addRippleWithDelay:(CFTimeInterval)delay {
    CGFloat size = 160;
    CALayer *ring = [CALayer layer];
    ring.frame = CGRectMake(0, 0, size, size);
    ring.cornerRadius = size / 2.0;
    ring.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.35].CGColor;
    ring.opacity = 0;
    [self.rippleContainer.layer addSublayer:ring];

    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @1.0;
    scale.toValue = @1.9;

    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.fromValue = @0.5;
    opacity.toValue = @0.0;

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[scale, opacity];
    group.duration = 2.7;
    group.beginTime = CACurrentMediaTime() + delay;
    group.repeatCount = HUGE_VALF;
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [ring addAnimation:group forKey:@"ripple"];
}

- (void)openMoreMenu {
    if (![self requireLoginForAction]) {
        return;
    }
    if ([self.view viewWithTag:9901]) {
        return;
    }
    [HangoDesignKit presentReportBlockActionSheetInView:self.view reportAction:^{
        [self reportTapped];
    } blockAction:^{
        [self blockTapped];
    }];
}

- (void)dismissMoreMenu {
    [HangoDesignKit dismissReportBlockActionSheetInView:self.view];
}

- (void)reportTapped {
    HangoReportDetailViewController *vc = [[HangoReportDetailViewController alloc] init];
    vc.contact = self.contact;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)blockTapped {
    if (self.contact.isDenied) {
        return;
    }
    NSString *message = [NSString stringWithFormat:HangoDisplayString(HangoDisplayStringKeyBlockConfirmFormat), self.contact.name];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:HangoDisplayString(HangoDisplayStringKeyBlockQuestion)
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    NSString *contactId = self.contact.contactId;
    [alert addAction:[UIAlertAction actionWithTitle:HangoDisplayString(HangoDisplayStringKeyBlock) style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[HangoRequestManager shared] requestWithDelay:0.75 inView:weakSelf.view showsHUD:YES completion:^{
            [[HangoDataStore shared] blockContactWithId:contactId];
            [MBProgressHUD showSuccessMessage:HangoDisplayString(HangoDisplayStringKeyBlockedSuccessfully)];
            UINavigationController *nav = weakSelf.navigationController;
            if (nav.viewControllers.count >= 3) {
                [nav popToViewController:nav.viewControllers[nav.viewControllers.count - 3] animated:YES];
            } else {
                [nav popViewControllerAnimated:YES];
            }
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
