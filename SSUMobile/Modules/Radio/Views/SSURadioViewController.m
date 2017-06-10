//
//  RadioViewController.m
//  SSUMobile
//
//  Created by Eric Amorde on 9/21/14.
//  Copyright (c) 2014 Sonoma State University Department of Computer Science. All rights reserved.
//

#import "SSURadioViewController.h"
#import "SSULogging.h"
#import "SSURadioConstants.h"
#import "SSUWebViewController.h"
#import "SSUMobile-Swift.h"

@import MediaPlayer;
@import AVFoundation;
@import SafariServices;

static NSString * SSURadioPlayerReadyMessage = @"Press play to start streaming";
static NSString * SSURadioPlayerLoadingMessage = @"Loading...";

static NSString * SSURadioButtonImagePlay = @"radio_play";
static NSString * SSURadioButtonImagePause = @"radio_pause";

@interface SSURadioViewController()

@property (nonatomic,getter=isPlaying) BOOL playing;

@end

@implementation SSURadioViewController

//Added by Danny 4/25/17
- (IBAction)calendarButton:(UIBarButtonItem *)sender {
}

//Added by Danny 4/25/17 --> Changed from previous method so another nav item could be added and for easier management
- (IBAction)systemAction:(UIBarButtonItem *)sender {
    [self actionButtonPressed:sender];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.elapsedLabel.text = SSURadioPlayerReadyMessage;
    self.title = @"KSUN Radio";
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:self.volumeSlider.bounds];
    [self.volumeSlider addSubview:volumeView];
    
    self.streamer = [SSURadioStreamer sharedInstance];
    self.streamer.delegate = self;
    
    // It's possible the radio is already playing
    self.playing = self.streamer.playing;
    [self updateButtonImage];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

#pragma mark -
#pragma mark - Notifications

/**
 Remote Control Notification
 
 This is called when the user interacts with the media controls on the lock screen
 or in the command center
 */
- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPause:
            case UIEventSubtypeRemoteControlPlay:
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self togglePlayer];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                break;
            default:
                break;
        }
    }
}

#pragma mark -
#pragma mark - Radio Controls

/**
 Toggles the stream between play and pause
 */
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

/**
 Plays the stream and updates the UI
 */
- (void) play
{
    [self.streamer play];
    self.elapsedLabel.text = SSURadioPlayerLoadingMessage;
    self.playing = YES;
    [self updateButtonImage];
}

/**
 Pauses the stream and updates the UI
 */
- (void) pause
{
    [self.streamer pause];
    self.elapsedLabel.text = SSURadioPlayerReadyMessage;
    self.playing = NO;
    [self updateButtonImage];
}

/*
 Stops the radio streamer
 This deactivates the audio session and removes the session from the MPNowPlayingInfoCenter and lock screen
 controls. Only call this in situations such as the application is about the terminate
 */
- (void) stop
{
    [self.streamer stop];
}

/**
 Takes a CMTime struct and returns a string in the format HH:mm:ss
 
 @param time CMTime to convert
 @return NSString representaiton of time
 */
- (NSString *) stringFromCMTime:(CMTime)time
{
    int totalSeconds = CMTimeGetSeconds(time);
    int hours = floor(totalSeconds / 3600);
    int minutes = floor(totalSeconds % 3600 / 60);
    int seconds = floor(totalSeconds % 3600 % 60);
    
    NSString *text = [NSString stringWithFormat:@"%d:%02d:%02d",hours, minutes, seconds];
    return text;
}

/**
 Updates the play/pause button based on whether or not the radio is currently playing
 */
