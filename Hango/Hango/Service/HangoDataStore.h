#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HangoPersona.h"
#import "HangoParty.h"
#import "HangoAlbumItem.h"
#import "HangoContact.h"
#import "HangoDialogueItem.h"
#import "HangovaluePackage.h"
#import "HangoDialogueThread.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const HangoDeniedContactsDidChangeNotification;
FOUNDATION_EXPORT NSNotificationName const HangoDialogueDataDidChangeNotification;
FOUNDATION_EXPORT NSNotificationName const HangoContactsDataDidChangeNotification;

@interface HangoDataStore : NSObject

@property (nonatomic, strong, readonly) HangoPersona *currentPersona;
@property (nonatomic, copy, readonly) NSArray<HangoAlbumItem *> *albumItems;
@property (nonatomic, copy, readonly) NSArray<HangoParty *> *upcomingParties;
@property (nonatomic, copy, readonly) NSArray<HangoParty *> *hostedParties;
@property (nonatomic, copy, readonly) NSArray<HangoParty *> *attendedParties;
@property (nonatomic, copy, readonly) NSArray<HangoContact *> *contacts;
@property (nonatomic, copy, readonly) NSArray<HangoContact *> *conversations;
@property (nonatomic, copy, readonly) NSArray<HangovaluePackage *> *valuePackages;
@property (nonatomic, copy, readonly) NSArray<NSString *> *reportReasons;

+ (instancetype)shared;

- (void)reloadDialogueDataForCurrentAccount;
- (void)unloadDialogueDataForGuestSession;
- (void)deletePersistedDialogueDataForCurrentAccount;

- (NSArray<HangoDialogueItem *> *)dialogueItemsForConversationId:(NSString *)conversationId;
- (NSArray<HangoDialogueItem *> *)dialogueItemsForPartyId:(NSString *)partyId;
- (HangoParty *)partyWithId:(NSString *)partyId;
- (BOOL)isPartyAccepted:(NSString *)partyId;
- (BOOL)setPartyAccepted:(BOOL)accepted forPartyId:(NSString *)partyId;
- (HangoContact *)contactWithId:(NSString *)contactId;
- (nullable HangoContact *)contactWithNumber:(NSString *)number;
- (NSArray<HangoContact *> *)contactsForParty:(HangoParty *)party;
- (NSInteger)addContactWithNumber:(NSString *)number;
- (BOOL)trackContact:(HangoContact *)contact;
- (BOOL)untrackContact:(HangoContact *)contact;
- (BOOL)isContactInList:(HangoContact *)contact;
- (BOOL)isCurrentPersonaContact:(HangoContact *)contact;
- (void)addSparkles:(NSInteger)amount;
- (void)spendSparkles:(NSInteger)amount;
- (void)addContactToDenyList:(NSString *)contactId;
- (void)removeContactFromDenyList:(NSString *)contactId;
- (NSArray<HangoContact *> *)deniedContacts;
- (void)blockContactWithId:(NSString *)contactId;
- (BOOL)isDeniedPersonWithName:(nullable NSString *)name avatarName:(nullable NSString *)avatarName;
- (BOOL)isPartyHostDenied:(HangoParty *)party;
- (NSArray<HangoContact *> *)visibleContacts;
- (NSArray<HangoParty *> *)visibleUpcomingParties;
- (NSArray<HangoParty *> *)visibleAttendedParties;
- (NSArray<HangoAlbumItem *> *)visibleAlbumItems;
- (NSArray<NSString *> *)visibleMemberAvatarNamesForParty:(HangoParty *)party;
- (NSArray<HangoContact *> *)activeConversations;
- (NSArray<HangoDialogueThread *> *)activeDialogueThreads;
- (nullable HangoDialogueItem *)lastDialogueForConversationId:(NSString *)conversationId;
- (nullable HangoDialogueItem *)lastDialogueForPartyId:(NSString *)partyId;
- (NSString *)previewTextForDialogueItem:(HangoDialogueItem *)item;
- (void)appendDialogueItem:(HangoDialogueItem *)item toConversationId:(NSString *)conversationId;
- (void)appendPartyDialogueItem:(HangoDialogueItem *)item partyId:(NSString *)partyId;
- (HangoParty *)createPartyWithTime:(NSString *)time date:(NSString *)date location:(NSString *)location invitation:(NSString *)invitation inviteeIds:(NSArray<NSString *> *)inviteeIds;
- (BOOL)deleteHostedPartyWithId:(NSString *)partyId;
- (void)updateCurrentPersonaProfileWithName:(NSString *)name avatarImage:(nullable UIImage *)avatarImage;
- (void)updateCurrentPersonaProfileWithName:(nullable NSString *)name
                                 avatarName:(nullable NSString *)avatarName
                                  avatarImage:(nullable UIImage *)avatarImage
                                          bio:(nullable NSString *)bio;
- (void)persistCurrentPersonaProfile;
- (void)assignPersonaIdForNewAccount;
- (void)clearSavedPersonaProfile;
- (void)loadSavedPersonaProfileIfNeeded;
- (BOOL)hasCompletedProfile;
- (BOOL)hasPersistedPersonaProfile;
- (void)applySeedProfileForTestAccountWithEmail:(NSString *)email;

- (nullable NSString *)appleCredentialIdentifier;
- (nullable NSString *)appleCachedDisplayName;
- (nullable NSString *)appleCachedDisplayNameForCredentialIdentifier:(NSString *)personaIdentifier;
- (nullable NSString *)appleCachedEmail;
- (void)saveAppleSignInWithCredentialIdentifier:(NSString *)personaIdentifier
                                    email:(nullable NSString *)email
                              displayName:(nullable NSString *)displayName;
- (void)clearAppleSignInCredentials;

- (NSArray<NSString *> *)partyRecordPhotoPathsForPartyId:(NSString *)partyId;
- (NSInteger)builtinPartyRecordPhotoCountForPartyId:(NSString *)partyId;
- (nullable UIImage *)latestPartyRecordPhotoImageForPartyId:(NSString *)partyId;
- (NSArray<UIImage *> *)partyRecordPhotoImagesForPartyId:(NSString *)partyId;
- (NSString *)savePartyRecordPhotoImage:(UIImage *)image partyId:(NSString *)partyId;
- (NSString *)saveConversationDialogueImage:(UIImage *)image conversationId:(NSString *)conversationId;
- (BOOL)removePartyRecordPhotoAtIndex:(NSInteger)index partyId:(NSString *)partyId;
- (BOOL)removePartyRecordPhotoAtDisplayIndex:(NSInteger)displayIndex partyId:(NSString *)partyId;
- (BOOL)isCurrentUserPartyRecordPhotoAtDisplayIndex:(NSInteger)displayIndex partyId:(NSString *)partyId;

- (NSInteger)decorationCountForName:(NSString *)name;
- (void)addDecorationCount:(NSInteger)amount forName:(NSString *)name;
- (BOOL)consumeDecorationWithName:(NSString *)name;
- (BOOL)purchaseDecorationPackForName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
