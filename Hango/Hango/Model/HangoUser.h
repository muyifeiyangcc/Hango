#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoUser : NSObject

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *avatarName;
@property (nonatomic, copy, nullable) NSString *avatarLocalPath;
@property (nonatomic, assign) NSInteger diamondBalance;
@property (nonatomic, assign) NSInteger hostedPartyCount;
@property (nonatomic, copy) NSString *bio;

@end

NS_ASSUME_NONNULL_END
