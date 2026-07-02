#import "HangoDisplayString.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoParty.h"
#import "HangoDialogueItem.h"
#import "HangoDataStore.h"
#import "HGXAnchor.h"
#import <objc/runtime.h>

static const NSInteger kHangoReportBlockActionSheetTag = 9901;
static const NSInteger kHangoReportBlockDimmingTag = 9902;
static const NSInteger kHangoReportBlockCardTag = 9903;
static NSString * const kHangoReportBlockSheetContextKey = @"HangoReportBlockSheetContextKey";

@interface HangoReportBlockSheetContext : NSObject
@property (nonatomic, weak) UIView *hostView;
@property (nonatomic, copy) void (^reportAction)(void);
@property (nonatomic, copy) void (^blockAction)(void);
@end

@implementation HangoReportBlockSheetContext

- (void)dismissSheet {
    [HangoDesignKit dismissReportBlockActionSheetInView:self.hostView];
}

- (void)reportTapped {
    [self dismissSheet];
    if (self.reportAction) {
        self.reportAction();
    }
}

- (void)blockTapped {
    [self dismissSheet];
    if (self.blockAction) {
        self.blockAction();
    }
}

- (void)cancelTapped {
    [self dismissSheet];
}

@end

@implementation HangoDesignKit

+ (UIButton *)backButtonWithTarget:(id)target action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *icon = [HangoTheme imageNamed:@"nav_back"];
    if (!icon) {
        icon = [HangoTheme imageNamed:@"artboard_2"];
    }
    if (icon) {
        [btn setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        btn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        [btn setTitle:@"<" forState:UIControlStateNormal];
        [btn setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    }
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

+ (UIButton *)termsNavButtonWithTarget:(id)target action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.55];
    btn.layer.cornerRadius = 16;
    [btn setTitle:@"EULA" forState:UIControlStateNormal];
    [btn setTitle:@"EULA" forState:UIControlStateHighlighted];
    [btn setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [HangoTheme captionFont];
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

+ (UIButton *)pillButtonWithTitle:(NSString *)title style:(HangoPillButtonStyle)style {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [HangoTheme monoFont];
    btn.layer.cornerRadius = 31;
    btn.clipsToBounds = YES;
    switch (style) {
        case HangoPillButtonStyleLight:
            btn.backgroundColor = UIColor.whiteColor;
            [btn setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
            break;
        case HangoPillButtonStyleAccent:
            btn.backgroundColor = [HangoTheme accentBlueColor];
            [btn setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
            break;
        case HangoPillButtonStyleOutline:
            btn.backgroundColor = UIColor.whiteColor;
            btn.layer.borderWidth = 1.2;
            btn.layer.borderColor = [HangoTheme primaryDarkColor].CGColor;
            [btn setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
            break;
        default:
            btn.backgroundColor = [HangoTheme primaryDarkColor];
            [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            break;
    }
    return btn;
}

+ (UIButton *)circleButtonWithImageName:(NSString *)imageName size:(CGFloat)size {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [HangoTheme accentBlueColor];
    btn.layer.cornerRadius = size / 2.0;
    UIImage *icon = [HangoTheme imageNamed:imageName];
    [btn setImage:icon forState:UIControlStateNormal];
    btn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    btn.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    return btn;
}

+ (UIView *)inputFieldWithPlaceholder:(NSString *)placeholder iconName:(NSString *)iconName {
    UIView *wrap = [[UIView alloc] init];
    wrap.backgroundColor = UIColor.whiteColor;
    wrap.layer.cornerRadius = 26;
    wrap.layer.borderWidth = 1.2;
    wrap.layer.borderColor = [HangoTheme primaryDarkColor].CGColor;

    UIImageView *icon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:iconName]];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    [wrap addSubview:icon];

    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.font = [HangoTheme bodyFont];
    field.textColor = [HangoTheme primaryDarkColor];
    field.borderStyle = UITextBorderStyleNone;
    field.tag = 9001;
    [wrap addSubview:field];

    [icon hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(wrap).offset(16);
        make.centerY.equalTo(wrap);
        make.width.height.hgx_equalTo(20);
    }];
    [field hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(icon.hgx_right).offset(10);
        make.right.equalTo(wrap).offset(-16);
        make.top.bottom.equalTo(wrap);
    }];
    return wrap;
}

+ (UIView *)searchBarWithPlaceholder:(NSString *)placeholder {
    UIView *wrap = [[UIView alloc] init];
    wrap.backgroundColor = UIColor.whiteColor;
    wrap.layer.cornerRadius = 22;

    UIImageView *icon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"search_icon"]];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    [wrap addSubview:icon];

    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.font = [HangoTheme bodyFont];
    field.textColor = [HangoTheme primaryDarkColor];
    field.tag = 9001;
    [wrap addSubview:field];

    [icon hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(wrap).offset(14);
        make.centerY.equalTo(wrap);
        make.width.height.hgx_equalTo(18);
    }];
    [field hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(icon.hgx_right).offset(8);
        make.right.equalTo(wrap).offset(-12);
        make.top.bottom.equalTo(wrap);
    }];
    return wrap;
}

