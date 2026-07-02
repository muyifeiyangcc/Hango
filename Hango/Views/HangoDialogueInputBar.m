#import "HangoDialogueInputBar.h"
#import "HangoTheme.h"
#import "HangoVoiceNoteManager.h"
#import "HangoPermissionManager.h"
#import <AVFoundation/AVFoundation.h>
#import "HGXAnchor.h"

@interface HangoDialogueInputBar ()
@property (nonatomic, strong) NSMutableArray<UIView *> *textModeViews;
@property (nonatomic, strong) UIView *voiceModeView;
@property (nonatomic, strong) UIButton *voiceBackToTextButton;
@property (nonatomic, strong) UIButton *voiceSendButton;
@property (nonatomic, strong) UIView *voiceGlowView;
@property (nonatomic, strong) UILabel *voiceHintLabel;
@property (nonatomic, assign) BOOL voiceMode;
@property (nonatomic, assign) CFTimeInterval voicePressBeganTime;
@property (nonatomic, assign) BOOL voicePressActive;
@property (nonatomic, assign) NSUInteger voicePressToken;
@property (nonatomic, assign) BOOL microphonePrepared;
@property (nonatomic, strong, nullable) dispatch_block_t pendingVoiceFinishBlock;
@end

@implementation HangoDialogueInputBar

static const CGFloat kHangoVoiceSendButtonSize = 136.0;
static const CGFloat kHangoVoiceBackgroundSize = 188.0;
static const CGFloat kHangoVoiceGlowSize = 124.0;
static const CGFloat kHangoVoiceMicSize = 42.0;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.clipsToBounds = NO;
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
        _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Type here..." attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.45]}];
        _textField.textColor = UIColor.whiteColor;
        _textField.font = [HangoTheme monoFont];
        [fieldWrap addSubview:_textField];

        UIButton *send = [UIButton buttonWithType:UIButtonTypeCustom];
        [send setImage:[HangoTheme imageNamed:@"chat_send_button"] forState:UIControlStateNormal];
        if (!send.currentImage) [send setTitle:@"➤" forState:UIControlStateNormal];
        [send setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [send addTarget:self action:@selector(sendTapped) forControlEvents:UIControlEventTouchUpInside];
        [fieldWrap addSubview:send];

        [voice hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.left.equalTo(self).offset(8);
            make.centerY.equalTo(self);
            make.width.height.hgx_equalTo(44);
        }];
        [photo hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.left.equalTo(voice.hgx_right).offset(8);
            make.centerY.width.height.equalTo(voice);
        }];
        [fieldWrap hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.left.equalTo(photo.hgx_right).offset(8);
            make.right.equalTo(self).offset(-8);
            make.centerY.equalTo(self);
            make.height.hgx_equalTo(48);
        }];
        [_textField hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.left.equalTo(fieldWrap).offset(14);
            make.centerY.equalTo(fieldWrap);
            make.right.equalTo(send.hgx_left).offset(-4);
        }];
        [send hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.right.equalTo(fieldWrap).offset(-10);
            make.centerY.equalTo(fieldWrap);
            make.width.height.hgx_equalTo(28);
        }];

        [self buildVoiceModeView];
        [self setVoiceMode:NO animated:NO];
    }
    return self;
}

- (void)dealloc {
    [self cancelPendingVoiceFinish];
    [self.voiceSendButton.layer removeAllAnimations];
    [self.voiceGlowView.layer removeAllAnimations];
    [[HangoVoiceNoteManager shared] cancelRecording];
}

- (void)cancelPendingVoiceFinish {
    if (self.pendingVoiceFinishBlock) {
        dispatch_block_cancel(self.pendingVoiceFinishBlock);
        self.pendingVoiceFinishBlock = nil;
    }
}

