#import "HangoEULAViewController.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import <Masonry/Masonry.h>

@implementation HangoEULAViewController {
    BOOL _agreed;
    UIButton *_agreeCheck;
    UITextView *_eulaTextView;
}

+ (NSString *)eulaBodyText {
    return @"This End User License Agreement (EULA) governs your use of Hango. By downloading, accessing or using Hango, you agree to be bound by this Agreement. If you do not agree to the terms herein, you may not use this application.\n\n1. Eligibility\nBy using Hango, you confirm that you are at least 18 years of age and agree to provide true and accurate age information. Individuals under the age of 18 are prohibited from using this application.\n\n2. User Generated Content\nHango allows users to post, share and view text, image and video content uploaded by users (hereinafter referred to as \"User Content\").\nBy posting content on Hango, you agree to the following terms:\n2.1 Prohibited Content\nYou may not post offensive, harmful, inappropriate or illegal content on the platform, including but not limited to:\n- Hate speech, abuse, harassment, threats or personal attacks against others;\n- Pornographic, explicit or vulgar and obscene content;\n- Content that advocates violence, discrimination, illegal activities or infringes on the legitimate rights and interests of others;\n- Content that violates public order and good customs, is irrelevant to the use of Hango, or is used for unauthorized commercial advertising and promotion;\n- False or misleading information of any kind.\n2.2 Content Licensing\nYou retain full ownership of your User Content. However, by posting User Content on Hango, you grant Hango a non-exclusive, royalty-free license to use, distribute, display and promote such content within Hango and its affiliated services.\n\n3. Reporting and Response Mechanism\n3.1 User Responsibilities\nIf you discover any content that violates this EULA, you shall promptly report it through the built-in reporting function of Hango.\n3.2 Platform Response Rules\nWe will review all reported content within 24 hours and take corresponding measures, including but not limited to removing illegal content, issuing warnings to violators, or suspending user accounts. Repeated violations will result in permanent account suspension.\n\n4. Privacy Policy\nYour use of Hango constitutes your acknowledgment and acceptance of our [Privacy Policy], which specifies the rules for our collection, use and protection of your personal information.\n\n5. Termination\nWe reserve the right to terminate or suspend your access to Hango at any time, with or without prior notice. You may cease using the application and delete your account at any time on your own initiative.\n\n6. Agreement Modification\nWe may amend the terms of this Agreement at any time. Revised terms will be announced on Hango. Your continued use of the application after the announcement constitutes your acceptance of the updated Agreement.\n\n7. Disclaimer\nHango is provided on an \"AS IS\" basis without any express or implied warranties. We do not guarantee that the application service will be uninterrupted, error-free or completely secure, nor do we guarantee the absolute accuracy of all content on the platform.\n\n8. Limitation of Liability\nTo the maximum extent permitted by applicable laws, we shall not be liable for any losses or damages arising from your use of Hango and its internal content.";
}

