#import "HangoTabBarView.h"
#import "HangoTheme.h"
#import <Masonry/Masonry.h>

static const CGFloat kHangoTabBarContentHeight = 56.0;

@interface HangoTabBarView ()
@property (nonatomic, strong) UIImageView *backgroundView;
@property (nonatomic, strong) NSArray<UIButton *> *tabButtons;
@property (nonatomic, strong) UIButton *centerButton;
@property (nonatomic, copy) NSArray<NSString *> *iconNames;
@property (nonatomic, copy) NSArray<NSString *> *selectedIconNames;
@end

@implementation HangoTabBarView

+ (CGFloat)preferredHeightForSafeAreaBottom:(CGFloat)safeAreaBottom {
    return kHangoTabBarContentHeight + safeAreaBottom;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.clipsToBounds = NO;

        self.backgroundView = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"tabbar_background"]];
        self.backgroundView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:self.backgroundView];

        self.iconNames = @[
            @"home_unselected",
            @"contacts_unselected",
            @"",
            @"chat_unselected",
            @"profile_unselected"
        ];
        self.selectedIconNames = @[
            @"home_selected",
            @"contacts_selected",
            @"",
            @"chat_selected",
            @"profile_selected"
        ];

        NSMutableArray *buttons = [NSMutableArray array];
        for (NSInteger i = 0; i < self.iconNames.count; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.tag = i;
            btn.adjustsImageWhenHighlighted = NO;
            btn.imageView.contentMode = UIViewContentModeScaleAspectFit;
            if (i == HangoTabIndexCreate) {
                UIImage *plus = [HangoTheme imageNamed:@"center_plus"];
                [btn setImage:[plus imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
                self.centerButton = btn;
            } else {
                UIImage *icon = [HangoTheme imageNamed:self.iconNames[i]];
                [btn setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
            }
            [btn addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
            [buttons addObject:btn];
        }
        self.tabButtons = buttons.copy;
        self.selectedIndex = HangoTabIndexHome;
        [self setSelectedIndex:HangoTabIndexHome animated:NO];
    }
    return self;
}

- (CGFloat)currentSafeAreaBottom {
    if (self.superview) {
        return self.superview.safeAreaInsets.bottom;
    }
    return self.window.safeAreaInsets.bottom;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat safeBottom = [self currentSafeAreaBottom];

    self.backgroundView.frame = CGRectMake(0, 0, width, height);

    CGFloat iconSize = 30.0;
    CGFloat centerSize = MIN(width * 0.168, 68.0);
    CGFloat iconY = height - safeBottom - iconSize - 8.0;

    NSArray<NSNumber *> *centerXs = @[
        @(width * 0.11),
        @(width * 0.31),
        @(width * 0.50),
        @(width * 0.69),
        @(width * 0.89)
    ];

    [self.tabButtons enumerateObjectsUsingBlock:^(UIButton *btn, NSUInteger idx, BOOL *stop) {
        CGFloat centerX = centerXs[idx].doubleValue;
        if (idx == HangoTabIndexCreate) {
            CGFloat centerY = kHangoTabBarContentHeight * 0.5 - centerSize * 0.50;
            btn.frame = CGRectMake(centerX - centerSize * 0.5, centerY, centerSize, centerSize);
        } else {
            CGFloat tapSize = 44.0;
            btn.frame = CGRectMake(centerX - tapSize * 0.5, iconY - (tapSize - iconSize) * 0.5, tapSize, tapSize);
            btn.imageEdgeInsets = UIEdgeInsetsMake((tapSize - iconSize) * 0.5,
                                                   (tapSize - iconSize) * 0.5,
                                                   (tapSize - iconSize) * 0.5,
                                                   (tapSize - iconSize) * 0.5);
        }
    }];
    [self bringSubviewToFront:self.centerButton];
}

- (void)tabTapped:(UIButton *)sender {
    if (self.onTabSelected) self.onTabSelected((HangoTabIndex)sender.tag);
}

- (void)setSelectedIndex:(HangoTabIndex)selectedIndex animated:(BOOL)animated {
    _selectedIndex = selectedIndex;
    [self.tabButtons enumerateObjectsUsingBlock:^(UIButton *btn, NSUInteger idx, BOOL *stop) {
        if (idx == HangoTabIndexCreate) return;
        BOOL selected = (idx == (NSUInteger)selectedIndex);
        NSString *name = selected ? self.selectedIconNames[idx] : self.iconNames[idx];
        UIImage *icon = [HangoTheme imageNamed:name] ?: [HangoTheme imageNamed:self.iconNames[idx]];
        [btn setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    }];
}

@end
