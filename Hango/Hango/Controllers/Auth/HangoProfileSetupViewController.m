#import "HangoProfileSetupViewController.h"
#import "HangoRequestManager.h"
#import "HangoSessionManager.h"
#import "HangoAppRouter.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import <Masonry/Masonry.h>

@interface HangoProfileSetupViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation HangoProfileSetupViewController {
    UIImageView *_avatarView;
    UITextField *_nameField;
    UIView *_underlineView;
    UIImage *_selectedAvatarImage;
}

- (void)setupUI {
    self.showsBackButton = YES;

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
    _nameField.placeholder = @"Enter username";
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

    UIButton *saveBtn = [HangoDesignKit pillButtonWithTitle:@"Save" style:HangoPillButtonStyleDark];
    saveBtn.layer.cornerRadius = 20;
    [saveBtn addTarget:self action:@selector(saveTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:saveBtn];

    [avatarWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(108);
        make.centerX.equalTo(self.contentView);
        make.width.height.mas_equalTo(120);
    }];
    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(avatarWrap);
    }];
    [editBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.equalTo(avatarWrap).offset(2);
        make.width.height.mas_equalTo(36);
    }];
    [_nameField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatarWrap.mas_bottom).offset(36);
        make.left.equalTo(self.contentView).offset(48);
        make.right.equalTo(self.contentView).offset(-48);
        make.height.mas_equalTo(36);
    }];
    [_underlineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_nameField.mas_bottom).offset(4);
        make.left.right.equalTo(_nameField);
        make.height.mas_equalTo(1);
    }];
    [saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(32);
        make.right.equalTo(self.contentView).offset(-32);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-36);
        make.height.mas_equalTo(62);
    }];
}

- (void)pickAvatar {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
        }]];
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Choose from Library" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.view;
        sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.delegate = self;
    picker.allowsEditing = YES;
    [self presentViewController:picker animated:YES completion:nil];
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
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveTapped {
    NSString *name = [_nameField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (_selectedAvatarImage == nil) {
        [self showAlertWithMessage:@"Please select an avatar."];
        return;
    }
    if (name.length == 0) {
        [self showAlertWithMessage:@"Please enter a username."];
        return;
    }

    UIImage *avatar = _selectedAvatarImage;
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view operation:^id {
        [[HangoSessionManager shared] updateProfileWithName:name avatarImage:avatar];
        return nil;
    } completion:^(__unused id result, __unused NSError *error) {
        [HangoAppRouter showMainTabBarSelectingProfileTab];
    }];
}

- (void)showAlertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
