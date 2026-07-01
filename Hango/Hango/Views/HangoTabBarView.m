#import "HangoTabBarView.h"
#import "HangoTheme.h"
#import "Masonry.h"

static const CGFloat kHangoTabBarContentHeight = 56.0;
static const CGFloat kHangoTabBarLegacyIconBottomInset = 6.0;
static const CGFloat kHangoTabBarReferenceWidth = 375.0;

@interface HangoTabBarView ()
@property (nonatomic, strong) UIImageView *backgroundView;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) NSArray<UIButton *> *tabButtons;
@property (nonatomic, strong) UIButton *centerButton;
@property (nonatomic, copy) NSArray<NSString *> *iconNames;
@property (nonatomic, copy) NSArray<NSString *> *selectedIconNames;
@end

static CGFloat HangoTabBarScaledValue(CGFloat width, CGFloat ratio, CGFloat minimum, CGFloat maximum) {
    return MIN(MAX(width * ratio, minimum), maximum);
}

static CGFloat HangoTabBarPlusButtonSize(CGFloat width) {
    UIImage *plusImage = [HangoTheme imageNamed:@"center_plus"];
    CGFloat referenceSize = plusImage.size.width > 0.0 ? plusImage.size.width : 75.0;
    return HangoTabBarScaledValue(width,
                                  referenceSize / kHangoTabBarReferenceWidth,
                                  referenceSize * 0.94,
                                  referenceSize * 1.06);
}

static CGRect HangoTabBarPlusButtonFrame(CGFloat width,
                                         CGFloat backgroundHeight,
                                         CGFloat centerSize,
                                         CGFloat sideIconCenterY) {
    (void)width;

    CGFloat plusLift = HangoTabBarScaledValue(width, 0.021, 8.0, 11.0) + 5.0;
    CGFloat plusCenterY = sideIconCenterY - plusLift;

    CGFloat arcSeatY = backgroundHeight * 0.30;
    CGFloat minCenterY = MAX(arcSeatY, centerSize * 0.36);
    CGFloat maxCenterY = sideIconCenterY - centerSize * 0.01;
    plusCenterY = MIN(MAX(plusCenterY, minCenterY), maxCenterY);

    CGFloat centerX = width * 0.50;
    return CGRectMake(centerX - centerSize * 0.5, plusCenterY - centerSize * 0.5, centerSize, centerSize);
}

@implementation HangoTabBarView

+ (CGFloat)backgroundImageHeight {
    UIImage *image = [HangoTheme imageNamed:@"tabbar_background"];
    if (!image || image.size.height <= 0) {
        return kHangoTabBarContentHeight;
    }
    return image.size.height;
}

+ (CGFloat)preferredHeightForWidth:(CGFloat)width safeAreaBottom:(CGFloat)safeAreaBottom {
    (void)width;
    (void)safeAreaBottom;
    return [self backgroundImageHeight];
}

+ (CGFloat)preferredHeightForSafeAreaBottom:(CGFloat)safeAreaBottom {
    return [self preferredHeightForWidth:CGRectGetWidth(UIScreen.mainScreen.bounds) safeAreaBottom:safeAreaBottom];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.clipsToBounds = NO;

        self.backgroundImage = [HangoTheme imageNamed:@"tabbar_background"];
        self.backgroundView = [[UIImageView alloc] initWithImage:self.backgroundImage];
        self.backgroundView.contentMode = UIViewContentModeScaleToFill;
        self.backgroundView.clipsToBounds = YES;
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

- (CGFloat)backgroundHeightForWidth:(CGFloat)width {
    (void)width;
    return [HangoTabBarView backgroundImageHeight];
}

- (CGFloat)iconBottomInsetForSafeBottom:(CGFloat)safeBottom width:(CGFloat)width {
    CGFloat designInset = HangoTabBarScaledValue(width, 0.042, 14.0, 17.0);
    if (safeBottom > 0.0) {
        return designInset;
    }
    return kHangoTabBarLegacyIconBottomInset;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat iconBottomInset = [self iconBottomInsetForSafeBottom:[self currentSafeAreaBottom] width:width];

    self.backgroundView.frame = CGRectMake(0.0, 0.0, width, height);

    CGFloat iconSize = HangoTabBarScaledValue(width, 0.076, 28.0, 30.0);
    CGFloat centerSize = HangoTabBarPlusButtonSize(width);
    CGFloat iconTopY = height - iconBottomInset - iconSize;
    CGFloat sideIconCenterY = iconTopY + iconSize * 0.5;

    NSArray<NSNumber *> *centerXs = @[
        @(width * 0.11),
        @(width * 0.31),
        @(width * 0.50),
        @(width * 0.69),
        @(width * 0.89)
    ];

    CGRect plusFrame = HangoTabBarPlusButtonFrame(width,
                                                  height,
                                                  centerSize,
                                                  sideIconCenterY);

    [self.tabButtons enumerateObjectsUsingBlock:^(UIButton *btn, NSUInteger idx, BOOL *stop) {
        CGFloat centerX = centerXs[idx].doubleValue;
        if (idx == HangoTabIndexCreate) {
            btn.frame = plusFrame;
        } else {
            CGFloat tapSize = 44.0;
            btn.frame = CGRectMake(centerX - tapSize * 0.5,
                                   iconTopY - (tapSize - iconSize) * 0.5,
                                   tapSize,
                                   tapSize);
            btn.imageEdgeInsets = UIEdgeInsetsMake((tapSize - iconSize) * 0.5,
                                                   (tapSize - iconSize) * 0.5,
                                                   (tapSize - iconSize) * 0.5,
                                                   (tapSize - iconSize) * 0.5);
        }
    }];
    [self sendSubviewToBack:self.backgroundView];
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
