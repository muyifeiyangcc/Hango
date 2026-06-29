#import "HangoChatInputBar.h"
#import "HangoTheme.h"
#import <Masonry/Masonry.h>

@interface HangoChatInputBar ()
@property (nonatomic, strong) NSMutableArray<UIView *> *textModeViews;
@property (nonatomic, strong) UIView *voiceModeView;
@property (nonatomic, strong) UIButton *voiceSendButton;
@property (nonatomic, strong) UIView *voiceGlowView;
@property (nonatomic, strong) UILabel *voiceHintLabel;
@property (nonatomic, assign) BOOL voiceMode;
@property (nonatomic, assign) CFTimeInterval voicePressBeganTime;
@end

@implementation HangoChatInputBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.textModeViews = [NSMutableArray array];

        UIButton *voice = [self roundIcon:@"chat_voice_icon_black" fallback:@"private_chat_voice" action:@selector(voiceTapped)];
        UIButton *photo = [self roundIcon:@"chat_send_image" fallback:@"artboard_51" action:@selector(photoTapped)];
        [self addSubview:voice];
        [self addSubview:photo];
        [self.textModeViews addObject:voice];
        [self.textModeViews addObject:photo];

        UIView *fieldWrap = [[UIView alloc] init];
        fieldWrap.backgroundColor = [HangoTheme primaryDarkColor];
        fieldWrap.layer.cornerRadius = 24;
        [self addSubview:fieldWrap];
        [self.textModeViews addObject:fieldWrap];

        _textField = [[UITextField alloc] init];
        _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Type a message..." attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.45]}];
        _textField.textColor = UIColor.whiteColor;
        _textField.font = [HangoTheme monoFont];
        [fieldWrap addSubview:_textField];

        UIButton *send = [UIButton buttonWithType:UIButtonTypeCustom];
        [send setImage:[HangoTheme imageNamed:@"chat_send_button"] forState:UIControlStateNormal];
        if (!send.currentImage) [send setTitle:@"➤" forState:UIControlStateNormal];
        [send setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [send addTarget:self action:@selector(sendTapped) forControlEvents:UIControlEventTouchUpInside];
        [fieldWrap addSubview:send];

        [voice mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(8);
            make.centerY.equalTo(self);
            make.width.height.mas_equalTo(44);
        }];
        [photo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(voice.mas_right).offset(8);
            make.centerY.width.height.equalTo(voice);
        }];
        [fieldWrap mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(photo.mas_right).offset(8);
            make.right.equalTo(self).offset(-8);
            make.centerY.equalTo(self);
            make.height.mas_equalTo(48);
        }];
        [_textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(fieldWrap).offset(14);
            make.centerY.equalTo(fieldWrap);
            make.right.equalTo(send.mas_left).offset(-4);
        }];
        [send mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(fieldWrap).offset(-10);
            make.centerY.equalTo(fieldWrap);
            make.width.height.mas_equalTo(28);
        }];

        [self buildVoiceModeView];
        [self setVoiceMode:NO animated:NO];
    }
    return self;
}

- (void)buildVoiceModeView {
    _voiceModeView = [[UIView alloc] init];
    _voiceModeView.hidden = YES;
    [self addSubview:_voiceModeView];

    _voiceHintLabel = [[UILabel alloc] init];
    _voiceHintLabel.text = @"Long press to send";
    _voiceHintLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightMedium];
    _voiceHintLabel.textColor = [[HangoTheme primaryDarkColor] colorWithAlphaComponent:0.6];
    _voiceHintLabel.textAlignment = NSTextAlignmentCenter;
    [_voiceModeView addSubview:_voiceHintLabel];

    _voiceGlowView = [[UIView alloc] init];
    _voiceGlowView.backgroundColor = [HangoTheme accentBlueColor];
    _voiceGlowView.alpha = 0.0;
    _voiceGlowView.layer.cornerRadius = 54;
    _voiceGlowView.userInteractionEnabled = NO;
    [_voiceModeView addSubview:_voiceGlowView];

    _voiceSendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _voiceSendButton.backgroundColor = UIColor.clearColor;
    [_voiceSendButton addTarget:self action:@selector(voicePressBegan) forControlEvents:UIControlEventTouchDown];
    [_voiceSendButton addTarget:self action:@selector(voicePressReleased) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [_voiceModeView addSubview:_voiceSendButton];

    UIImageView *background = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"voice_message_background"]];
    background.contentMode = UIViewContentModeScaleAspectFit;
    background.userInteractionEnabled = NO;
    [_voiceSendButton addSubview:background];

    UIImageView *mic = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"voice_message_microphone"]];
    mic.contentMode = UIViewContentModeScaleAspectFit;
    mic.userInteractionEnabled = NO;
    [_voiceSendButton addSubview:mic];

    [_voiceModeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [_voiceHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_voiceModeView);
        make.bottom.equalTo(_voiceSendButton.mas_top).offset(2);
    }];
    [_voiceGlowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(_voiceSendButton);
        make.width.height.mas_equalTo(108);
    }];
    [_voiceSendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_voiceModeView);
        make.bottom.equalTo(_voiceModeView).offset(-8);
        make.width.height.mas_equalTo(136);
    }];
    [background mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_voiceSendButton);
    }];
    [mic mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_voiceSendButton);
        make.centerY.equalTo(_voiceSendButton).offset(0);
        make.width.height.mas_equalTo(42);
    }];
}

