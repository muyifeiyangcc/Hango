#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoDecorStickerView : UIImageView

@property (nonatomic, copy, nullable) void (^onRemove)(void);

- (instancetype)initWithStickerImage:(UIImage *)image;

- (void)drawStickerInContext:(CGContextRef)context
                previewSize:(CGSize)previewSize
                   imageSize:(CGSize)imageSize;

@end

NS_ASSUME_NONNULL_END
