#import "HangoDataStore.h"

@interface HangoDataStore ()
@property (nonatomic, strong, readwrite) HangoUser *currentUser;
@property (nonatomic, copy, readwrite) NSArray<HangoAlbumItem *> *albumItems;
@property (nonatomic, copy, readwrite) NSArray<HangoParty *> *upcomingParties;
@property (nonatomic, copy, readwrite) NSArray<HangoParty *> *hostedParties;
@property (nonatomic, copy, readwrite) NSArray<HangoContact *> *contacts;
@property (nonatomic, copy, readwrite) NSArray<HangoContact *> *conversations;
@property (nonatomic, copy) NSArray<HangoContact *> *directoryContacts;
@property (nonatomic, copy, readwrite) NSArray<HangoWalletPackage *> *walletPackages;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *reportReasons;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<HangoChatMessage *> *> *conversationMessages;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<HangoChatMessage *> *> *partyMessages;
@end

@implementation HangoDataStore

+ (instancetype)shared {
    static HangoDataStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[HangoDataStore alloc] init];
        [store loadInitialData];
    });
    return store;
}

- (void)loadInitialData {
    HangoUser *user = [[HangoUser alloc] init];
    user.userId = @"100005131";
    user.name = @"Amelia";
    user.email = @"amelia@hango.app";
    user.avatarName = @"avatar_1";
    user.diamondBalance = 3700;
    user.hostedPartyCount = 7;
    user.bio = @"Love parties and good vibes";
    self.currentUser = user;
    [self loadSavedUserProfileIfNeeded];

    NSMutableArray *albums = [NSMutableArray array];
    NSArray *albumDates = @[@"Nov 28th 2025", @"Nov 28th 2025", @"Nov 28th 2025"];
    NSArray *albumImages = @[@"home_album_1", @"home_album_2", @"home_album_3"];
    for (NSInteger i = 0; i < albumDates.count; i++) {
        HangoAlbumItem *item = [[HangoAlbumItem alloc] init];
        item.albumId = [NSString stringWithFormat:@"album_%ld", (long)i];
        item.dateText = albumDates[i];
        item.imageName = albumImages[i];
        [albums addObject:item];
    }
    self.albumItems = albums.copy;

    HangoParty *party1 = [self buildPartyWithId:@"party_1"
                                       hostName:@"Amelia"
                                  hostAvatarName:@"avatar_1"
                                        timeText:@"06:00 PM"
                                        dateText:@"Nov 20th 2025"
                                        location:@"Amelia's home"
                                     invitation:@"Join me for my birthday party at my place!"
                                   coverImageName:@"avatar_10"
                               memberAvatarNames:@[@"avatar_2", @"avatar_3", @"avatar_4", @"avatar_5"]
                                extraMemberCount:5
                                        isHosted:NO
                                     isUpcoming:YES];

    HangoParty *party2 = [self buildPartyWithId:@"party_2"
                                       hostName:@"Ellie"
                                  hostAvatarName:@"avatar_6"
                                        timeText:@"07:30 PM"
                                        dateText:@"Nov 22th 2025"
                                        location:@"Downtown Lounge"
                                     invitation:@"Celebrating Ellie's sister's promotion!"
                                   coverImageName:@"avatar_14"
                               memberAvatarNames:@[@"avatar_7", @"avatar_8", @"avatar_9"]
                                extraMemberCount:3
                                        isHosted:NO
                                     isUpcoming:YES];
    self.upcomingParties = @[party1, party2];

    HangoParty *hosted1 = [self buildPartyWithId:@"hosted_1"
                                        hostName:@"Amelia"
                                   hostAvatarName:@"avatar_1"
                                         timeText:@"06:00 PM"
                                         dateText:@"Nov 20th 2025"
                                         location:@"Amelia's home"
                                      invitation:@"Birthday party at my place!"
                                    coverImageName:@"avatar_10"
                                memberAvatarNames:@[@"avatar_2", @"avatar_3", @"avatar_4"]
                                 extraMemberCount:5
                                         isHosted:YES
                                      isUpcoming:YES];
    HangoParty *hosted2 = [self buildPartyWithId:@"hosted_2"
                                        hostName:@"Amelia"
                                   hostAvatarName:@"avatar_1"
                                         timeText:@"08:00 PM"
                                         dateText:@"Oct 15th 2025"
                                         location:@"Rooftop Bar"
                                      invitation:@"Summer rooftop gathering"
                                    coverImageName:@"avatar_15"
                                memberAvatarNames:@[@"avatar_16", @"avatar_17"]
                                 extraMemberCount:2
                                         isHosted:YES
                                      isUpcoming:NO];
    self.hostedParties = @[hosted1, hosted2];

    NSMutableArray *contacts = [NSMutableArray array];
    NSArray *names = @[@"Nikolai Gray", @"Amelia", @"Ellie", @"Sophia", @"Mia"];
    NSArray *numbers = @[@"123456", @"234567", @"345678", @"456789", @"567890"];
    NSArray *avatars = @[@"avatar_18", @"avatar_1", @"avatar_6", @"avatar_19", @"avatar_20"];
    for (NSInteger i = 0; i < names.count; i++) {
        HangoContact *contact = [[HangoContact alloc] init];
        contact.contactId = [NSString stringWithFormat:@"contact_%ld", (long)i];
        contact.name = names[i];
        contact.number = numbers[i];
        contact.avatarName = avatars[i];
        contact.isBlacklisted = NO;
        [contacts addObject:contact];
    }
    self.directoryContacts = contacts.copy;
    self.contacts = [contacts subarrayWithRange:NSMakeRange(0, 3)];
    self.conversations = @[[contacts objectAtIndex:1], [contacts objectAtIndex:0], [contacts objectAtIndex:2]];

    self.walletPackages = @[
        [self packageWithId:@"pkg_1" diamonds:400 price:@"$0.99"],
        [self packageWithId:@"pkg_2" diamonds:800 price:@"$1.99"],
        [self packageWithId:@"pkg_3" diamonds:1780 price:@"$3.99"],
        [self packageWithId:@"pkg_4" diamonds:2450 price:@"$4.99"],
        [self packageWithId:@"pkg_5" diamonds:5150 price:@"$9.99"],
        [self packageWithId:@"pkg_6" diamonds:10800 price:@"$19.99"],
        [self packageWithId:@"pkg_7" diamonds:14900 price:@"$29.99"],
        [self packageWithId:@"pkg_8" diamonds:29400 price:@"$49.99"]
    ];

    self.reportReasons = @[
        @"Harassment or bullying",
        @"Inappropriate content",
        @"Spam or scam",
        @"Other"
    ];

    self.conversationMessages = [NSMutableDictionary dictionary];
    self.partyMessages = [NSMutableDictionary dictionary];

    [self seedMessagesForConversationId:@"contact_1" contact:[self contactWithId:@"contact_1"]];
    [self seedMessagesForPartyId:@"party_1"];
}

