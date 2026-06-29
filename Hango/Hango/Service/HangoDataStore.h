#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HangoUser.h"
#import "HangoParty.h"
#import "HangoAlbumItem.h"
#import "HangoContact.h"
#import "HangoChatMessage.h"
#import "HangoWalletPackage.h"

NS_ASSUME_NONNULL_BEGIN

@interface HangoDataStore : NSObject

@property (nonatomic, strong, readonly) HangoUser *currentUser;
@property (nonatomic, copy, readonly) NSArray<HangoAlbumItem *> *albumItems;
@property (nonatomic, copy, readonly) NSArray<HangoParty *> *upcomingParties;
@property (nonatomic, copy, readonly) NSArray<HangoParty *> *hostedParties;
@property (nonatomic, copy, readonly) NSArray<HangoContact *> *contacts;
@property (nonatomic, copy, readonly) NSArray<HangoContact *> *conversations;
@property (nonatomic, copy, readonly) NSArray<HangoWalletPackage *> *walletPackages;
@property (nonatomic, copy, readonly) NSArray<NSString *> *reportReasons;

+ (instancetype)shared;

- (NSArray<HangoChatMessage *> *)messagesForConversationId:(NSString *)conversationId;
- (NSArray<HangoChatMessage *> *)messagesForPartyId:(NSString *)partyId;
- (HangoParty *)partyWithId:(NSString *)partyId;
- (HangoContact *)contactWithId:(NSString *)contactId;
- (nullable HangoContact *)contactWithNumber:(NSString *)number;
- (NSInteger)addFriendWithNumber:(NSString *)number;
- (void)addDiamonds:(NSInteger)amount;
- (void)spendDiamonds:(NSInteger)amount;
- (void)toggleBlacklistForContactId:(NSString *)contactId;
- (void)blockContactWithId:(NSString *)contactId;
- (NSArray<HangoContact *> *)activeConversations;
- (void)appendMessage:(HangoChatMessage *)message toConversationId:(NSString *)conversationId;
- (void)appendPartyMessage:(HangoChatMessage *)message partyId:(NSString *)partyId;
- (HangoParty *)createPartyWithTime:(NSString *)time date:(NSString *)date location:(NSString *)location invitation:(NSString *)invitation friendIds:(NSArray<NSString *> *)friendIds;
- (void)updateCurrentUserProfileWithName:(NSString *)name avatarImage:(nullable UIImage *)avatarImage;
- (void)clearSavedUserProfile;
- (void)loadSavedUserProfileIfNeeded;
- (BOOL)hasCompletedProfile;

@end

NS_ASSUME_NONNULL_END