+ (UIView *)cardView {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 16;
    [self applyCardShadow:card];
    return card;
}

+ (UIView *)statsPanelView {
    UIView *panel = [[UIView alloc] init];
    panel.backgroundColor = [UIColor colorWithRed:0.65 green:0.88 blue:0.98 alpha:0.55];
    panel.layer.cornerRadius = 14;
    return panel;
}

+ (UIImageView *)avatarImageViewWithImage:(UIImage *)image size:(CGFloat)size bordered:(BOOL)bordered {
    UIImageView *avatar = [[UIImageView alloc] initWithImage:image];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    avatar.layer.cornerRadius = size / 2.0;
    avatar.clipsToBounds = YES;
    if (bordered) {
        avatar.layer.borderWidth = 2.5;
        avatar.layer.borderColor = [HangoTheme accentBlueColor].CGColor;
    }
    return avatar;
}

+ (UIImageView *)avatarWithName:(NSString *)name size:(CGFloat)size bordered:(BOOL)bordered {
    return [self avatarImageViewWithImage:[HangoTheme avatarImageNamed:name] size:size bordered:bordered];
}

+ (UIImageView *)avatarForSenderName:(NSString *)senderName senderAvatarName:(NSString *)senderAvatarName size:(CGFloat)size bordered:(BOOL)bordered {
    UIImage *image = [HangoTheme avatarImageForSenderName:senderName senderAvatarName:senderAvatarName];
    return [self avatarImageViewWithImage:image size:size bordered:bordered];
}

+ (UIImageView *)avatarForDialogueItem:(HangoDialogueItem *)item size:(CGFloat)size bordered:(BOOL)bordered {
    UIImage *image = [HangoTheme avatarImageForDialogueItem:item];
    return [self avatarImageViewWithImage:image size:size bordered:bordered];
}

+ (UIImageView *)placeholderAvatarWithSize:(CGFloat)size bordered:(BOOL)bordered {
    UIImageView *avatar = [[UIImageView alloc] init];
    avatar.backgroundColor = [UIColor colorWithRed:0.86 green:0.89 blue:0.92 alpha:1.0];
    avatar.contentMode = UIViewContentModeCenter;
    avatar.layer.cornerRadius = size / 2.0;
    avatar.clipsToBounds = YES;

    CGFloat iconPointSize = MAX(12.0, size * 0.50);
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:iconPointSize weight:UIImageSymbolWeightMedium];
    UIImage *personIcon = [UIImage systemImageNamed:@"person.fill" withConfiguration:config];
    if (personIcon) {
        avatar.image = [personIcon imageWithTintColor:[UIColor colorWithWhite:0.66 alpha:1.0]
                                          renderingMode:UIImageRenderingModeAlwaysOriginal];
    } else {
        UIImage *fallback = [HangoTheme imageNamed:@"profile_unselected"];
        avatar.image = fallback;
        avatar.contentMode = UIViewContentModeScaleAspectFit;
    }

    if (bordered) {
        avatar.layer.borderWidth = 2.0;
        avatar.layer.borderColor = UIColor.whiteColor.CGColor;
    }
    return avatar;
}

