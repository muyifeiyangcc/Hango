#import <UIKit/UIKit.h>
@class HangoParty;

NS_ASSUME_NONNULL_BEGIN

@interface HangoPartyCardView : UIView
@property (nonatomic, copy, nullable) void (^onReceive)(void);
- (void)configureWithParty:(HangoParty *)party;
@end

NS_ASSUME_NONNULL_END
