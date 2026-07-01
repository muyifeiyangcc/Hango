#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "Masonry.h"

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

    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(wrap).offset(16);
        make.centerY.equalTo(wrap);
        make.width.height.mas_equalTo(20);
    }];
    [field mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(icon.mas_right).offset(10);
        make.right.equalTo(wrap).offset(-16);
        make.top.bottom.equalTo(wrap);
    }];
    return wrap;
}

+ (UIView *)searchBarWithPlaceholder:(NSString *)placeholder {
    UIView *wrap = [[UIView alloc] init];
    wrap.backgroundColor = UIColor.whiteColor;
    wrap.layer.cornerRadius = 22;

    UIImageView *icon = [[UIImageView alloc] init];
    icon.image = [HangoTheme imageNamed:@"artboard_48"];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    if (!icon.image) {
        icon.backgroundColor = [HangoTheme secondaryTextColor];
        icon.layer.cornerRadius = 8;
    }
    [wrap addSubview:icon];

    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.font = [HangoTheme bodyFont];
    field.textColor = [HangoTheme primaryDarkColor];
    field.tag = 9001;
    [wrap addSubview:field];

    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(wrap).offset(14);
        make.centerY.equalTo(wrap);
        make.width.height.mas_equalTo(18);
    }];
    [field mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(icon.mas_right).offset(8);
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

+ (UIImageView *)avatarWithName:(NSString *)name size:(CGFloat)size bordered:(BOOL)bordered {
    UIImageView *avatar = [[UIImageView alloc] initWithImage:[HangoTheme avatarImageNamed:name]];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    avatar.layer.cornerRadius = size / 2.0;
    avatar.clipsToBounds = YES;
    if (bordered) {
        avatar.layer.borderWidth = 2.5;
        avatar.layer.borderColor = [HangoTheme accentBlueColor].CGColor;
    }
    return avatar;
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
    label.font = [HangoTheme captionFont];
    label.textColor = [HangoTheme accentBlueColor];
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

    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(btn).offset(16);
        make.centerY.equalTo(btn);
        make.width.height.mas_equalTo(22);
    }];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(iconView.mas_right).offset(12);
        make.centerY.equalTo(btn);
        make.right.lessThanOrEqualTo(btn).offset(-16);
    }];

    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(52); }];
    return btn;
}

+ (UIView *)albumCardWithImageName:(NSString *)imageName dateText:(NSString *)dateText {
    return [self albumCardWithImage:nil fallbackImageName:imageName dateText:dateText];
}

+ (UIView *)albumCardWithImage:(UIImage *)image fallbackImageName:(NSString *)imageName dateText:(NSString *)dateText {
    UIView *card = [[UIView alloc] init];
    card.layer.cornerRadius = 14;
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

    UIView *glass = [[UIView alloc] init];
    glass.backgroundColor = [UIColor colorWithRed:0.72 green:0.91 blue:0.98 alpha:0.72];
    [card addSubview:glass];

    [img mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(card); }];
    [dateBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(card);
        make.height.mas_equalTo(22);
    }];
    [date mas_makeConstraints:^(MASConstraintMaker *make) { make.edges.equalTo(dateBar); }];
    [glass mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(card);
        make.height.equalTo(card).multipliedBy(0.34);
    }];
    return card;
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
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
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
    NSInteger seconds = MAX(duration, 1);
    CGFloat width = screenWidth > 0 ? screenWidth : CGRectGetWidth(UIScreen.mainScreen.bounds);
    CGFloat maxWidth = width * 0.8;
    CGFloat minWidth = 88.0;
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

    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(view).offset(12);
        make.centerY.equalTo(view);
        make.width.height.mas_equalTo(18);
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

@end
