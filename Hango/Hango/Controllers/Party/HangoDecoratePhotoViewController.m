#import "HangoDecoratePhotoViewController.h"
#import "HangoParty.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoDecorStickerView.h"
#import "HangoWalletViewController.h"
#import "HangoNoMoneyViewController.h"
#import "HangoPurchaseDecorViewController.h"
#import "HangoHUD.h"
#import "Masonry.h"

static const NSInteger kHangoDecorCountLabelTag = 2000;
static const NSInteger kHangoNotFoundIndex = -1;

@interface HangoDecoratePhotoViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, assign) CGAffineTransform stickerGestureStartTransform;
@property (nonatomic, assign) NSInteger pendingPurchaseDecorIndex;
@end

@implementation HangoDecoratePhotoViewController {
    UIView *_previewContainer;
    UIImageView *_preview;
    UIView *_stickerCanvas;
    HangoDecorStickerView *_activeSticker;
    UIView *_gridOverlay;
    UIScrollView *_decorScroll;
    NSArray<NSString *> *_decorNames;
    NSInteger _selectedIndex;
    NSInteger _activeStickerDecorIndex;
    UIImage *_selectedImage;
    BOOL _didPlaceSticker;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateDecorCountLabels];
}

- (void)openWalletPage {
    [self.navigationController pushViewController:[[HangoWalletViewController alloc] init] animated:YES];
}

- (void)setupUI {
    self.showsBackButton = YES;
    _selectedIndex = kHangoNotFoundIndex;
    _activeStickerDecorIndex = kHangoNotFoundIndex;
    _pendingPurchaseDecorIndex = kHangoNotFoundIndex;

    UIButton *upload = [UIButton buttonWithType:UIButtonTypeCustom];
    upload.backgroundColor = UIColor.whiteColor;
    upload.layer.cornerRadius = 20;
    upload.layer.borderWidth = 1.0;
    upload.layer.borderColor = [HangoTheme primaryDarkColor].CGColor;
    UIImage *uploadIcon = [HangoTheme imageNamed:@"上传照片图标"];
    [upload setImage:[uploadIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [upload setTitle:@" Upload" forState:UIControlStateNormal];
    [upload setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    upload.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    upload.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 4);
    upload.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
    [upload addTarget:self action:@selector(confirmDecorate) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:upload];

    _previewContainer = [[UIView alloc] init];
    _previewContainer.clipsToBounds = YES;
    _previewContainer.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    [self.contentView addSubview:_previewContainer];

    _preview = [[UIImageView alloc] init];
    _preview.contentMode = UIViewContentModeScaleAspectFill;
    _preview.clipsToBounds = YES;
    _preview.userInteractionEnabled = NO;
    [_previewContainer addSubview:_preview];

    _stickerCanvas = [[UIView alloc] init];
    _stickerCanvas.backgroundColor = UIColor.clearColor;
    _stickerCanvas.clipsToBounds = NO;
    _stickerCanvas.multipleTouchEnabled = YES;
    [_previewContainer addSubview:_stickerCanvas];

    UIPinchGestureRecognizer *canvasPinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleStickerPinch:)];
    UIRotationGestureRecognizer *canvasRotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleStickerRotate:)];
    canvasPinch.delegate = self;
    canvasRotate.delegate = self;
    [_stickerCanvas addGestureRecognizer:canvasPinch];
    [_stickerCanvas addGestureRecognizer:canvasRotate];

    _gridOverlay = [[UIView alloc] init];
    _gridOverlay.userInteractionEnabled = NO;
    _gridOverlay.backgroundColor = UIColor.clearColor;
    [_previewContainer addSubview:_gridOverlay];

    UIView *panel = [[UIView alloc] init];
    panel.backgroundColor = [UIColor colorWithRed:0.88 green:0.97 blue:0.98 alpha:1];
    [self.contentView addSubview:panel];

    UILabel *choose = [[UILabel alloc] init];
    choose.text = @"Choose decoration";
    choose.font = [HangoTheme headlineFont];
    choose.textColor = [HangoTheme primaryDarkColor];
    [panel addSubview:choose];

    _decorNames = @[
        @"artboard_46", @"artboard_47", @"artboard_48", @"artboard_49",
        @"artboard_50", @"artboard_51", @"artboard_52", @"artboard_53",
        @"artboard_54", @"artboard_55", @"artboard_56", @"artboard_57"
    ];
    _decorScroll = [[UIScrollView alloc] init];
    _decorScroll.showsHorizontalScrollIndicator = NO;
    [panel addSubview:_decorScroll];

    CGFloat x = 16;
    for (NSInteger i = 0; i < _decorNames.count; i++) {
        UIButton *item = [UIButton buttonWithType:UIButtonTypeCustom];
        item.tag = i;
        item.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
        item.layer.cornerRadius = 32;
        item.layer.borderWidth = 1.0;
        item.layer.borderColor = [UIColor colorWithWhite:0.82 alpha:1.0].CGColor;
        item.imageView.contentMode = UIViewContentModeScaleAspectFit;
        item.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        [item setImage:[HangoTheme imageNamed:_decorNames[i]] forState:UIControlStateNormal];
        item.frame = CGRectMake(x, 0, 64, 64);
        [item addTarget:self action:@selector(selectDecor:) forControlEvents:UIControlEventTouchUpInside];
        [_decorScroll addSubview:item];

        UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 70, 64, 18)];
        countLabel.tag = kHangoDecorCountLabelTag + i;
        countLabel.font = [HangoTheme captionFont];
        countLabel.textAlignment = NSTextAlignmentCenter;
        countLabel.textColor = [HangoTheme primaryDarkColor];
        [_decorScroll addSubview:countLabel];
        x += 80;
    }
    _decorScroll.contentSize = CGSizeMake(x, 90);

    [upload mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(8);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(118);
    }];
    [_previewContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(upload.mas_bottom).offset(8);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(panel.mas_top);
    }];
    [_preview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_previewContainer);
    }];
    [_stickerCanvas mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_previewContainer);
    }];
    [_gridOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_previewContainer);
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

    if (self.selectedImage) {
        _selectedImage = self.selectedImage;
        _preview.image = self.selectedImage;
    }
    [self updateDecorCountLabels];
    [self updateDecorSelection];
    [self drawGridLines];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self drawGridLines];
    [self placeStickerIfNeeded];
}