- (void) updateButtonImage
{
    NSString * imageName = (self.isPlaying) ? SSURadioButtonImagePause : SSURadioButtonImagePlay;
    [self.button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

/* Segue added by Danny 4/25/17 to jump to new view for the calendar where a webview is loaded.
   This is done so you can use the default nav bar back button to go back to the radio 
   and not back to the home page
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"radioToCalendar"]) {
        SSURadioCalendarViewController *vc = [segue destinationViewController];
    }
}

#pragma mark -
#pragma mark - IBActions


/**
 Connected to the play/stop button
 
 @param sender: UIButton object
 */
- (IBAction)buttonPressed:(id)sender
{
    [self togglePlayer];
}

/**
 Connected to the progress slider
 
 This is called as the user is sliding the progress bar, while sliderFinished:
 is called when the user releases their finger from the slider. Here we do not want
 to actually seek the streamer to the location, but rather keep track of where the
 user slides and update the label to show them where they would be skipping to.
 
 @param aSlider: the sending UISlider, same as self.progressSlider
 */
- (IBAction)sliderMoved:(UISlider *)aSlider
{
    [self.streamer pause];
    CMTime sliderTime = CMTimeMakeWithSeconds(aSlider.value, self.streamer.timeScale);
    if (CMTimeGetSeconds(self.streamer.currentTime) > self.progressSlider.maximumValue)
    {
        // We've passed the maximum, so subtract from the current time
        sliderTime = CMTimeSubtract(self.streamer.currentTime, sliderTime);
    }
    self.elapsedLabel.text = [self stringFromCMTime:sliderTime];
}


/**
 Connected to the progress slider
 
 This is called when the user lets go of the slider button on the progress slider
 Here is where you want to actually seek to the desired location
 
 @param aSlider: the sending UISlider, same as self.progressSlider
 */
- (IBAction)sliderFinished:(UISlider *)slider
{
    float value = slider.value;
    CMTime sliderTime = CMTimeMakeWithSeconds(value, self.streamer.timeScale);
    if (CMTimeGetSeconds(self.streamer.currentTime) > self.progressSlider.maximumValue)
    {
        // We've passed the maximum, so subtract from the current time
        sliderTime = CMTimeSubtract(self.streamer.currentTime, sliderTime);
    }
    
    [self.streamer seekToTime:sliderTime];
}

#pragma mark -
#pragma mark - SSURadioStreamerDelegate

/**
 Part of the SSURadioStreamerDelegate protocol
 
 Called when the the streamer observes a change in the AVPlayer status property
 
 @param radioStreamer the current radio streamer
 @param status the new/current status
 
 @see AVPlayer, SSURadioStreamer
 */
- (void) streamer:(SSURadioStreamer *)radioStreamer playerStatusDidChange:(AVPlayerStatus)status
{
    SSULogDebug(@"%s",__FUNCTION__);
}


/**
 Part of the SSURadioStreamerDelegate protocol
 
 Called on a regular time interval. Use this to update the elapsedLabel text
 
 @param radioStreamer the current radio streamer
 @param time the current CMTime of the AVPlayer
 
 @see AVPlayer, SSURadioStreamer
 */
- (void) streamer:(SSURadioStreamer *)radioStreamer receivedTimeUpdate:(CMTime)time
{
    [self.progressSlider setEnabled:YES];
    [self.progressSlider setValue:CMTimeGetSeconds(time) animated:YES];
    self.elapsedLabel.text = [self stringFromCMTime:time];
}

#pragma mark -
#pragma mark - SSU Radio Webpage

/**
 Opens the SSU Radio webpage
 */
- (void) openSSURadioHomepage
{
    NSURL * url = [NSURL URLWithString:[[SSUConfiguration sharedInstance] stringForKey:SSURadioWebsiteURLKey]];
    if (NSStringFromClass([SFSafariViewController class])) {
        SFSafariViewController * vc = [[SFSafariViewController alloc] initWithURL:url
                                                          entersReaderIfAvailable:NO];
        vc.preferredBarTintColor = SSU_BLUE_COLOR;
        [self presentViewController:vc animated:YES completion:NULL];
    } else {
        SSUWebViewController* controller = [SSUWebViewController webViewController];
        controller.urlToLoad = url;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

/**
 Connected to the "action" button on the right of the navigation bar
 */
- (void) actionButtonPressed:(UIBarButtonItem *)barButton
{
    NSString * urlString = [[SSUConfiguration sharedInstance] stringForKey:SSURadioWebsiteURLKey];
    NSString * buttonTitle = [NSString stringWithFormat:@"Open %@", urlString];
    UIAlertController * controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [controller addAction:[UIAlertAction actionWithTitle:buttonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openSSURadioHomepage];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
    [self presentViewController:controller animated:YES completion:NULL];
}


#pragma mark -
#pragma mark - dealloc

- (void) dealloc
{
    
}


@end
