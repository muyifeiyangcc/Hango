#import "HangoDisplayString.h"
#import "HangoEULAViewController.h"
#import "HangoAppRouter.h"
#import "HangoEULAAcceptance.h"
#import "HangoDocHostViewController.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HGXAnchor.h"

static NSString * const kHangoEULABodyText =
@"This End User License Agreement (EULA) governs your use of Hango. By downloading, accessing or using Hango, you agree to be bound by this Agreement. If you do not agree to the terms herein, you may not use this application.\n\n"
@"1. Eligibility\n"
@"By using Hango, you confirm that you are at least 18 years of age and agree to provide true and accurate age information. Individuals under the age of 18 are prohibited from using this application.\n\n"
@"2. Member Generated Content\n"
@"Hango allows members to share, share and view text, image and video content uploaded by members (hereinafter referred to as \"Member Content\").\n"
@"By sharing content on Hango, you agree to the following terms:\n\n"
@"2.1 Prohibited Content\n"
@"You may not share offensive, harmful, inappropriate or illegal content on the platform, including but not limited to:\n"
@"- Hate speech, abuse, harassment, threats or personal attacks against others;\n"
@"- Pornographic, explicit or vulgar and obscene content;\n"
@"- Content that advocates violence, discrimination, illegal activities or infringes on the legitimate rights and interests of others;\n"
@"- Content that violates public order and good customs, is irrelevant to the use of Hango, or is used for unauthorized commercial advertising and promotion;\n"
@"- False or misleading information of any kind.\n\n"
@"2.2 Content Licensing\n"
@"You retain full ownership of your Member Content. However, by sharing Member Content on Hango, you grant Hango a non-exclusive, royalty-free license to use, distribute, display and promote such content within Hango and its affiliated services.\n\n"
@"3. Reporting and Response Mechanism\n\n"
@"3.1 Member Responsibilities\n"
@"If you discover any content that violates this EULA, you shall promptly report it through the built-in reporting function of Hango.\n\n"
@"3.2 Platform Response Rules\n"
@"We will review all reported content within 24 hours and take corresponding measures, including but not limited to removing illegal content, issuing warnings to violators, or suspending persona accounts. Repeated violations will result in permanent account suspension.\n\n"
@"4. Privacy Policy\n"
@"Your use of Hango constitutes your acknowledgment and acceptance of our Privacy Policy, which specifies the rules for our collection, use and protection of your personal information.\n\n"
@"5. Termination\n"
@"We reserve the right to terminate or suspend your access to Hango at any time, with or without prior notice. You may cease using the application and delete your account at any time on your own initiative.\n\n"
@"6. Agreement Modification\n"
@"We may amend the terms of this Agreement at any time. Revised terms will be announced on Hango. Your continued use of the application after the announcement constitutes your acceptance of the updated Agreement.\n\n"
@"7. Disclaimer\n"
@"Hango is provided on an \"AS IS\" basis without any express or implied warranties. We do not guarantee that the application service will be uninterrupted, error-free or completely secure, nor do we guarantee the absolute accuracy of all content on the platform.\n\n"
@"8. Limitation of Liability\n"
@"To the maximum extent permitted by applicable laws, we shall not be liable for any losses or damages arising from your use of Hango and its internal content.";

@implementation HangoEULAViewController {
    UIScrollView *_scrollView;
    UIView *_scrollContent;
    UIButton *_agreeCheck;
    UIButton *_cancelButton;
    UIButton *_agreeButton;
    BOOL _agreed;
}

- (void)viewDidLoad {
    _agreed = self.initialAgreementChecked;
    [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.isMovingFromParentViewController || !_agreed || !self.onAgreementConfirmed) {
        return;
    }
    self.onAgreementConfirmed();
}

- (void)setupUI {
    self.showsBackButton = !self.isLaunchGate;
    self.navTitleText = @"EULA";

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsVerticalScrollIndicator = YES;
    _scrollView.alwaysBounceVertical = YES;
    [self.contentView addSubview:_scrollView];

    _scrollContent = [[UIView alloc] init];
    [_scrollView addSubview:_scrollContent];

    UILabel *bodyLabel = [[UILabel alloc] init];
    bodyLabel.numberOfLines = 0;
    bodyLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    bodyLabel.textColor = [HangoTheme primaryDarkColor];
    bodyLabel.text = kHangoEULABodyText;
    [_scrollContent addSubview:bodyLabel];

    UIButton *termsButton = [self linkButtonWithTitle:@"Terms of Use" action:@selector(openTermsOfUse)];
    UIButton *privacyButton = [self linkButtonWithTitle:@"Privacy Policy" action:@selector(openPrivacyPolicy)];
    [_scrollContent addSubview:termsButton];
    [_scrollContent addSubview:privacyButton];

    UIView *footer = [[UIView alloc] init];
    [self.contentView addSubview:footer];

    _cancelButton = [HangoDesignKit pillButtonWithTitle:@"Cancel" style:HangoPillButtonStyleDark];
    _cancelButton.layer.cornerRadius = 20;
    [_cancelButton setTitleColor:[HangoTheme accentBlueColor] forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:_cancelButton];

    _agreeButton = [HangoDesignKit pillButtonWithTitle:@"I agree" style:HangoPillButtonStyleLight];
    _agreeButton.layer.cornerRadius = 20;
    _agreeButton.layer.borderWidth = 1.2;
    _agreeButton.layer.borderColor = [HangoTheme primaryDarkColor].CGColor;
    [_agreeButton addTarget:self action:@selector(agreeTapped) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:_agreeButton];

    UIView *agreeRow = [self agreementRow];
    [footer addSubview:agreeRow];

    [_scrollView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(footer.hgx_top);
    }];
    [_scrollContent hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(_scrollView);
        make.width.equalTo(_scrollView);
    }];
    [bodyLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_scrollContent).offset(8);
        make.left.equalTo(_scrollContent).offset(24);
        make.right.equalTo(_scrollContent).offset(-24);
    }];
    [termsButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(bodyLabel.hgx_bottom).offset(20);
        make.left.equalTo(bodyLabel);
        make.bottom.equalTo(_scrollContent).offset(-16);
    }];
    [privacyButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(termsButton);
        make.right.equalTo(bodyLabel);
    }];
    [footer hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.contentView);
    }];
    if (self.isLaunchGate) {
        _cancelButton.hidden = YES;
        [_agreeButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.equalTo(footer).offset(8);
            make.left.equalTo(footer).offset(24);
            make.right.equalTo(footer).offset(-24);
            make.height.hgx_equalTo(52);
        }];
    } else {
        [_cancelButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.equalTo(footer).offset(8);
            make.left.equalTo(footer).offset(24);
            make.height.hgx_equalTo(52);
        }];
        [_agreeButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.width.height.equalTo(_cancelButton);
            make.left.equalTo(_cancelButton.hgx_right).offset(12);
            make.right.equalTo(footer).offset(-24);
        }];
    }
    [agreeRow hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_agreeButton.hgx_bottom).offset(16);
        make.left.equalTo(footer).offset(24);
        make.right.equalTo(footer).offset(-24);
        make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom).offset(-16);
    }];
}