- (void)placeStickerIfNeeded {
    if (!_activeSticker || _didPlaceSticker || CGRectIsEmpty(_stickerCanvas.bounds)) {
        return;
    }
    _activeSticker.center = CGPointMake(CGRectGetMidX(_stickerCanvas.bounds), CGRectGetMidY(_stickerCanvas.bounds));
    _didPlaceSticker = YES;
}

- (void)drawGridLines {
    for (CALayer *layer in _gridOverlay.layer.sublayers.copy) {
        [layer removeFromSuperlayer];
    }
    CGRect bounds = _gridOverlay.bounds;
    if (CGRectIsEmpty(bounds)) {
        return;
    }
    CGFloat thirdW = CGRectGetWidth(bounds) / 3.0;
    CGFloat thirdH = CGRectGetHeight(bounds) / 3.0;
    CGColorRef lineColor = [UIColor colorWithWhite:1 alpha:0.75].CGColor;
    for (NSInteger i = 1; i < 3; i++) {
        CALayer *v = [CALayer layer];
        v.backgroundColor = lineColor;
        v.frame = CGRectMake(thirdW * i, 0, 1, CGRectGetHeight(bounds));
        [_gridOverlay.layer addSublayer:v];

        CALayer *h = [CALayer layer];
        h.backgroundColor = lineColor;
        h.frame = CGRectMake(0, thirdH * i, CGRectGetWidth(bounds), 1);
        [_gridOverlay.layer addSublayer:h];
    }
}

- (void)updateDecorCountLabels {
    for (NSInteger i = 0; i < _decorNames.count; i++) {
        UILabel *label = [_decorScroll viewWithTag:kHangoDecorCountLabelTag + i];
        if (![label isKindOfClass:UILabel.class]) {
            continue;
        }
        NSInteger count = [[HangoDataStore shared] decorationCountForName:_decorNames[i]];
        label.text = [NSString stringWithFormat:@"× %ld", (long)count];
    }
}