- (UIButton *)roundIcon:(NSString *)name fallback:(NSString *)fallback action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = UIColor.whiteColor;
    btn.layer.cornerRadius = 22;
    UIImage *img = [HangoTheme imageNamed:name];
    if (!img && fallback.length > 0) {
        img = [HangoTheme imageNamed:fallback];
    }
    if (img) {
        [btn setImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    }
    btn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)voiceTapped {
    [self.textField resignFirstResponder];
    [self setVoiceMode:YES animated:YES];
    if (self.onVoice) self.onVoice();
}

- (void)setVoiceMode:(BOOL)voiceMode animated:(BOOL)animated {
    _voiceMode = voiceMode;
    void (^changes)(void) = ^{
        for (UIView *view in self.textModeViews) {
            view.alpha = voiceMode ? 0 : 1;
        }
        self.voiceModeView.alpha = voiceMode ? 1 : 0;
    };

    self.voiceModeView.hidden = NO;
    if (animated) {
        [UIView animateWithDuration:0.2 animations:changes completion:^(__unused BOOL finished) {
            self.voiceModeView.hidden = !voiceMode;
            for (UIView *view in self.textModeViews) {
                view.hidden = voiceMode;
            }
        }];
    } else {
        changes();
        self.voiceModeView.hidden = !voiceMode;
        for (UIView *view in self.textModeViews) {
            view.hidden = voiceMode;
        }
    }

    if (self.onModeChanged) {
        self.onModeChanged(voiceMode);
    }
}

- (void)voicePressBegan {
    self.voicePressBeganTime = CACurrentMediaTime();
    [self.voiceSendButton.layer removeAnimationForKey:@"hango.voice.pulse"];
    [self.voiceGlowView.layer removeAnimationForKey:@"hango.voice.ripple.scale"];
    [self.voiceGlowView.layer removeAnimationForKey:@"hango.voice.ripple.opacity"];
    self.voiceHintLabel.text = @"Release to send";

    [UIView animateWithDuration:0.16 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.voiceSendButton.transform = CGAffineTransformMakeScale(1.12, 1.12);
        self.voiceGlowView.alpha = 0.28;
        self.voiceGlowView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } completion:nil];

    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
    pulse.fromValue = @0.55;
    pulse.toValue = @1.0;
    pulse.duration = 0.55;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [self.voiceSendButton.layer addAnimation:pulse forKey:@"hango.voice.pulse"];

    CABasicAnimation *rippleScale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    rippleScale.fromValue = @0.78;
    rippleScale.toValue = @1.45;
    rippleScale.duration = 0.9;
    rippleScale.repeatCount = HUGE_VALF;
    rippleScale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    CABasicAnimation *rippleOpacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    rippleOpacity.fromValue = @0.35;
    rippleOpacity.toValue = @0.0;
    rippleOpacity.duration = 0.9;
    rippleOpacity.repeatCount = HUGE_VALF;
    rippleOpacity.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    [self.voiceGlowView.layer addAnimation:rippleScale forKey:@"hango.voice.ripple.scale"];
    [self.voiceGlowView.layer addAnimation:rippleOpacity forKey:@"hango.voice.ripple.opacity"];
}

- (void)voicePressReleased {
    CFTimeInterval elapsed = CACurrentMediaTime() - self.voicePressBeganTime;
    [self.voiceSendButton.layer removeAnimationForKey:@"hango.voice.pulse"];
    [self.voiceGlowView.layer removeAnimationForKey:@"hango.voice.ripple.scale"];
    [self.voiceGlowView.layer removeAnimationForKey:@"hango.voice.ripple.opacity"];
    self.voiceHintLabel.text = @"Long press to send";
    [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.voiceSendButton.transform = CGAffineTransformIdentity;
        self.voiceGlowView.alpha = 0.0;
        self.voiceGlowView.transform = CGAffineTransformIdentity;
    } completion:nil];

    if (elapsed >= 0.35 && self.onVoiceSend) {
        self.onVoiceSend(MAX(1, MIN(60, (NSInteger)lrint(elapsed))));
    }
}

- (void)photoTapped { if (self.onPhoto) self.onPhoto(); }
- (void)sendTapped {
    if (self.textField.text.length == 0) return;
    if (self.onSend) self.onSend(self.textField.text.copy);
    self.textField.text = @"";
}

@end