+ (void)populatePartyMemberAvatarsInStack:(UIStackView *)stack party:(HangoParty *)party size:(CGFloat)size {
    for (UIView *view in stack.arrangedSubviews) {
        [stack removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    BOOL showPlaceholder = party.isHosted && party.memberAvatarNames.count == 0 && party.extraMemberCount <= 0;
    if (showPlaceholder) {
        UIImageView *placeholder = [self placeholderAvatarWithSize:size bordered:YES];
        [placeholder hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.width.height.hgx_equalTo(size);
        }];
        [stack addArrangedSubview:placeholder];
        return;
    }

    for (NSString *memberName in [HangoDataStore.shared visibleMemberAvatarNamesForParty:party]) {
        NSString *memberAvatarName = [HangoTheme resolvedPartyAvatarName:memberName];
        UIImageView *img = [self avatarWithName:memberAvatarName size:size bordered:YES];
        [img hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.width.height.hgx_equalTo(size);
        }];
        [stack addArrangedSubview:img];
    }
    if (party.extraMemberCount > 0) {
        UILabel *extra = [[UILabel alloc] init];
        extra.text = [NSString stringWithFormat:@"+%ld", (long)party.extraMemberCount];
        extra.font = [UIFont boldSystemFontOfSize:11];
        extra.textAlignment = NSTextAlignmentCenter;
        extra.backgroundColor = [HangoTheme accentBlueColor];
        extra.textColor = [HangoTheme primaryDarkColor];
        extra.layer.cornerRadius = size / 2.0;
        extra.clipsToBounds = YES;
        extra.layer.borderWidth = 2;
        extra.layer.borderColor = UIColor.whiteColor.CGColor;
        [extra hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.width.height.hgx_equalTo(size);
        }];
        [stack addArrangedSubview:extra];
    }
}

+ (UILabel *)titleLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont boldSystemFontOfSize:28];
    label.textColor = [HangoTheme primaryDarkColor];
    return label;
}

+ (UILabel *)subtitleLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [HangoTheme bodyFont];
    label.textColor = [HangoTheme primaryDarkColor];
    return label;
}

+ (UILabel *)linkLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [HangoTheme linkLabelFont];
    label.textColor = [UIColor colorWithRed:38.0 / 255.0 green:54.0 / 255.0 blue:69.0 / 255.0 alpha:1.0];
    return label;
}

+ (UIButton *)menuRowWithIcon:(NSString *)iconName title:(NSString *)title target:(id)target action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = UIColor.whiteColor;
    btn.layer.cornerRadius = 14;
    [self applyCardShadow:btn];

    UIImageView *iconView = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:iconName]];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [btn addSubview:iconView];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [HangoTheme bodyFont];
    titleLabel.textColor = [HangoTheme primaryDarkColor];
    [btn addSubview:titleLabel];

    [iconView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(btn).offset(16);
        make.centerY.equalTo(btn);
        make.width.height.hgx_equalTo(22);
    }];
    [titleLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(iconView.hgx_right).offset(12);
        make.centerY.equalTo(btn);
        make.right.lessThanOrEqualTo(btn).offset(-16);
    }];

    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [btn hgx_makeConstraints:^(HGXConstraintMaker *make) { make.height.hgx_equalTo(52); }];
    return btn;
}

+ (UIView *)albumCardWithImageName:(NSString *)imageName dateText:(NSString *)dateText {
    return [self albumCardWithImage:nil fallbackImageName:imageName dateText:dateText];
}

+ (UIView *)albumCardWithImage:(UIImage *)image fallbackImageName:(NSString *)imageName dateText:(NSString *)dateText {
    UIView *card = [[UIView alloc] init];
    card.clipsToBounds = YES;

    UIImage *displayImage = image ?: [HangoTheme imageNamed:imageName];
    UIImageView *img = [[UIImageView alloc] initWithImage:displayImage];
    img.contentMode = UIViewContentModeScaleAspectFill;
    [card addSubview:img];

    UIView *dateBar = [[UIView alloc] init];
    dateBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.42];
    [card addSubview:dateBar];

    UILabel *date = [[UILabel alloc] init];
    date.text = dateText;
    date.font = [UIFont monospacedSystemFontOfSize:9 weight:UIFontWeightMedium];
    date.textColor = UIColor.whiteColor;
    date.textAlignment = NSTextAlignmentCenter;
    [dateBar addSubview:date];

    [img hgx_makeConstraints:^(HGXConstraintMaker *make) { make.edges.equalTo(card); }];
    [dateBar hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.left.right.equalTo(card);
        make.height.hgx_equalTo(22);
    }];
    [date hgx_makeConstraints:^(HGXConstraintMaker *make) { make.edges.equalTo(dateBar); }];
    return card;
}

