#import "HangoDisplayString.h"
#import "HangoDataStore.h"
#import "HangoTheme.h"
#import "HangoAccountStore.h"

static NSString * const kHangoSavedPersonaNameKey = @"HangoSavedPersonaName";
static NSString * const kHangoSavedPersonaEmailKey = @"HangoSavedPersonaEmail";
static NSString * const kHangoSavedPersonaBioKey = @"HangoSavedPersonaBio";
static NSString * const kHangoSavedPersonaAvatarNameKey = @"HangoSavedPersonaAvatarName";
static NSString * const kHangoSavedPersonaAvatarLocalPathKey = @"HangoSavedPersonaAvatarLocalPath";
static NSString * const kHangoSavedSparkleBalanceKey = @"HangoSavedSparkleBalance";
static NSString * const kHangoSparkleIAPResetKey = @"HangoSparkleIAPReset_v1";
static NSString * const kHangoSavedHostedPartyCountKey = @"HangoSavedHostedPartyCount";
static NSString * const kHangoSavedPersonaIdKey = @"HangoSavedPersonaId";
static NSString * const kHangoNextPersonaIdKey = @"HangoNextPersonaId";
static NSString * const kHangoDeniedContactIdsKey = @"HangoDeniedContactIds";
static NSString * const kHangoSavedContactsKey = @"HangoSavedContacts";
static NSString * const kHangoDefaultContactsSeededKey = @"HangoDefaultContactsSeeded_v1";
static NSString * const kHangoSavedHostedPartiesKey = @"HangoSavedHostedParties";
static NSString * const kHangoSeedPartySchedulesKey = @"HangoSeedPartySchedules";
static NSString * const kHangoIsLoggedInKey = @"HangoIsLoggedIn";
static NSString * const kHangoConversationDialogueKey = @"HangoConversationDialogue";
static NSString * const kHangoConversationContactIdsKey = @"HangoConversationContactIds";
static NSString * const kHangoPartyDialogueKey = @"HangoPartyDialogue";
static NSString * const kHangoPartyConversationIdsKey = @"HangoPartyConversationIds";
static NSString * const kHangoDialogueThreadOrderKey = @"HangoDialogueThreadOrder";
static NSString * const kHangoDialogueLegacyMigratedPrefix = @"HangoDialogueLegacyMigrated.";
static NSString * const kHangoContactsLegacyMigratedPrefix = @"HangoContactsLegacyMigrated.";
static NSString * const kHangoPartyRecordPhotosKey = @"HangoPartyRecordPhotos";
static NSString * const kHangoPartyPhotosFolderName = @"HangoPartyPhotos";
static NSString * const kHangoDialogueImagesFolderName = @"HangoDialogueImages";
static NSString * const kHangoDecorationCountsKey = @"HangoDecorationCounts";
static NSString * const kHangoAcceptedPartyIdsKey = @"HangoAcceptedPartyIds";
static NSString * const kHangoAttendedPartyPhotosSeedKey = @"HangoAttendedPartyPhotosSeed_v2";
static NSString * const kHangoAttendedPartyPhotoMergeMigrationKey = @"HangoAttendedPartyPhotoMerge_v3";
static NSString * const kHangoAppleCredentialIdentifierKey = @"HangoAppleCredentialIdentifier";
static NSString * const kHangoAppleDisplayNameKey = @"HangoAppleDisplayName";
static NSString * const kHangoAppleEmailKey = @"HangoAppleEmail";
static NSString * const kHangoHiddenBuiltinPartyPhotosKey = @"HangoHiddenBuiltinPartyPhotos";
static const NSInteger kHangoBasePersonaId = 100005131;
static const NSInteger kHangoDecorationPurchasePackSize = 50;
static const NSInteger kHangoDecorationPurchaseSparkleCost = 50;

NSNotificationName const HangoDeniedContactsDidChangeNotification = @"HangoDeniedContactsDidChangeNotification";
NSNotificationName const HangoDialogueDataDidChangeNotification = @"HangoDialogueDataDidChangeNotification";
NSNotificationName const HangoContactsDataDidChangeNotification = @"HangoContactsDataDidChangeNotification";

@interface HangoDataStore ()
@property (nonatomic, strong, readwrite) HangoPersona *currentPersona;
@property (nonatomic, copy, readwrite) NSArray<HangoAlbumItem *> *albumItems;
@property (nonatomic, copy, readwrite) NSArray<HangoParty *> *upcomingParties;
@property (nonatomic, copy, readwrite) NSArray<HangoParty *> *hostedParties;
@property (nonatomic, copy, readwrite) NSArray<HangoParty *> *attendedParties;
@property (nonatomic, copy, readwrite) NSArray<HangoContact *> *contacts;
@property (nonatomic, copy, readwrite) NSArray<HangoContact *> *conversations;
@property (nonatomic, copy) NSArray<HangoContact *> *directoryContacts;
@property (nonatomic, copy, readwrite) NSArray<HangovaluePackage *> *valuePackages;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *reportReasons;
@property (nonatomic, strong) NSMutableArray<NSString *> *conversationContactIds;
@property (nonatomic, strong) NSMutableArray<NSString *> *partyConversationPartyIds;
@property (nonatomic, strong) NSMutableArray<NSString *> *dialogueThreadOrder;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<HangoDialogueItem *> *> *conversationDialogueItems;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<HangoDialogueItem *> *> *partyDialogueItems;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *partyRecordPhotoPaths;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *hiddenBuiltinPartyPhotoIndexes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *decorationCounts;
@property (nonatomic, strong) NSMutableSet<NSString *> *deniedContactIds;
@property (nonatomic, strong) NSMutableSet<NSString *> *acceptedPartyIds;
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
    self.attendedParties = @[];
    HangoPersona *persona = [[HangoPersona alloc] init];
    persona.personaId = @(kHangoBasePersonaId).stringValue;
    persona.name = @"Amelia";
    persona.email = @"amelia@hango.app";
    persona.avatarName = @"";
    persona.sparkleBalance = 0;
    persona.hostedPartyCount = 0;
    persona.bio = @"Love parties and good vibes";
    self.currentPersona = persona;
    [self loadSavedPersonaProfileIfNeeded];
    [self loadSavedPersonaStatsIfNeeded];
    [self loadSavedPersonaIdIfNeeded];

    HangoParty *party1 = [self buildPartyWithId:@"party_1"
                                       hostName:@"Sophia"
                                  hostAvatarName:@"Sophia"
                                        timeText:@""
                                        dateText:@""
                                        location:@"Sophia's home"
                                     invitation:@"Join me for my birthday party at my place!"
                                   coverImageName:@"home_album_1"
                               memberAvatarNames:@[@"Palmer", @"Norris", @"Dillon", @"Lillie"]
                                extraMemberCount:5
                                        isHosted:NO
                                     isUpcoming:YES];

    HangoParty *party2 = [self buildPartyWithId:@"party_2"
                                       hostName:@"Lillie"
                                  hostAvatarName:@"Lillie"
                                        timeText:@""
                                        dateText:@""
                                        location:@"Downtown Lounge"
                                     invitation:@"Celebrating Lillie's sister's promotion!"
                                   coverImageName:@"home_album_2"
                               memberAvatarNames:@[@"Sophia", @"Faith", @"Palmer"]
                                extraMemberCount:3
                                        isHosted:NO
                                     isUpcoming:YES];

    HangoParty *party3 = [self buildPartyWithId:@"party_3"
                                       hostName:@"Norris"
                                  hostAvatarName:@"Norris"
                                        timeText:@""
                                        dateText:@""
                                        location:@"Riverside Park"
                                     invitation:@"Weekend BBQ — bring your appetite!"
                                   coverImageName:@"home_album_3"
                               memberAvatarNames:@[@"Dillon", @"Faith", @"Sophia"]
                                extraMemberCount:2
                                        isHosted:NO
                                     isUpcoming:YES];
    self.upcomingParties = @[party1, party2, party3];
    [self loadSavedOrInitializeSeedPartySchedules];
    self.hostedParties = @[];

    HangoParty *attended1 = [self buildPartyWithId:@"attended_1"
                                          hostName:@"Norris"
                                     hostAvatarName:@"Norris"
                                           timeText:@"07:30 PM"
                                           dateText:@"Jul 4th 2026"
                                           location:@"Central Street BBQ Restaurant"
                                        invitation:@"Hey guys! Let's grab BBQ this Friday night. Free drinks prepared, come hang out with me!"
                                      coverImageName:@"party_record_1_1"
                                  memberAvatarNames:@[@"Palmer", @"Dillon", @"Lillie", @"Sophia"]
                                   extraMemberCount:5
                                           isHosted:NO
                                        isUpcoming:NO];

    HangoParty *attended2 = [self buildPartyWithId:@"attended_2"
                                          hostName:@"Faith"
                                     hostAvatarName:@"Faith"
                                           timeText:@"08:00 PM"
                                           dateText:@"Jul 12th 2026"
                                           location:@"Riverside Cycling Park Entrance"
                                        invitation:@"Weekend riding plan! We'll cycle along the river then have picnic together. Bring your bike and sunscreen!"
                                      coverImageName:@"party_record_2_1"
                                  memberAvatarNames:@[@"Norris", @"Dillon", @"Palmer", @"Sophia"]
                                   extraMemberCount:5
                                           isHosted:NO
                                        isUpcoming:NO];

    HangoParty *attended3 = [self buildPartyWithId:@"attended_3"
                                          hostName:@"Lillie"
                                     hostAvatarName:@"Lillie"
                                           timeText:@"09:00 PM"
                                           dateText:@"Jul 8th 2026"
                                           location:@"My home cinema room"
                                        invitation:@"Movie marathon night! New horror & comedy films ready, popcorn and cola all set. Come chill after work!"
                                      coverImageName:@"party_record_3_1"
                                  memberAvatarNames:@[@"Palmer", @"Norris", @"Faith", @"Sophia"]
                                   extraMemberCount:5
                                           isHosted:NO
                                        isUpcoming:NO];

    HangoParty *attended4 = [self buildPartyWithId:@"attended_4"
                                          hostName:@"Sophia"
                                     hostAvatarName:@"Sophia"
                                           timeText:@"06:30 PM"
                                           dateText:@"Jul 15th 2026"
                                           location:@"West Coast Beach"
                                        invitation:@"Watch sunset by the sea together! I bring wine and snacks, let's relax and take nice photos."
                                      coverImageName:@"party_record_4_1"
                                  memberAvatarNames:@[@"Palmer", @"Norris", @"Dillon", @"Faith"]
                                   extraMemberCount:5
                                           isHosted:NO
                                        isUpcoming:NO];
    self.attendedParties = @[attended1, attended2, attended3, attended4];

    NSMutableArray<HangoAlbumItem *> *albums = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)self.attendedParties.count; i++) {
        HangoParty *party = self.attendedParties[i];
        HangoAlbumItem *item = [[HangoAlbumItem alloc] init];
        item.albumId = [NSString stringWithFormat:@"album_%ld", (long)i];
        item.partyId = party.partyId;
        item.dateText = party.dateText;
        item.imageName = party.coverImageName;
        [albums addObject:item];
    }
    self.albumItems = albums.copy;

    NSMutableArray *contacts = [NSMutableArray array];
    NSArray *names = @[@"Palmer", @"Norris", @"Dillon", @"Lillie", @"Sophia", @"Faith"];
    NSArray *avatars = @[@"Palmer", @"Norris", @"Dillon", @"Lillie", @"Sophia", @"Faith"];
    for (NSInteger i = 0; i < names.count; i++) {
        HangoContact *contact = [[HangoContact alloc] init];
        contact.contactId = [NSString stringWithFormat:@"contact_%ld", (long)i];
        contact.name = names[i];
        contact.number = @(kHangoBasePersonaId + i).stringValue;
        contact.avatarName = avatars[i];
        contact.isDenied = NO;
        [contacts addObject:contact];
    }
    self.directoryContacts = contacts.copy;
    self.contacts = @[];
    self.conversations = @[];
    self.conversationContactIds = [NSMutableArray array];
    self.partyConversationPartyIds = [NSMutableArray array];
    self.dialogueThreadOrder = [NSMutableArray array];
    self.deniedContactIds = [NSMutableSet set];
    [self loadAcceptedPartyIds];
    [self loadSavedHostedParties];
    [self rebuildUpcomingPartiesList];

    self.valuePackages = @[
        [self packageWithProductId:@"kuwifjdkwdvyeuex" sparkles:400 price:@"$0.99"],
        [self packageWithProductId:@"mekmbbtkjjxsvgyw" sparkles:800 price:@"$1.99"],
        [self packageWithProductId:@"hnqwpvmxzktrflcd" sparkles:1780 price:@"$3.99"],
        [self packageWithProductId:@"idaxswttnfhdisim" sparkles:2450 price:@"$4.99"],
        [self packageWithProductId:@"nwoglcwfvxqnygtk" sparkles:5150 price:@"$9.99"],
        [self packageWithProductId:@"prprpvxjuvecvsiq" sparkles:10800 price:@"$19.99"],
        [self packageWithProductId:@"qnrcuelbtiuflyky" sparkles:14900 price:@"$29.99"],
        [self packageWithProductId:@"gpsgwupyifxtvavf" sparkles:29400 price:@"$49.99"],
        [self packageWithProductId:@"ymohxnvpkqxutvab" sparkles:34500 price:@"$69.99"],
        [self packageWithProductId:@"keecuncsynldehal" sparkles:63700 price:@"$99.99"],
    ];

    self.reportReasons = @[
        @"Harassment or bullying",
        @"Inappropriate content",
        @"Spam or scam",
        @"Other"
    ];

    self.conversationDialogueItems = [NSMutableDictionary dictionary];
    self.partyDialogueItems = [NSMutableDictionary dictionary];
    [self clearInMemoryDialogueData];
    if ([NSUserDefaults.standardUserDefaults boolForKey:kHangoIsLoggedInKey]) {
        [self reloadDialogueDataForCurrentAccount];
    }
    [self loadPartyRecordPhotos];
    [self loadHiddenBuiltinPartyPhotos];
    [self seedAttendedPartyRecordPhotosIfNeeded];
    [self loadDecorationCounts];
    [self syncHostedPartyCount];
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
    if ([HangoTheme isRealPersonAvatarName:hostName]) {
        party.hostAvatarName = hostName;
    } else {
        party.hostAvatarName = hostAvatarName;
    }
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

