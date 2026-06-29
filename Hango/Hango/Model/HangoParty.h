#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoParty : NSObject

@property (nonatomic, copy) NSString *partyId;
@property (nonatomic, copy) NSString *hostName;
@property (nonatomic, copy) NSString *hostAvatarName;
@property (nonatomic, copy) NSString *timeText;
@property (nonatomic, copy) NSString *dateText;
@property (nonatomic, copy) NSString *location;
@property (nonatomic, copy) NSString *invitation;
@property (nonatomic, copy) NSString *coverImageName;
@property (nonatomic, copy) NSArray<NSString *> *memberAvatarNames;
@property (nonatomic, assign) NSInteger extraMemberCount;
@property (nonatomic, assign) BOOL isHosted;
@property (nonatomic, assign) BOOL isUpcoming;

@end

NS_ASSUME_NONNULL_END