- (void)updateDecorSelection {
    for (UIView *v in _decorScroll.subviews) {
        if ([v isKindOfClass:UIButton.class]) {
            UIButton *btn = (UIButton *)v;
            BOOL selected = btn.tag == _selectedIndex;
            btn.layer.borderWidth = selected ? 2.5 : 1.0;
            btn.layer.borderColor = (selected ? [HangoTheme accentBlueColor] : [UIColor colorWithWhite:0.82 alpha:1.0]).CGColor;
        }
    }
}

- (void)placeStickerForDecorIndex:(NSInteger)index {
    NSString *name = _decorNames[index];
    UIImage *stickerImage = [HangoTheme imageNamed:name];
    if (!stickerImage) {
        return;
    }
    if (!_activeSticker) {
        _activeSticker = [[HangoDecorStickerView alloc] initWithStickerImage:stickerImage];
        __weak typeof(self) weakSelf = self;
        _activeSticker.onRemove = ^{
            [weakSelf removeActiveSticker];
        };
        [_stickerCanvas addSubview:_activeSticker];
        _didPlaceSticker = NO;
        [self placeStickerIfNeeded];
    } else {
        _activeSticker.image = stickerImage;
        _activeSticker.transform = CGAffineTransformIdentity;
        _activeSticker.center = CGPointMake(CGRectGetMidX(_stickerCanvas.bounds), CGRectGetMidY(_stickerCanvas.bounds));
    }
    _activeStickerDecorIndex = index;
    _selectedIndex = index;
    [self updateDecorSelection];
}

- (void)removeActiveSticker {
    if (_activeStickerDecorIndex != kHangoNotFoundIndex) {
        [[HangoDataStore shared] addDecorationCount:1 forName:_decorNames[_activeStickerDecorIndex]];
    }
    [_activeSticker removeFromSuperview];
    _activeSticker = nil;
    _activeStickerDecorIndex = kHangoNotFoundIndex;
    _selectedIndex = kHangoNotFoundIndex;
    _didPlaceSticker = NO;
    [self updateDecorCountLabels];
    [self updateDecorSelection];
}

- (void)selectDecor:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < 0 || index >= (NSInteger)_decorNames.count) {
        return;
    }
    if (_activeStickerDecorIndex == index) {
        _selectedIndex = index;
        [self updateDecorSelection];
        return;
    }

    NSString *name = _decorNames[index];
    if ([[HangoDataStore shared] decorationCountForName:name] <= 0) {
        self.pendingPurchaseDecorIndex = index;
        [self presentPurchaseForDecorIndex:index];
        return;
    }

    if (_activeStickerDecorIndex != kHangoNotFoundIndex) {
        [[HangoDataStore shared] addDecorationCount:1 forName:_decorNames[_activeStickerDecorIndex]];
    }
    if (![[HangoDataStore shared] consumeDecorationWithName:name]) {
        self.pendingPurchaseDecorIndex = index;
        [self presentPurchaseForDecorIndex:index];
        return;
    }

    [self placeStickerForDecorIndex:index];
    [self updateDecorCountLabels];
}

