#import "HangoVoiceNoteManager.h"
#import <AVFoundation/AVFoundation.h>

NSString * const HangoVoicePlaybackStateDidChangeNotification = @"HangoVoicePlaybackStateDidChangeNotification";
NSString * const HangoVoicePlaybackPathKey = @"path";
NSString * const HangoVoicePlaybackPlayingKey = @"playing";

@interface HangoVoiceNoteManager ()
@property (nonatomic, strong, nullable) AVAudioRecorder *recorder;
@property (nonatomic, strong, nullable) AVAudioPlayer *player;
@property (nonatomic, copy, nullable) NSString *recordingPath;
@property (nonatomic, copy, nullable) NSString *playingPath;
@property (nonatomic, strong) dispatch_queue_t audioQueue;
@end

static void *kHangoVoiceAudioQueueContext = &kHangoVoiceAudioQueueContext;

@implementation HangoVoiceNoteManager

+ (instancetype)shared {
    static HangoVoiceNoteManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HangoVoiceNoteManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _audioQueue = dispatch_queue_create("com.hango.voice.audio", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_audioQueue, kHangoVoiceAudioQueueContext, kHangoVoiceAudioQueueContext, NULL);
    }
    return self;
}

- (NSString *)voiceNotesDirectory {
    NSString *cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *dir = [cache stringByAppendingPathComponent:@"VoiceNotes"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

- (NSString *)makeRecordingFilePath {
    return [[self voiceNotesDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a", NSUUID.UUID.UUIDString]];
}

- (void)performAudioSync:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    if (dispatch_get_specific(kHangoVoiceAudioQueueContext)) {
        block();
    } else {
        dispatch_sync(self.audioQueue, block);
    }
}

- (void)performAudioAsync:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    dispatch_async(self.audioQueue, block);
}

- (void)performOnMain:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (BOOL)isRecording {
    __block BOOL recording = NO;
    [self performAudioSync:^{
        recording = self.recorder.isRecording;
    }];
    return recording;
}

- (BOOL)isPlaying {
    __block BOOL playing = NO;
    [self performAudioSync:^{
        playing = self.player.isPlaying;
    }];
    return playing;
}

- (NSString *)currentPlayingPath {
    __block NSString *path = nil;
    [self performAudioSync:^{
        if (self.player.isPlaying) {
            path = [self.playingPath copy];
        }
    }];
    return path;
}

- (void)postPlaybackStateForPath:(NSString *)path playing:(BOOL)playing {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (path.length > 0) {
        userInfo[HangoVoicePlaybackPathKey] = path;
    }
    userInfo[HangoVoicePlaybackPlayingKey] = @(playing);
    NSDictionary *payload = userInfo.copy;
    [self performOnMain:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:HangoVoicePlaybackStateDidChangeNotification
                                                            object:self
                                                          userInfo:payload];
    }];
}

- (void)stopPlayerLocked {
    AVAudioPlayer *player = self.player;
    NSString *path = [self.playingPath copy];
    if (player) {
        player.delegate = nil;
        if (player.isPlaying) {
            [player stop];
        }
    }
    self.player = nil;
    self.playingPath = nil;
    if (path.length > 0) {
        [self postPlaybackStateForPath:path playing:NO];
    }
}

- (BOOL)configureAudioSessionForRecording:(NSError **)error {
    AVAudioSession *session = AVAudioSession.sharedInstance;
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth
                        error:error]) {
        return NO;
    }
    return [session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:error];
}