- (void)setupUI {
    self.showsBackButton = YES;
    self.navTitleText = @"EULA";

    _eulaTextView = [[UITextView alloc] init];
    _eulaTextView.editable = NO;
    _eulaTextView.selectable = NO;
    _eulaTextView.backgroundColor = UIColor.clearColor;
    _eulaTextView.textContainerInset = UIEdgeInsetsZero;
    _eulaTextView.textContainer.lineFragmentPadding = 0;
    _eulaTextView.showsVerticalScrollIndicator = YES;
    _eulaTextView.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    _eulaTextView.textColor = [HangoTheme primaryDarkColor];
    _eulaTextView.text = [self.class eulaBodyText];
    [self.contentView addSubview:_eulaTextView];

    UIButton *termsLink = [self linkButtonWithTitle:@"Terms of Use" action:@selector(scrollToTop)];
    UIButton *privacyLink = [self linkButtonWithTitle:@"Privacy Policy" action:@selector(scrollToPrivacySection)];
    [self.contentView addSubview:termsLink];
    [self.contentView addSubview:privacyLink];

    UIButton *cancelBtn = [HangoDesignKit pillButtonWithTitle:@"Cancel" style:HangoPillButtonStyleDark];
    cancelBtn.backgroundColor = [HangoTheme primaryDarkColor];
    [cancelBtn setTitleColor:[HangoTheme backgroundTopColor] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:cancelBtn];

    UIButton *agreeBtn = [HangoDesignKit pillButtonWithTitle:@"I agree" style:HangoPillButtonStyleLight];
    agreeBtn.layer.borderWidth = 0;
    [agreeBtn addTarget:self action:@selector(agreeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:agreeBtn];

    UIView *agreeRow = [self agreementRow];
    [self.contentView addSubview:agreeRow];

    [_eulaTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(52);
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
        make.bottom.equalTo(termsLink.mas_top).offset(-16);
    }];
    [termsLink mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(24);
        make.bottom.equalTo(cancelBtn.mas_top).offset(-20);
    }];
    [privacyLink mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-24);
        make.centerY.equalTo(termsLink);
    }];
    [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(24);
        make.bottom.equalTo(agreeRow.mas_top).offset(-18);
        make.height.mas_equalTo(50);
        make.right.equalTo(self.contentView.mas_centerX).offset(-6);
    }];
    [agreeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-24);
        make.left.equalTo(self.contentView.mas_centerX).offset(6);
        make.centerY.height.equalTo(cancelBtn);
    }];
    [agreeRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-10);
    }];
}

- (UIButton *)linkButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    NSDictionary *attrs = @{
        NSFontAttributeName: [HangoTheme monoFont],
        NSForegroundColorAttributeName: [HangoTheme primaryDarkColor],
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
    [btn setAttributedTitle:[[NSAttributedString alloc] initWithString:title attributes:attrs] forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (UIView *)agreementRow {
    UIView *row = [[UIView alloc] init];

    _agreeCheck = [UIButton buttonWithType:UIButtonTypeCustom];
    _agreed = NO;
    _agreeCheck.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self updateAgreeCheckImage];
    [_agreeCheck addTarget:self action:@selector(toggleAgree) forControlEvents:UIControlEventTouchUpInside];
    [row addSubview:_agreeCheck];

    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 2;
    label.attributedText = [self agreementAttributedText];
    [row addSubview:label];

    [_agreeCheck mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(row);
        make.centerY.equalTo(label);
        make.width.height.mas_equalTo(18);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_agreeCheck.mas_right).offset(8);
        make.right.top.bottom.equalTo(row);
    }];
    return row;
}

- (NSAttributedString *)agreementAttributedText {
    NSString *text = @"Agree with User Agreement and Privacy Policy";
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text attributes:@{
        NSFontAttributeName: [HangoTheme captionFont],
        NSForegroundColorAttributeName: [HangoTheme primaryDarkColor]
    }];
    NSRange userRange = [text rangeOfString:@"User Agreement"];
    NSRange privacyRange = [text rangeOfString:@"Privacy Policy"];
    if (userRange.location != NSNotFound) {
        [attr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:userRange];
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
    _agreeCheck.backgroundColor = UIColor.clearColor;
    _agreeCheck.layer.borderWidth = 0;
    _agreeCheck.layer.cornerRadius = 0;
}

- (void)toggleAgree {
    _agreed = !_agreed;
    [self updateAgreeCheckImage];
}

- (void)scrollToTop {
    [_eulaTextView setContentOffset:CGPointZero animated:YES];
}

- (void)scrollToPrivacySection {
    NSRange range = [_eulaTextView.text rangeOfString:@"4. Privacy Policy"];
    if (range.location != NSNotFound) {
        [_eulaTextView scrollRangeToVisible:range];
    }
}

- (void)agreeTapped {
    if (!_agreed) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"Please agree to the User Agreement and Privacy Policy."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [self goBack];
}

@end