- (void)presentPurchaseForDecorIndex:(NSInteger)index {
    NSString *name = _decorNames[index];
    self.pendingPurchaseDecorIndex = index;
    HangoPurchaseDecorViewController *vc = [[HangoPurchaseDecorViewController alloc] init];
    vc.decorImageName = name;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    __weak typeof(self) weakSelf = self;
    vc.onCancel = ^{
        weakSelf.pendingPurchaseDecorIndex = kHangoNotFoundIndex;
    };
    vc.onRecharge = ^{
        [weakSelf openWalletPage];
    };
    vc.onPurchase = ^{
        [weakSelf handlePurchaseForDecorIndex:index];
    };
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)presentInsufficientBalanceForDecorIndex:(NSInteger)index {
    HangoNoMoneyViewController *vc = [[HangoNoMoneyViewController alloc] init];
    vc.previewImageName = _decorNames[index];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    __weak typeof(self) weakSelf = self;
    vc.onCancel = ^{
        weakSelf.pendingPurchaseDecorIndex = kHangoNotFoundIndex;
    };
    vc.onRecharge = ^{
        [weakSelf openWalletPage];
    };
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)handlePurchaseForDecorIndex:(NSInteger)index {
    NSString *name = _decorNames[index];

    [[HangoRequestManager shared] requestWithDelay:0.5 inView:self.view showsHUD:YES completion:^{
        BOOL success = [[HangoDataStore shared] purchaseDecorationPackForName:name];
        if (!success) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self presentInsufficientBalanceForDecorIndex:index];
            }];
            return;
        }

        [self dismissViewControllerAnimated:YES completion:^{
            [self updateDecorCountLabels];
            if (self.pendingPurchaseDecorIndex == index) {
                self.pendingPurchaseDecorIndex = kHangoNotFoundIndex;
                [self selectDecorAfterPurchaseAtIndex:index];
            }
        }];
    }];
}

- (void)selectDecorAfterPurchaseAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)_decorNames.count) {
        return;
    }
    NSString *name = _decorNames[index];
    if (_activeStickerDecorIndex != kHangoNotFoundIndex) {
        [[HangoDataStore shared] addDecorationCount:1 forName:_decorNames[_activeStickerDecorIndex]];
    }
    if (![[HangoDataStore shared] consumeDecorationWithName:name]) {
        return;
    }
    [self placeStickerForDecorIndex:index];
    [self updateDecorCountLabels];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [gestureRecognizer isKindOfClass:UIPinchGestureRecognizer.class]
        || [gestureRecognizer isKindOfClass:UIRotationGestureRecognizer.class]
        || [otherGestureRecognizer isKindOfClass:UIPinchGestureRecognizer.class]
        || [otherGestureRecognizer isKindOfClass:UIRotationGestureRecognizer.class];
}

- (void)handleStickerPinch:(UIPinchGestureRecognizer *)gesture {
    if (!_activeSticker) {
        return;
    }
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.stickerGestureStartTransform = _activeSticker.transform;
    }
    if (gesture.state == UIGestureRecognizerStateChanged || gesture.state == UIGestureRecognizerStateEnded) {
        _activeSticker.transform = CGAffineTransformScale(self.stickerGestureStartTransform, gesture.scale, gesture.scale);
    }
}

- (void)handleStickerRotate:(UIRotationGestureRecognizer *)gesture {
    if (!_activeSticker) {
        return;
    }
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.stickerGestureStartTransform = _activeSticker.transform;
    }
    if (gesture.state == UIGestureRecognizerStateChanged || gesture.state == UIGestureRecognizerStateEnded) {
        _activeSticker.transform = CGAffineTransformRotate(self.stickerGestureStartTransform, gesture.rotation);
    }
}

- (UIImage *)composedImage {
    UIImage *baseImage = _selectedImage ?: _preview.image;
    if (!baseImage) {
        return nil;
    }
    CGSize imageSize = baseImage.size;
    if (imageSize.width <= 0 || imageSize.height <= 0) {
        return nil;
    }
    CGSize previewSize = _previewContainer.bounds.size;
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = baseImage.scale;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:imageSize format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        [baseImage drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
        if (self->_activeSticker) {
            [self->_activeSticker drawStickerInContext:rendererContext.CGContext previewSize:previewSize imageSize:imageSize];
        }
    }];
}

- (void)confirmDecorate {
    if (!_selectedImage && !_preview.image) {
        return;
    }

    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:YES completion:^{
        UIImage *finalImage = [self composedImage];
        if (!finalImage) {
            return;
        }
        if (self.party.partyId.length == 0) {
            return;
        }

        [[HangoDataStore shared] savePartyRecordPhotoImage:finalImage partyId:self.party.partyId];
        [MBProgressHUD showSuccessMessage:@"Upload successful"];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
