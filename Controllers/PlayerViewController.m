#import "PlayerViewController.h"

@interface PlayerViewController ()
{
	// Keys
	UIWindow *boundsWindow;
	BOOL deviceOrientation;
	NSString *playerAssetsBundlePath;
	NSBundle *playerAssetsBundle;

	// Player
	AVPlayerItem *playerItem;
	AVPlayer *player;
	AVPlayerLayer *playerLayer;
	AVPictureInPictureController *pictureInPictureController;
	UIImageView *videoImage;

	// Overlay
	UIView *overlayView;
	UIImageView *collapseImage;
	UIImageView *rewindImage;
	UIImageView *playImage;
	UIImageView *pauseImage;
	UIImageView *forwardImage;

	// Info
	UISlider *progressSlider;
	UILabel *videoTitleLabel;
	UILabel *videoInfoLabel;
	UIButton *shareButton;
}
- (void)keysSetup;
- (void)playerSetup;
- (void)overlaySetup;
- (void)infoSetup;
- (void)playerTimeChanged;
@end

@implementation PlayerViewController

- (void)loadView {
	[super loadView];

	self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
	[self.navigationController setNavigationBarHidden:YES animated:NO];

	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem = doneButton;

	[self keysSetup];
	[self playerSetup];
	[self overlaySetup];
	[self infoSetup];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)keysSetup {
	boundsWindow = [[UIApplication sharedApplication] keyWindow];
	deviceOrientation = 0;
	playerAssetsBundlePath = [[NSBundle mainBundle] pathForResource:@"PlayerAssets" ofType:@"bundle"];
	playerAssetsBundle = [NSBundle bundleWithPath:playerAssetsBundlePath];
}

- (void)playerSetup {
	if (self.videoStream != nil) {
		AVURLAsset *streamAsset = [[AVURLAsset alloc] initWithURL:self.videoStream options:nil];

		playerItem = [[AVPlayerItem alloc] initWithAsset:streamAsset];
		AVMediaSelectionGroup *subtitleSelectionGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
		[playerItem selectMediaOption:nil inMediaSelectionGroup:subtitleSelectionGroup];

		player = [AVPlayer playerWithPlayerItem:playerItem];
		player.allowsExternalPlayback = YES;
		[player addObserver:self forKeyPath:@"status" options:0 context:nil];
		[player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0 / 60.0, NSEC_PER_SEC) queue:nil usingBlock:^(CMTime time) {
			[self playerTimeChanged];
		}];

		playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
		playerLayer.frame = CGRectMake(0, boundsWindow.safeAreaInsets.top, self.view.bounds.size.width, self.view.bounds.size.width * 9 / 16);
		[self.view.layer addSublayer:playerLayer];
	} else if (self.audioURL != nil) {
		AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:self.audioURL options:nil];

		playerItem = [[AVPlayerItem alloc] initWithAsset:audioAsset];
		AVMediaSelectionGroup *subtitleSelectionGroup = [playerItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
		[playerItem selectMediaOption:nil inMediaSelectionGroup:subtitleSelectionGroup];

		player = [AVPlayer playerWithPlayerItem:playerItem];
		player.allowsExternalPlayback = YES;
		[player addObserver:self forKeyPath:@"status" options:0 context:nil];
		[player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0 / 60.0, NSEC_PER_SEC) queue:nil usingBlock:^(CMTime time) {
			[self playerTimeChanged];
		}];

		videoImage = [[UIImageView alloc] init];
		videoImage.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.videoArtwork]];
		videoImage.frame = CGRectMake(0, boundsWindow.safeAreaInsets.top, self.view.bounds.size.width, self.view.bounds.size.width * 9 / 16);
		[self.view addSubview:videoImage];
	}
}