- (NSDictionary *)dictionaryFromParty:(HangoParty *)party {
    return @{
        @"partyId": party.partyId ?: @"",
        @"hostName": party.hostName ?: @"",
        @"hostAvatarName": party.hostAvatarName ?: @"",
        @"timeText": party.timeText ?: @"",
        @"dateText": party.dateText ?: @"",
        @"location": party.location ?: @"",
        @"invitation": party.invitation ?: @"",
        @"coverImageName": party.coverImageName ?: @"",
        @"memberAvatarNames": party.memberAvatarNames ?: @[],
        @"extraMemberCount": @(party.extraMemberCount),
        @"isHosted": @(party.isHosted),
        @"isUpcoming": @(party.isUpcoming),
    };
}

- (HangoParty *)partyFromDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSString *partyId = dict[@"partyId"];
    if (partyId.length == 0) {
        return nil;
    }

    NSArray *memberAvatarNames = dict[@"memberAvatarNames"];
    if (![memberAvatarNames isKindOfClass:NSArray.class]) {
        memberAvatarNames = @[];
    }

    return [self buildPartyWithId:partyId
                         hostName:dict[@"hostName"] ?: @""
                    hostAvatarName:dict[@"hostAvatarName"] ?: @""
                          timeText:dict[@"timeText"] ?: @""
                          dateText:dict[@"dateText"] ?: @""
                          location:dict[@"location"] ?: @""
                       invitation:dict[@"invitation"] ?: @""
                     coverImageName:dict[@"coverImageName"] ?: @""
                 memberAvatarNames:memberAvatarNames
                  extraMemberCount:[dict[@"extraMemberCount"] integerValue]
                          isHosted:[dict[@"isHosted"] boolValue]
                       isUpcoming:[dict[@"isUpcoming"] boolValue]];
}

- (void)loadSavedHostedParties {
    NSArray *saved = [NSUserDefaults.standardUserDefaults arrayForKey:kHangoSavedHostedPartiesKey];
    if (![saved isKindOfClass:NSArray.class] || saved.count == 0) {
        self.hostedParties = @[];
        return;
    }

    NSMutableArray<HangoParty *> *loaded = [NSMutableArray array];
    for (NSDictionary *dict in saved) {
        HangoParty *party = [self partyFromDictionary:dict];
        if (party) {
            [loaded addObject:party];
        }
    }
    self.hostedParties = loaded.copy;
}

- (void)saveHostedParties {
    NSMutableArray *serialized = [NSMutableArray array];
    for (HangoParty *party in self.hostedParties) {
        [serialized addObject:[self dictionaryFromParty:party]];
    }
    [NSUserDefaults.standardUserDefaults setObject:serialized forKey:kHangoSavedHostedPartiesKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)rebuildUpcomingPartiesList {
    NSMutableArray<HangoParty *> *others = [NSMutableArray array];
    for (HangoParty *party in self.upcomingParties) {
        if (!party.isHosted) {
            [others addObject:party];
        }
    }
    self.upcomingParties = [self.hostedParties arrayByAddingObjectsFromArray:others];
}

- (NSString *)formattedPartyTimeTextFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"hh:mm a";
    return [formatter stringFromDate:date];
}

- (NSString *)formattedPartyDateTextFromDate:(NSDate *)date {
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:date];
    NSInteger day = components.day;
    NSString *suffix = @"th";
    if (day % 100 < 11 || day % 100 > 13) {
        switch (day % 10) {
            case 1: suffix = @"st"; break;
            case 2: suffix = @"nd"; break;
            case 3: suffix = @"rd"; break;
            default: break;
        }
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    formatter.dateFormat = @"MMM";
    NSString *month = [formatter stringFromDate:date];
    formatter.dateFormat = @"yyyy";
    NSString *year = [formatter stringFromDate:date];
    return [NSString stringWithFormat:@"%@ %ld%@ %@", month, (long)day, suffix, year];
}

- (NSDate *)partyDateByAddingRandomDaysToNow {
    NSInteger days = 1 + arc4random_uniform(10);
    return [NSCalendar.currentCalendar dateByAddingUnit:NSCalendarUnitDay value:days toDate:[NSDate date] options:0] ?: [NSDate date];
}

- (void)applyRandomUpcomingScheduleToParty:(HangoParty *)party {
    NSDate *scheduled = [self partyDateByAddingRandomDaysToNow];
    party.timeText = [self formattedPartyTimeTextFromDate:scheduled];
    party.dateText = [self formattedPartyDateTextFromDate:scheduled];
}

- (void)loadSavedOrInitializeSeedPartySchedules {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSDictionary *saved = [defaults dictionaryForKey:kHangoSeedPartySchedulesKey];
    NSMutableDictionary *schedules = saved ? saved.mutableCopy : [NSMutableDictionary dictionary];
    BOOL shouldSave = saved == nil;

    NSSet<NSString *> *seedPartyIds = [NSSet setWithArray:@[@"party_1", @"party_2", @"party_3"]];

    for (HangoParty *party in self.upcomingParties) {
        if (![seedPartyIds containsObject:party.partyId]) {
            continue;
        }

        NSDictionary *schedule = schedules[party.partyId];
        NSString *timeText = schedule[@"timeText"];
        NSString *dateText = schedule[@"dateText"];
        if ([schedule isKindOfClass:NSDictionary.class] && timeText.length > 0 && dateText.length > 0) {
            party.timeText = timeText;
            party.dateText = dateText;
            continue;
        }

        [self applyRandomUpcomingScheduleToParty:party];
        schedules[party.partyId] = @{
            @"timeText": party.timeText ?: @"",
            @"dateText": party.dateText ?: @"",
        };
        shouldSave = YES;
    }

    if (shouldSave) {
        [defaults setObject:schedules.copy forKey:kHangoSeedPartySchedulesKey];
        [defaults synchronize];
    }
}

- (HangovaluePackage *)packageWithProductId:(NSString *)productId sparkles:(NSInteger)sparkles price:(NSString *)price {
    HangovaluePackage *pkg = [[HangovaluePackage alloc] init];
    pkg.packageId = productId;
    pkg.productId = productId;
    pkg.sparkles = sparkles;
    pkg.priceText = price;
    return pkg;
}

- (void)seedDialogueItemsForPartyId:(NSString *)partyId {
    HangoDialogueItem *text = [self dialogueItemWithId:@"pmsg_1"
                                      senderName:@"Palmer"
                                 senderAvatarName:@"Palmer"
                                         content:@"Is everyone having fun?"
                                        timeText:@"06:33 PM"
                                     itemType:HangoDialogueItemTypeText
                                      isOutgoing:NO
                                   audioDuration:0];

    HangoDialogueItem *audio = [self dialogueItemWithId:@"pmsg_2"
                                       senderName:@"Sophia"
                                  senderAvatarName:@"Sophia"
                                          content:@"12s"
                                         timeText:@"06:33 PM"
                                      itemType:HangoDialogueItemTypeAudio
                                       isOutgoing:YES
                                    audioDuration:12];

    HangoDialogueItem *image = [self dialogueItemWithId:@"pmsg_3"
                                       senderName:@"Norris"
                                  senderAvatarName:@"Norris"
                                          content:@"home_album_1"
                                         timeText:@"06:33 PM"
                                      itemType:HangoDialogueItemTypeImage
                                       isOutgoing:NO
                                    audioDuration:0];

    self.partyDialogueItems[partyId] = [NSMutableArray arrayWithObjects:text, audio, image, nil];
}

- (HangoDialogueItem *)dialogueItemWithId:(NSString *)itemId
                         senderName:(NSString *)senderName
                    senderAvatarName:(NSString *)senderAvatarName
                            content:(NSString *)content
                           timeText:(NSString *)timeText
                        itemType:(HangoDialogueItemType)itemType
                         isOutgoing:(BOOL)isOutgoing
                      audioDuration:(NSInteger)audioDuration {
    HangoDialogueItem *dialogueItem = [[HangoDialogueItem alloc] init];
    dialogueItem.itemId = itemId;
    dialogueItem.senderName = senderName;
    dialogueItem.senderAvatarName = senderAvatarName;
    dialogueItem.content = content;
    dialogueItem.timeText = timeText;
    dialogueItem.itemType = itemType;
    dialogueItem.isOutgoing = isOutgoing;
    dialogueItem.audioDuration = audioDuration;
    return dialogueItem;
}

