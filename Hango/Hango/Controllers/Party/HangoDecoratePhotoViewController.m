#import "HangoDecoratePhotoViewController.h"
#import "HangoParty.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoWalletViewController.h"
#import "HangoGroupChatViewController.h"
#import "HangoNoMoneyViewController.h"
#import <MBProgressHUD+JDragon/MBProgressHUD+JDragon.h>
#import <Masonry/Masonry.h>

@implementation HangoDecoratePhotoViewController {
    UIImageView *_preview;
    UIScrollView *_decorScroll;
    NSArray<NSString *> *_decorNames;
    NSInteger _selectedIndex;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UIButton *upload = [UIButton buttonWithType:UIButtonTypeCustom];
    upload.backgroundColor = UIColor.whiteColor;
    upload.layer.cornerRadius = 20;
    [upload setImage:[HangoTheme imageNamed:@"interface-upload-button-2--arrow-bottom-download-internet-network,-erver-up-upload"] forState:UIControlStateNormal];
    [upload setTitle:@" Upload" forState:UIControlStateNormal];
    [upload setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    upload.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [upload addTarget:self action:@selector(confirmDecorate) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:upload];

    _preview = [[UIImageView alloc] initWithImage:[HangoTheme avatarImageNamed:self.party.coverImageName ?: @"avatar_10"]];
    _preview.contentMode = UIViewContentModeScaleAspectFill;
    _preview.layer.cornerRadius = 0;
    _preview.clipsToBounds = YES;
    [self.contentView addSubview:_preview];

    UIView *grid = [[UIView alloc] init];
    grid.userInteractionEnabled = NO;
    grid.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
    grid.layer.borderWidth = 1;
    [_preview addSubview:grid];

    UIView *panel = [[UIView alloc] init];
    panel.backgroundColor = [UIColor colorWithRed:0.88 green:0.97 blue:0.98 alpha:1];
    [self.contentView addSubview:panel];

    UILabel *choose = [[UILabel alloc] init];
    choose.text = @"Choose decoration";
    choose.font = [HangoTheme headlineFont];
    choose.textColor = [HangoTheme primaryDarkColor];
    [panel addSubview:choose];

    _decorNames = @[@"artboard_55", @"artboard_56", @"artboard_57", @"artboard_53", @"artboard_54"];
    _decorScroll = [[UIScrollView alloc] init];
    _decorScroll.showsHorizontalScrollIndicator = NO;
    [panel addSubview:_decorScroll];

    CGFloat x = 16;
    for (NSInteger i = 0; i < _decorNames.count; i++) {
        UIButton *item = [UIButton buttonWithType:UIButtonTypeCustom];
        item.tag = i;
        item.backgroundColor = [HangoTheme primaryDarkColor];
        item.layer.cornerRadius = 32;
        [item setImage:[HangoTheme imageNamed:_decorNames[i]] forState:UIControlStateNormal];
        item.frame = CGRectMake(x, 0, 64, 64);
        [item addTarget:self action:@selector(selectDecor:) forControlEvents:UIControlEventTouchUpInside];
        [_decorScroll addSubview:item];

        UILabel *cost = [[UILabel alloc] initWithFrame:CGRectMake(x, 70, 64, 18)];
        cost.text = @"× 50";
        cost.font = [HangoTheme captionFont];
        cost.textAlignment = NSTextAlignmentCenter;
        cost.textColor = [HangoTheme primaryDarkColor];
        [_decorScroll addSubview:cost];
        x += 80;
    }
    _decorScroll.contentSize = CGSizeMake(x, 90);
    _selectedIndex = 0;

    [upload mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(48);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(110);
    }];
    [_preview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(upload.mas_bottom).offset(8);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(panel.mas_top);
    }];
    [grid mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_preview);
    }];
    [panel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(170);
    }];
    [choose mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(panel).offset(16);
        make.left.equalTo(panel).offset(20);
    }];
    [_decorScroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(choose.mas_bottom).offset(12);
        make.left.right.equalTo(panel);
        make.height.mas_equalTo(96);
    }];
}

- (void)selectDecor:(UIButton *)sender {
    _selectedIndex = sender.tag;
    for (UIView *v in _decorScroll.subviews) {
        if ([v isKindOfClass:UIButton.class]) {
            UIButton *btn = (UIButton *)v;
            btn.layer.borderWidth = btn.tag == _selectedIndex ? 3 : 0;
            btn.layer.borderColor = [HangoTheme accentBlueColor].CGColor;
        }
    }
}

- (void)confirmDecorate {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
        if ([HangoDataStore shared].currentUser.diamondBalance >= 50) {
            [[HangoDataStore shared] spendDiamonds:50];
            [MBProgressHUD showSuccessMessage:@"Decoration applied"];
        } else {
            HangoNoMoneyViewController *vc = [[HangoNoMoneyViewController alloc] init];
            vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
            __weak typeof(self) weakSelf = self;
            vc.onRecharge = ^{
                [weakSelf.navigationController pushViewController:[[HangoWalletViewController alloc] init] animated:YES];
            };
            [self presentViewController:vc animated:YES completion:nil];
        }
    }];
}

@end