- (void)overlaySetup {
	overlayView = [[UIView alloc] init];
	overlayView.frame = CGRectMake(0, boundsWindow.safeAreaInsets.top, self.view.bounds.size.width, self.view.bounds.size.width * 9 / 16);
	overlayView.userInteractionEnabled = YES;
	UITapGestureRecognizer *overlayViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overlayTap:)];
	overlayViewTap.numberOfTapsRequired = 1;
	[overlayView addGestureRecognizer:overlayViewTap];
	[self.view addSubview:overlayView];
	
	collapseImage = [[UIImageView alloc] init];
	NSString *collapseImagePath = [playerAssetsBundle pathForResource:@"collapse" ofType:@"png"];
	collapseImage.image = [[UIImage imageWithContentsOfFile:collapseImagePath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	collapseImage.frame = CGRectMake(10, boundsWindow.safeAreaInsets.top + 10, 24, 24);
	collapseImage.tintColor = [UIColor whiteColor];
	collapseImage.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
	collapseImage.layer.cornerRadius = collapseImage.bounds.size.width / 2;
	collapseImage.clipsToBounds = YES;
	collapseImage.hidden = YES;
	collapseImage.userInteractionEnabled = YES;
	UITapGestureRecognizer *collapseViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(collapseTap:)];
	collapseViewTap.numberOfTapsRequired = 1;
	[collapseImage addGestureRecognizer:collapseViewTap];
	[self.view addSubview:collapseImage];
	
	rewindImage = [[UIImageView alloc] init];
	NSString *rewindImagePath = [playerAssetsBundle pathForResource:@"rewind" ofType:@"png"];
	rewindImage.image = [[UIImage imageWithContentsOfFile:rewindImagePath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	rewindImage.frame = CGRectMake((overlayView.bounds.size.width / 2) - 96, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
	rewindImage.tintColor = [UIColor whiteColor];
	rewindImage.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
	rewindImage.layer.cornerRadius = rewindImage.bounds.size.width / 2;
	rewindImage.clipsToBounds = YES;
	rewindImage.hidden = YES;
	rewindImage.userInteractionEnabled = YES;
	UITapGestureRecognizer *rewindViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rewindTap:)];
	rewindViewTap.numberOfTapsRequired = 1;
	[rewindImage addGestureRecognizer:rewindViewTap];
	[self.view addSubview:rewindImage];

	playImage = [[UIImageView alloc] init];
	NSString *playImagePath = [playerAssetsBundle pathForResource:@"play" ofType:@"png"];
	playImage.image = [[UIImage imageWithContentsOfFile:playImagePath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	playImage.frame = CGRectMake((overlayView.bounds.size.width / 2) - 24, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
	playImage.tintColor = [UIColor whiteColor];
	playImage.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
	playImage.layer.cornerRadius = playImage.bounds.size.width / 2;
	playImage.clipsToBounds = YES;
	playImage.hidden = YES;
	playImage.userInteractionEnabled = YES;
	UITapGestureRecognizer *playViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPauseTap:)];
	playViewTap.numberOfTapsRequired = 1;
	[playImage addGestureRecognizer:playViewTap];
	[self.view addSubview:playImage];

	pauseImage = [[UIImageView alloc] init];
	NSString *pauseImagePath = [playerAssetsBundle pathForResource:@"pause" ofType:@"png"];
	pauseImage.image = [[UIImage imageWithContentsOfFile:pauseImagePath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	pauseImage.frame = CGRectMake((overlayView.bounds.size.width / 2) - 24, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
	pauseImage.tintColor = [UIColor whiteColor];
	pauseImage.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
	pauseImage.layer.cornerRadius = pauseImage.bounds.size.width / 2;
	pauseImage.clipsToBounds = YES;
	pauseImage.hidden = YES;
	pauseImage.userInteractionEnabled = YES;
	UITapGestureRecognizer *pauseViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPauseTap:)];
	pauseViewTap.numberOfTapsRequired = 1;
	[pauseImage addGestureRecognizer:pauseViewTap];
	[self.view addSubview:pauseImage];

	forwardImage = [[UIImageView alloc] init];
	NSString *forwardImagePath = [playerAssetsBundle pathForResource:@"forward" ofType:@"png"];
	forwardImage.image = [[UIImage imageWithContentsOfFile:forwardImagePath] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	forwardImage.frame = CGRectMake((overlayView.bounds.size.width / 2) + 48, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
	forwardImage.tintColor = [UIColor whiteColor];
	forwardImage.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
	forwardImage.layer.cornerRadius = forwardImage.bounds.size.width / 2;
	forwardImage.clipsToBounds = YES;
	forwardImage.hidden = YES;
	forwardImage.userInteractionEnabled = YES;
	UITapGestureRecognizer *forwardViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(forwardTap:)];
	forwardViewTap.numberOfTapsRequired = 1;
	[forwardImage addGestureRecognizer:forwardViewTap];
	[self.view addSubview:forwardImage];
}

- (void)infoSetup {
	progressSlider = [[UISlider alloc] init];
	progressSlider.frame = CGRectMake(0, boundsWindow.safeAreaInsets.top + overlayView.frame.size.height, self.view.bounds.size.width, 10);
	NSString *sliderThumbPath = [playerAssetsBundle pathForResource:@"sliderthumb" ofType:@"png"];
	[progressSlider setThumbImage:[UIImage imageWithContentsOfFile:sliderThumbPath] forState:UIControlStateNormal];
	[progressSlider setThumbImage:[UIImage imageWithContentsOfFile:sliderThumbPath] forState:UIControlStateHighlighted];
	progressSlider.minimumTrackTintColor = [UIColor redColor];
	progressSlider.minimumValue = 0.0f;
	progressSlider.maximumValue = [self.videoLength floatValue];
	[progressSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:progressSlider];

	videoTitleLabel = [[UILabel alloc] init];
	videoTitleLabel.frame = CGRectMake(0, boundsWindow.safeAreaInsets.top + overlayView.frame.size.height + progressSlider.frame.size.height + 15, self.view.bounds.size.width, 40);
	videoTitleLabel.text = self.videoTitle;
	videoTitleLabel.textColor = [UIColor whiteColor];
	videoTitleLabel.numberOfLines = 2;
	videoTitleLabel.adjustsFontSizeToFitWidth = true;
	videoTitleLabel.adjustsFontForContentSizeCategory = false;
	[self.view addSubview:videoTitleLabel];

	videoInfoLabel = [[UILabel alloc] init];
	videoInfoLabel.frame = CGRectMake(0, boundsWindow.safeAreaInsets.top + overlayView.frame.size.height + progressSlider.frame.size.height + 20 + videoTitleLabel.frame.size.height, self.view.bounds.size.width, 60);
	videoInfoLabel.text = [NSString stringWithFormat:@"View Count: %@\nLikes: %@\nDislikes: %@", self.videoViewCount, self.videoLikes, self.videoDislikes];
	videoInfoLabel.textColor = [UIColor whiteColor];
	videoInfoLabel.numberOfLines = 3;
	videoInfoLabel.adjustsFontSizeToFitWidth = true;
	videoInfoLabel.adjustsFontForContentSizeCategory = false;
	[self.view addSubview:videoInfoLabel];

	shareButton = [[UIButton alloc] init];
	shareButton.frame = CGRectMake(0, boundsWindow.safeAreaInsets.top + overlayView.frame.size.height + progressSlider.frame.size.height + 25 + videoTitleLabel.frame.size.height + videoInfoLabel.frame.size.height, self.view.bounds.size.width, 60);
	[shareButton setTitle:@"Share" forState:UIControlStateNormal];
	shareButton.backgroundColor = [UIColor colorWithRed:0.110 green:0.110 blue:0.118 alpha:1.0];
	shareButton.tintColor = [UIColor whiteColor];
	[self.view addSubview:shareButton];
}

- (BOOL)prefersHomeIndicatorAutoHidden {
	return YES;
}

@end

@implementation PlayerViewController (Privates)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == player && [keyPath isEqualToString:@"status"]) {
        if (player.status == AVPlayerStatusReadyToPlay) {
			if ([[NSUserDefaults standardUserDefaults] integerForKey:@"kBackgroundMode"] == 1 || [[NSUserDefaults standardUserDefaults] integerForKey:@"kBackgroundMode"] == 2) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

				if ([[NSUserDefaults standardUserDefaults] integerForKey:@"kBackgroundMode"] == 2) {
					if ([AVPictureInPictureController isPictureInPictureSupported]) {
						pictureInPictureController = [[AVPictureInPictureController alloc] initWithPlayerLayer:playerLayer];
						pictureInPictureController.delegate = self;
						if (@available(iOS 14.2, *)) {
							pictureInPictureController.canStartPictureInPictureAutomaticallyFromInline = YES;
						}
					}
				}
			}
            [player play];
        }
    }
}

- (void)overlayTap:(UITapGestureRecognizer *)recognizer {
	if (collapseImage.hidden == YES && rewindImage.hidden == YES && playImage.hidden == YES && pauseImage.hidden == YES && forwardImage.hidden == YES) {
		collapseImage.hidden = NO;
		rewindImage.hidden = NO;
		if (player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
			pauseImage.hidden = NO;
		} else {
			playImage.hidden = NO;
		}
		forwardImage.hidden = NO;
		progressSlider.hidden = NO;
	} else {
		collapseImage.hidden = YES;
		rewindImage.hidden = YES;
		playImage.hidden = YES;
		pauseImage.hidden = YES;
		forwardImage.hidden = YES;
		if (deviceOrientation == 1) {
			progressSlider.hidden = YES;
		} else {
			progressSlider.hidden = NO;
		}
	}
}

- (void)collapseTap:(UITapGestureRecognizer *)recognizer {
	if ([pictureInPictureController isPictureInPictureActive]) {
        [pictureInPictureController stopPictureInPicture];
    }
    [player pause];
	playerLayer.player = nil;
	player = nil;
    [playerLayer removeFromSuperlayer];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)rewindTap:(UITapGestureRecognizer *)recognizer {
	NSTimeInterval currentTime = CMTimeGetSeconds(player.currentTime);
	NSTimeInterval newTime = currentTime - 15.0f;
	CMTime time = CMTimeMakeWithSeconds(newTime, NSEC_PER_SEC);
	[player seekToTime:time];
}

- (void)playPauseTap:(UITapGestureRecognizer *)recognizer {
	if (player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
		[player pause];
		playImage.hidden = NO;
		pauseImage.hidden = YES;
	} else {
		[player play];
		playImage.hidden = YES;
		pauseImage.hidden = NO;
	}
}

- (void)forwardTap:(UITapGestureRecognizer *)recognizer {
	NSTimeInterval currentTime = CMTimeGetSeconds(player.currentTime);
	NSTimeInterval newTime = currentTime + 15.0f;
	CMTime time = CMTimeMakeWithSeconds(newTime, NSEC_PER_SEC);
	[player seekToTime:time];
}

- (void)enteredBackground:(NSNotification *)notification {
	if (![pictureInPictureController isPictureInPictureActive]) {
		playerLayer.player = nil;
	}
	MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.togglePlayPauseCommand setEnabled:YES];
    [commandCenter.playCommand setEnabled:YES];
    [commandCenter.pauseCommand setEnabled:YES];
    [commandCenter.nextTrackCommand setEnabled:NO];
    [commandCenter.previousTrackCommand setEnabled:NO];
	[commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [player play];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [player pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

	MPNowPlayingInfoCenter *playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
	
	NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];

	MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:self.videoArtwork]]];
	[songInfo setObject:[NSString stringWithFormat:@"%@", self.videoTitle] forKey:MPMediaItemPropertyTitle];
	[songInfo setObject:[NSNumber numberWithDouble:CMTimeGetSeconds(player.currentTime)] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
	[songInfo setObject:[NSNumber numberWithDouble:CMTimeGetSeconds(playerItem.duration)] forKey:MPMediaItemPropertyPlaybackDuration];
	[songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];

	[playingInfoCenter setNowPlayingInfo:songInfo];
}

