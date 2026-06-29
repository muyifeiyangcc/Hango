#import "HangoTabRootViewController.h"
#import "HangoCreatePartyViewController.h"
#import "HangoTabBarView.h"
#import <Masonry/Masonry.h>

@interface HangoTabRootViewController ()
@property (nonatomic, strong, readwrite) HangoTabBarView *tabBarView;
@end

@implementation HangoTabRootViewController

- (void)setupUI {
    [super setupUI];
    self.view.clipsToBounds = NO;

    self.tabBarView = [[HangoTabBarView alloc] init];
    __weak typeof(self) weakSelf = self;
    self.tabBarView.onTabSelected = ^(HangoTabIndex index) {
        [weakSelf handleTabSelection:index];
    };
    [self.view addSubview:self.tabBarView];
    [self.tabBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo([HangoTabBarView preferredHeightForSafeAreaBottom:0]);
    }];
    [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.tabBarView.mas_top).offset(22);
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat height = [HangoTabBarView preferredHeightForSafeAreaBottom:self.view.safeAreaInsets.bottom];
    [self.tabBarView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(height);
    }];
    [self.tabBarView setNeedsLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tabBarView setSelectedIndex:self.tabIndex animated:NO];
}

- (void)handleTabSelection:(HangoTabIndex)index {
    if (index == self.tabIndex) return;
    UITabBarController *tab = self.tabBarController;
    if (!tab) return;

    if (index == HangoTabIndexCreate) {
        HangoCreatePartyViewController *create = [[HangoCreatePartyViewController alloc] init];
        create.hidesBottomBarWhenPushed = NO;
        [self.navigationController pushViewController:create animated:YES];
        [self.tabBarView setSelectedIndex:self.tabIndex animated:NO];
        return;
    }

    tab.selectedIndex = index;
    UINavigationController *nav = tab.viewControllers[index];
    [nav popToRootViewControllerAnimated:NO];
}

@end
