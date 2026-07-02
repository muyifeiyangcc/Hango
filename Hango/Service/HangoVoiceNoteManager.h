#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const HangoVoicePlaybackStateDidChangeNotification;
FOUNDATION_EXPORT NSString * const HangoVoicePlaybackPathKey;
FOUNDATION_EXPORT NSString * const HangoVoicePlaybackPlayingKey;

@interface HangoVoiceNoteManager : NSObject <AVAudioPlayerDelegate>

+ (instancetype)shared;

- (BOOL)isRecording;
- (BOOL)isPlaying;
- (nullable NSString *)currentPlayingPath;
- (NSString *)makeRecordingFilePath;
- (BOOL)startRecordingToPath:(NSString *)path error:(NSError * _Nullable * _Nullable)error;
- (void)cancelRecording;
- (BOOL)stopRecordingReturningDuration:(NSInteger *)outDuration filePath:(NSString * _Nullable * _Nullable)outPath;
- (NSInteger)audioDurationForFileAtPath:(NSString *)path;
- (void)playAudioAtPath:(NSString *)path;
- (void)stopPlayback;

@end

NS_ASSUME_NONNULL_END