- (void)enteredForeground:(NSNotification *)notification {
	if (![pictureInPictureController isPictureInPictureActive]) {
		playerLayer.player = player;
	}
}

- (void)orientationChanged:(NSNotification *)notification {
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	switch (orientation) {
		case UIInterfaceOrientationPortrait:
		deviceOrientation = 0;
		playerLayer.frame = CGRectMake(0, boundsWindow.safeAreaInsets.top, self.view.bounds.size.width, self.view.bounds.size.width * 9 / 16);
		videoImage.frame = CGRectMake(0, boundsWindow.safeAreaInsets.top, self.view.bounds.size.width, self.view.bounds.size.width * 9 / 16);
		overlayView.frame = CGRectMake(0, boundsWindow.safeAreaInsets.top, self.view.bounds.size.width, self.view.bounds.size.width * 9 / 16);
		collapseImage.alpha = 1.0;
		rewindImage.frame = CGRectMake((overlayView.bounds.size.width / 2) - 96, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
		playImage.frame = CGRectMake((overlayView.bounds.size.width / 2) - 24, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
		pauseImage.frame = CGRectMake((overlayView.bounds.size.width / 2) - 24, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
		forwardImage.frame = CGRectMake((overlayView.bounds.size.width / 2) + 48, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
		progressSlider.frame = CGRectMake(0, boundsWindow.safeAreaInsets.top + overlayView.frame.size.height, self.view.bounds.size.width, 10);
		progressSlider.hidden = NO;
		videoTitleLabel.hidden = NO;
		videoInfoLabel.hidden = NO;
		break;

		case UIInterfaceOrientationLandscapeLeft:
		deviceOrientation = 1;
		playerLayer.frame = self.view.bounds;
		videoImage.frame = self.view.bounds;
		overlayView.frame = self.view.bounds;
		collapseImage.alpha = 0.0;
		rewindImage.frame = CGRectMake((overlayView.bounds.size.width / 2) - 96, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
		playImage.frame = CGRectMake((overlayView.bounds.size.width / 2) - 24, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
		pauseImage.frame = CGRectMake((overlayView.bounds.size.width / 2) - 24, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
		forwardImage.frame = CGRectMake((overlayView.bounds.size.width / 2) + 48, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
		progressSlider.frame = CGRectMake(60, boundsWindow.safeAreaInsets.top + overlayView.frame.size.height - boundsWindow.safeAreaInsets.bottom - 60, self.view.bounds.size.width - 120, 10);
		if (collapseImage.hidden == YES && rewindImage.hidden == YES && playImage.hidden == YES && pauseImage.hidden == YES && forwardImage.hidden == YES) {
			progressSlider.hidden = YES;
		}
		videoTitleLabel.hidden = YES;
		videoInfoLabel.hidden = YES;
		break;

		case UIInterfaceOrientationLandscapeRight:
		deviceOrientation = 1;
		playerLayer.frame = self.view.bounds;
		videoImage.frame = self.view.bounds;
		overlayView.frame = self.view.bounds;
		collapseImage.alpha = 0.0;
		rewindImage.frame = CGRectMake((overlayView.bounds.size.width / 2) - 96, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
		playImage.frame = CGRectMake((overlayView.bounds.size.width / 2) - 24, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
		pauseImage.frame = CGRectMake((overlayView.bounds.size.width / 2) - 24, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
		forwardImage.frame = CGRectMake((overlayView.bounds.size.width / 2) + 48, boundsWindow.safeAreaInsets.top + (overlayView.bounds.size.height / 2) - 24, 48, 48);
		progressSlider.frame = CGRectMake(60, boundsWindow.safeAreaInsets.top + overlayView.frame.size.height - boundsWindow.safeAreaInsets.bottom - 60, self.view.bounds.size.width - 120, 10);
		if (collapseImage.hidden == YES && rewindImage.hidden == YES && playImage.hidden == YES && pauseImage.hidden == YES && forwardImage.hidden == YES) {
			progressSlider.hidden = YES;
		}
		videoTitleLabel.hidden = YES;
		videoInfoLabel.hidden = YES;
		break;
	}
}

- (void)sliderValueChanged:(UISlider *)sender {
	[player seekToTime:CMTimeMakeWithSeconds(sender.value, NSEC_PER_SEC)];
}

- (void)playerTimeChanged {
	progressSlider.value = (float)CMTimeGetSeconds(player.currentTime);
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockSponsorSegmentedInt"] && [[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockSponsorSegmentedInt"] == 1) {
		if (CMTimeGetSeconds(player.currentTime) >= [[[self.sponsorBlockValues objectForKey:@"sponsor"] objectAtIndex:0] floatValue] && CMTimeGetSeconds(player.currentTime) <= [[[self.sponsorBlockValues objectForKey:@"sponsor"] objectAtIndex:1] floatValue]) {
			[player seekToTime:CMTimeMakeWithSeconds([[[self.sponsorBlockValues objectForKey:@"sponsor"] objectAtIndex:1] floatValue] + 1, NSEC_PER_SEC)];
		}
	}
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockSelfPromoSegmentedInt"] && [[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockSelfPromoSegmentedInt"] == 1) {
		if (CMTimeGetSeconds(player.currentTime) >= [[[self.sponsorBlockValues objectForKey:@"selfpromo"] objectAtIndex:0] floatValue] && CMTimeGetSeconds(player.currentTime) <= [[[self.sponsorBlockValues objectForKey:@"selfpromo"] objectAtIndex:1] floatValue]) {
			[player seekToTime:CMTimeMakeWithSeconds([[[self.sponsorBlockValues objectForKey:@"selfpromo"] objectAtIndex:1] floatValue] + 1, NSEC_PER_SEC)];
		}
	}
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockInteractionSegmentedInt"] && [[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockInteractionSegmentedInt"] == 1) {
		if (CMTimeGetSeconds(player.currentTime) >= [[[self.sponsorBlockValues objectForKey:@"interaction"] objectAtIndex:0] floatValue] && CMTimeGetSeconds(player.currentTime) <= [[[self.sponsorBlockValues objectForKey:@"interaction"] objectAtIndex:1] floatValue]) {
			[player seekToTime:CMTimeMakeWithSeconds([[[self.sponsorBlockValues objectForKey:@"interaction"] objectAtIndex:1] floatValue] + 1, NSEC_PER_SEC)];
		}
	}
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockIntroSegmentedInt"] && [[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockIntroSegmentedInt"] == 1) {
		if (CMTimeGetSeconds(player.currentTime) >= [[[self.sponsorBlockValues objectForKey:@"intro"] objectAtIndex:0] floatValue] && CMTimeGetSeconds(player.currentTime) <= [[[self.sponsorBlockValues objectForKey:@"intro"] objectAtIndex:1] floatValue]) {
			[player seekToTime:CMTimeMakeWithSeconds([[[self.sponsorBlockValues objectForKey:@"intro"] objectAtIndex:1] floatValue] + 1, NSEC_PER_SEC)];
		}
	}
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockOutroSegmentedInt"] && [[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockOutroSegmentedInt"] == 1) {
		if (CMTimeGetSeconds(player.currentTime) >= [[[self.sponsorBlockValues objectForKey:@"outro"] objectAtIndex:0] floatValue] && CMTimeGetSeconds(player.currentTime) <= [[[self.sponsorBlockValues objectForKey:@"outro"] objectAtIndex:1] floatValue]) {
			[player seekToTime:CMTimeMakeWithSeconds([[[self.sponsorBlockValues objectForKey:@"outro"] objectAtIndex:1] floatValue] + 1, NSEC_PER_SEC)];
		}
	}
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockPreviewSegmentedInt"] && [[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockPreviewSegmentedInt"] == 1) {
		if (CMTimeGetSeconds(player.currentTime) >= [[[self.sponsorBlockValues objectForKey:@"preview"] objectAtIndex:0] floatValue] && CMTimeGetSeconds(player.currentTime) <= [[[self.sponsorBlockValues objectForKey:@"preview"] objectAtIndex:1] floatValue]) {
			[player seekToTime:CMTimeMakeWithSeconds([[[self.sponsorBlockValues objectForKey:@"preview"] objectAtIndex:1] floatValue] + 1, NSEC_PER_SEC)];
		}
	}
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockMusicOffTopicSegmentedInt"] && [[NSUserDefaults standardUserDefaults] integerForKey:@"kSponsorBlockMusicOffTopicSegmentedInt"] == 1) {
		if (CMTimeGetSeconds(player.currentTime) >= [[[self.sponsorBlockValues objectForKey:@"music_offtopic"] objectAtIndex:0] floatValue] && CMTimeGetSeconds(player.currentTime) <= [[[self.sponsorBlockValues objectForKey:@"music_offtopic"] objectAtIndex:1] floatValue]) {
			[player seekToTime:CMTimeMakeWithSeconds([[[self.sponsorBlockValues objectForKey:@"music_offtopic"] objectAtIndex:1] floatValue] + 1, NSEC_PER_SEC)];
		}
	}
}

@end