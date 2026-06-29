#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoWalletPackage : NSObject

@property (nonatomic, copy) NSString *packageId;
@property (nonatomic, assign) NSInteger diamonds;
@property (nonatomic, copy) NSString *priceText;

@end

NS_ASSUME_NONNULL_END
