#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HangoContact : NSObject

@property (nonatomic, copy) NSString *contactId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *number;
@property (nonatomic, copy) NSString *avatarName;
@property (nonatomic, assign) BOOL isBlacklisted;

@end

NS_ASSUME_NONNULL_END
