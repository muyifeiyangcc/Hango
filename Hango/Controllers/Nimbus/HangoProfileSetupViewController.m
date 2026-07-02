#import "HangoProfileSetupViewController.h"
#import "HangoAppleSignInManager.h"
#import "HangoPersona.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoSessionManager.h"
#import "HangoAppRouter.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPermissionManager.h"
#import "HangoHUD.h"
#import "HGXAnchor.h"

@interface HangoProfileSetupViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation HangoProfileSetupViewController {
    UIImageView *_avatarView;
    UITextField *_nameField;
    UIView *_underlineView;
    UIButton *_saveBtn;
    UIImage *_selectedAvatarImage;
    BOOL _hasExistingAvatar;
    BOOL _didApplyPrefill;
}

- (void)setupUI {
    self.showsBackButton = YES;
    if (self.editingExistingProfile) {
        self.navTitleText = @"Editing materials";
    }

    UIView *avatarWrap = [[UIView alloc] init];
    [self.contentView addSubview:avatarWrap];

    _avatarView = [[UIImageView alloc] init];
    _avatarView.contentMode = UIViewContentModeScaleAspectFill;
    _avatarView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.55];
    _avatarView.layer.cornerRadius = 60;
    _avatarView.clipsToBounds = YES;
    _avatarView.layer.borderWidth = 2.5;
    _avatarView.layer.borderColor = UIColor.whiteColor.CGColor;
    [avatarWrap addSubview:_avatarView];

    UIButton *editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *editIcon = [HangoTheme imageNamed:@"edit_avatar"];
    if (editIcon) {
        [editBtn setImage:[editIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        editBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    [editBtn addTarget:self action:@selector(pickAvatar) forControlEvents:UIControlEventTouchUpInside];
    [avatarWrap addSubview:editBtn];

    _nameField = [[UITextField alloc] init];
    _nameField.placeholder = @"Enter display name";
    _nameField.font = [HangoTheme monoFont];
    _nameField.textColor = [HangoTheme primaryDarkColor];
    _nameField.textAlignment = NSTextAlignmentCenter;
    _nameField.borderStyle = UITextBorderStyleNone;
    _nameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    _nameField.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.contentView addSubview:_nameField];

    _underlineView = [[UIView alloc] init];
    _underlineView.backgroundColor = [HangoTheme primaryDarkColor];
    [self.contentView addSubview:_underlineView];

    NSString *actionTitle = self.editingExistingProfile ? @"Done" : @"Save";
    _saveBtn = [HangoDesignKit pillButtonWithTitle:actionTitle style:HangoPillButtonStyleDark];
    _saveBtn.layer.cornerRadius = 20;
    [_saveBtn addTarget:self action:@selector(saveTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_saveBtn];

    [avatarWrap hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.view.hgx_safeAreaLayoutGuideTop).offset(108);
        make.centerX.equalTo(self.contentView);
        make.width.height.hgx_equalTo(120);
    }];
    [_avatarView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(avatarWrap);
    }];
    [editBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.right.bottom.equalTo(avatarWrap).offset(2);
        make.width.height.hgx_equalTo(36);
    }];
    [_nameField hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(avatarWrap.hgx_bottom).offset(36);
        make.left.equalTo(self.contentView).offset(48);
        make.right.equalTo(self.contentView).offset(-48);
        make.height.hgx_equalTo(36);
    }];
    [_underlineView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_nameField.hgx_bottom).offset(4);
        make.left.right.equalTo(_nameField);
        make.height.hgx_equalTo(1);
    }];
    [_saveBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(32);
        make.right.equalTo(self.contentView).offset(-32);
        make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom).offset(-36);
        make.height.hgx_equalTo(62);
    }];

    [self applyPrefilledProfileIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.editingExistingProfile) {
        [self loadExistingProfile];
    } else {
        [self applyPrefilledProfileIfNeeded];
    }
}

- (void)applyPrefilledProfileIfNeeded {
    if (_didApplyPrefill || self.editingExistingProfile) {
        return;
    }
    _didApplyPrefill = YES;

    NSString *displayName = self.prefilledDisplayName;
    if (displayName.length == 0) {
        displayName = [[HangoDataStore shared] appleCachedDisplayName];
    }
    if (displayName.length == 0) {
        displayName = [[HangoDataStore shared].currentPersona.name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    }
    if (displayName.length > 0 && _nameField.text.length == 0) {
        _nameField.text = displayName;
    }

    UIImage *avatarImage = self.prefilledAvatarImage;
    if (!avatarImage && displayName.length > 0) {
        avatarImage = [HangoAppleSignInManager avatarImageForDisplayName:displayName];
    }
    if (avatarImage && !_hasExistingAvatar) {
        _selectedAvatarImage = avatarImage;
        _avatarView.image = avatarImage;
        _avatarView.backgroundColor = UIColor.clearColor;
        _hasExistingAvatar = YES;
    }
}

- (void)loadExistingProfile {
    HangoPersona *persona = [HangoDataStore shared].currentPersona;
    _nameField.text = persona.name;
    UIImage *avatar = [HangoTheme avatarImageForPersona:persona];
    if (avatar) {
        _avatarView.image = avatar;
        _avatarView.backgroundColor = UIColor.clearColor;
        _hasExistingAvatar = YES;
    }
}

- (void)pickAvatar {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [HangoPermissionManager presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera
                                                  fromViewController:self
                                                            delegate:self];
        }]];
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Choose from Library" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [HangoPermissionManager presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary
                                                  fromViewController:self
                                                            delegate:self];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.view;
        sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) {
        image = info[UIImagePickerControllerOriginalImage];
    }
    if (image) {
        _selectedAvatarImage = image;
        _avatarView.image = image;
        _avatarView.backgroundColor = UIColor.clearColor;
        _hasExistingAvatar = YES;
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)avatarImageForSaving {
    if (_selectedAvatarImage) {
        return _selectedAvatarImage;
    }
    if (_hasExistingAvatar) {
        return [HangoTheme avatarImageForPersona:[HangoDataStore shared].currentPersona];
    }
    return nil;
}

- (void)saveTapped {
    NSString *name = [_nameField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    UIImage *avatar = [self avatarImageForSaving];
    if (!avatar) {
        [self showAlertWithText:@"Please select an avatar."];
        return;
    }
    if (name.length == 0) {
        [self showAlertWithText:@"Please enter a display name."];
        return;
    }

    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:YES operation:^id {
        [[HangoSessionManager shared] updateProfileWithName:name avatarImage:avatar];
        return nil;
    } completion:^(__unused id result, __unused NSError *error) {
        if (self.editingExistingProfile) {
            [MBProgressHUD showSuccessMessage:@"Profile updated"];
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
        [HangoAppRouter showMainTabBar];
    }];
}

- (void)showAlertWithText:(NSString *)text {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
