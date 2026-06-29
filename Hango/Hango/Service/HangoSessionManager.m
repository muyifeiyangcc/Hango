#import "HangoSessionManager.h"
#import "HangoDataStore.h"

static NSString * const kHangoIsLoggedInKey = @"HangoIsLoggedIn";

@interface HangoSessionManager ()
@property (nonatomic, assign, readwrite) BOOL isLoggedIn;
@property (nonatomic, strong, readwrite) HangoUser *currentUser;
@end

@implementation HangoSessionManager

+ (instancetype)shared {
    static HangoSessionManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HangoSessionManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentUser = [HangoDataStore shared].currentUser;
        _isLoggedIn = [NSUserDefaults.standardUserDefaults boolForKey:kHangoIsLoggedInKey];
    }
    return self;
}

- (void)persistLoginState {
    [NSUserDefaults.standardUserDefaults setBool:self.isLoggedIn forKey:kHangoIsLoggedInKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)loginWithEmail:(NSString *)email password:(NSString *)password {
    HangoUser *user = [HangoDataStore shared].currentUser;
    if (email.length) {
        user.email = email;
    }
    self.currentUser = user;
    self.isLoggedIn = YES;
    [self persistLoginState];
}

- (void)registerWithEmail:(NSString *)email password:(NSString *)password {
    HangoUser *user = [HangoDataStore shared].currentUser;
    user.email = email.length ? email : user.email;
    user.bio = @"";
    [[HangoDataStore shared] clearSavedUserProfile];
    self.currentUser = user;
    self.isLoggedIn = YES;
    [self persistLoginState];
}

- (void)updateProfileWithName:(NSString *)name avatarName:(NSString *)avatarName bio:(NSString *)bio {
    HangoUser *user = self.currentUser ?: [HangoDataStore shared].currentUser;
    if (name.length) {
        user.name = name;
    }
    if (avatarName.length) {
        user.avatarName = avatarName;
    }
    if (bio.length) {
        user.bio = bio;
    }
    self.currentUser = user;
}

- (void)updateProfileWithName:(NSString *)name avatarImage:(UIImage *)avatarImage {
    [[HangoDataStore shared] updateCurrentUserProfileWithName:name avatarImage:avatarImage];
    self.currentUser = [HangoDataStore shared].currentUser;
}

- (void)logout {
    self.isLoggedIn = NO;
    [self persistLoginState];
}

- (void)deleteAccount {
    self.isLoggedIn = NO;
    self.currentUser = nil;
    [self persistLoginState];
}

@end