- (HangoParty *)buildPartyWithId:(NSString *)partyId
                        hostName:(NSString *)hostName
                   hostAvatarName:(NSString *)hostAvatarName
                         timeText:(NSString *)timeText
                         dateText:(NSString *)dateText
                         location:(NSString *)location
                      invitation:(NSString *)invitation
                    coverImageName:(NSString *)coverImageName
                memberAvatarNames:(NSArray<NSString *> *)memberAvatarNames
                 extraMemberCount:(NSInteger)extraMemberCount
                         isHosted:(BOOL)isHosted
                      isUpcoming:(BOOL)isUpcoming {
    HangoParty *party = [[HangoParty alloc] init];
    party.partyId = partyId;
    party.hostName = hostName;
    party.hostAvatarName = hostAvatarName;
    party.timeText = timeText;
    party.dateText = dateText;
    party.location = location;
    party.invitation = invitation;
    party.coverImageName = coverImageName;
    party.memberAvatarNames = memberAvatarNames;
    party.extraMemberCount = extraMemberCount;
    party.isHosted = isHosted;
    party.isUpcoming = isUpcoming;
    return party;
}

- (HangoWalletPackage *)packageWithId:(NSString *)packageId diamonds:(NSInteger)diamonds price:(NSString *)price {
    HangoWalletPackage *pkg = [[HangoWalletPackage alloc] init];
    pkg.packageId = packageId;
    pkg.diamonds = diamonds;
    pkg.priceText = price;
    return pkg;
}