+ (UIImage *)albumMaskPinImageUseRightPin:(BOOL)useRightPin {
    UIImage *source = [HangoTheme imageNamed:@"album_pin_mask"];
    if (!source.CGImage) {
        return source;
    }

    size_t pixelWidth = CGImageGetWidth(source.CGImage);
    size_t pixelHeight = CGImageGetHeight(source.CGImage);
    size_t pinSize = pixelHeight;
    CGRect cropRect = useRightPin
        ? CGRectMake((CGFloat)pixelWidth - (CGFloat)pinSize, 0, (CGFloat)pinSize, (CGFloat)pixelHeight)
        : CGRectMake(0, 0, (CGFloat)pinSize, (CGFloat)pixelHeight);

    CGImageRef cropped = CGImageCreateWithImageInRect(source.CGImage, cropRect);
    if (!cropped) {
        return source;
    }
    UIImage *image = [UIImage imageWithCGImage:cropped scale:source.scale orientation:source.imageOrientation];
    CGImageRelease(cropped);
    return image;
}

+ (UIImageView *)albumMaskPinImageViewUseRightPin:(BOOL)useRightPin {
    UIImageView *pin = [[UIImageView alloc] initWithImage:[self albumMaskPinImageUseRightPin:useRightPin]];
    pin.contentMode = UIViewContentModeScaleAspectFit;
    return pin;
}

+ (UIImageView *)albumMaskPinImageView {
    return [self albumMaskPinImageViewUseRightPin:NO];
}

+ (UIView *)homeAlbumMaskOverlayView {
    UIView *container = [[UIView alloc] init];
    container.userInteractionEnabled = NO;

    UIView *mask = [[UIView alloc] init];
    mask.backgroundColor = [UIColor colorWithRed:113.0 / 255.0 green:190.0 / 255.0 blue:232.0 / 255.0 alpha:0.6];
    mask.layer.cornerRadius = 20.0;
    mask.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    mask.clipsToBounds = YES;
    [container addSubview:mask];

    UIImageView *leftPin = [self albumMaskPinImageViewUseRightPin:NO];
    UIImageView *rightPin = [self albumMaskPinImageViewUseRightPin:YES];
    [container addSubview:leftPin];
    [container addSubview:rightPin];

    [mask hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(container);
    }];
    [leftPin hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(container).offset(10);
        make.bottom.equalTo(container).offset(-10);
        make.width.height.hgx_equalTo(13);
    }];
    [rightPin hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.right.equalTo(container).offset(-10);
        make.bottom.equalTo(container).offset(-10);
        make.width.height.hgx_equalTo(13);
    }];
    return container;
}

+ (UIView *)bottomSheetWithTitle:(NSString *)title {
    UIView *sheet = [[UIView alloc] init];
    sheet.backgroundColor = UIColor.whiteColor;
    sheet.layer.cornerRadius = 28;
    sheet.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [HangoTheme headlineFont];
    label.textColor = [HangoTheme primaryDarkColor];
    label.textAlignment = NSTextAlignmentCenter;
    [sheet addSubview:label];
    [label hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(sheet).offset(24);
        make.left.right.equalTo(sheet);
    }];
    return sheet;
}

+ (void)applyCardShadow:(UIView *)view {
    view.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    view.layer.shadowOpacity = 1;
    view.layer.shadowRadius = 10;
    view.layer.shadowOffset = CGSizeMake(0, 4);
    view.layer.masksToBounds = NO;
}

+ (void)applyReceiveButtonStyle:(UIButton *)button {
    button.backgroundColor = [HangoTheme accentBlueColor];
    button.layer.cornerRadius = 18;
    [button setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:13];
}

+ (CGFloat)voiceBubbleWidthForDuration:(NSInteger)duration screenWidth:(CGFloat)screenWidth {
    return [self voiceBubbleWidthForDuration:duration screenWidth:screenWidth horizontalReserved:0];
}