- (UIButton *)linkButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    NSDictionary *attributes = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
    NSAttributedString *titleAttr = [[NSAttributedString alloc] initWithString:title attributes:attributes];
    [button setAttributedTitle:titleAttr forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIView *)agreementRow {
    UIView *row = [[UIView alloc] init];

    _agreeCheck = [UIButton buttonWithType:UIButtonTypeCustom];
    _agreeCheck.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self updateAgreeCheckImage];
    [_agreeCheck addTarget:self action:@selector(toggleAgree) forControlEvents:UIControlEventTouchUpInside];
    [row addSubview:_agreeCheck];

    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 2;
    label.attributedText = [self agreementAttributedText];
    label.userInteractionEnabled = YES;
    [label addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(agreementLabelTapped:)]];
    [row addSubview:label];

    [_agreeCheck hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(row);
        make.centerY.equalTo(label);
        make.width.height.hgx_equalTo(18);
    }];
    [label hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(_agreeCheck.hgx_right).offset(8);
        make.right.top.bottom.equalTo(row);
    }];
    return row;
}

- (NSAttributedString *)agreementAttributedText {
    NSString *text = HangoDisplayStringAgreeUserAgreementLine();
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text attributes:@{
        NSFontAttributeName: [HangoTheme captionFont],
        NSForegroundColorAttributeName: [HangoTheme primaryDarkColor]
    }];
    NSRange agreementRange = HangoDisplayStringUserAgreementRangeInAgreeLine(text);
    NSRange privacyRange = [text rangeOfString:@"Privacy Policy"];
    if (agreementRange.location != NSNotFound) {
        [attr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:agreementRange];
    }
    if (privacyRange.location != NSNotFound) {
        [attr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:privacyRange];
    }
    return attr;
}

- (void)updateAgreeCheckImage {
    NSString *imageName = _agreed ? @"agreement_checked" : @"agreement_unchecked";
    UIImage *image = [[HangoTheme imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [_agreeCheck setImage:image forState:UIControlStateNormal];
}

- (void)toggleAgree {
    _agreed = !_agreed;
    [self updateAgreeCheckImage];
}

- (NSRange)rangeAtPoint:(CGPoint)point inLabel:(UILabel *)label {
    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:label.attributedText];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:label.bounds.size];
    container.lineFragmentPadding = 0;
    container.maximumNumberOfLines = label.numberOfLines;
    container.lineBreakMode = label.lineBreakMode;
    [layoutManager addTextContainer:container];
    [storage addLayoutManager:layoutManager];

    NSUInteger index = [layoutManager characterIndexForPoint:point inTextContainer:container fractionOfDistanceBetweenInsertionPoints:NULL];
    if (index < label.attributedText.length) {
        return NSMakeRange(index, 1);
    }
    return NSMakeRange(NSNotFound, 0);
}

- (void)agreementLabelTapped:(UITapGestureRecognizer *)gesture {
    UILabel *label = (UILabel *)gesture.view;
    if (![label isKindOfClass:UILabel.class] || label.attributedText.length == 0) {
        return;
    }

    NSString *text = label.attributedText.string;
    NSRange agreementRange = HangoDisplayStringUserAgreementRangeInAgreeLine(text);
    NSRange privacyRange = [text rangeOfString:@"Privacy Policy"];
    NSRange targetRange = [self rangeAtPoint:[gesture locationInView:label] inLabel:label];

    if (agreementRange.location != NSNotFound && NSLocationInRange(targetRange.location, agreementRange)) {
        [self openTermsOfUse];
        return;
    }
    if (privacyRange.location != NSNotFound && NSLocationInRange(targetRange.location, privacyRange)) {
        [self openPrivacyPolicy];
    }
}

- (void)openTermsOfUse {
    [self.navigationController pushViewController:[HangoDocHostViewController memberAgreementViewController] animated:YES];
}

- (void)openPrivacyPolicy {
    [self.navigationController pushViewController:[HangoDocHostViewController privacyPolicyViewController] animated:YES];
}

- (void)cancelTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)agreeTapped {
    _agreed = YES;
    [self updateAgreeCheckImage];
    [HangoEULAAcceptance markLaunchEULAAccepted];
    if (self.onAgreementConfirmed) {
        self.onAgreementConfirmed();
    }
    if (self.isLaunchGate) {
        [HangoAppRouter showWelcome];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