- (void)seedMessagesForConversationId:(NSString *)conversationId contact:(HangoContact *)contact {
    if (!contact) {
        return;
    }
    NSString *myName = self.currentUser.name.length ? self.currentUser.name : @"Me";
    NSString *myAvatar = self.currentUser.avatarName.length ? self.currentUser.avatarName : @"avatar_18";

    HangoChatMessage *text = [self messageWithId:[NSString stringWithFormat:@"%@_text", conversationId]
                                      senderName:contact.name
                                 senderAvatarName:contact.avatarName
                                         content:@"Is everyone having fun?"
                                        timeText:@"06:33 PM"
                                     messageType:HangoChatMessageTypeText
                                      isOutgoing:NO
                                   audioDuration:0];

    HangoChatMessage *audio = [self messageWithId:[NSString stringWithFormat:@"%@_audio", conversationId]
                                       senderName:myName
                                  senderAvatarName:myAvatar
                                          content:@"12s"
                                         timeText:@"06:33 PM"
                                      messageType:HangoChatMessageTypeAudio
                                       isOutgoing:YES
                                    audioDuration:12];

    HangoChatMessage *image = [self messageWithId:[NSString stringWithFormat:@"%@_image", conversationId]
                                       senderName:contact.name
                                  senderAvatarName:contact.avatarName
                                          content:@"avatar_10"
                                         timeText:@"06:33 PM"
                                      messageType:HangoChatMessageTypeImage
                                       isOutgoing:NO
                                    audioDuration:0];

    self.conversationMessages[conversationId] = [NSMutableArray arrayWithObjects:text, audio, image, nil];
}

- (void)seedMessagesForPartyId:(NSString *)partyId {
    HangoChatMessage *text = [self messageWithId:@"pmsg_1"
                                      senderName:@"Amelia"
                                 senderAvatarName:@"avatar_1"
                                         content:@"Is everyone having fun?"
                                        timeText:@"06:33 PM"
                                     messageType:HangoChatMessageTypeText
                                      isOutgoing:NO
                                   audioDuration:0];

    HangoChatMessage *audio = [self messageWithId:@"pmsg_2"
                                       senderName:@"Amelia"
                                  senderAvatarName:@"avatar_18"
                                          content:@"12s"
                                         timeText:@"06:33 PM"
                                      messageType:HangoChatMessageTypeAudio
                                       isOutgoing:YES
                                    audioDuration:12];

    HangoChatMessage *image = [self messageWithId:@"pmsg_3"
                                       senderName:@"Amelia"
                                  senderAvatarName:@"avatar_1"
                                          content:@"avatar_10"
                                         timeText:@"06:33 PM"
                                      messageType:HangoChatMessageTypeImage
                                       isOutgoing:NO
                                    audioDuration:0];

    self.partyMessages[partyId] = [NSMutableArray arrayWithObjects:text, audio, image, nil];
}

- (HangoChatMessage *)messageWithId:(NSString *)messageId
                         senderName:(NSString *)senderName
                    senderAvatarName:(NSString *)senderAvatarName
                            content:(NSString *)content
                           timeText:(NSString *)timeText
                        messageType:(HangoChatMessageType)messageType
                         isOutgoing:(BOOL)isOutgoing
                      audioDuration:(NSInteger)audioDuration {
    HangoChatMessage *message = [[HangoChatMessage alloc] init];
    message.messageId = messageId;
    message.senderName = senderName;
    message.senderAvatarName = senderAvatarName;
    message.content = content;
    message.timeText = timeText;
    message.messageType = messageType;
    message.isOutgoing = isOutgoing;
    message.audioDuration = audioDuration;
    return message;
}

- (NSArray<HangoChatMessage *> *)messagesForConversationId:(NSString *)conversationId {
    NSMutableArray *messages = self.conversationMessages[conversationId];
    if (messages.count == 0) {
        HangoContact *contact = [self contactWithId:conversationId];
        if (contact) {
            [self seedMessagesForConversationId:conversationId contact:contact];
            messages = self.conversationMessages[conversationId];
        }
    }
    return messages.copy ?: @[];
}

