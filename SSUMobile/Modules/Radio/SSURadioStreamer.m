//
//  SSURadioStreamer.m
//  SSUMobile
//
//  Created by Eric Amorde on 9/22/14.
//  Copyright (c) 2014 Sonoma State University Department of Computer Science. All rights reserved.
//

@import MediaPlayer;

#import "SSURadioStreamer.h"
#import "SSULogging.h"
#import "SSUMobile-Swift.h"

static NSString * SSURadioNowPlayingSongTitle = @"KSUN Radio";
static NSString * SSURadioNowPlayingSongAlbum = @"Sonoma State University";
static NSString * SSURadioNowPlayingSongArtist = @"KSUN Radio";
static NSString * SSURadioNowPlayingAlbumArt = @"radio_album";


static SSURadioStreamer * _sharedInstance = nil;

@interface SSURadioStreamer() {
    id timeObserver;
    CMTime maxSeekTime;
}

@property (nonatomic, getter=isPlaying) BOOL playing;

@end

@implementation SSURadioStreamer

#pragma mark -
#pragma mark - Singleton

+ (SSURadioStreamer *) sharedInstance
{
    if (!_sharedInstance) {
        NSString * urlString = [[SSUConfiguration sharedInstance] objectForKey:SSURadioStreamURLKey];
        _sharedInstance = [[SSURadioStreamer alloc] initWithURL:[NSURL URLWithString:urlString]];
    }
    return _sharedInstance;
}

+ (void) setSharedInstance:(SSURadioStreamer *)sharedInstance
{
    _sharedInstance = sharedInstance;
}


#pragma mark -
#pragma mark - Init

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.playing = NO;
        timeObserver = nil;
        self.player = nil;
        self.timeScale = NSEC_PER_SEC;
        self.timeInterval = 1;
        maxSeekTime = CMTimeMakeWithSeconds(0, self.timeScale);
        
    }
    return self;
}

/**
 Initializes the SSURadioStreamer with the provided URL. Obviously, passing a bad URL here
 will result in the radio not functioning at all.
 
 @param URL the URL of KSUN's live stream
 */
- (instancetype) initWithURL:(NSURL *)URL
{
    self = [self init];
    if (self) {
        self.player = [[AVPlayer alloc] initWithURL:URL];
    }
    return self;
}

#pragma mark -
#pragma mark - Notifications

/**
 Register as an observer to to relevant key paths and notifications
 */
- (void) beginObserving
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
}

/**
 Remove self from all notifications and KVO
 */
- (void) endObserving
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) applicationWillTerminate:(NSNotification *)notification
{
    [self stop];
}

#pragma mark -
#pragma mark - Accessors

/**
 Returns the AVPlayer object's currentTime property
 
 @return currentTime property of AVPlayer
 */
- (CMTime) currentTime
{
    return self.player.currentTime;
}

 /**
 Returns the AVPlayer object's duration property
  
  @return duration property of player.currentItem
  */
- (CMTime) duration
{
    return self.player.currentItem.duration;
}

#pragma mark -
#pragma mark - AVAudioSession

/**
 Activates an AVAudioSession instance and places media information into MPNowPlayingInfoCenter
 so that the user can control the radio from the lock screen as well as the control center
 
 Calling this multiple times will not have adverse effects
 */
- (void) registerAudioSession
{
    // Register our audio session so the user can pause from the lockscreen and
    // allow the app sound to continue to play after leaving the app (pressing the home button).
    NSError * error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        SSULogError(@"Error registering for background playback: %@",error.userInfo[NSLocalizedDescriptionKey]);
    }
    error = nil;
    [[AVAudioSession sharedInstance] setActive:YES withOptions:0 error:&error];
    if (error) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:@"Unable to play KSUN radio. Please try again later."
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // Allow the user to control the radio with the now playing info center, and
    // show album art & track info on the lock screen
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:SSURadioNowPlayingAlbumArt]];
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{ MPMediaItemPropertyTitle : SSURadioNowPlayingSongTitle,
                                                               MPMediaItemPropertyArtist : SSURadioNowPlayingSongArtist,
                                                               MPMediaItemPropertyAlbumTitle : SSURadioNowPlayingSongAlbum,
                                                               MPMediaItemPropertyArtwork : artwork };
}

#pragma mark -
#pragma mark - Play/Pause/Stop/Seek

- (void) togglePlayer
{
    if (self.isPlaying)
    {
        [self pause];
    }
    else
    {
        [self play];
    }
}

- (void) play
{
    [self.player play];
    self.playing = YES;
    
    [self registerAudioSession];
    
    [self.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
    [self.player play];
}

- (void) pause
{
    [self.player pause];
    self.playing = NO;
}

- (void) stop
{
    // Pause the stream and allow any previous media to resume playback
    [self pause];
    [[AVAudioSession sharedInstance] setActive:NO
                                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:nil];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (void) seekToTime:(CMTime)time
{
    if (CMTIME_IS_INVALID(time))
    {
        [self play];
        return;
    }
    CMTimeShow(time);
    CMTimeShow(maxSeekTime);
    int comp = CMTimeCompare(time, maxSeekTime);
    if (comp == -1)
    {
        // Less
        [self.player seekToTime:time];
    }
    else
    {
        // Greater or equal;
    }
    [self play];
    
}

#pragma mark -
#pragma mark - Playback State

- (void) didBeginOrResumePlaying
{
    __weak id weakSelf = self;
    if (timeObserver) {
        [self.player removeTimeObserver:timeObserver];
        timeObserver = nil;
    }
    timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(self.timeInterval, self.timeScale) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf timeUpdate:time];
    }];
}

- (void) timeUpdate:(CMTime)time
{
    id<SSURadioStreamerDelegate> radioDelegate = self.delegate;
    if ([radioDelegate respondsToSelector:@selector(streamer:receivedTimeUpdate:)])
    {
        [radioDelegate streamer:self receivedTimeUpdate:time];
    }
    
    maxSeekTime = CMTimeMaximum(time, maxSeekTime);
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"] && [object isKindOfClass:[AVPlayer class]])
    {
        AVPlayer * player = (AVPlayer *)object;
        AVPlayerStatus status = [player status];
        if (self.player.status == AVPlayerStatusReadyToPlay && self.isPlaying)
        {
            [self didBeginOrResumePlaying];
        }
        if (self.player.status == AVPlayerStatusFailed && self.isPlaying)
        {
            [self stop];
            [self play];
        }
        if ([self.delegate respondsToSelector:@selector(streamer:playerStatusDidChange:)])
        {
            [self.delegate streamer:self playerStatusDidChange:status];
        }
    }
}

#pragma mark -
#pragma mark - Other

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self.player removeObserver:self forKeyPath:@"status"];
    [self.player removeTimeObserver:timeObserver];
    [self stop];
}



@end