+ (CGFloat)voiceBubbleWidthForDuration:(NSInteger)duration screenWidth:(CGFloat)screenWidth horizontalReserved:(CGFloat)horizontalReserved {
    NSInteger seconds = MAX(duration, 1);
    CGFloat width = screenWidth > 0 ? screenWidth : CGRectGetWidth(UIScreen.mainScreen.bounds);
    CGFloat maxWidth = width * 0.8;
    if (horizontalReserved > 0) {
        maxWidth = MIN(maxWidth, MAX(72.0, width - horizontalReserved));
    }
    CGFloat minWidth = 72.0;
    CGFloat progress = MIN((CGFloat)seconds / 60.0, 1.0);
    return minWidth + (maxWidth - minWidth) * progress;
}

static NSInteger const kHangoVoiceRippleContainerTag = 88021;

+ (void)startVoicePlaybackRippleOnView:(UIView *)view color:(UIColor *)color {
    if (!view) {
        return;
    }
    [self stopVoicePlaybackRippleOnView:view];
    view.clipsToBounds = NO;

    UIView *container = [[UIView alloc] init];
    container.tag = kHangoVoiceRippleContainerTag;
    container.userInteractionEnabled = NO;
    container.backgroundColor = UIColor.clearColor;
    [view insertSubview:container atIndex:0];

    [container hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(view).offset(12);
        make.centerY.equalTo(view);
        make.width.height.hgx_equalTo(18);
    }];
    [view layoutIfNeeded];

    UIColor *rippleColor = color ?: UIColor.whiteColor;
    [self addVoiceRippleLayerToContainer:container color:rippleColor delay:0];
    [self addVoiceRippleLayerToContainer:container color:rippleColor delay:0.55];
}

+ (void)addVoiceRippleLayerToContainer:(UIView *)container color:(UIColor *)color delay:(CFTimeInterval)delay {
    CALayer *ripple = [CALayer layer];
    ripple.backgroundColor = [color colorWithAlphaComponent:0.32].CGColor;
    ripple.cornerRadius = 9;
    ripple.frame = CGRectMake(0, 0, 18, 18);
    ripple.opacity = 0;
    [container.layer addSublayer:ripple];

    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @0.75;
    scale.toValue = @3.0;

    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.fromValue = @0.55;
    opacity.toValue = @0.0;

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[scale, opacity];
    group.duration = 1.1;
    group.repeatCount = HUGE_VALF;
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;
    group.beginTime = CACurrentMediaTime() + delay;
    [ripple addAnimation:group forKey:@"hango.voice.playback.ripple"];
}

+ (void)stopVoicePlaybackRippleOnView:(UIView *)view {
    if (!view) {
        return;
    }
    UIView *container = [view viewWithTag:kHangoVoiceRippleContainerTag];
    for (CALayer *layer in container.layer.sublayers.copy) {
        [layer removeAllAnimations];
        [layer removeFromSuperlayer];
    }
    [container removeFromSuperview];
}

+ (UIButton *)reportBlockSheetButtonWithTitle:(NSString *)title
                              backgroundColor:(UIColor *)backgroundColor
                                   titleColor:(UIColor *)titleColor
                                       height:(CGFloat)height {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightSemibold];
    button.backgroundColor = backgroundColor;
    button.layer.cornerRadius = height / 2.0;
    button.clipsToBounds = YES;
    return button;
}

