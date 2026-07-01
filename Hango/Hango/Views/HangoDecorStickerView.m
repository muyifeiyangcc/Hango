#import "HangoDecorStickerView.h"
#import "Masonry.h"

@interface HangoDecorStickerView ()
@property (nonatomic, assign) CGPoint panStartCenter;
@property (nonatomic, strong) UIButton *removeButton;
@end

@implementation HangoDecorStickerView

- (instancetype)initWithStickerImage:(UIImage *)image {
    self = [super initWithImage:image];
    if (self) {
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.bounds = CGRectMake(0, 0, 96, 96);

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];

        _removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_removeButton setTitle:@"×" forState:UIControlStateNormal];
        [_removeButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        _removeButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        _removeButton.backgroundColor = UIColor.clearColor;
        [_removeButton addTarget:self action:@selector(removeTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_removeButton];

        [_removeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(-4);
            make.right.equalTo(self).offset(4);
            make.width.height.mas_equalTo(24);
        }];
    }
    return self;
}

- (void)removeTapped {
    if (self.onRemove) {
        self.onRemove();
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
  if (gesture.state == UIGestureRecognizerStateBegan) {
        self.panStartCenter = self.center;
    }
    if (gesture.state == UIGestureRecognizerStateChanged || gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint translation = [gesture translationInView:self.superview];
        self.center = CGPointMake(self.panStartCenter.x + translation.x, self.panStartCenter.y + translation.y);
    }
}

+ (CGRect)visibleImageRectForImageSize:(CGSize)imageSize previewSize:(CGSize)previewSize {
    if (imageSize.width <= 0 || imageSize.height <= 0 || previewSize.width <= 0 || previewSize.height <= 0) {
        return CGRectZero;
    }
    CGFloat imageAspect = imageSize.width / imageSize.height;
    CGFloat previewAspect = previewSize.width / previewSize.height;
    if (imageAspect > previewAspect) {
        CGFloat displayWidth = previewSize.height * imageAspect;
        CGFloat offsetX = (previewSize.width - displayWidth) * 0.5;
        return CGRectMake(offsetX, 0, displayWidth, previewSize.height);
    }
    CGFloat displayHeight = previewSize.width / imageAspect;
    CGFloat offsetY = (previewSize.height - displayHeight) * 0.5;
    return CGRectMake(0, offsetY, previewSize.width, displayHeight);
}

- (void)drawStickerInContext:(CGContextRef)context previewSize:(CGSize)previewSize imageSize:(CGSize)imageSize {
    if (!context || !self.image || previewSize.width <= 0 || previewSize.height <= 0) {
        return;
    }

    CGRect visibleRect = [HangoDecorStickerView visibleImageRectForImageSize:imageSize previewSize:previewSize];
    if (CGRectIsEmpty(visibleRect)) {
        return;
    }

    CGFloat scaleX = imageSize.width / CGRectGetWidth(visibleRect);
    CGFloat scaleY = imageSize.height / CGRectGetHeight(visibleRect);
    CGPoint center = CGPointMake(self.center.x - CGRectGetMinX(visibleRect), self.center.y - CGRectGetMinY(visibleRect));
    center = CGPointMake(center.x * scaleX, center.y * scaleY);

    CGSize drawSize = CGSizeMake(self.bounds.size.width * scaleX, self.bounds.size.height * scaleY);
    CGFloat transformScale = sqrt(self.transform.a * self.transform.a + self.transform.c * self.transform.c);
    drawSize = CGSizeMake(drawSize.width * transformScale, drawSize.height * transformScale);
    CGFloat angle = atan2(self.transform.b, self.transform.a);

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, center.x, center.y);
    CGContextRotateCTM(context, angle);
    [self.image drawInRect:CGRectMake(-drawSize.width * 0.5, -drawSize.height * 0.5, drawSize.width, drawSize.height)];
    CGContextRestoreGState(context);
}

@end