- (void)buildVoiceModeView {
    _voiceModeView = [[UIView alloc] init];
    _voiceModeView.hidden = YES;
    _voiceModeView.clipsToBounds = NO;
    [self addSubview:_voiceModeView];

    _voiceHintLabel = [[UILabel alloc] init];
    _voiceHintLabel.text = @"Long press to send";
    _voiceHintLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightMedium];
    _voiceHintLabel.textColor = [[HangoTheme primaryDarkColor] colorWithAlphaComponent:0.6];
    _voiceHintLabel.textAlignment = NSTextAlignmentCenter;
    [_voiceModeView addSubview:_voiceHintLabel];

    _voiceBackToTextButton = [self roundIcon:@"voice_back_to_text" fallback:nil action:@selector(backToTextTapped)];
    [_voiceModeView addSubview:_voiceBackToTextButton];

    UIImageView *background = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"voice_message_background"]];
    background.contentMode = UIViewContentModeScaleAspectFit;
    background.userInteractionEnabled = NO;
    [_voiceModeView addSubview:background];

    _voiceGlowView = [[UIView alloc] init];
    _voiceGlowView.backgroundColor = [HangoTheme accentBlueColor];
    _voiceGlowView.alpha = 0.0;
    _voiceGlowView.layer.cornerRadius = kHangoVoiceGlowSize * 0.5;
    _voiceGlowView.userInteractionEnabled = NO;
    [_voiceModeView addSubview:_voiceGlowView];

    _voiceSendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _voiceSendButton.backgroundColor = UIColor.clearColor;
    [_voiceSendButton addTarget:self action:@selector(voicePressBegan) forControlEvents:UIControlEventTouchDown];
    [_voiceSendButton addTarget:self action:@selector(voicePressReleased) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [_voiceModeView addSubview:_voiceSendButton];

    UIImageView *mic = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"voice_message_microphone"]];
    mic.contentMode = UIViewContentModeScaleAspectFit;
    mic.userInteractionEnabled = NO;
    [_voiceSendButton addSubview:mic];

    [_voiceModeView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [_voiceBackToTextButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(_voiceModeView).offset(8);
        make.centerY.equalTo(_voiceSendButton);
        make.width.height.hgx_equalTo(44);
    }];
    [_voiceHintLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(_voiceModeView);
        make.bottom.equalTo(_voiceSendButton.hgx_top).offset(2);
    }];
    [_voiceSendButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(_voiceModeView);
        make.bottom.equalTo(_voiceModeView).offset(-8);
        make.width.height.hgx_equalTo(kHangoVoiceSendButtonSize);
    }];
    [background hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.center.equalTo(_voiceSendButton);
        make.width.height.hgx_equalTo(kHangoVoiceBackgroundSize);
    }];
    [_voiceGlowView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.center.equalTo(_voiceSendButton);
        make.width.height.hgx_equalTo(kHangoVoiceGlowSize);
    }];
    [mic hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(_voiceSendButton);
        make.centerY.equalTo(_voiceSendButton).offset(7);
        make.width.height.hgx_equalTo(kHangoVoiceMicSize);
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

- (void)prepareMicrophoneIfNeededWithCompletion:(void (^)(BOOL granted))completion {
    if ([HangoPermissionManager isAuthorizedForPermission:HangoPermissionTypeMicrophone]) {
        self.microphonePrepared = YES;
        if (completion) {
            completion(YES);
        }
        return;
    }

    UIViewController *presenter = [HangoPermissionManager presentingViewControllerFromView:self];
    __weak typeof(self) weakSelf = self;
    [HangoPermissionManager requestPermission:HangoPermissionTypeMicrophone
                           fromViewController:presenter
                                   completion:^(BOOL granted) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            if (completion) {
                completion(granted);
            }
            return;
        }
        strongSelf.microphonePrepared = granted;
        if (completion) {
            completion(granted);
        }
    }];
}

- (BOOL)beginRecordingForPressToken:(NSUInteger)pressToken {
    if (!self.voicePressActive || pressToken != self.voicePressToken) {
        return NO;
    }

    AVAudioSessionRecordPermission permission = AVAudioSession.sharedInstance.recordPermission;
    if (permission != AVAudioSessionRecordPermissionGranted) {
        self.voiceHintLabel.text = @"Microphone access required";
        __weak typeof(self) weakSelf = self;
        [self prepareMicrophoneIfNeededWithCompletion:^(BOOL granted) {
            if (granted && weakSelf.voicePressActive && pressToken == weakSelf.voicePressToken) {
                [weakSelf beginRecordingForPressToken:pressToken];
            }
        }];
        return NO;
    }

    NSString *path = [[HangoVoiceNoteManager shared] makeRecordingFilePath];
    NSError *error = nil;
    if (![[HangoVoiceNoteManager shared] startRecordingToPath:path error:&error]) {
        self.voiceHintLabel.text = @"Unable to record";
        return NO;
    }

    if (self.pendingVoiceFinishBlock) {
        [self completeVoicePressForToken:pressToken];
    }
    return YES;
}

