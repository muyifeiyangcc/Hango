#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HangoTabIndex) {
    HangoTabIndexHome = 0,
    HangoTabIndexContacts,
    HangoTabIndexCreate,
    HangoTabIndexMessages,
    HangoTabIndexProfile
};

@interface HangoTabBarView : UIView

@property (nonatomic, copy) void (^onTabSelected)(HangoTabIndex index);
@property (nonatomic, assign) HangoTabIndex selectedIndex;

+ (CGFloat)preferredHeightForSafeAreaBottom:(CGFloat)safeAreaBottom;

- (void)setSelectedIndex:(HangoTabIndex)selectedIndex animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
