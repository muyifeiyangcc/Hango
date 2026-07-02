#import "HangoTabRootViewController.h"
#import "HangoMainTabBarController.h"
#import "HangoTabBarView.h"
#import "HGXAnchor.h"

static const CGFloat kHangoTabBarContentOverlap = 24.0;

@implementation HangoTabRootViewController

- (HangoTabBarView *)tabBarView {
    if ([self.tabBarController isKindOfClass:HangoMainTabBarController.class]) {
        return [(HangoMainTabBarController *)self.tabBarController customTabBarView];
    }
    return nil;
}

- (CGFloat)tabBarReservedHeight {
    CGFloat safeBottom = self.view.safeAreaInsets.bottom;
    if (safeBottom <= 0.0 && self.tabBarController.view) {
        safeBottom = self.tabBarController.view.safeAreaInsets.bottom;
    }
    CGFloat width = CGRectGetWidth(self.view.bounds);
    if (width <= 0.0 && self.tabBarController.view) {
        width = CGRectGetWidth(self.tabBarController.view.bounds);
    }
    return [HangoTabBarView preferredHeightForWidth:width safeAreaBottom:safeBottom];
}

- (void)setupUI {
    [super setupUI];
    self.view.clipsToBounds = NO;

    [self.contentView hgx_remakeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.view.hgx_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.hgx_bottom).offset(-([self tabBarReservedHeight] - kHangoTabBarContentOverlap));
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.contentView hgx_updateConstraints:^(HGXConstraintMaker *make) {
        make.bottom.equalTo(self.view.hgx_bottom).offset(-([self tabBarReservedHeight] - kHangoTabBarContentOverlap));
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tabBarView setSelectedIndex:self.tabIndex animated:NO];
}

@end
