#import "HangoBaseViewController.h"

@class HangoContact;

NS_ASSUME_NONNULL_BEGIN

@interface HangoInvitePartyContactsViewController : HangoBaseViewController

@property (nonatomic, copy) NSArray<NSString *> *selectedContactIds;
@property (nonatomic, copy, nullable) void (^onComplete)(NSArray<HangoContact *> *selectedContacts);

@end

NS_ASSUME_NONNULL_END
