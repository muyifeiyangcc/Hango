#import "HangoMainTabBarController.h"
#import "HangoHomeViewController.h"
#import "HangoContactsViewController.h"
#import "HangoCreatePartyViewController.h"
#import "HangoMessagesViewController.h"
#import "HangoProfileViewController.h"

@implementation HangoMainTabBarController

+ (instancetype)mainTabBarController {
    HangoHomeViewController *home = [[HangoHomeViewController alloc] init];
    HangoContactsViewController *contacts = [[HangoContactsViewController alloc] init];
    HangoCreatePartyViewController *create = [[HangoCreatePartyViewController alloc] init];
    HangoMessagesViewController *messages = [[HangoMessagesViewController alloc] init];
    HangoProfileViewController *profile = [[HangoProfileViewController alloc] init];

    UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:home];
    UINavigationController *contactsNav = [[UINavigationController alloc] initWithRootViewController:contacts];
    UINavigationController *createNav = [[UINavigationController alloc] initWithRootViewController:create];
    UINavigationController *messagesNav = [[UINavigationController alloc] initWithRootViewController:messages];
    UINavigationController *profileNav = [[UINavigationController alloc] initWithRootViewController:profile];

    HangoMainTabBarController *tab = [[HangoMainTabBarController alloc] init];
    tab.viewControllers = @[homeNav, contactsNav, createNav, messagesNav, profileNav];
    tab.tabBar.hidden = YES;
    return tab;
}

@end