- (void)completeVoicePressForToken:(NSUInteger)pressToken {
    if (pressToken != self.voicePressToken) {
        return;
    }

    [self cancelPendingVoiceFinish];

    CFTimeInterval elapsed = CACurrentMediaTime() - self.voicePressBeganTime;
    if (elapsed < 0.35) {
        [[HangoVoiceNoteManager shared] cancelRecording];
        return;
    }

    NSInteger duration = 0;
    NSString *path = nil;
    if (![[HangoVoiceNoteManager shared] stopRecordingReturningDuration:&duration filePath:&path]) {
        return;
    }

    void (^sendHandler)(NSInteger, NSString *) = self.onVoiceSend;
    if (!sendHandler || path.length == 0) {
        return;
    }

    NSInteger finalDuration = MAX(duration, 1);
    NSString *finalPath = [path copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        sendHandler(finalDuration, finalPath);
    });
}

- (void)voiceTapped {
    [self.textField resignFirstResponder];
    __weak typeof(self) weakSelf = self;
    [self prepareMicrophoneIfNeededWithCompletion:^(BOOL granted) {
        if (!granted) {
            return;
        }
        [weakSelf setVoiceMode:YES animated:YES];
        if (weakSelf.onVoice) {
            weakSelf.onVoice();
        }
    }];
}

- (void)backToTextTapped {
    [self setVoiceMode:NO animated:YES];
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

    if (!voiceMode) {
        self.voicePressActive = NO;
        [self cancelPendingVoiceFinish];
        [[HangoVoiceNoteManager shared] cancelRecording];
    }

    if (self.onModeChanged) {
        self.onModeChanged(voiceMode);
    }
}

- (void)voicePressBegan {
    self.voicePressToken += 1;
    NSUInteger pressToken = self.voicePressToken;
    self.voicePressActive = YES;
    self.voicePressBeganTime = CACurrentMediaTime();
    [self.voiceSendButton.layer removeAnimationForKey:@"hango.voice.pulse"];
    [self.voiceGlowView.layer removeAnimationForKey:@"hango.voice.ripple.scale"];
    [self.voiceGlowView.layer removeAnimationForKey:@"hango.voice.ripple.opacity"];
    self.voiceHintLabel.text = @"Release to send";

    if (![self beginRecordingForPressToken:pressToken]) {
        if (![HangoPermissionManager isAuthorizedForPermission:HangoPermissionTypeMicrophone]) {
            [self prepareMicrophoneIfNeededWithCompletion:nil];
        }
    }

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
    NSUInteger pressToken = self.voicePressToken;
    self.voicePressActive = NO;
    [self cancelPendingVoiceFinish];
    [self.voiceSendButton.layer removeAnimationForKey:@"hango.voice.pulse"];
    [self.voiceGlowView.layer removeAnimationForKey:@"hango.voice.ripple.scale"];
    [self.voiceGlowView.layer removeAnimationForKey:@"hango.voice.ripple.opacity"];
    self.voiceHintLabel.text = @"Long press to send";
    [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.voiceSendButton.transform = CGAffineTransformIdentity;
        self.voiceGlowView.alpha = 0.0;
        self.voiceGlowView.transform = CGAffineTransformIdentity;
    } completion:nil];

    if ([[HangoVoiceNoteManager shared] isRecording]) {
        [self completeVoicePressForToken:pressToken];
        return;
    }

    CFTimeInterval elapsed = CACurrentMediaTime() - self.voicePressBeganTime;
    if (elapsed < 0.35) {
        [[HangoVoiceNoteManager shared] cancelRecording];
        return;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_block_t finishBlock = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || pressToken != strongSelf.voicePressToken) {
            return;
        }
        strongSelf.pendingVoiceFinishBlock = nil;
        if ([[HangoVoiceNoteManager shared] isRecording]) {
            [strongSelf completeVoicePressForToken:pressToken];
            return;
        }
        if ([strongSelf beginRecordingForPressToken:pressToken]) {
            [strongSelf completeVoicePressForToken:pressToken];
        } else {
            [[HangoVoiceNoteManager shared] cancelRecording];
        }
    });
    self.pendingVoiceFinishBlock = finishBlock;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.12 * NSEC_PER_SEC)), dispatch_get_main_queue(), finishBlock);
}

- (void)photoTapped { if (self.onPhoto) self.onPhoto(); }
- (void)sendTapped {
    if (self.textField.text.length == 0) return;
    if (self.onSend) self.onSend(self.textField.text.copy);
    self.textField.text = @"";
}

@end