- (BOOL)isDeniedPersonWithName:(NSString *)name avatarName:(NSString *)avatarName {
    for (NSString *contactId in self.deniedContactIds) {
        HangoContact *contact = [self contactWithId:contactId];
        if (!contact) {
            continue;
        }
        if (name.length > 0 && contact.name.length > 0 && [contact.name isEqualToString:name]) {
            return YES;
        }
        if (avatarName.length > 0 && contact.avatarName.length > 0 && [contact.avatarName isEqualToString:avatarName]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isDeniedDialogueItem:(HangoDialogueItem *)item {
    if (!item || item.isOutgoing) {
        return NO;
    }
    return [self isDeniedPersonWithName:item.senderName avatarName:item.senderAvatarName];
}

- (NSArray<HangoDialogueItem *> *)filteredDialogueItems:(NSArray<HangoDialogueItem *> *)items {
    if (items.count == 0) {
        return @[];
    }
    NSMutableArray<HangoDialogueItem *> *result = [NSMutableArray arrayWithCapacity:items.count];
    for (HangoDialogueItem *item in items) {
        if (![self isDeniedDialogueItem:item]) {
            [result addObject:item];
        }
    }
    return result.copy;
}

- (BOOL)isPartyHostDenied:(HangoParty *)party {
    if (!party) {
        return NO;
    }
    return [self isDeniedPersonWithName:party.hostName avatarName:party.hostAvatarName];
}

- (NSArray<HangoParty *> *)visiblePartiesFromArray:(NSArray<HangoParty *> *)parties {
    NSMutableArray<HangoParty *> *result = [NSMutableArray array];
    for (HangoParty *party in parties) {
        if (![self isPartyHostDenied:party]) {
            [result addObject:party];
        }
    }
    return result.copy;
}

- (NSArray<HangoContact *> *)visibleContacts {
    if (![self canAccessDialogueData]) {
        return @[];
    }
    NSMutableArray<HangoContact *> *result = [NSMutableArray array];
    for (HangoContact *contact in self.contacts) {
        if (!contact.isDenied) {
            [result addObject:contact];
        }
    }
    return result.copy;
}

- (NSArray<HangoParty *> *)visibleUpcomingParties {
    return [self visiblePartiesFromArray:self.upcomingParties];
}

- (NSArray<HangoParty *> *)visibleAttendedParties {
    return [self visiblePartiesFromArray:self.attendedParties];
}

- (NSArray<HangoAlbumItem *> *)visibleAlbumItems {
    NSMutableArray<HangoAlbumItem *> *result = [NSMutableArray array];
    for (HangoAlbumItem *item in self.albumItems) {
        HangoParty *party = [self partyWithId:item.partyId];
        if (party && ![self isPartyHostDenied:party]) {
            [result addObject:item];
        }
    }
    return result.copy;
}

- (NSArray<NSString *> *)visibleMemberAvatarNamesForParty:(HangoParty *)party {
    if (!party) {
        return @[];
    }
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    for (NSString *avatarName in party.memberAvatarNames) {
        HangoContact *matched = [self contactMatchingName:nil avatarName:avatarName];
        NSString *memberName = matched.name ?: avatarName;
        if (![self isDeniedPersonWithName:memberName avatarName:avatarName]) {
            [result addObject:avatarName];
        }
    }
    return result.copy;
}

- (void)notifyDeniedContactsDidChange {
    [NSNotificationCenter.defaultCenter postNotificationName:HangoDeniedContactsDidChangeNotification object:self];
}

- (NSArray<HangoDialogueItem *> *)dialogueItemsForConversationId:(NSString *)conversationId {
    if (![self canAccessDialogueData]) {
        return @[];
    }
    return [self filteredDialogueItems:[self.conversationDialogueItems[conversationId] copy] ?: @[]];
}

- (NSArray<HangoDialogueItem *> *)dialogueItemsForPartyId:(NSString *)partyId {
    if (![self canAccessDialogueData]) {
        return @[];
    }
    return [self filteredDialogueItems:[self.partyDialogueItems[partyId] copy] ?: @[]];
}

- (void)loadAcceptedPartyIds {
    NSArray<NSString *> *saved = [NSUserDefaults.standardUserDefaults arrayForKey:kHangoAcceptedPartyIdsKey];
    self.acceptedPartyIds = saved.count > 0 ? [NSMutableSet setWithArray:saved] : [NSMutableSet set];
}

- (BOOL)isPartyAccepted:(NSString *)partyId {
    return partyId.length > 0 && [self.acceptedPartyIds containsObject:partyId];
}

- (BOOL)setPartyAccepted:(BOOL)accepted forPartyId:(NSString *)partyId {
    if (partyId.length == 0) {
        return NO;
    }
    if (accepted) {
        [self.acceptedPartyIds addObject:partyId];
    } else {
        [self.acceptedPartyIds removeObject:partyId];
    }
    [NSUserDefaults.standardUserDefaults setObject:self.acceptedPartyIds.allObjects forKey:kHangoAcceptedPartyIdsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    return YES;
}

- (HangoParty *)partyWithId:(NSString *)partyId {
    for (HangoParty *party in self.upcomingParties) {
        if ([party.partyId isEqualToString:partyId]) return party;
    }
    for (HangoParty *party in self.hostedParties) {
        if ([party.partyId isEqualToString:partyId]) return party;
    }
    for (HangoParty *party in self.attendedParties) {
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

- (HangoContact *)contactMatchingName:(NSString *)name avatarName:(NSString *)avatarName {
    for (HangoContact *contact in self.contacts) {
        if (avatarName.length > 0 && [contact.avatarName isEqualToString:avatarName]) {
            return contact;
        }
        if (name.length > 0 && [contact.name isEqualToString:name]) {
            return contact;
        }
    }
    return [self directoryContactMatchingName:name avatarName:avatarName];
}

- (HangoContact *)directoryContactMatchingName:(NSString *)name avatarName:(NSString *)avatarName {
    for (HangoContact *contact in self.directoryContacts) {
        if (avatarName.length > 0 && [contact.avatarName isEqualToString:avatarName]) {
            return contact;
        }
        if (name.length > 0 && [contact.name isEqualToString:name]) {
            return contact;
        }
    }
    return nil;
}

- (HangoContact *)syntheticContactWithName:(NSString *)name avatarName:(NSString *)avatarName {
    HangoContact *contact = [[HangoContact alloc] init];
    NSString *key = avatarName.length > 0 ? avatarName : name;
    contact.contactId = [NSString stringWithFormat:@"party_member_%@", key ?: @"guest"];
    contact.name = name.length > 0 ? name : (avatarName ?: @"Guest");
    contact.avatarName = avatarName ?: @"";
    contact.number = @"";
    return contact;
}

- (NSArray<HangoContact *> *)contactsForParty:(HangoParty *)party {
    if (!party) {
        return @[];
    }

    NSMutableArray<HangoContact *> *result = [NSMutableArray array];
    NSMutableSet<NSString *> *seenKeys = [NSMutableSet set];

    void (^addPerson)(NSString *, NSString *) = ^(NSString *name, NSString *avatarName) {
        NSString *key = avatarName.length > 0 ? avatarName : name;
        if (key.length == 0 || [seenKeys containsObject:key]) {
            return;
        }
        [seenKeys addObject:key];

        HangoContact *contact = [self contactMatchingName:name avatarName:avatarName];
        if (!contact) {
            contact = [self syntheticContactWithName:name avatarName:avatarName];
        }
        [result addObject:contact];
    };

    if (![self isDeniedPersonWithName:party.hostName avatarName:party.hostAvatarName]) {
        addPerson(party.hostName, party.hostAvatarName);
    }
    for (NSString *avatarName in party.memberAvatarNames) {
        HangoContact *matched = [self contactMatchingName:nil avatarName:avatarName];
        NSString *memberName = matched.name ?: avatarName;
        if ([self isDeniedPersonWithName:memberName avatarName:avatarName]) {
            continue;
        }
        addPerson(memberName, avatarName);
    }

    return result.copy;
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

- (NSInteger)addContactWithNumber:(NSString *)number {
    if (![self canAccessDialogueData]) {
        return 0;
    }
    HangoContact *contact = [self contactWithNumber:number];
    if (!contact) {
        return 0;
    }
    if ([self isContactInList:contact]) {
        return 2;
    }
    self.contacts = [self.contacts arrayByAddingObject:contact];
    [self saveContacts];
    return 1;
}

- (BOOL)isContactInList:(HangoContact *)contact {
    if (!contact) {
        return NO;
    }
    for (HangoContact *existing in self.contacts) {
        if (existing.contactId.length > 0 && [existing.contactId isEqualToString:contact.contactId]) {
            return YES;
        }
        if (contact.avatarName.length > 0 && [existing.avatarName isEqualToString:contact.avatarName]) {
            return YES;
        }
        if (contact.name.length > 0 && [existing.name isEqualToString:contact.name]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isCurrentPersonaContact:(HangoContact *)contact {
    if (!contact) {
        return NO;
    }
    if (contact.name.length > 0 && [contact.name isEqualToString:self.currentPersona.name]) {
        return YES;
    }
    if (contact.avatarName.length > 0 && self.currentPersona.avatarName.length > 0 &&
        [contact.avatarName isEqualToString:self.currentPersona.avatarName]) {
        return YES;
    }
    return NO;
}

- (BOOL)trackContact:(HangoContact *)contact {
    if (![self canAccessDialogueData] || !contact || [self isCurrentPersonaContact:contact] || [self isContactInList:contact]) {
        return NO;
    }

    HangoContact *toAdd = [self contactMatchingName:contact.name avatarName:contact.avatarName];
    if (!toAdd) {
        toAdd = contact;
    }
    self.contacts = [self.contacts arrayByAddingObject:toAdd];
    [self saveContacts];
    return YES;
}

- (BOOL)untrackContact:(HangoContact *)contact {
    if (![self canAccessDialogueData] || !contact || ![self isContactInList:contact]) {
        return NO;
    }

    NSMutableArray<HangoContact *> *updated = [NSMutableArray array];
    for (HangoContact *existing in self.contacts) {
        BOOL isSame = NO;
        if (contact.contactId.length > 0 && [existing.contactId isEqualToString:contact.contactId]) {
            isSame = YES;
        } else if (contact.avatarName.length > 0 && [existing.avatarName isEqualToString:contact.avatarName]) {
            isSame = YES;
        } else if (contact.name.length > 0 && [existing.name isEqualToString:contact.name]) {
            isSame = YES;
        }
        if (!isSame) {
            [updated addObject:existing];
        }
    }
    if (updated.count == self.contacts.count) {
        return NO;
    }
    self.contacts = updated.copy;
    [self saveContacts];
    return YES;
}

- (NSDictionary *)dictionaryFromContact:(HangoContact *)contact {
    return @{
        @"contactId": contact.contactId ?: @"",
        @"name": contact.name ?: @"",
        @"number": contact.number ?: @"",
        @"avatarName": contact.avatarName ?: @"",
    };
}

- (HangoContact *)contactFromDictionary:(NSDictionary *)dict {
    HangoContact *contact = [[HangoContact alloc] init];
    contact.contactId = dict[@"contactId"];
    contact.name = dict[@"name"];
    contact.number = dict[@"number"];
    contact.avatarName = dict[@"avatarName"];
    contact.isDenied = [self.deniedContactIds containsObject:contact.contactId];
    return contact;
}

- (void)seedDefaultContacts {
    NSArray<NSString *> *defaultNames = @[@"Norris", @"Dillon", @"Lillie", @"Sophia", @"Faith"];
    NSMutableArray<HangoContact *> *defaults = [NSMutableArray array];
    for (NSString *name in defaultNames) {
        HangoContact *contact = [self directoryContactMatchingName:name avatarName:name];
        if (contact) {
            [defaults addObject:contact];
        }
    }
    self.contacts = [self contactsWithDirectoryNumbers:defaults];
    [self applyDenyStateToContacts];
    [self saveContacts];
    NSString *scopedSeededKey = [self scopedDefaultsKey:kHangoDefaultContactsSeededKey];
    if (scopedSeededKey.length > 0) {
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:scopedSeededKey];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

- (BOOL)shouldSeedDefaultContactsForCurrentAccount {
    NSString *email = [[self.currentPersona.email stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] lowercaseString];
    return [[HangoAccountStore shared] isSeedTestAccountEmail:email];
}

- (void)loadSavedContacts {
    if (![self canAccessDialogueData]) {
        self.contacts = @[];
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *scopedContactsKey = [self scopedDefaultsKey:kHangoSavedContactsKey];
    NSString *scopedSeededKey = [self scopedDefaultsKey:kHangoDefaultContactsSeededKey];
    if (scopedContactsKey.length == 0) {
        self.contacts = @[];
        return;
    }

    if ([defaults objectForKey:scopedContactsKey] == nil) {
        if ([self shouldSeedDefaultContactsForCurrentAccount]) {
            [self seedDefaultContacts];
        } else {
            self.contacts = @[];
        }
        return;
    }

    NSArray *saved = [defaults arrayForKey:scopedContactsKey];
    if (![saved isKindOfClass:NSArray.class]) {
        self.contacts = @[];
        return;
    }
    if (saved.count == 0) {
        if (scopedSeededKey.length > 0 && ![defaults boolForKey:scopedSeededKey] && [self shouldSeedDefaultContactsForCurrentAccount]) {
            [self seedDefaultContacts];
        } else {
            self.contacts = @[];
        }
        return;
    }

    NSMutableArray<HangoContact *> *loaded = [NSMutableArray array];
    for (NSDictionary *dict in saved) {
        if (![dict isKindOfClass:NSDictionary.class]) {
            continue;
        }
        HangoContact *stored = [self contactFromDictionary:dict];
        HangoContact *canonical = [self directoryContactMatchingName:stored.name avatarName:stored.avatarName];
        [loaded addObject:canonical ?: stored];
    }
    self.contacts = [self contactsWithDirectoryNumbers:loaded];
    [self applyDenyStateToContacts];
    if ([self shouldSeedDefaultContactsForCurrentAccount] && self.contacts.count > 0) {
        [self saveContacts];
    }
}

- (NSArray<HangoContact *> *)contactsWithDirectoryNumbers:(NSArray<HangoContact *> *)contacts {
    NSMutableArray<HangoContact *> *synced = [NSMutableArray arrayWithCapacity:contacts.count];
    for (HangoContact *contact in contacts) {
        HangoContact *canonical = [self directoryContactMatchingName:contact.name avatarName:contact.avatarName];
        [synced addObject:canonical ?: contact];
    }
    return synced.copy;
}

- (void)saveContacts {
    if (![self canAccessDialogueData]) {
        return;
    }
    NSString *scopedContactsKey = [self scopedDefaultsKey:kHangoSavedContactsKey];
    if (scopedContactsKey.length == 0) {
        return;
    }

    NSMutableArray *serialized = [NSMutableArray array];
    for (HangoContact *contact in self.contacts) {
        [serialized addObject:[self dictionaryFromContact:contact]];
    }
    [NSUserDefaults.standardUserDefaults setObject:serialized forKey:scopedContactsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    [self notifyContactsDataDidChange];
}

- (void)addSparkles:(NSInteger)amount {
    self.currentPersona.sparkleBalance += amount;
    [self savePersonaStats];
}

- (void)spendSparkles:(NSInteger)amount {
    self.currentPersona.sparkleBalance = MAX(0, self.currentPersona.sparkleBalance - amount);
    [self savePersonaStats];
}

- (void)loadDenyListedContactIds {
    if (![self canAccessDialogueData]) {
        self.deniedContactIds = [NSMutableSet set];
        return;
    }
    NSString *scopedKey = [self scopedDefaultsKey:kHangoDeniedContactIdsKey];
    NSArray<NSString *> *saved = scopedKey.length > 0 ? [NSUserDefaults.standardUserDefaults arrayForKey:scopedKey] : nil;
    self.deniedContactIds = saved.count > 0 ? [NSMutableSet setWithArray:saved] : [NSMutableSet set];
    [self applyDenyStateToContacts];
}

- (void)applyDenyStateToContacts {
    for (HangoContact *contact in self.directoryContacts) {
        contact.isDenied = [self.deniedContactIds containsObject:contact.contactId];
    }
    for (HangoContact *contact in self.contacts) {
        contact.isDenied = [self.deniedContactIds containsObject:contact.contactId];
    }
}

- (void)saveDeniedContactIds {
    if (![self canAccessDialogueData]) {
        return;
    }
    NSString *scopedKey = [self scopedDefaultsKey:kHangoDeniedContactIdsKey];
    if (scopedKey.length == 0) {
        return;
    }
    [NSUserDefaults.standardUserDefaults setObject:self.deniedContactIds.allObjects forKey:scopedKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)addContactToDenyList:(NSString *)contactId {
    if (contactId.length == 0) {
        return;
    }
    HangoContact *contact = [self contactWithId:contactId];
    if (!contact) {
        return;
    }
    [self.deniedContactIds addObject:contactId];
    contact.isDenied = YES;
    [self saveDeniedContactIds];
    [self.conversationContactIds removeObject:contactId];
    [self rebuildConversationsList];
    [self saveConversationData];
    [self notifyDeniedContactsDidChange];
}

- (void)removeContactFromDenyList:(NSString *)contactId {
    if (contactId.length == 0) {
        return;
    }
    HangoContact *contact = [self contactWithId:contactId];
    if (!contact) {
        return;
    }
    [self.deniedContactIds removeObject:contactId];
    contact.isDenied = NO;
    [self saveDeniedContactIds];

    if ([self hasOutgoingDialogueItemsForConversationId:contactId] && ![self.conversationContactIds containsObject:contactId]) {
        [self.conversationContactIds insertObject:contactId atIndex:0];
        [self rebuildConversationsList];
        [self saveConversationData];
    }
    [self notifyDeniedContactsDidChange];
}

- (NSArray<HangoContact *> *)deniedContacts {
    NSMutableArray<HangoContact *> *result = [NSMutableArray array];
    for (HangoContact *contact in self.directoryContacts) {
        if (contact.isDenied) {
            [result addObject:contact];
        }
    }
    return result.copy;
}

- (void)blockContactWithId:(NSString *)contactId {
    [self addContactToDenyList:contactId];
}

- (NSArray<HangoContact *> *)activeConversations {
    NSMutableArray<HangoContact *> *result = [NSMutableArray array];
    for (NSString *contactId in self.conversationContactIds) {
        HangoContact *contact = [self contactWithId:contactId];
        if (!contact || contact.isDenied) {
            continue;
        }
        if ([self hasOutgoingDialogueItemsForConversationId:contactId]) {
            [result addObject:contact];
        }
    }
    return result.copy;
}

- (NSString *)privateThreadKeyForContactId:(NSString *)contactId {
    return [NSString stringWithFormat:@"private:%@", contactId ?: @""];
}

- (NSString *)partyThreadKeyForPartyId:(NSString *)partyId {
    return [NSString stringWithFormat:@"party:%@", partyId ?: @""];
}

- (void)promoteDialogueThreadKey:(NSString *)threadKey {
    if (threadKey.length == 0) {
        return;
    }
    [self.dialogueThreadOrder removeObject:threadKey];
    [self.dialogueThreadOrder insertObject:threadKey atIndex:0];
}

- (BOOL)hasOutgoingDialogueItemsForPartyId:(NSString *)partyId {
    for (HangoDialogueItem *dialogueItem in self.partyDialogueItems[partyId]) {
        if (dialogueItem.isOutgoing) {
            return YES;
        }
    }
    return NO;
}

- (nullable HangoDialogueItem *)lastDialogueForPartyId:(NSString *)partyId {
    return [self dialogueItemsForPartyId:partyId].lastObject;
}

- (NSArray<HangoDialogueThread *> *)activeDialogueThreads {
    if (![self canAccessDialogueData]) {
        return @[];
    }
    NSMutableArray<HangoDialogueThread *> *threads = [NSMutableArray array];
    NSMutableSet<NSString *> *seenKeys = [NSMutableSet set];

    for (NSString *threadKey in self.dialogueThreadOrder) {
        if ([seenKeys containsObject:threadKey]) {
            continue;
        }
        NSArray<NSString *> *parts = [threadKey componentsSeparatedByString:@":"];
        if (parts.count < 2) {
            continue;
        }
        NSString *kind = parts[0];
        NSString *identifier = [[parts subarrayWithRange:NSMakeRange(1, parts.count - 1)] componentsJoinedByString:@":"];
        if (identifier.length == 0) {
            continue;
        }
        if ([kind isEqualToString:@"private"]) {
            if (![self hasOutgoingDialogueItemsForConversationId:identifier]) {
                continue;
            }
            HangoContact *contact = [self contactWithId:identifier];
            if (!contact || contact.isDenied) {
                continue;
            }
            HangoDialogueThread *thread = [[HangoDialogueThread alloc] init];
            thread.kind = HangoDialogueThreadKindPrivate;
            thread.threadId = identifier;
            thread.contact = contact;
            [threads addObject:thread];
            [seenKeys addObject:threadKey];
        } else if ([kind isEqualToString:@"party"]) {
            if (![self hasOutgoingDialogueItemsForPartyId:identifier]) {
                continue;
            }
            HangoParty *party = [self partyWithId:identifier];
            if (!party || [self isPartyHostDenied:party]) {
                continue;
            }
            HangoDialogueThread *thread = [[HangoDialogueThread alloc] init];
            thread.kind = HangoDialogueThreadKindParty;
            thread.threadId = identifier;
            thread.party = party;
            [threads addObject:thread];
            [seenKeys addObject:threadKey];
        }
    }

    for (NSString *contactId in self.conversationContactIds) {
        NSString *threadKey = [self privateThreadKeyForContactId:contactId];
        if ([seenKeys containsObject:threadKey]) {
            continue;
        }
        if (![self hasOutgoingDialogueItemsForConversationId:contactId]) {
            continue;
        }
        HangoContact *contact = [self contactWithId:contactId];
        if (!contact || contact.isDenied) {
            continue;
        }
        HangoDialogueThread *thread = [[HangoDialogueThread alloc] init];
        thread.kind = HangoDialogueThreadKindPrivate;
        thread.threadId = contactId;
        thread.contact = contact;
        [threads addObject:thread];
        [seenKeys addObject:threadKey];
    }

    for (NSString *partyId in self.partyConversationPartyIds) {
        NSString *threadKey = [self partyThreadKeyForPartyId:partyId];
        if ([seenKeys containsObject:threadKey]) {
            continue;
        }
        if (![self hasOutgoingDialogueItemsForPartyId:partyId]) {
            continue;
        }
        HangoParty *party = [self partyWithId:partyId];
        if (!party || [self isPartyHostDenied:party]) {
            continue;
        }
        HangoDialogueThread *thread = [[HangoDialogueThread alloc] init];
        thread.kind = HangoDialogueThreadKindParty;
        thread.threadId = partyId;
        thread.party = party;
        [threads addObject:thread];
        [seenKeys addObject:threadKey];
    }

    return threads.copy;
}

- (BOOL)hasOutgoingDialogueItemsForConversationId:(NSString *)conversationId {
    for (HangoDialogueItem *dialogueItem in self.conversationDialogueItems[conversationId]) {
        if (dialogueItem.isOutgoing) {
            return YES;
        }
    }
    return NO;
}

- (nullable HangoDialogueItem *)lastDialogueForConversationId:(NSString *)conversationId {
    return [self dialogueItemsForConversationId:conversationId].lastObject;
}

- (NSString *)previewTextForDialogueItem:(HangoDialogueItem *)dialogueItem {
    if (!dialogueItem) {
        return @"";
    }
    switch (dialogueItem.itemType) {
        case HangoDialogueItemTypeAudio: {
            if (dialogueItem.content.length > 0) {
                return [NSString stringWithFormat:HangoDisplayString(HangoDisplayStringKeyVoicePreviewFormat), dialogueItem.content];
            }
            NSInteger seconds = MAX(dialogueItem.audioDuration, 1);
            return [NSString stringWithFormat:HangoDisplayString(HangoDisplayStringKeyVoicePreviewSecondsFormat), (long)seconds];
        }
        case HangoDialogueItemTypeImage:
            return HangoDisplayString(HangoDisplayStringKeyPhotoPreview);
        default:
            return dialogueItem.content ?: @"";
    }
}

- (void)appendDialogueItem:(HangoDialogueItem *)dialogueItem toConversationId:(NSString *)conversationId {
    if (conversationId.length == 0 || !dialogueItem || ![self canAccessDialogueData]) {
        return;
    }
    if (!self.conversationDialogueItems[conversationId]) {
        self.conversationDialogueItems[conversationId] = [NSMutableArray array];
    }
    [self.conversationDialogueItems[conversationId] addObject:dialogueItem];

    if (dialogueItem.isOutgoing) {
        [self.conversationContactIds removeObject:conversationId];
        [self.conversationContactIds insertObject:conversationId atIndex:0];
        [self promoteDialogueThreadKey:[self privateThreadKeyForContactId:conversationId]];
        [self rebuildConversationsList];
    }
    [self saveConversationData];
}

- (void)appendPartyDialogueItem:(HangoDialogueItem *)dialogueItem partyId:(NSString *)partyId {
    if (partyId.length == 0 || !dialogueItem || ![self canAccessDialogueData]) {
        return;
    }
    if (!self.partyDialogueItems[partyId]) {
        self.partyDialogueItems[partyId] = [NSMutableArray array];
    }
    [self.partyDialogueItems[partyId] addObject:dialogueItem];

    if (dialogueItem.isOutgoing) {
        [self.partyConversationPartyIds removeObject:partyId];
        [self.partyConversationPartyIds insertObject:partyId atIndex:0];
        [self promoteDialogueThreadKey:[self partyThreadKeyForPartyId:partyId]];
    }
    [self savePartyConversationData];
}

- (HangoParty *)createPartyWithTime:(NSString *)time date:(NSString *)date location:(NSString *)location invitation:(NSString *)invitation inviteeIds:(NSArray<NSString *> *)inviteeIds {
    NSMutableArray *avatars = [NSMutableArray array];
    for (NSString *contactId in inviteeIds) {
        HangoContact *contact = [self contactWithId:contactId];
        if (contact.avatarName.length) {
            [avatars addObject:contact.avatarName];
        }
    }
    NSString *hostName = self.currentPersona.name ?: @"";
    NSString *hostAvatarName = [HangoTheme isRealPersonAvatarName:hostName] ? hostName : (self.currentPersona.avatarName ?: hostName);
    HangoParty *party = [self buildPartyWithId:[NSString stringWithFormat:@"party_%@", @((NSInteger)[[NSDate date] timeIntervalSince1970])]
                                      hostName:hostName
                                 hostAvatarName:hostAvatarName
                                       timeText:time
                                       dateText:date
                                       location:location
                                    invitation:invitation
                                  coverImageName:@"home_album_1"
                              memberAvatarNames:avatars.copy
                               extraMemberCount:0
                                       isHosted:YES
                                    isUpcoming:YES];
    self.hostedParties = [@[party] arrayByAddingObjectsFromArray:self.hostedParties];
    self.upcomingParties = [@[party] arrayByAddingObjectsFromArray:self.upcomingParties];
    [self syncHostedPartyCount];
    return party;
}

- (BOOL)deleteHostedPartyWithId:(NSString *)partyId {
    if (partyId.length == 0) {
        return NO;
    }

    NSUInteger hostedCount = self.hostedParties.count;
    self.hostedParties = [self.hostedParties filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(HangoParty *party, NSDictionary<NSString *, id> * _Nullable bindings) {
        return ![party.partyId isEqualToString:partyId];
    }]];
    if (self.hostedParties.count == hostedCount) {
        return NO;
    }

    self.upcomingParties = [self.upcomingParties filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(HangoParty *party, NSDictionary<NSString *, id> * _Nullable bindings) {
        return ![party.partyId isEqualToString:partyId];
    }]];
    [self syncHostedPartyCount];
    return YES;
}

- (void)initializePersonaIdCounterIfNeeded {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults objectForKey:kHangoNextPersonaIdKey] == nil) {
        [defaults setInteger:kHangoBasePersonaId + 1 forKey:kHangoNextPersonaIdKey];
        [defaults synchronize];
    }
}

- (NSString *)issueNextPersonaId {
    [self initializePersonaIdCounterIfNeeded];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSInteger nextId = [defaults integerForKey:kHangoNextPersonaIdKey];
    NSInteger increment = 1 + arc4random_uniform(15);
    [defaults setInteger:nextId + increment forKey:kHangoNextPersonaIdKey];
    [defaults synchronize];
    return @(nextId).stringValue;
}

- (void)savePersonaId {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:self.currentPersona.personaId ?: @"" forKey:kHangoSavedPersonaIdKey];
    [defaults synchronize];
}

- (void)assignPersonaIdForNewAccount {
    self.currentPersona.personaId = [self issueNextPersonaId];
    [self savePersonaId];
}

- (void)loadSavedPersonaIdIfNeeded {
    NSString *personaId = [NSUserDefaults.standardUserDefaults stringForKey:kHangoSavedPersonaIdKey];
    if (personaId.length > 0) {
        self.currentPersona.personaId = personaId;
    }
}

- (NSString *)avatarDirectoryPath {
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [documents stringByAppendingPathComponent:@"HangoAvatars"];
}

- (NSString *)storedAvatarPathForAbsolutePath:(NSString *)absolutePath {
    if (absolutePath.length == 0) {
        return nil;
    }
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if ([absolutePath hasPrefix:documents]) {
        NSString *relative = [absolutePath substringFromIndex:documents.length];
        if ([relative hasPrefix:@"/"]) {
            relative = [relative substringFromIndex:1];
        }
        return relative;
    }
    return absolutePath;
}

- (NSString *)resolvedAvatarPath:(NSString *)storedPath {
    if (storedPath.length == 0) {
        return nil;
    }
    if ([storedPath hasPrefix:@"/"]) {
        return storedPath;
    }
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [documents stringByAppendingPathComponent:storedPath];
}

- (UIImage *)normalizedAvatarImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    CGFloat maxSide = 512.0;
    CGSize size = image.size;
    if (size.width <= 0.0 || size.height <= 0.0) {
        return image;
    }
    if (size.width <= maxSide && size.height <= maxSide) {
        return image;
    }
    CGFloat scale = MIN(maxSide / size.width, maxSide / size.height);
    CGSize targetSize = CGSizeMake(MAX(1.0, size.width * scale), MAX(1.0, size.height * scale));
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.opaque = NO;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:targetSize format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        [image drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
    }];
}

- (NSString *)saveAvatarImage:(UIImage *)image {
    UIImage *normalized = [self normalizedAvatarImage:image];
    if (!normalized) {
        return nil;
    }
    NSData *data = UIImageJPEGRepresentation(normalized, 0.88);
    if (!data) {
        data = UIImagePNGRepresentation(normalized);
    }
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

- (void)loadSavedPersonaProfileIfNeeded {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *name = [defaults stringForKey:kHangoSavedPersonaNameKey];
    if (name.length > 0) {
        self.currentPersona.name = name;
    }
    NSString *email = [defaults stringForKey:kHangoSavedPersonaEmailKey];
    if (email.length > 0) {
        self.currentPersona.email = email;
    }
    NSString *bio = [defaults stringForKey:kHangoSavedPersonaBioKey];
    if (bio.length > 0) {
        self.currentPersona.bio = bio;
    }
    NSString *avatarName = [defaults stringForKey:kHangoSavedPersonaAvatarNameKey];
    if (avatarName.length > 0) {
        self.currentPersona.avatarName = avatarName;
    }
    NSString *storedAvatarPath = [defaults stringForKey:kHangoSavedPersonaAvatarLocalPathKey];
    NSString *resolvedAvatarPath = [self resolvedAvatarPath:storedAvatarPath];
    if (resolvedAvatarPath.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:resolvedAvatarPath]) {
        self.currentPersona.avatarLocalPath = resolvedAvatarPath;
    }
    NSString *personaId = [defaults stringForKey:kHangoSavedPersonaIdKey];
    if (personaId.length > 0) {
        self.currentPersona.personaId = personaId;
    }
}

- (void)loadSavedPersonaStatsIfNeeded {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (![defaults boolForKey:kHangoSparkleIAPResetKey]) {
        self.currentPersona.sparkleBalance = 0;
        [defaults setBool:YES forKey:kHangoSparkleIAPResetKey];
        [self savePersonaStats];
        return;
    }
    if ([defaults objectForKey:kHangoSavedSparkleBalanceKey] != nil) {
        self.currentPersona.sparkleBalance = [defaults integerForKey:kHangoSavedSparkleBalanceKey];
    }
    if ([defaults objectForKey:kHangoSavedHostedPartyCountKey] != nil) {
        self.currentPersona.hostedPartyCount = [defaults integerForKey:kHangoSavedHostedPartyCountKey];
    }
}

- (void)savePersonaStats {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setInteger:self.currentPersona.sparkleBalance forKey:kHangoSavedSparkleBalanceKey];
    [defaults setInteger:self.currentPersona.hostedPartyCount forKey:kHangoSavedHostedPartyCountKey];
    [defaults synchronize];
}

- (void)syncHostedPartyCount {
    self.currentPersona.hostedPartyCount = (NSInteger)self.hostedParties.count;
    [self savePersonaStats];
    [self saveHostedParties];
}

- (void)rebuildConversationsList {
    NSMutableArray<NSString *> *validIds = [NSMutableArray array];
    for (NSString *contactId in self.conversationContactIds) {
        HangoContact *contact = [self contactWithId:contactId];
        if (contact && !contact.isDenied && [self hasOutgoingDialogueItemsForConversationId:contactId]) {
            [validIds addObject:contactId];
        }
    }
    self.conversationContactIds = validIds;

    NSMutableArray<HangoContact *> *updated = [NSMutableArray array];
    for (NSString *contactId in self.conversationContactIds) {
        HangoContact *contact = [self contactWithId:contactId];
        if (contact) {
            [updated addObject:contact];
        }
    }
    self.conversations = updated.copy;
}

- (NSDictionary *)dictionaryFromDialogueItem:(HangoDialogueItem *)dialogueItem {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"itemId"] = dialogueItem.itemId ?: @"";
    dict[@"senderName"] = dialogueItem.senderName ?: @"";
    dict[@"senderAvatarName"] = dialogueItem.senderAvatarName ?: @"";
    dict[@"content"] = dialogueItem.content ?: @"";
    dict[@"timeText"] = dialogueItem.timeText ?: @"";
    dict[@"itemType"] = @(dialogueItem.itemType);
    dict[@"isOutgoing"] = @(dialogueItem.isOutgoing);
    dict[@"audioDuration"] = @(dialogueItem.audioDuration);
    if (dialogueItem.audioFilePath.length > 0) {
        dict[@"audioFilePath"] = dialogueItem.audioFilePath;
    }
    return dict;
}

- (HangoDialogueItem *)dialogueItemFromDictionary:(NSDictionary *)dict {
    HangoDialogueItem *dialogueItem = [[HangoDialogueItem alloc] init];
    dialogueItem.itemId = dict[@"itemId"];
    dialogueItem.senderName = dict[@"senderName"];
    dialogueItem.senderAvatarName = dict[@"senderAvatarName"];
    dialogueItem.content = dict[@"content"];
    dialogueItem.timeText = dict[@"timeText"];
    dialogueItem.itemType = [dict[@"itemType"] integerValue];
    dialogueItem.isOutgoing = [dict[@"isOutgoing"] boolValue];
    dialogueItem.audioDuration = [dict[@"audioDuration"] integerValue];
    dialogueItem.audioFilePath = dict[@"audioFilePath"];
    return dialogueItem;
}

#pragma mark - Account-scoped dialogue storage

- (NSString *)dialogueStorageKeyForPersona:(HangoPersona *)persona {
    NSString *name = [persona.name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (name.length > 0) {
        return [NSString stringWithFormat:@"user:%@", name];
    }
    NSString *email = [[persona.email stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] lowercaseString];
    if (email.length > 0) {
        return [NSString stringWithFormat:@"email:%@", email];
    }
    if (persona.personaId.length > 0) {
        return [NSString stringWithFormat:@"id:%@", persona.personaId];
    }
    return nil;
}

- (NSString *)dialogueStorageKeyForCurrentSession {
    if (![NSUserDefaults.standardUserDefaults boolForKey:kHangoIsLoggedInKey]) {
        return nil;
    }
    return [self dialogueStorageKeyForPersona:self.currentPersona];
}

- (BOOL)canAccessDialogueData {
    return [self dialogueStorageKeyForCurrentSession].length > 0;
}

- (NSString *)scopedDefaultsKey:(NSString *)baseKey storageKey:(NSString *)storageKey {
    if (baseKey.length == 0 || storageKey.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@.%@", baseKey, storageKey];
}

- (NSString *)scopedDefaultsKey:(NSString *)baseKey {
    return [self scopedDefaultsKey:baseKey storageKey:[self dialogueStorageKeyForCurrentSession]];
}

- (void)clearInMemoryDialogueData {
    [self.conversationDialogueItems removeAllObjects];
    [self.conversationContactIds removeAllObjects];
    [self.partyDialogueItems removeAllObjects];
    [self.partyConversationPartyIds removeAllObjects];
    [self.dialogueThreadOrder removeAllObjects];
    self.conversations = @[];
}

- (void)clearInMemoryContactsData {
    self.contacts = @[];
    self.deniedContactIds = [NSMutableSet set];
    [self applyDenyStateToContacts];
}

- (void)notifyDialogueDataDidChange {
    [NSNotificationCenter.defaultCenter postNotificationName:HangoDialogueDataDidChangeNotification object:self];
}

- (void)notifyContactsDataDidChange {
    [NSNotificationCenter.defaultCenter postNotificationName:HangoContactsDataDidChangeNotification object:self];
}

- (void)unloadDialogueDataForGuestSession {
    [self clearInMemoryDialogueData];
    [self clearInMemoryContactsData];
    [self notifyDialogueDataDidChange];
    [self notifyContactsDataDidChange];
}

- (void)deletePersistedDialogueDataForCurrentAccount {
    NSString *storageKey = [self dialogueStorageKeyForCurrentSession];
    if (storageKey.length == 0) {
        storageKey = [self dialogueStorageKeyForPersona:self.currentPersona];
    }
    if (storageKey.length > 0) {
        [self removePersistedDialogueDataForStorageKey:storageKey];
        [self removePersistedContactsDataForStorageKey:storageKey];
    }
    [self clearInMemoryDialogueData];
    [self clearInMemoryContactsData];
}

- (void)reloadDialogueDataForCurrentAccount {
    [self clearInMemoryDialogueData];
    [self clearInMemoryContactsData];
    if (![self canAccessDialogueData]) {
        [self notifyDialogueDataDidChange];
        [self notifyContactsDataDidChange];
        return;
    }
    [self migrateLegacyGlobalDialogueDataIfNeeded];
    [self migrateLegacyGlobalContactsDataIfNeeded];
    [self loadDenyListedContactIds];
    [self loadSavedContacts];
    [self loadSavedConversationDialogueItems];
    [self loadSavedPartyDialogueItems];
    [self notifyDialogueDataDidChange];
    [self notifyContactsDataDidChange];
}

- (void)migrateLegacyGlobalDialogueDataIfNeeded {
    NSString *accountKey = [self dialogueStorageKeyForCurrentSession];
    if (accountKey.length == 0) {
        return;
    }

    NSString *migrationFlagKey = [NSString stringWithFormat:@"%@%@", kHangoDialogueLegacyMigratedPrefix, accountKey];
    if ([NSUserDefaults.standardUserDefaults boolForKey:migrationFlagKey]) {
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults objectForKey:[self scopedDefaultsKey:kHangoConversationDialogueKey]]) {
        [defaults setBool:YES forKey:migrationFlagKey];
        [defaults synchronize];
        return;
    }

    NSDictionary *legacyConversationDialogue = [defaults dictionaryForKey:kHangoConversationDialogueKey];
    NSArray *legacyContactIds = [defaults arrayForKey:kHangoConversationContactIdsKey];
    NSDictionary *legacyPartyDialogue = [defaults dictionaryForKey:kHangoPartyDialogueKey];
    NSArray *legacyPartyIds = [defaults arrayForKey:kHangoPartyConversationIdsKey];
    NSArray *legacyThreadOrder = [defaults arrayForKey:kHangoDialogueThreadOrderKey];
    BOOL hasLegacyData = legacyConversationDialogue.count > 0
        || legacyPartyDialogue.count > 0
        || legacyContactIds.count > 0
        || legacyPartyIds.count > 0
        || legacyThreadOrder.count > 0;
    if (!hasLegacyData) {
        [defaults setBool:YES forKey:migrationFlagKey];
        [defaults synchronize];
        return;
    }

    if (legacyConversationDialogue) {
        [defaults setObject:legacyConversationDialogue forKey:[self scopedDefaultsKey:kHangoConversationDialogueKey]];
    }
    if (legacyContactIds) {
        [defaults setObject:legacyContactIds forKey:[self scopedDefaultsKey:kHangoConversationContactIdsKey]];
    }
    if (legacyPartyDialogue) {
        [defaults setObject:legacyPartyDialogue forKey:[self scopedDefaultsKey:kHangoPartyDialogueKey]];
    }
    if (legacyPartyIds) {
        [defaults setObject:legacyPartyIds forKey:[self scopedDefaultsKey:kHangoPartyConversationIdsKey]];
    }
    if (legacyThreadOrder) {
        [defaults setObject:legacyThreadOrder forKey:[self scopedDefaultsKey:kHangoDialogueThreadOrderKey]];
    }

    [defaults removeObjectForKey:kHangoConversationDialogueKey];
    [defaults removeObjectForKey:kHangoConversationContactIdsKey];
    [defaults removeObjectForKey:kHangoPartyDialogueKey];
    [defaults removeObjectForKey:kHangoPartyConversationIdsKey];
    [defaults removeObjectForKey:kHangoDialogueThreadOrderKey];
    [defaults setBool:YES forKey:migrationFlagKey];
    [defaults synchronize];
}

- (void)migratePersistedDialogueDataFromKey:(NSString *)fromKey toKey:(NSString *)toKey {
    if (fromKey.length == 0 || toKey.length == 0 || [fromKey isEqualToString:toKey]) {
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSArray<NSString *> *baseKeys = @[
        kHangoConversationDialogueKey,
        kHangoConversationContactIdsKey,
        kHangoPartyDialogueKey,
        kHangoPartyConversationIdsKey,
        kHangoDialogueThreadOrderKey,
        kHangoSavedContactsKey,
        kHangoDeniedContactIdsKey
    ];
    for (NSString *baseKey in baseKeys) {
        NSString *fromScopedKey = [self scopedDefaultsKey:baseKey storageKey:fromKey];
        NSString *toScopedKey = [self scopedDefaultsKey:baseKey storageKey:toKey];
        id value = [defaults objectForKey:fromScopedKey];
        if (value && ![defaults objectForKey:toScopedKey]) {
            [defaults setObject:value forKey:toScopedKey];
        }
        [defaults removeObjectForKey:fromScopedKey];
    }

    NSString *fromSeededKey = [self scopedDefaultsKey:kHangoDefaultContactsSeededKey storageKey:fromKey];
    NSString *toSeededKey = [self scopedDefaultsKey:kHangoDefaultContactsSeededKey storageKey:toKey];
    if ([defaults objectForKey:fromSeededKey] && ![defaults objectForKey:toSeededKey]) {
        [defaults setBool:[defaults boolForKey:fromSeededKey] forKey:toSeededKey];
    }
    [defaults removeObjectForKey:fromSeededKey];
    [defaults synchronize];
}

- (void)removePersistedContactsDataForStorageKey:(NSString *)storageKey {
    if (storageKey.length == 0) {
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSArray<NSString *> *baseKeys = @[
        kHangoSavedContactsKey,
        kHangoDeniedContactIdsKey
    ];
    for (NSString *baseKey in baseKeys) {
        [defaults removeObjectForKey:[self scopedDefaultsKey:baseKey storageKey:storageKey]];
    }
    [defaults removeObjectForKey:[self scopedDefaultsKey:kHangoDefaultContactsSeededKey storageKey:storageKey]];
    [defaults removeObjectForKey:[NSString stringWithFormat:@"%@%@", kHangoContactsLegacyMigratedPrefix, storageKey]];
    [defaults synchronize];
}

- (void)migrateLegacyGlobalContactsDataIfNeeded {
    NSString *accountKey = [self dialogueStorageKeyForCurrentSession];
    if (accountKey.length == 0) {
        return;
    }

    NSString *migrationFlagKey = [NSString stringWithFormat:@"%@%@", kHangoContactsLegacyMigratedPrefix, accountKey];
    if ([NSUserDefaults.standardUserDefaults boolForKey:migrationFlagKey]) {
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults objectForKey:[self scopedDefaultsKey:kHangoSavedContactsKey]]) {
        [defaults setBool:YES forKey:migrationFlagKey];
        [defaults synchronize];
        return;
    }

    NSArray *legacyContacts = [defaults arrayForKey:kHangoSavedContactsKey];
    NSArray *legacyDeniedIds = [defaults arrayForKey:kHangoDeniedContactIdsKey];
    BOOL legacySeeded = [defaults boolForKey:kHangoDefaultContactsSeededKey];
    BOOL hasLegacyData = legacyContacts.count > 0 || legacyDeniedIds.count > 0 || legacySeeded;
    if (!hasLegacyData) {
        [defaults setBool:YES forKey:migrationFlagKey];
        [defaults synchronize];
        return;
    }

    if ([self shouldSeedDefaultContactsForCurrentAccount]) {
        if (legacyContacts) {
            [defaults setObject:legacyContacts forKey:[self scopedDefaultsKey:kHangoSavedContactsKey]];
        }
        if (legacyDeniedIds) {
            [defaults setObject:legacyDeniedIds forKey:[self scopedDefaultsKey:kHangoDeniedContactIdsKey]];
        }
        if (legacySeeded) {
            NSString *scopedSeededKey = [self scopedDefaultsKey:kHangoDefaultContactsSeededKey];
            if (scopedSeededKey.length > 0) {
                [defaults setBool:YES forKey:scopedSeededKey];
            }
        }
    }

    [defaults removeObjectForKey:kHangoSavedContactsKey];
    [defaults removeObjectForKey:kHangoDeniedContactIdsKey];
    [defaults removeObjectForKey:kHangoDefaultContactsSeededKey];
    [defaults setBool:YES forKey:migrationFlagKey];
    [defaults synchronize];
}

- (void)removePersistedDialogueDataForStorageKey:(NSString *)storageKey {
    if (storageKey.length == 0) {
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSArray<NSString *> *baseKeys = @[
        kHangoConversationDialogueKey,
        kHangoConversationContactIdsKey,
        kHangoPartyDialogueKey,
        kHangoPartyConversationIdsKey,
        kHangoDialogueThreadOrderKey
    ];
    for (NSString *baseKey in baseKeys) {
        [defaults removeObjectForKey:[self scopedDefaultsKey:baseKey storageKey:storageKey]];
    }
    [defaults removeObjectForKey:[NSString stringWithFormat:@"%@%@", kHangoDialogueLegacyMigratedPrefix, storageKey]];
    [defaults synchronize];
}

- (void)loadSavedConversationDialogueItems {
    NSString *scopedDialogueKey = [self scopedDefaultsKey:kHangoConversationDialogueKey];
    if (scopedDialogueKey.length == 0) {
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSDictionary *savedDialogueItems = [defaults dictionaryForKey:scopedDialogueKey];
    if ([savedDialogueItems isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary<NSString *, NSMutableArray<HangoDialogueItem *> *> *loaded = [NSMutableDictionary dictionary];
        [savedDialogueItems enumerateKeysAndObjectsUsingBlock:^(NSString *conversationId, NSArray *itemDicts, BOOL *stop) {
            if (![itemDicts isKindOfClass:NSArray.class]) {
                return;
            }
            NSMutableArray<HangoDialogueItem *> *dialogueItems = [NSMutableArray array];
            for (NSDictionary *dict in itemDicts) {
                if ([dict isKindOfClass:NSDictionary.class]) {
                    [dialogueItems addObject:[self dialogueItemFromDictionary:dict]];
                }
            }
            if (dialogueItems.count > 0) {
                loaded[conversationId] = dialogueItems;
            }
        }];
        self.conversationDialogueItems = loaded;
    }

    NSArray<NSString *> *savedContactIds = [defaults arrayForKey:[self scopedDefaultsKey:kHangoConversationContactIdsKey]];
    if ([savedContactIds isKindOfClass:NSArray.class]) {
        self.conversationContactIds = savedContactIds.mutableCopy;
    }

    NSArray<NSString *> *savedThreadOrder = [defaults arrayForKey:[self scopedDefaultsKey:kHangoDialogueThreadOrderKey]];
    if ([savedThreadOrder isKindOfClass:NSArray.class]) {
        self.dialogueThreadOrder = savedThreadOrder.mutableCopy;
    } else {
        [self rebuildDialogueThreadOrderFromLegacyLists];
    }
    [self rebuildConversationsList];
}

- (void)rebuildDialogueThreadOrderFromLegacyLists {
    [self.dialogueThreadOrder removeAllObjects];
    for (NSString *contactId in self.conversationContactIds) {
        [self.dialogueThreadOrder addObject:[self privateThreadKeyForContactId:contactId]];
    }
    for (NSString *partyId in self.partyConversationPartyIds) {
        [self.dialogueThreadOrder addObject:[self partyThreadKeyForPartyId:partyId]];
    }
}

- (void)loadSavedPartyDialogueItems {
    NSString *scopedDialogueKey = [self scopedDefaultsKey:kHangoPartyDialogueKey];
    if (scopedDialogueKey.length == 0) {
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSDictionary *savedDialogueItems = [defaults dictionaryForKey:scopedDialogueKey];
    if ([savedDialogueItems isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary<NSString *, NSMutableArray<HangoDialogueItem *> *> *loaded = [NSMutableDictionary dictionary];
        [savedDialogueItems enumerateKeysAndObjectsUsingBlock:^(NSString *partyId, NSArray *itemDicts, BOOL *stop) {
            if (![itemDicts isKindOfClass:NSArray.class]) {
                return;
            }
            NSMutableArray<HangoDialogueItem *> *dialogueItems = [NSMutableArray array];
            for (NSDictionary *dict in itemDicts) {
                if ([dict isKindOfClass:NSDictionary.class]) {
                    [dialogueItems addObject:[self dialogueItemFromDictionary:dict]];
                }
            }
            if (dialogueItems.count > 0) {
                loaded[partyId] = dialogueItems;
            }
        }];
        self.partyDialogueItems = loaded;
    }

    NSArray<NSString *> *savedPartyIds = [defaults arrayForKey:[self scopedDefaultsKey:kHangoPartyConversationIdsKey]];
    if ([savedPartyIds isKindOfClass:NSArray.class]) {
        self.partyConversationPartyIds = savedPartyIds.mutableCopy;
    }
}

- (void)savePartyConversationData {
    if (![self canAccessDialogueData]) {
        return;
    }

    NSMutableDictionary *serialized = [NSMutableDictionary dictionary];
    [self.partyDialogueItems enumerateKeysAndObjectsUsingBlock:^(NSString *partyId, NSMutableArray<HangoDialogueItem *> *dialogueItems, BOOL *stop) {
        NSMutableArray *itemDicts = [NSMutableArray array];
        for (HangoDialogueItem *dialogueItem in dialogueItems) {
            [itemDicts addObject:[self dictionaryFromDialogueItem:dialogueItem]];
        }
        serialized[partyId] = itemDicts;
    }];

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:serialized forKey:[self scopedDefaultsKey:kHangoPartyDialogueKey]];
    [defaults setObject:self.partyConversationPartyIds.copy forKey:[self scopedDefaultsKey:kHangoPartyConversationIdsKey]];
    [defaults setObject:self.dialogueThreadOrder.copy forKey:[self scopedDefaultsKey:kHangoDialogueThreadOrderKey]];
    [defaults synchronize];
}

- (void)saveConversationData {
    if (![self canAccessDialogueData]) {
        return;
    }

    NSMutableDictionary *serialized = [NSMutableDictionary dictionary];
    [self.conversationDialogueItems enumerateKeysAndObjectsUsingBlock:^(NSString *conversationId, NSMutableArray<HangoDialogueItem *> *dialogueItems, BOOL *stop) {
        NSMutableArray *itemDicts = [NSMutableArray array];
        for (HangoDialogueItem *dialogueItem in dialogueItems) {
            [itemDicts addObject:[self dictionaryFromDialogueItem:dialogueItem]];
        }
        serialized[conversationId] = itemDicts;
    }];

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:serialized forKey:[self scopedDefaultsKey:kHangoConversationDialogueKey]];
    [defaults setObject:self.conversationContactIds.copy forKey:[self scopedDefaultsKey:kHangoConversationContactIdsKey]];
    [defaults setObject:self.dialogueThreadOrder.copy forKey:[self scopedDefaultsKey:kHangoDialogueThreadOrderKey]];
    [defaults synchronize];
}

- (NSString *)partyPhotosDirectoryPath {
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [documents stringByAppendingPathComponent:kHangoPartyPhotosFolderName];
}

- (NSString *)storedPartyPhotoPathForAbsolutePath:(NSString *)absolutePath {
    if (absolutePath.length == 0) {
        return nil;
    }
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if ([absolutePath hasPrefix:documents]) {
        NSString *relative = [absolutePath substringFromIndex:documents.length];
        if ([relative hasPrefix:@"/"]) {
            relative = [relative substringFromIndex:1];
        }
        return relative;
    }
    return absolutePath;
}

- (NSString *)resolvedPartyPhotoPath:(NSString *)storedPath {
    if (storedPath.length == 0) {
        return nil;
    }
    if ([storedPath hasPrefix:@"/"]) {
        return storedPath;
    }
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [documents stringByAppendingPathComponent:storedPath];
}

- (void)seedAttendedPartyRecordPhotosIfNeeded {
    [self migrateAttendedPartyStoredPhotosIfNeeded];
}

- (void)migrateAttendedPartyStoredPhotosIfNeeded {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults boolForKey:kHangoAttendedPartyPhotoMergeMigrationKey]) {
        return;
    }

    NSArray<NSString *> *attendedPartyIds = @[@"attended_1", @"attended_2", @"attended_3", @"attended_4"];
    for (NSString *partyId in attendedPartyIds) {
        NSMutableArray<NSString *> *paths = self.partyRecordPhotoPaths[partyId];
        if (!paths || paths.count == 0) {
            continue;
        }

        NSInteger seededCount = [self attendedPartyPhotoAssetNamesForPartyId:partyId].count;
        NSInteger removeCount = MIN((NSInteger)paths.count, seededCount);
        for (NSInteger i = 0; i < removeCount; i++) {
            NSString *storedPath = paths.firstObject;
            NSString *resolved = [self resolvedPartyPhotoPath:storedPath];
            if (resolved.length > 0) {
                [NSFileManager.defaultManager removeItemAtPath:resolved error:nil];
            }
            [paths removeObjectAtIndex:0];
        }
        if (paths.count == 0) {
            [self.partyRecordPhotoPaths removeObjectForKey:partyId];
        }
    }

    [self savePartyRecordPhotos];
    [defaults setBool:YES forKey:kHangoAttendedPartyPhotoMergeMigrationKey];
    [defaults setBool:YES forKey:kHangoAttendedPartyPhotosSeedKey];
    [defaults synchronize];
}

- (void)loadPartyRecordPhotos {
    NSDictionary *saved = [NSUserDefaults.standardUserDefaults dictionaryForKey:kHangoPartyRecordPhotosKey];
    self.partyRecordPhotoPaths = [NSMutableDictionary dictionary];
    if (![saved isKindOfClass:NSDictionary.class]) {
        return;
    }
    [saved enumerateKeysAndObjectsUsingBlock:^(NSString *partyId, NSArray *paths, BOOL *stop) {
        if (![paths isKindOfClass:NSArray.class]) {
            return;
        }
        NSMutableArray<NSString *> *validPaths = [NSMutableArray array];
        for (NSString *path in paths) {
            if (![path isKindOfClass:NSString.class] || path.length == 0) {
                continue;
            }
            NSString *resolved = [self resolvedPartyPhotoPath:path];
            if ([NSFileManager.defaultManager fileExistsAtPath:resolved]) {
                [validPaths addObject:[self storedPartyPhotoPathForAbsolutePath:resolved] ?: path];
            }
        }
        if (validPaths.count > 0) {
            self.partyRecordPhotoPaths[partyId] = validPaths;
        }
    }];
    [self savePartyRecordPhotos];
}

- (void)savePartyRecordPhotos {
    NSMutableDictionary *serialized = [NSMutableDictionary dictionary];
    [self.partyRecordPhotoPaths enumerateKeysAndObjectsUsingBlock:^(NSString *partyId, NSMutableArray<NSString *> *paths, BOOL *stop) {
        serialized[partyId] = paths.copy;
    }];
    [NSUserDefaults.standardUserDefaults setObject:serialized forKey:kHangoPartyRecordPhotosKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (NSArray<NSString *> *)partyRecordPhotoPathsForPartyId:(NSString *)partyId {
    NSArray<NSString *> *storedPaths = [self.partyRecordPhotoPaths[partyId] copy] ?: @[];
    NSMutableArray<NSString *> *resolvedPaths = [NSMutableArray arrayWithCapacity:storedPaths.count];
    for (NSString *path in storedPaths) {
        NSString *resolved = [self resolvedPartyPhotoPath:path];
        if (resolved.length > 0) {
            [resolvedPaths addObject:resolved];
        }
    }
    return resolvedPaths.copy;
}

- (NSArray<NSString *> *)attendedPartyPhotoAssetNamesForPartyId:(NSString *)partyId {
    static NSDictionary<NSString *, NSArray<NSString *> *> *mapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mapping = @{
            @"attended_1": @[@"party_record_1_1", @"party_record_1_2", @"party_record_1_3"],
            @"attended_2": @[@"party_record_2_1", @"party_record_2_2", @"party_record_2_3"],
            @"attended_3": @[@"party_record_3_1", @"party_record_3_2"],
            @"attended_4": @[@"party_record_4_1", @"party_record_4_2", @"party_record_4_3"],
        };
    });
    return partyId.length > 0 ? (mapping[partyId] ?: @[]) : @[];
}

- (NSInteger)builtinPartyRecordPhotoCountForPartyId:(NSString *)partyId {
    NSInteger count = 0;
    for (NSString *assetName in [self attendedPartyPhotoAssetNamesForPartyId:partyId]) {
        if ([HangoTheme imageNamed:assetName]) {
            count += 1;
        }
    }
    return count;
}

- (UIImage *)latestPartyRecordPhotoImageForPartyId:(NSString *)partyId {
    NSArray<UIImage *> *images = [self partyRecordPhotoImagesForPartyId:partyId];
    return images.lastObject;
}

- (NSArray<UIImage *> *)partyRecordPhotoImagesForPartyId:(NSString *)partyId {
    HangoParty *party = [self partyWithId:partyId];
    if ([self isPartyHostDenied:party]) {
        return @[];
    }

    NSMutableArray<UIImage *> *images = [NSMutableArray array];
    NSArray<NSString *> *assetNames = [self attendedPartyPhotoAssetNamesForPartyId:partyId];
    if (assetNames.count > 0) {
        NSSet<NSNumber *> *hiddenIndexes = [NSSet setWithArray:[self hiddenBuiltinPhotoIndexesForPartyId:partyId]];
        for (NSInteger i = 0; i < (NSInteger)assetNames.count; i++) {
            if ([hiddenIndexes containsObject:@(i)]) {
                continue;
            }
            UIImage *image = [HangoTheme imageNamed:assetNames[i]];
            if (image) {
                [images addObject:image];
            }
        }
    }

    for (NSString *path in [self partyRecordPhotoPathsForPartyId:partyId]) {
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        if (image) {
            [images addObject:image];
        }
    }
    return images.copy;
}

- (NSString *)savePartyRecordPhotoImage:(UIImage *)image partyId:(NSString *)partyId {
    if (!image || partyId.length == 0) {
        return nil;
    }
    NSData *data = UIImageJPEGRepresentation(image, 0.88);
    if (!data) {
        return nil;
    }
    NSString *directory = [self partyPhotosDirectoryPath];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *fileName = [NSString stringWithFormat:@"party_%@_%@.jpg", partyId, NSUUID.UUID.UUIDString];
    NSString *absolutePath = [directory stringByAppendingPathComponent:fileName];
    if (![data writeToFile:absolutePath atomically:YES]) {
        return nil;
    }
    NSString *storedPath = [NSString stringWithFormat:@"%@/%@", kHangoPartyPhotosFolderName, fileName];
    if (!self.partyRecordPhotoPaths[partyId]) {
        self.partyRecordPhotoPaths[partyId] = [NSMutableArray array];
    }
    [self.partyRecordPhotoPaths[partyId] addObject:storedPath];
    [self savePartyRecordPhotos];
    return absolutePath;
}

- (NSString *)dialogueImagesDirectoryPath {
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [documents stringByAppendingPathComponent:kHangoDialogueImagesFolderName];
}

- (NSString *)saveConversationDialogueImage:(UIImage *)image conversationId:(NSString *)conversationId {
    if (!image || conversationId.length == 0) {
        return nil;
    }
    NSData *data = UIImageJPEGRepresentation(image, 0.88);
    if (!data) {
        return nil;
    }
    NSString *directory = [self dialogueImagesDirectoryPath];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *fileName = [NSString stringWithFormat:@"chat_%@_%@.jpg", conversationId, NSUUID.UUID.UUIDString];
    NSString *absolutePath = [directory stringByAppendingPathComponent:fileName];
    if (![data writeToFile:absolutePath atomically:YES]) {
        return nil;
    }
    return absolutePath;
}

- (BOOL)removePartyRecordPhotoAtIndex:(NSInteger)index partyId:(NSString *)partyId {
    if (partyId.length == 0) {
        return NO;
    }
    NSMutableArray<NSString *> *paths = self.partyRecordPhotoPaths[partyId];
    if (!paths || index < 0 || index >= (NSInteger)paths.count) {
        return NO;
    }
    NSString *storedPath = paths[index];
    NSString *resolvedPath = [self resolvedPartyPhotoPath:storedPath];
    if (resolvedPath.length > 0) {
        [NSFileManager.defaultManager removeItemAtPath:resolvedPath error:nil];
    }
    [paths removeObjectAtIndex:index];
    if (paths.count == 0) {
        [self.partyRecordPhotoPaths removeObjectForKey:partyId];
    }
    [self savePartyRecordPhotos];
    return YES;
}

- (NSArray<NSNumber *> *)hiddenBuiltinPhotoIndexesForPartyId:(NSString *)partyId {
    if (partyId.length == 0) {
        return @[];
    }
    return [self.hiddenBuiltinPartyPhotoIndexes[partyId] copy] ?: @[];
}

- (void)loadHiddenBuiltinPartyPhotos {
    self.hiddenBuiltinPartyPhotoIndexes = [NSMutableDictionary dictionary];
    NSDictionary *saved = [NSUserDefaults.standardUserDefaults dictionaryForKey:kHangoHiddenBuiltinPartyPhotosKey];
    if (![saved isKindOfClass:NSDictionary.class]) {
        return;
    }
    [saved enumerateKeysAndObjectsUsingBlock:^(NSString *partyId, id indexes, BOOL *stop) {
        if (![partyId isKindOfClass:NSString.class] || ![indexes isKindOfClass:NSArray.class]) {
            return;
        }
        NSMutableArray<NSNumber *> *hidden = [NSMutableArray array];
        for (id value in (NSArray *)indexes) {
            if ([value isKindOfClass:NSNumber.class]) {
                [hidden addObject:value];
            }
        }
        if (hidden.count > 0) {
            self.hiddenBuiltinPartyPhotoIndexes[partyId] = hidden;
        }
    }];
}

- (void)saveHiddenBuiltinPartyPhotos {
    NSMutableDictionary<NSString *, NSArray<NSNumber *> *> *payload = [NSMutableDictionary dictionary];
    [self.hiddenBuiltinPartyPhotoIndexes enumerateKeysAndObjectsUsingBlock:^(NSString *partyId, NSMutableArray<NSNumber *> *indexes, BOOL *stop) {
        if (partyId.length > 0 && indexes.count > 0) {
            payload[partyId] = indexes.copy;
        }
    }];
    [NSUserDefaults.standardUserDefaults setObject:payload forKey:kHangoHiddenBuiltinPartyPhotosKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (NSInteger)visibleBuiltinPartyRecordPhotoCountForPartyId:(NSString *)partyId {
    NSInteger count = 0;
    NSArray<NSString *> *assetNames = [self attendedPartyPhotoAssetNamesForPartyId:partyId];
    NSSet<NSNumber *> *hiddenIndexes = [NSSet setWithArray:[self hiddenBuiltinPhotoIndexesForPartyId:partyId]];
    for (NSInteger i = 0; i < (NSInteger)assetNames.count; i++) {
        if ([hiddenIndexes containsObject:@(i)]) {
            continue;
        }
        if ([HangoTheme imageNamed:assetNames[i]]) {
            count += 1;
        }
    }
    return count;
}

- (BOOL)isCurrentUserPartyRecordPhotoAtDisplayIndex:(NSInteger)displayIndex partyId:(NSString *)partyId {
    if (partyId.length == 0 || displayIndex < 0) {
        return NO;
    }
    return displayIndex >= [self visibleBuiltinPartyRecordPhotoCountForPartyId:partyId];
}

- (BOOL)removePartyRecordPhotoAtDisplayIndex:(NSInteger)displayIndex partyId:(NSString *)partyId {
    if (partyId.length == 0 || displayIndex < 0) {
        return NO;
    }

    NSArray<NSString *> *assetNames = [self attendedPartyPhotoAssetNamesForPartyId:partyId];
    if (assetNames.count == 0) {
        return [self removePartyRecordPhotoAtIndex:displayIndex partyId:partyId];
    }

    NSSet<NSNumber *> *hiddenIndexes = [NSSet setWithArray:[self hiddenBuiltinPhotoIndexesForPartyId:partyId]];
    NSInteger visibleBuiltinIndex = 0;
    for (NSInteger assetIndex = 0; assetIndex < (NSInteger)assetNames.count; assetIndex++) {
        if ([hiddenIndexes containsObject:@(assetIndex)]) {
            continue;
        }
        if (visibleBuiltinIndex == displayIndex) {
            NSMutableArray<NSNumber *> *hidden = self.hiddenBuiltinPartyPhotoIndexes[partyId];
            if (!hidden) {
                hidden = [NSMutableArray array];
                self.hiddenBuiltinPartyPhotoIndexes[partyId] = hidden;
            }
            if (![hidden containsObject:@(assetIndex)]) {
                [hidden addObject:@(assetIndex)];
            }
            [self saveHiddenBuiltinPartyPhotos];
            return YES;
        }
        visibleBuiltinIndex += 1;
    }

    NSInteger uploadedIndex = displayIndex - visibleBuiltinIndex;
    return [self removePartyRecordPhotoAtIndex:uploadedIndex partyId:partyId];
}

- (void)loadDecorationCounts {
    NSDictionary *saved = [NSUserDefaults.standardUserDefaults dictionaryForKey:kHangoDecorationCountsKey];
    self.decorationCounts = [NSMutableDictionary dictionary];
    if (![saved isKindOfClass:NSDictionary.class]) {
        return;
    }
    [saved enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSNumber *count, BOOL *stop) {
        if ([name isKindOfClass:NSString.class] && [count isKindOfClass:NSNumber.class]) {
            self.decorationCounts[name] = @(MAX(0, count.integerValue));
        }
    }];
}

- (void)saveDecorationCounts {
    [NSUserDefaults.standardUserDefaults setObject:self.decorationCounts.copy forKey:kHangoDecorationCountsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (NSInteger)decorationCountForName:(NSString *)name {
    if (name.length == 0) {
        return 0;
    }
    return [self.decorationCounts[name] integerValue];
}

- (void)addDecorationCount:(NSInteger)amount forName:(NSString *)name {
    if (name.length == 0 || amount <= 0) {
        return;
    }
    NSInteger current = [self decorationCountForName:name];
    self.decorationCounts[name] = @(current + amount);
    [self saveDecorationCounts];
}

- (BOOL)consumeDecorationWithName:(NSString *)name {
    if (name.length == 0) {
        return NO;
    }
    NSInteger current = [self decorationCountForName:name];
    if (current <= 0) {
        return NO;
    }
    self.decorationCounts[name] = @(current - 1);
    [self saveDecorationCounts];
    return YES;
}

- (BOOL)purchaseDecorationPackForName:(NSString *)name {
    if (name.length == 0) {
        return NO;
    }
    if (self.currentPersona.sparkleBalance < kHangoDecorationPurchaseSparkleCost) {
        return NO;
    }
    [self spendSparkles:kHangoDecorationPurchaseSparkleCost];
    [self addDecorationCount:kHangoDecorationPurchasePackSize forName:name];
    return YES;
}

- (void)clearDecorationCounts {
    [self.decorationCounts removeAllObjects];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:kHangoDecorationCountsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)clearPartyRecordPhotos {
    for (NSArray<NSString *> *paths in self.partyRecordPhotoPaths.allValues) {
        for (NSString *path in paths) {
            NSString *resolved = [self resolvedPartyPhotoPath:path];
            if (resolved.length > 0) {
                [NSFileManager.defaultManager removeItemAtPath:resolved error:nil];
            }
        }
    }
    [self.partyRecordPhotoPaths removeAllObjects];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:kHangoPartyRecordPhotosKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)clearConversationData {
    NSString *storageKey = [self dialogueStorageKeyForCurrentSession];
    [self clearInMemoryDialogueData];
    if (storageKey.length > 0) {
        [self removePersistedDialogueDataForStorageKey:storageKey];
    }
}

- (void)clearSavedPersonaProfile {
    if (self.currentPersona.avatarLocalPath.length > 0) {
        [NSFileManager.defaultManager removeItemAtPath:self.currentPersona.avatarLocalPath error:nil];
    }
    self.currentPersona.name = @"";
    self.currentPersona.avatarName = @"";
    self.currentPersona.avatarLocalPath = nil;
    self.currentPersona.sparkleBalance = 0;
    self.currentPersona.hostedPartyCount = 0;
    self.contacts = @[];
    self.deniedContactIds = [NSMutableSet set];
    self.hostedParties = @[];
    [self rebuildUpcomingPartiesList];

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:kHangoSavedPersonaNameKey];
    [defaults removeObjectForKey:kHangoSavedPersonaEmailKey];
    [defaults removeObjectForKey:kHangoSavedPersonaBioKey];
    [defaults removeObjectForKey:kHangoSavedPersonaAvatarNameKey];
    [defaults removeObjectForKey:kHangoSavedPersonaAvatarLocalPathKey];
    [defaults removeObjectForKey:kHangoSavedSparkleBalanceKey];
    [defaults removeObjectForKey:kHangoSavedHostedPartyCountKey];
    [defaults removeObjectForKey:kHangoSavedHostedPartiesKey];
    [defaults removeObjectForKey:kHangoSavedPersonaIdKey];
    [defaults synchronize];
    [self clearInMemoryContactsData];
    [self clearPartyRecordPhotos];
    [self clearDecorationCounts];
    self.currentPersona.personaId = @(kHangoBasePersonaId).stringValue;
}

- (BOOL)hasCompletedProfile {
    if (![self hasPersistedPersonaProfile]) {
        return NO;
    }
    NSString *trimmedName = [self.currentPersona.name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return trimmedName.length > 0;
}

- (BOOL)hasPersistedPersonaProfile {
    return [NSUserDefaults.standardUserDefaults stringForKey:kHangoSavedPersonaNameKey].length > 0;
}

- (void)applySeedProfileForTestAccountWithEmail:(NSString *)email {
    NSString *normalizedEmail = [[email stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] lowercaseString];
    NSString *oldStorageKey = [self dialogueStorageKeyForPersona:self.currentPersona];
    self.currentPersona.personaId = @(kHangoBasePersonaId).stringValue;
    [self savePersonaId];

    self.currentPersona.name = @"Palmer";
    self.currentPersona.email = normalizedEmail;
    if (self.currentPersona.bio.length == 0) {
        self.currentPersona.bio = @"";
    }

    if (self.currentPersona.avatarLocalPath.length > 0) {
        [NSFileManager.defaultManager removeItemAtPath:self.currentPersona.avatarLocalPath error:nil];
    }
    self.currentPersona.avatarName = @"Palmer";
    self.currentPersona.avatarLocalPath = nil;
    [self persistCurrentPersonaProfile];
    NSString *newStorageKey = [self dialogueStorageKeyForPersona:self.currentPersona];
    if (oldStorageKey.length > 0 && newStorageKey.length > 0 && ![oldStorageKey isEqualToString:newStorageKey]) {
        [self migratePersistedDialogueDataFromKey:oldStorageKey toKey:newStorageKey];
    }
}

- (void)persistCurrentPersonaProfile {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:self.currentPersona.name ?: @"" forKey:kHangoSavedPersonaNameKey];
    [defaults setObject:self.currentPersona.email ?: @"" forKey:kHangoSavedPersonaEmailKey];
    [defaults setObject:self.currentPersona.bio ?: @"" forKey:kHangoSavedPersonaBioKey];
    [defaults setObject:self.currentPersona.avatarName ?: @"" forKey:kHangoSavedPersonaAvatarNameKey];
    NSString *storedAvatarPath = [self storedAvatarPathForAbsolutePath:self.currentPersona.avatarLocalPath] ?: @"";
    [defaults setObject:storedAvatarPath forKey:kHangoSavedPersonaAvatarLocalPathKey];
    [defaults setObject:self.currentPersona.personaId ?: @"" forKey:kHangoSavedPersonaIdKey];
    [defaults synchronize];
}

- (void)updateCurrentPersonaProfileWithName:(NSString *)name
                                 avatarName:(NSString *)avatarName
                                  avatarImage:(UIImage *)avatarImage
                                          bio:(NSString *)bio {
    NSString *oldStorageKey = [self dialogueStorageKeyForPersona:self.currentPersona];
    NSString *trimmedName = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedName.length > 0) {
        self.currentPersona.name = trimmedName;
    }
    if (bio) {
        self.currentPersona.bio = bio;
    }

    if (avatarImage) {
        NSString *savedPath = [self saveAvatarImage:avatarImage];
        if (savedPath.length > 0) {
            NSString *previousPath = self.currentPersona.avatarLocalPath;
            self.currentPersona.avatarLocalPath = savedPath;
            self.currentPersona.avatarName = @"";
            if (previousPath.length > 0 && ![previousPath isEqualToString:savedPath]) {
                [NSFileManager.defaultManager removeItemAtPath:previousPath error:nil];
            }
        }
    } else if (avatarName.length > 0) {
        if (self.currentPersona.avatarLocalPath.length > 0) {
            [NSFileManager.defaultManager removeItemAtPath:self.currentPersona.avatarLocalPath error:nil];
        }
        self.currentPersona.avatarLocalPath = nil;
        self.currentPersona.avatarName = avatarName;
    }

    [self persistCurrentPersonaProfile];
    NSString *newStorageKey = [self dialogueStorageKeyForPersona:self.currentPersona];
    if (oldStorageKey.length > 0 && newStorageKey.length > 0 && ![oldStorageKey isEqualToString:newStorageKey]) {
        [self migratePersistedDialogueDataFromKey:oldStorageKey toKey:newStorageKey];
        [self reloadDialogueDataForCurrentAccount];
    }
}

- (void)updateCurrentPersonaProfileWithName:(NSString *)name avatarImage:(UIImage *)avatarImage {
    [self updateCurrentPersonaProfileWithName:name avatarName:nil avatarImage:avatarImage bio:nil];
}

- (NSString *)appleCredentialIdentifier {
    return [NSUserDefaults.standardUserDefaults stringForKey:kHangoAppleCredentialIdentifierKey];
}

- (NSString *)appleCachedDisplayName {
    return [self appleCachedDisplayNameForCredentialIdentifier:self.appleCredentialIdentifier];
}

- (NSString *)appleCachedDisplayNameForCredentialIdentifier:(NSString *)personaIdentifier {
    if (personaIdentifier.length == 0) {
        return nil;
    }
    NSString *storedUserId = [NSUserDefaults.standardUserDefaults stringForKey:kHangoAppleCredentialIdentifierKey];
    if (storedUserId.length == 0 || ![storedUserId isEqualToString:personaIdentifier]) {
        return nil;
    }
    return [NSUserDefaults.standardUserDefaults stringForKey:kHangoAppleDisplayNameKey];
}

- (NSString *)appleCachedEmail {
    return [NSUserDefaults.standardUserDefaults stringForKey:kHangoAppleEmailKey];
}

- (void)saveAppleSignInWithCredentialIdentifier:(NSString *)personaIdentifier
                                    email:(NSString *)email
                              displayName:(NSString *)displayName {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:personaIdentifier forKey:kHangoAppleCredentialIdentifierKey];

    if (email.length > 0) {
        [defaults setObject:email forKey:kHangoAppleEmailKey];
        self.currentPersona.email = email;
    } else {
        NSString *cachedEmail = [defaults stringForKey:kHangoAppleEmailKey];
        if (cachedEmail.length > 0) {
            self.currentPersona.email = cachedEmail;
        }
    }

    NSString *cachedName = [defaults stringForKey:kHangoAppleDisplayNameKey];
    NSString *resolvedName = displayName.length > 0 ? displayName : cachedName;
    if (displayName.length > 0) {
        [defaults setObject:displayName forKey:kHangoAppleDisplayNameKey];
    }
    if (resolvedName.length > 0 && ![self hasCompletedProfile]) {
        self.currentPersona.name = resolvedName;
    }

    [self persistCurrentPersonaProfile];
    [defaults synchronize];
}

- (void)clearAppleSignInCredentials {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:kHangoAppleCredentialIdentifierKey];
    [defaults removeObjectForKey:kHangoAppleDisplayNameKey];
    [defaults removeObjectForKey:kHangoAppleEmailKey];
    [defaults synchronize];
}

@end