- (BOOL)startRecordingToPath:(NSString *)path error:(NSError **)error {
    if (path.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"HangoVoiceNoteManager" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Invalid recording path."}];
        }
        return NO;
    }

    __block BOOL started = NO;
    __block NSError *localError = nil;
    [self performAudioSync:^{
        [self cancelRecordingLocked];
        [self stopPlayerLocked];

        if (![self configureAudioSessionForRecording:&localError]) {
            return;
        }

        NSDictionary *settings = @{
            AVFormatIDKey: @(kAudioFormatMPEG4AAC),
            AVSampleRateKey: @44100.0,
            AVNumberOfChannelsKey: @1,
            AVEncoderAudioQualityKey: @(AVAudioQualityMedium)
        };

        NSURL *url = [NSURL fileURLWithPath:path];
        AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&localError];
        if (!recorder) {
            return;
        }

        recorder.meteringEnabled = NO;
        if (![recorder prepareToRecord] || ![recorder record]) {
            if (!localError) {
                localError = [NSError errorWithDomain:@"HangoVoiceNoteManager" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Unable to start recording."}];
            }
            return;
        }

        self.recorder = recorder;
        self.recordingPath = [path copy];
        started = YES;
    }];

    if (error) {
        *error = localError;
    }
    return started;
}

- (void)cancelRecordingLocked {
    AVAudioRecorder *recorder = self.recorder;
    NSString *path = self.recordingPath;
    self.recorder = nil;
    self.recordingPath = nil;

    if (recorder.isRecording) {
        [recorder stop];
    }
    if (path.length > 0) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

- (void)cancelRecording {
    [self performAudioSync:^{
        [self cancelRecordingLocked];
    }];
}

- (NSInteger)audioDurationForFileAtPath:(NSString *)path {
    if (path.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return 0;
    }

    NSURL *url = [NSURL fileURLWithPath:path];
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    if (player && player.duration > 0) {
        return MAX(1, MIN(60, (NSInteger)lrint(player.duration)));
    }

    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    Float64 seconds = CMTimeGetSeconds(asset.duration);
    if (seconds > 0 && isfinite(seconds)) {
        return MAX(1, MIN(60, (NSInteger)lrint(seconds)));
    }
    return 0;
}

- (BOOL)stopRecordingReturningDuration:(NSInteger *)outDuration filePath:(NSString **)outPath {
    __block BOOL stopped = NO;
    __block NSInteger duration = 0;
    __block NSString *path = nil;

    [self performAudioSync:^{
        AVAudioRecorder *recorder = self.recorder;
        NSString *recordingPath = [self.recordingPath copy];
        self.recorder = nil;
        self.recordingPath = nil;

        if (!recorder || recordingPath.length == 0) {
            return;
        }

        [recorder stop];
        NSTimeInterval seconds = recorder.currentTime;
        duration = MAX(1, MIN(60, (NSInteger)lrint(seconds)));
        path = recordingPath;
        NSInteger fileDuration = [self audioDurationForFileAtPath:recordingPath];
        if (fileDuration > 0) {
            duration = fileDuration;
        }
        stopped = YES;
    }];

    if (outDuration) {
        *outDuration = stopped ? duration : 0;
    }
    if (outPath) {
        *outPath = stopped ? path : nil;
    }
    return stopped;
}

- (void)playAudioAtPath:(NSString *)path {
    if (path.length == 0) {
        return;
    }

    [self performAudioAsync:^{
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return;
        }

        [self stopPlayerLocked];
        [self cancelRecordingLocked];

        NSError *error = nil;
        AVAudioSession *session = AVAudioSession.sharedInstance;
        if (![session setCategory:AVAudioSessionCategoryPlayback error:&error]) {
            return;
        }
        if (![session setActive:YES error:&error]) {
            return;
        }

        NSURL *url = [NSURL fileURLWithPath:path];
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        if (!player) {
            return;
        }

        player.delegate = self;
        self.player = player;
        self.playingPath = [path copy];
        if (![player play]) {
            player.delegate = nil;
            self.player = nil;
            self.playingPath = nil;
            return;
        }
        [self postPlaybackStateForPath:path playing:YES];
    }];
}

- (void)stopPlayback {
    [self performAudioSync:^{
        [self stopPlayerLocked];
    }];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    (void)flag;
    [self performAudioAsync:^{
        if (player != self.player) {
            return;
        }
        NSString *path = [self.playingPath copy];
        player.delegate = nil;
        self.player = nil;
        self.playingPath = nil;
        if (path.length > 0) {
            [self postPlaybackStateForPath:path playing:NO];
        }
    }];
}

@end