- (NSArray<HangoChatMessage *> *)messagesForPartyId:(NSString *)partyId {
    return [self.partyMessages[partyId] copy] ?: @[];
}

- (HangoParty *)partyWithId:(NSString *)partyId {
    for (HangoParty *party in self.upcomingParties) {
        if ([party.partyId isEqualToString:partyId]) return party;
    }
    for (HangoParty *party in self.hostedParties) {
        if ([party.partyId isEqualToString:partyId]) return party;
    }
    return nil;
}

- (HangoContact *)contactWithId:(NSString *)contactId {
    for (HangoContact *contact in self.contacts) {
        if ([contact.contactId isEqualToString:contactId]) return contact;
    }
    for (HangoContact *contact in self.directoryContacts) {
        if ([contact.contactId isEqualToString:contactId]) return contact;
    }
    return nil;
}

- (HangoContact *)contactWithNumber:(NSString *)number {
    NSString *trimmed = [number stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0) {
        return nil;
    }
    for (HangoContact *contact in self.directoryContacts) {
        if ([contact.number isEqualToString:trimmed]) {
            return contact;
        }
    }
    return nil;
}

- (NSInteger)addFriendWithNumber:(NSString *)number {
    HangoContact *contact = [self contactWithNumber:number];
    if (!contact) {
        return 0;
    }
    for (HangoContact *existing in self.contacts) {
        if ([existing.number isEqualToString:contact.number]) {
            return 2;
        }
    }
    self.contacts = [self.contacts arrayByAddingObject:contact];
    return 1;
}

- (void)addDiamonds:(NSInteger)amount {
    self.currentUser.diamondBalance += amount;
}

- (void)spendDiamonds:(NSInteger)amount {
    self.currentUser.diamondBalance = MAX(0, self.currentUser.diamondBalance - amount);
}

- (void)toggleBlacklistForContactId:(NSString *)contactId {
    HangoContact *contact = [self contactWithId:contactId];
    contact.isBlacklisted = !contact.isBlacklisted;
}

- (void)blockContactWithId:(NSString *)contactId {
    HangoContact *contact = [self contactWithId:contactId];
    if (!contact) {
        return;
    }
    contact.isBlacklisted = YES;
    NSMutableArray<HangoContact *> *updated = [NSMutableArray array];
    for (HangoContact *conversation in self.conversations) {
        if (![conversation.contactId isEqualToString:contactId]) {
            [updated addObject:conversation];
        }
    }
    self.conversations = updated.copy;
}

- (NSArray<HangoContact *> *)activeConversations {
    NSMutableArray<HangoContact *> *result = [NSMutableArray array];
    for (HangoContact *contact in self.conversations) {
        if (!contact.isBlacklisted) {
            [result addObject:contact];
        }
    }
    return result.copy;
}

- (void)appendMessage:(HangoChatMessage *)message toConversationId:(NSString *)conversationId {
    if (!self.conversationMessages[conversationId]) {
        self.conversationMessages[conversationId] = [NSMutableArray array];
    }
    [self.conversationMessages[conversationId] addObject:message];
}

- (void)appendPartyMessage:(HangoChatMessage *)message partyId:(NSString *)partyId {
    if (!self.partyMessages[partyId]) {
        self.partyMessages[partyId] = [NSMutableArray array];
    }
    [self.partyMessages[partyId] addObject:message];
}

- (HangoParty *)createPartyWithTime:(NSString *)time date:(NSString *)date location:(NSString *)location invitation:(NSString *)invitation friendIds:(NSArray<NSString *> *)friendIds {
    NSMutableArray *avatars = [NSMutableArray array];
    for (NSString *contactId in friendIds) {
        HangoContact *contact = [self contactWithId:contactId];
        if (contact.avatarName.length) {
            [avatars addObject:contact.avatarName];
        }
    }
    HangoParty *party = [self buildPartyWithId:[NSString stringWithFormat:@"party_%@", @((NSInteger)[[NSDate date] timeIntervalSince1970])]
                                      hostName:self.currentUser.name
                                 hostAvatarName:self.currentUser.avatarName
                                       timeText:time
                                       dateText:date
                                       location:location
                                    invitation:invitation
                                  coverImageName:@"avatar_10"
                              memberAvatarNames:avatars.copy
                               extraMemberCount:0
                                       isHosted:YES
                                    isUpcoming:YES];
    self.hostedParties = [@[party] arrayByAddingObjectsFromArray:self.hostedParties];
    self.currentUser.hostedPartyCount += 1;
    return party;
}

