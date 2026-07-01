#import "HangoMainTabBarController.h"
#import "HangoHomeViewController.h"
#import "HangoContactsViewController.h"
#import "HangoCreatePartyViewController.h"
#import "HangoInboxViewController.h"
#import "HangoProfileViewController.h"
#import "HangoTabBarView.h"
#import "Masonry.h"

@interface HangoMainTabBarController () <UINavigationControllerDelegate, UITabBarControllerDelegate>
@property (nonatomic, strong, readwrite) HangoTabBarView *customTabBarView;
@end

@implementation HangoMainTabBarController

- (CGFloat)currentTabBarHeight {
    return [HangoTabBarView preferredHeightForWidth:CGRectGetWidth(self.view.bounds)
                                     safeAreaBottom:self.view.safeAreaInsets.bottom];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.clipsToBounds = NO;
    self.delegate = self;
    [self configureSystemTabBarHidden];

    self.customTabBarView = [[HangoTabBarView alloc] init];
    __weak typeof(self) weakSelf = self;
    self.customTabBarView.onTabSelected = ^(HangoTabIndex index) {
        [weakSelf handleTabSelection:index];
    };
    [self.view addSubview:self.customTabBarView];
    [self.customTabBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo([self currentTabBarHeight]);
    }];
    [self.view bringSubviewToFront:self.customTabBarView];
    [self.customTabBarView setSelectedIndex:HangoTabIndexHome animated:NO];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self configureSystemTabBarHidden];

    CGFloat height = [self currentTabBarHeight];
    [self.customTabBarView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(height);
    }];
    [self.customTabBarView setNeedsLayout];
    [self.view bringSubviewToFront:self.customTabBarView];
    [self refreshCustomTabBarVisibilityAnimated:NO];
}

- (void)configureSystemTabBarHidden {
    self.tabBar.hidden = YES;
    self.tabBar.alpha = 0;
    self.tabBar.userInteractionEnabled = NO;
    self.tabBar.clipsToBounds = YES;
    self.tabBar.backgroundColor = UIColor.clearColor;
    self.tabBar.barTintColor = UIColor.clearColor;
    self.tabBar.translucent = YES;
    [self.tabBar setBackgroundImage:[[UIImage alloc] init]];
    [self.tabBar setShadowImage:[[UIImage alloc] init]];
    if (@available(iOS 15.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        appearance.backgroundColor = UIColor.clearColor;
        appearance.shadowColor = UIColor.clearColor;
        self.tabBar.standardAppearance = appearance;
        self.tabBar.scrollEdgeAppearance = appearance;
    }
    CGRect frame = self.tabBar.frame;
    frame.origin.y = CGRectGetHeight(self.view.bounds);
    frame.size.height = 0;
    self.tabBar.frame = frame;
    for (UIView *subview in self.tabBar.subviews) {
        subview.hidden = YES;
        subview.alpha = 0;
    }
}

- (UINavigationController *)activeNavigationController {
    UIViewController *selected = self.selectedViewController;
    if ([selected isKindOfClass:UINavigationController.class]) {
        return (UINavigationController *)selected;
    }
    return nil;
}

- (BOOL)shouldHideCustomTabBarForNavigationController:(UINavigationController *)navigationController
                                    topViewController:(UIViewController *)viewController {
    if (!navigationController || !viewController) {
        return NO;
    }
    return viewController != navigationController.viewControllers.firstObject;
}

- (void)refreshCustomTabBarVisibilityAnimated:(BOOL)animated {
    UINavigationController *nav = [self activeNavigationController];
    UIViewController *top = nav.viewControllers.lastObject;
    BOOL hidden = [self shouldHideCustomTabBarForNavigationController:nav topViewController:top];
    [self setCustomTabBarHidden:hidden animated:animated];
}

- (void)setCustomTabBarHidden:(BOOL)hidden animated:(BOOL)animated {
    if (self.customTabBarView.hidden == hidden && (hidden || self.customTabBarView.alpha == 1.0)) {
        return;
    }

    void (^applyState)(void) = ^{
        self.customTabBarView.hidden = hidden;
        self.customTabBarView.alpha = hidden ? 0.0 : 1.0;
        self.customTabBarView.transform = CGAffineTransformIdentity;
    };

    if (!animated) {
        applyState();
        return;
    }

    if (hidden) {
        [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.customTabBarView.alpha = 0.0;
            self.customTabBarView.transform = CGAffineTransformMakeTranslation(0, 12);
        } completion:^(__unused BOOL finished) {
            applyState();
        }];
        return;
    }

    self.customTabBarView.hidden = NO;
    self.customTabBarView.alpha = 0.0;
    self.customTabBarView.transform = CGAffineTransformMakeTranslation(0, 12);
    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.customTabBarView.alpha = 1.0;
        self.customTabBarView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    if (navigationController != [self activeNavigationController]) {
        return;
    }
    BOOL hidden = [self shouldHideCustomTabBarForNavigationController:navigationController topViewController:viewController];
    [self setCustomTabBarHidden:hidden animated:animated];
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if (![viewController isKindOfClass:UINavigationController.class]) {
        return;
    }
    UINavigationController *nav = (UINavigationController *)viewController;
    [self refreshCustomTabBarVisibilityAnimated:NO];
    (void)nav;
}

- (void)handleTabSelection:(HangoTabIndex)index {
    if (index == HangoTabIndexCreate) {
        UINavigationController *nav = [self activeNavigationController];
        if (!nav) {
            return;
        }
        HangoCreatePartyViewController *create = [[HangoCreatePartyViewController alloc] init];
        [nav pushViewController:create animated:YES];
        [self.customTabBarView setSelectedIndex:self.selectedIndex animated:NO];
        return;
    }

    if (index == self.selectedIndex) {
        return;
    }

    self.selectedIndex = index;
    if (index < self.viewControllers.count) {
        UINavigationController *nav = self.viewControllers[index];
        [nav popToRootViewControllerAnimated:NO];
    }
    [self.customTabBarView setSelectedIndex:index animated:NO];
    [self refreshCustomTabBarVisibilityAnimated:NO];
}

+ (instancetype)mainTabBarController {
    HangoHomeViewController *home = [[HangoHomeViewController alloc] init];
    HangoContactsViewController *contacts = [[HangoContactsViewController alloc] init];
    HangoCreatePartyViewController *create = [[HangoCreatePartyViewController alloc] init];
    HangoInboxViewController *inbox = [[HangoInboxViewController alloc] init];
    HangoProfileViewController *profile = [[HangoProfileViewController alloc] init];

    UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:home];
    UINavigationController *contactsNav = [[UINavigationController alloc] initWithRootViewController:contacts];
    UINavigationController *createNav = [[UINavigationController alloc] initWithRootViewController:create];
    UINavigationController *inboxNav = [[UINavigationController alloc] initWithRootViewController:inbox];
    UINavigationController *profileNav = [[UINavigationController alloc] initWithRootViewController:profile];

    HangoMainTabBarController *tab = [[HangoMainTabBarController alloc] init];
    tab.viewControllers = @[homeNav, contactsNav, createNav, inboxNav, profileNav];
    for (UINavigationController *nav in tab.viewControllers) {
        nav.delegate = tab;
    }
    return tab;
}

@end