+ (void)presentReportBlockActionSheetInView:(UIView *)view
                               reportAction:(void (^)(void))reportAction
                                blockAction:(void (^)(void))blockAction {
    if (!view || [view viewWithTag:kHangoReportBlockActionSheetTag]) {
        return;
    }

    static const CGFloat kActionButtonHeight = 52.0;
    static const CGFloat kWideButtonRatio = 0.78;
    static const CGFloat kCancelButtonRatio = 0.56;

    HangoReportBlockSheetContext *context = [[HangoReportBlockSheetContext alloc] init];
    context.hostView = view;
    context.reportAction = reportAction;
    context.blockAction = blockAction;

    UIView *container = [[UIView alloc] init];
    container.tag = kHangoReportBlockActionSheetTag;
    container.backgroundColor = UIColor.clearColor;
    [view addSubview:container];

    UIButton *dimming = [UIButton buttonWithType:UIButtonTypeCustom];
    dimming.tag = kHangoReportBlockDimmingTag;
    dimming.backgroundColor = [UIColor colorWithWhite:0 alpha:0.15];
    dimming.alpha = 0;
    [dimming addTarget:context action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:dimming];

    UIView *card = [[UIView alloc] init];
    card.tag = kHangoReportBlockCardTag;
    card.backgroundColor = [UIColor colorWithRed:0.88 green:0.96 blue:1.0 alpha:1.0];
    card.layer.cornerRadius = 28;
    card.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [container addSubview:card];

    UIButton *reportBtn = [self reportBlockSheetButtonWithTitle:HangoDisplayString(HangoDisplayStringKeyReport)
                                                backgroundColor:[UIColor colorWithRed:0.98 green:0.55 blue:0.18 alpha:1.0]
                                                     titleColor:UIColor.whiteColor
                                                         height:kActionButtonHeight];
    [reportBtn addTarget:context action:@selector(reportTapped) forControlEvents:UIControlEventTouchUpInside];

    UIButton *blockBtn = [self reportBlockSheetButtonWithTitle:HangoDisplayString(HangoDisplayStringKeyBlock)
                                               backgroundColor:[HangoTheme primaryDarkColor]
                                                    titleColor:UIColor.whiteColor
                                                        height:kActionButtonHeight];
    [blockBtn addTarget:context action:@selector(blockTapped) forControlEvents:UIControlEventTouchUpInside];

    UIButton *cancelBtn = [self reportBlockSheetButtonWithTitle:@"Cancel"
                                                backgroundColor:[HangoTheme accentBlueColor]
                                                     titleColor:UIColor.whiteColor
                                                         height:kActionButtonHeight];
    [cancelBtn addTarget:context action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];

    objc_setAssociatedObject(container, (__bridge const void *)kHangoReportBlockSheetContextKey, context, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [card addSubview:reportBtn];
    [card addSubview:blockBtn];
    [card addSubview:cancelBtn];

    [container hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(view);
    }];
    [dimming hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(container);
    }];
    [card hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.bottom.equalTo(container);
    }];
    [reportBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(card).offset(28);
        make.centerX.equalTo(card);
        make.width.equalTo(card).multipliedBy(kWideButtonRatio);
        make.height.hgx_equalTo(kActionButtonHeight);
    }];
    [blockBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(reportBtn.hgx_bottom).offset(14);
        make.centerX.width.height.equalTo(reportBtn);
    }];
    [cancelBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(blockBtn.hgx_bottom).offset(14);
        make.centerX.equalTo(card);
        make.width.equalTo(card).multipliedBy(kCancelButtonRatio);
        make.height.hgx_equalTo(kActionButtonHeight);
        make.bottom.equalTo(container.hgx_safeAreaLayoutGuideBottom).offset(-24);
    }];

    [view layoutIfNeeded];
    CGFloat slideDistance = CGRectGetHeight(card.bounds);
    if (slideDistance <= 0) {
        slideDistance = 260.0;
    }
    card.transform = CGAffineTransformMakeTranslation(0, slideDistance);

    [UIView animateWithDuration:0.32
                          delay:0
         usingSpringWithDamping:0.92
          initialSpringVelocity:0.5
                        options:0
                     animations:^{
        dimming.alpha = 1;
        card.transform = CGAffineTransformIdentity;
    } completion:nil];
}

+ (void)dismissReportBlockActionSheetInView:(UIView *)view {
    UIView *container = [view viewWithTag:kHangoReportBlockActionSheetTag];
    if (!container) {
        return;
    }

    UIView *dimming = [container viewWithTag:kHangoReportBlockDimmingTag];
    UIView *card = [container viewWithTag:kHangoReportBlockCardTag];
    CGFloat slideDistance = CGRectGetHeight(card.bounds);
    if (slideDistance <= 0) {
        slideDistance = 260.0;
    }

    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        dimming.alpha = 0;
        card.transform = CGAffineTransformMakeTranslation(0, slideDistance);
    } completion:^(__unused BOOL finished) {
        objc_setAssociatedObject(container, (__bridge const void *)kHangoReportBlockSheetContextKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [container removeFromSuperview];
    }];
}

@end
