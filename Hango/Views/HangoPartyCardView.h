#import <UIKit/UIKit.h>
@class HangoParty;

NS_ASSUME_NONNULL_BEGIN

@interface HangoPartyCardView : UIView
- (void)configureWithParty:(HangoParty *)party;
- (void)configureWithParty:(HangoParty *)party showsAcceptButton:(BOOL)showsAcceptButton;
@end

NS_ASSUME_NONNULL_END