static NSString * const kHangoSavedUserNameKey = @"HangoSavedUserName";
static NSString * const kHangoSavedUserEmailKey = @"HangoSavedUserEmail";
static NSString * const kHangoSavedUserAvatarNameKey = @"HangoSavedUserAvatarName";
static NSString * const kHangoSavedUserAvatarLocalPathKey = @"HangoSavedUserAvatarLocalPath";

- (NSString *)avatarDirectoryPath {
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [documents stringByAppendingPathComponent:@"HangoAvatars"];
}

- (NSString *)saveAvatarImage:(UIImage *)image {
    NSData *data = UIImageJPEGRepresentation(image, 0.85);
    if (!data) {
        return nil;
    }
    NSString *directory = [self avatarDirectoryPath];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *fileName = [NSString stringWithFormat:@"avatar_%@.jpg", NSUUID.UUID.UUIDString];
    NSString *path = [directory stringByAppendingPathComponent:fileName];
    if (![data writeToFile:path atomically:YES]) {
        return nil;
    }
    return path;
}

- (void)loadSavedUserProfileIfNeeded {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *name = [defaults stringForKey:kHangoSavedUserNameKey];
    if (name.length == 0) {
        return;
    }
    self.currentUser.name = name;
    NSString *email = [defaults stringForKey:kHangoSavedUserEmailKey];
    if (email.length > 0) {
        self.currentUser.email = email;
    }
    NSString *avatarName = [defaults stringForKey:kHangoSavedUserAvatarNameKey];
    if (avatarName.length > 0) {
        self.currentUser.avatarName = avatarName;
    }
    NSString *localPath = [defaults stringForKey:kHangoSavedUserAvatarLocalPathKey];
    if (localPath.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:localPath]) {
        self.currentUser.avatarLocalPath = localPath;
    }
}

- (void)clearSavedUserProfile {
    if (self.currentUser.avatarLocalPath.length > 0) {
        [NSFileManager.defaultManager removeItemAtPath:self.currentUser.avatarLocalPath error:nil];
    }
    self.currentUser.name = @"";
    self.currentUser.avatarName = @"";
    self.currentUser.avatarLocalPath = nil;

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:kHangoSavedUserNameKey];
    [defaults removeObjectForKey:kHangoSavedUserAvatarNameKey];
    [defaults removeObjectForKey:kHangoSavedUserAvatarLocalPathKey];
    [defaults synchronize];
}

- (BOOL)hasCompletedProfile {
    NSString *trimmedName = [self.currentUser.name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedName.length == 0) {
        return NO;
    }
    if (self.currentUser.avatarLocalPath.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:self.currentUser.avatarLocalPath]) {
        return YES;
    }
    return self.currentUser.avatarName.length > 0;
}

- (void)updateCurrentUserProfileWithName:(NSString *)name avatarImage:(UIImage *)avatarImage {
    NSString *trimmedName = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedName.length > 0) {
        self.currentUser.name = trimmedName;
    }
    if (avatarImage) {
        if (self.currentUser.avatarLocalPath.length > 0) {
            [NSFileManager.defaultManager removeItemAtPath:self.currentUser.avatarLocalPath error:nil];
        }
        NSString *savedPath = [self saveAvatarImage:avatarImage];
        if (savedPath.length > 0) {
            self.currentUser.avatarLocalPath = savedPath;
            self.currentUser.avatarName = @"";
        }
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:self.currentUser.name forKey:kHangoSavedUserNameKey];
    [defaults setObject:self.currentUser.email ?: @"" forKey:kHangoSavedUserEmailKey];
    [defaults setObject:self.currentUser.avatarName ?: @"" forKey:kHangoSavedUserAvatarNameKey];
    [defaults setObject:self.currentUser.avatarLocalPath ?: @"" forKey:kHangoSavedUserAvatarLocalPathKey];
    [defaults synchronize];
}

@end
