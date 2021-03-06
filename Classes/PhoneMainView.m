/*
 * Copyright (c) 2010-2019 Belledonne Communications SARL.
 *
 * This file is part of linphone-iphone
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioServices.h>
#import "LinphoneAppDelegate.h"
#import "Log.h"
#import "PhoneMainView.h"
#import <SAMKeychain/SAMKeychain.h>

static RootViewManager *rootViewManagerInstance = nil;

@implementation RootViewManager {
	PhoneMainView *currentViewController;
}

+ (void)setupWithPortrait:(PhoneMainView *)portrait {
	assert(rootViewManagerInstance == nil);
	rootViewManagerInstance = [[RootViewManager alloc] initWithPortrait:portrait];
}

- (instancetype)initWithPortrait:(PhoneMainView *)portrait {
	self = [super init];
	if (self) {
		self.portraitViewController = portrait;
		self.rotatingViewController = [[PhoneMainView alloc] init];

		self.portraitViewController.name = @"Portrait";
		self.rotatingViewController.name = @"Rotating";

		currentViewController = portrait;
		self.viewDescriptionStack = [NSMutableArray array];
	}
	return self;
}

+ (RootViewManager *)instance {
	if (!rootViewManagerInstance) {
		@throw [NSException exceptionWithName:@"RootViewManager" reason:@"nil instance" userInfo:nil];
	}
	return rootViewManagerInstance;
}

- (PhoneMainView *)currentView {
	return currentViewController;
}

- (PhoneMainView *)setViewControllerForDescription:(UICompositeViewDescription *)description {
	return currentViewController;

// not sure what this code was doing... but since iphone does support rotation as well now...
#if 0
	if (IPAD)
		return currentViewController;

	PhoneMainView *newMainView = description.landscapeMode ? self.rotatingViewController : self.portraitViewController;
	if (newMainView != currentViewController) {
		PhoneMainView *previousMainView = currentViewController;
		UIInterfaceOrientation nextViewOrientation = newMainView.interfaceOrientation;
		UIInterfaceOrientation previousOrientation = currentViewController.interfaceOrientation;

		LOGI(@"Changing rootViewController: %@ -> %@", currentViewController.name, newMainView.name);
		currentViewController = newMainView;
		LinphoneAppDelegate *delegate = (LinphoneAppDelegate *)[UIApplication sharedApplication].delegate;

		if (ANIMATED) {
			[UIView transitionWithView:delegate.window
				duration:0.3
				options:UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionAllowAnimatedContent
				animations:^{
				  delegate.window.rootViewController = newMainView;
				  // when going to landscape-enabled view, we have to get the current portrait frame and orientation,
				  // because it could still have landscape-based size
				  if (nextViewOrientation != previousOrientation && newMainView == self.rotatingViewController) {
					  newMainView.view.frame = previousMainView.view.frame;
					  [newMainView.mainViewController.view setFrame:previousMainView.mainViewController.view.frame];
					  [newMainView willRotateToInterfaceOrientation:previousOrientation duration:0.3];
					  [newMainView willAnimateRotationToInterfaceOrientation:previousOrientation duration:0.3];
					  [newMainView didRotateFromInterfaceOrientation:nextViewOrientation];
				  }
				}
				completion:^(BOOL finished){
				}];
		} else {
			delegate.window.rootViewController = newMainView;
			// when going to landscape-enabled view, we have to get the current portrait frame and orientation,
			// because it could still have landscape-based size
			if (nextViewOrientation != previousOrientation && newMainView == self.rotatingViewController) {
				newMainView.view.frame = previousMainView.view.frame;
				[newMainView.mainViewController.view setFrame:previousMainView.mainViewController.view.frame];
				[newMainView willRotateToInterfaceOrientation:previousOrientation duration:0.];
				[newMainView willAnimateRotationToInterfaceOrientation:previousOrientation duration:0.];
				[newMainView didRotateFromInterfaceOrientation:nextViewOrientation];
			}
		}
	}
	return currentViewController;
#endif
}

@end

@implementation PhoneMainView

@synthesize mainViewController;
@synthesize currentView;
@synthesize statusBarBG;
@synthesize volumeView;
AVAudioPlayer *avCallFailedPlayer;
NSDictionary *secretDict;

BOOL contactsOnly;
BOOL displayedAssistantView;

#pragma mark - Lifecycle Functions

- (void)initPhoneMainView {
	currentView = nil;
	_currentRoom = NULL;
	_currentName = NULL;
	_previousView = nil;
	inhibitedEvents = [[NSMutableArray alloc] init];
    
    displayedAssistantView = NO;
    
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"glacier_unable_to_complete_call"
                                              withExtension:@"mp3"];
    avCallFailedPlayer = [[AVAudioPlayer alloc]
                          initWithContentsOfURL:soundURL error:nil];
    avCallFailedPlayer.delegate = self;
    
    [self setupDownloadDirectory];
    
    // For AWS and domain values supplied before building
    NSString *appBundle = [[NSBundle mainBundle] bundlePath];
    appBundle = [appBundle stringByAppendingPathComponent:@"InAppSettings.bundle"];
    NSString *secPath = [appBundle stringByAppendingPathComponent:@"Secrets.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:secPath]) {
        secretDict = [[NSDictionary alloc] initWithContentsOfFile:secPath];
    }
}

- (id)init {
	self = [super init];
	if (self) {
		[self initPhoneMainView];
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		[self initPhoneMainView];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initPhoneMainView];
	}
	return self;
}

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)setupDownloadDirectory {
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"download"] withIntermediateDirectories:YES
                                                    attributes:nil error:&error]) {
        NSLog(@"Creating 'download' directory failed. Error: [%@]", error);
    }
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];

	volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, -100, 16, 16)];
	volumeView.showsRouteButton = false;
	volumeView.userInteractionEnabled = false;

	[self.view addSubview:mainViewController.view];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// Set observers
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(callUpdate:)
											   name:kLinphoneCallUpdate
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(registrationUpdate:)
											   name:kLinphoneRegistrationUpdate
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(textReceived:)
											   name:kLinphoneMessageReceived
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(onGlobalStateChanged:)
											   name:kLinphoneGlobalStateUpdate
											 object:nil];
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(batteryLevelChanged:)
											   name:UIDeviceBatteryLevelDidChangeNotification
											 object:nil];
    
    // account type refers to VPN type or none
    if (_accountType == nil) {
        NSUserDefaults *glacierDefaults = [[NSUserDefaults alloc] initWithSuiteName:GLACIER_APPLICATION_KEY];
        _accountType = [glacierDefaults stringForKey:@"connection"];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[NSNotificationCenter.defaultCenter removeObserver:self];
	[NSNotificationCenter.defaultCenter removeObserver:self name:UIDeviceBatteryLevelDidChangeNotification object:nil];
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:NO];
}

/* IPHONE X specific : hide the HomeIndcator when not used */
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_X (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height >= 812.0)
#define IPHONE_STATUSBAR_HEIGHT (IS_IPHONE_X ? 35 : 20)

- (BOOL)isIphoneXDevice{
	return IS_IPHONE_X;
}

+ (int)iphoneStatusBarHeight{
	return IPHONE_STATUSBAR_HEIGHT;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if([self isIphoneXDevice]){
		if(@available(iOS 11.0, *)) {
			[self childViewControllerForHomeIndicatorAutoHidden];
			[self prefersHomeIndicatorAutoHidden];
			[self setNeedsUpdateOfHomeIndicatorAutoHidden];
		}
	}

}

- (BOOL)prefersHomeIndicatorAutoHidden{
	return YES;
}

- (void)setVolumeHidden:(BOOL)hidden {
	// sometimes when placing a call, the volume view will appear. Inserting a
	// carefully hidden MPVolumeView into the view hierarchy will hide it
	if (hidden) {
		if (!(volumeView.superview == self.view)) {
			[self.view addSubview:volumeView];
		}
	} else {
		if (volumeView.superview == self.view) {
			[volumeView removeFromSuperview];
		}
	}
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#else
- (NSUInteger)supportedInterfaceOrientations
#endif
{
	return UIInterfaceOrientationMaskPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
								duration:(NSTimeInterval)duration {
	if (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
		return;

	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[mainViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self orientationUpdate:toInterfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										 duration:(NSTimeInterval)duration {
	if (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
		return;

	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[mainViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[mainViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (UIInterfaceOrientation)interfaceOrientation {
	return [mainViewController currentOrientation];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	[mainViewController clearCache:[RootViewManager instance].viewDescriptionStack];
}

#pragma mark - Event Functions

- (void)textReceived:(NSNotification *)notif {
	//
}

- (void)registrationUpdate:(NSNotification *)notif {
	LinphoneRegistrationState state = [[notif.userInfo objectForKey:@"state"] intValue];
	if (state == LinphoneRegistrationFailed && ![currentView equal:AssistantView.compositeViewDescription] &&
		[UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
    } 
}

- (void)onGlobalStateChanged:(NSNotification *)notif {
	LinphoneGlobalState state = (LinphoneGlobalState)[[[notif userInfo] valueForKey:@"state"] integerValue];
	static BOOL already_shown = FALSE;
	if (state == LinphoneGlobalOn && !already_shown && LinphoneManager.instance.wasRemoteProvisioned) {
		LinphoneProxyConfig *conf = linphone_core_get_default_proxy_config(LC);
		if ([LinphoneManager.instance lpConfigBoolForKey:@"show_login_view" inSection:@"app"] && conf == NULL) {
			already_shown = TRUE;
			AssistantView *view = VIEW(AssistantView);
			[PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
			[view fillDefaultValues];
		}
	}
}

- (void)callUpdate:(NSNotification *)notif {
	LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState state = [[notif.userInfo objectForKey:@"state"] intValue];
	NSString *message = [notif.userInfo objectForKey:@"message"];

	switch (state) {
		case LinphoneCallIncomingReceived:
			if (!CallManager.callKitEnabled) {
				[self displayIncomingCall:call];
			}
			break;
		case LinphoneCallIncomingEarlyMedia: {
			if (linphone_core_get_calls_nb(LC) > 1 ||
				(floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max)) {
				[self displayIncomingCall:call];
			}
			break;
		}
		case LinphoneCallOutgoingInit: {
			[self changeCurrentView:CallOutgoingView.compositeViewDescription];
			break;
		}
		case LinphoneCallPausedByRemote:
		case LinphoneCallConnected: {
			if (![LinphoneManager.instance isCTCallCenterExist]) {
				/*only register CT call center CB for connected call*/
				[LinphoneManager.instance setupGSMInteraction];
				[[UIDevice currentDevice] setProximityMonitoringEnabled:!(CallManager.instance.speakerEnabled || CallManager.instance.bluetoothEnabled)];
			}
			break;
		}
		case LinphoneCallStreamsRunning: {
			[self changeCurrentView:CallView.compositeViewDescription];
			break;
		}
		case LinphoneCallUpdatedByRemote: {
			const LinphoneCallParams *current = linphone_call_get_current_params(call);
			const LinphoneCallParams *remote = linphone_call_get_remote_params(call);

			if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
				[self changeCurrentView:CallView.compositeViewDescription];
			}
			break;
		}
		case LinphoneCallError: {
			[self displayCallError:call message:message];
		}
		case LinphoneCallEnd: {
			const MSList *calls = linphone_core_get_calls(LC);
			if (!calls) {
				while ((currentView == CallView.compositeViewDescription) ||
					   (currentView == CallIncomingView.compositeViewDescription) ||
					   (currentView == CallOutgoingView.compositeViewDescription)) {
					[self popCurrentView];
				}
			} else {
				[self changeCurrentView:CallView.compositeViewDescription];
			}
            if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
                [LinphoneManager.instance setConnectingToNetwork:TRUE];
            }
			break;
		}
		case LinphoneCallEarlyUpdatedByRemote:
		case LinphoneCallEarlyUpdating:
		case LinphoneCallIdle:
			break;
		case LinphoneCallOutgoingEarlyMedia:
		case LinphoneCallOutgoingProgress: {
			break;
		}
        case LinphoneCallReleased:
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [PhoneMainView.instance popToView:DialerView.compositeViewDescription];
                    [CoreManager.instance stopLinphoneCore];
                });
            }
            break;
		case LinphoneCallOutgoingRinging:
		case LinphoneCallPaused:
		case LinphoneCallPausing:
		case LinphoneCallRefered:
            break;
		case LinphoneCallResuming: {
			break;
		}
		case LinphoneCallUpdating:
			break;
	}
	if (state == LinphoneCallEnd || state == LinphoneCallError || floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max)
		[self updateApplicationBadgeNumber];
}

#pragma mark -

- (void)orientationUpdate:(UIInterfaceOrientation)orientation {
	int oldLinphoneOrientation = linphone_core_get_device_rotation(LC);
	int newRotation = 0;
	switch (orientation) {
		case UIInterfaceOrientationPortrait:
			newRotation = 0;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			newRotation = 180;
			break;
		case UIInterfaceOrientationLandscapeRight:
			newRotation = 270;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			newRotation = 90;
			break;
		default:
			newRotation = oldLinphoneOrientation;
	}
	if (oldLinphoneOrientation != newRotation) {
		linphone_core_set_device_rotation(LC, newRotation);
	}
}
- (void)startUp {
	@try {
        [self setupCognito];
        [self teardownCognito];
        
		LinphoneManager *lm = LinphoneManager.instance;
                LOGI(@"%s", linphone_global_state_to_string(
                                linphone_core_get_global_state(LC)));
                if (linphone_core_get_global_state(LC) != LinphoneGlobalOn) {
                  [self changeCurrentView:DialerView.compositeViewDescription];
                } else if ([LinphoneManager.instance
                               lpConfigBoolForKey:
                                   @"enable_first_login_view_preference"] ==
                           true) {
                  [PhoneMainView.instance
                      changeCurrentView:FirstLoginView
                                            .compositeViewDescription];
                } else {
                  // always start to dialer when testing
                  // Change to default view
                  const MSList *list = linphone_core_get_proxy_config_list(LC);
                  if (list != NULL ||
                      ([lm lpConfigBoolForKey:@"hide_assistant_preference"] ==
                       true) ||
                      lm.isTesting) {
                    [self
                        changeCurrentView:DialerView.compositeViewDescription];
                  } else {
                    [self setupAccount];
                  }
                }
                [self updateApplicationBadgeNumber]; // Update Badge at startup
        } @catch (NSException *exception) {
          // we'll wait until the app transitions correctly
        }
}

// Tries to create and load account from values stored in in App group
- (void)setupAccount {
    LinphoneProxyConfig *default_proxy = linphone_core_get_default_proxy_config(LC);
    if (default_proxy == NULL) {
        NSUserDefaults *glacierDefaults = [[NSUserDefaults alloc]
                                           initWithSuiteName:GLACIER_APPLICATION_KEY];
        NSString *extvalue = [glacierDefaults stringForKey:@"extension"];
        NSString *passvalue = [glacierDefaults stringForKey:@"password"];
        NSString *displayvalue = [glacierDefaults stringForKey:@"displayname"];
        NSString *connectionvalue = [glacierDefaults stringForKey:@"connection"];
        contactsOnly = NO;
        
        // get pass from keychain
        NSError *error = nil;
        NSString *idvalue = [SAMKeychain passwordForService:GLACIER_APPLICATION_KEY account:GLACIER_ACCT_KEY accessGroup:GLACIER_APPLICATION_KEY error:&error];
        if (idvalue) {
            passvalue = [SAMKeychain passwordForService:GLACIER_APPLICATION_KEY account:idvalue accessGroup:GLACIER_APPLICATION_KEY error:&error];
        }
        if (error) {
            LOGE(@"Error retreiving password from keychain: %@%@", [error localizedDescription], [error userInfo]);
            passvalue = [glacierDefaults stringForKey:@"password"];
        }
        
        if (!extvalue.length || !passvalue.length) { //go to AssistantView
            [self displayAssistantView:YES];
        } else { //create account from stored values
            NSString *domainvalue = nil;
            if (secretDict != nil) {
                domainvalue = [secretDict objectForKey:@"defaultDomainAddress"];
            }
            if (!domainvalue) {
                NSLog(@"No defaultDomainAddress to create account");
                [self returnToMainView];
                return;
            }
            
            if (connectionvalue.length) {
                _accountType = connectionvalue;
                if ([connectionvalue isEqualToString:@"none"]) {
                    domainvalue = [secretDict objectForKey:@"defaultPublicDomainAddress"];
                    
                    SettingsView *sview = VIEW(SettingsView);
                    if (sview) {
                        [sview trySetBypass:YES];
                    }
                }
            }
            
            NSArray *components = [extvalue componentsSeparatedByString:@"@"];
            if (components.count == 2) {
                domainvalue = components.lastObject;
                extvalue = components.firstObject;
            }
            
            NSString *type = @"tls";
            
            LinphoneProxyConfig *config = linphone_core_create_proxy_config(LC);
            LinphoneAddress *addr = linphone_address_new([NSString stringWithFormat:@"sip:%@@%@", extvalue, domainvalue].UTF8String);
            if (displayvalue && ![displayvalue isEqualToString:@""]) {
                linphone_address_set_display_name(addr, displayvalue.UTF8String);
            }
            linphone_proxy_config_set_identity_address(config, addr);
            
            // set transport
            linphone_proxy_config_set_route(config,[NSString stringWithFormat:@"%s;transport=%s", domainvalue.UTF8String, type.lowercaseString.UTF8String].UTF8String);
            linphone_proxy_config_set_server_addr(config,[NSString stringWithFormat:@"%s;transport=%s", domainvalue.UTF8String, type.lowercaseString.UTF8String].UTF8String);
            linphone_core_set_media_encryption(LC, LinphoneMediaEncryptionSRTP);
            
            linphone_proxy_config_enable_publish(config, FALSE);
            linphone_proxy_config_enable_register(config, TRUE);
            
            LinphoneAuthInfo *info = linphone_auth_info_new(linphone_address_get_username(addr), // username
                                                            NULL,                                // user id
                                                            passvalue.UTF8String,                // passwd
                                                            NULL,                                // ha1
                                                            linphone_address_get_domain(addr),   // realm - assumed to be domain
                                                            linphone_address_get_domain(addr)    // domain
                                                            );
            linphone_core_add_auth_info(LC, info);
            linphone_address_unref(addr);
            
            if (config) {
                [[LinphoneManager instance] configurePushTokenForProxyConfig:config];
                if (linphone_core_add_proxy_config(LC, config) != -1) {
                    linphone_core_set_default_proxy_config(LC, config);
                    // reload address book to prepend proxy config domain to contacts' phone number
                    // todo: STOP doing that!
                    [[LinphoneManager.instance fastAddressBook] fetchContactsInBackGroundThread];
                    linphone_proxy_config_done(config);
                    
                    SettingsView *sview = VIEW(SettingsView);
                    if (sview) {
                        [sview trySynchronize];
                    }
                    [self returnToMainView];
                    
                    UIApplication *app = [UIApplication sharedApplication];
                    LinphoneAppDelegate *delegate = (LinphoneAppDelegate *)app.delegate;
                    [delegate registerForNotifications];
                    [delegate tryWaitForNetwork];
                    
                    // if we had password from Messenger and can delete from Keychain
                    if (idvalue && !displayedAssistantView) {
                        [SAMKeychain deletePasswordForService:GLACIER_APPLICATION_KEY account:idvalue accessGroup:GLACIER_APPLICATION_KEY error:&error];
                    }
                    
                } else {
                    [self displayAssistantView:YES];
                }
            } else {
                [self displayAssistantView:YES];
            }
        }
    } else {
        [self returnToMainView];
    }
}

- (void) displayAssistantView:(BOOL)needsNewAccount {
    AssistantView *view = VIEW(AssistantView);
    [self changeCurrentView:view.compositeViewDescription];
    [view reset:needsNewAccount];
    
    displayedAssistantView = YES;
}

- (UIViewController *) getViewController {
    return self;
}

- (void) handleLoginSelection:(BOOL)cognitoLogin {
    [self setupCognito];
    if (cognitoLogin) {
        [self getUserDetails];
    } else {
        if (self.auth != nil && self.auth.isSignedIn && [self coreSignedIn]) {
            [self getUserDetails];
        } else if (self.auth != nil){
            [self.auth getSession:self completion:^(AWSCognitoAuthUserSession * _Nullable session, NSError * _Nullable error) {
                if(error){
                    [self alertWithTitle:@"Authentication issue" message:@"Could not authenticate. For assistance contact your Glacier account representative."];
                    self.session = nil;
                }else {
                    self.session = session;
                    if (self.session != nil) {
                        [self getUserDetails];
                    }
                }
            }];
        } else {
            [self alertWithTitle:@"Authentication issue" message:@"Could not authenticate. For assistance contact your Glacier account representative."];
        }
    }
}

- (void) alertWithTitle: (NSString *) title message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:title
                                     message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void) showSpinner {
    UIView *spinnerView = [[UIView alloc] initWithFrame:self.view.bounds];
    spinnerView.backgroundColor = [[UIColor alloc] initWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    [ai startAnimating];
    ai.center = spinnerView.center;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [spinnerView addSubview:ai];
        [self.view addSubview:spinnerView];
    });
    
    self.vSpinner = spinnerView;
}

- (void) removeSpinner {
    if (self.vSpinner == nil) { return; }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vSpinner removeFromSuperview];
        self.vSpinner = nil;
    });
}

- (void)updateApplicationBadgeNumber {
	int count = 0;
	count += linphone_core_get_missed_calls_count(LC);
	count += [LinphoneManager unreadMessageCount];
	count += linphone_core_get_calls_nb(LC);
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
	TabBarView *view = (TabBarView *)[PhoneMainView.instance.mainViewController getCachedController:NSStringFromClass(TabBarView.class)];
	[view update:TRUE];
}

+ (CATransition *)getBackwardTransition {
	BOOL RTL = [LinphoneManager langageDirectionIsRTL];
	BOOL land = UIInterfaceOrientationIsLandscape([self.instance interfaceOrientation]);
	NSString *transition = land ? kCATransitionFromBottom : (RTL ? kCATransitionFromRight : kCATransitionFromLeft);
	CATransition *trans = [CATransition animation];
	[trans setType:kCATransitionPush];
	[trans setDuration:0.35];
	[trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	[trans setSubtype:transition];

	return trans;
}

+ (CATransition *)getForwardTransition {
	BOOL RTL = [LinphoneManager langageDirectionIsRTL];
	BOOL land = UIInterfaceOrientationIsLandscape([self.instance interfaceOrientation]);
	NSString *transition = land ? kCATransitionFromTop : (RTL ? kCATransitionFromLeft : kCATransitionFromRight);
	CATransition *trans = [CATransition animation];
	[trans setType:kCATransitionPush];
	[trans setDuration:0.35];
	[trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	[trans setSubtype:transition];

	return trans;
}

+ (CATransition *)getTransition:(UICompositeViewDescription *)old new:(UICompositeViewDescription *) new {
	bool left = false;

	if ([old equal:SettingsView.compositeViewDescription]) {
		if ([new equal:DialerView.compositeViewDescription] || [new equal:ContactsListView.compositeViewDescription] ||
			[new equal:HistoryListView.compositeViewDescription]) {
			left = true;
		}
	} else if ([old equal:DialerView.compositeViewDescription]) {
		if ([new equal:ContactsListView.compositeViewDescription] ||
			[new equal:HistoryListView.compositeViewDescription]) {
			left = true;
		}
	} else if ([old equal:ContactsListView.compositeViewDescription]) {
		if ([new equal:HistoryListView.compositeViewDescription]) {
			left = true;
		}
	}

	if (left) {
		return [PhoneMainView getBackwardTransition];
	} else {
		return [PhoneMainView getForwardTransition];
	}
}

+ (PhoneMainView *)instance {
	return [[RootViewManager instance] currentView];
}

- (void)hideTabBar:(BOOL)hide {
	[mainViewController hideTabBar:hide];
}

- (void)hideStatusBar:(BOOL)hide {
	[mainViewController hideStatusBar:hide];
}

- (void)updateStatusBar:(UICompositeViewDescription *)to_view {
	// Not used any more. It seems that there is no problem with new devices.
#pragma deploymate push "ignored-api-availability"
	if (UIDevice.currentDevice.systemVersion.doubleValue >= 7.) {
		// In iOS7, the app has a black background on dialer, incoming and incall, so we have to adjust the
		// status bar style for each transition to/from these views
		BOOL toLightStatus = (to_view != NULL) && ![to_view darkBackground];
        toLightStatus = true;
		if (!toLightStatus) {
			// black bg: white text on black background
			[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

			[UIView animateWithDuration:0.3f
							 animations:^{
							   statusBarBG.backgroundColor = [UIColor blackColor];
							 }];

		} else {
			// light bg: black text on white bg
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
			
			[UIView animateWithDuration:0.3f
							 animations:^{
							   statusBarBG.backgroundColor = [UIColor whiteColor];
							 }];
		}
        
        if(IS_IPHONE_X){
            CGRect framey = self.statusBarBG.frame;
            framey.size.height = IPHONE_STATUSBAR_HEIGHT;
            statusBarBG.frame = framey;
        }
	}
#pragma deploymate pop
}

- (void)fullScreen:(BOOL)enabled {
	[statusBarBG setHidden:enabled];
	[mainViewController setFullscreen:enabled];
}

- (UIViewController *)popCurrentView {
	NSMutableArray *viewStack = [RootViewManager instance].viewDescriptionStack;
	if (viewStack.count <= 1) {
		[viewStack removeAllObjects];
		LOGW(@"PhoneMainView: Trying to pop view but none stacked, going to %@!",
			 DialerView.compositeViewDescription.name);
	} else {
		[viewStack removeLastObject];
		LOGI(@"PhoneMainView: Popping view %@, going to %@", currentView.name,
			 ((UICompositeViewDescription *)(viewStack.lastObject ?: DialerView.compositeViewDescription)).name);
	}
	[self _changeCurrentView:viewStack.lastObject ?: DialerView.compositeViewDescription
				  transition:[PhoneMainView getBackwardTransition]
					animated:ANIMATED];
	return [mainViewController getCurrentViewController];
}

- (void)changeCurrentView:(UICompositeViewDescription *)view {
	[self _changeCurrentView:view transition:nil animated:ANIMATED];
}

- (UIViewController *)_changeCurrentView:(UICompositeViewDescription *)view
							  transition:(CATransition *)transition
								animated:(BOOL)animated {
	PhoneMainView *vc = [[RootViewManager instance] setViewControllerForDescription:view];
	if (![view equal:vc.currentView] || vc != self) {
		LOGI(@"Change current view to %@", view.name);
		[self setPreviousViewName:vc.currentView.name];
		NSMutableArray *viewStack = [RootViewManager instance].viewDescriptionStack;
		[viewStack addObject:view];
		if (animated && transition == nil)
			transition = [PhoneMainView getTransition:vc.currentView new:view];
		[vc.mainViewController setViewTransition:(animated ? transition : nil)];
        [vc updateStatusBar:nil];
		[vc.mainViewController changeView:view];
		vc->currentView = view;
	}

	NSDictionary *mdict = [NSMutableDictionary dictionaryWithObject:vc->currentView forKey:@"view"];
	[NSNotificationCenter.defaultCenter postNotificationName:kLinphoneMainViewChange object:self userInfo:mdict];

	return [vc->mainViewController getCurrentViewController];
}

- (UIViewController *)popToView:(UICompositeViewDescription *)view {
	NSMutableArray *viewStack = [RootViewManager instance].viewDescriptionStack;
	while (viewStack.count > 0 && ![[viewStack lastObject] equal:view]) {
		[viewStack removeLastObject];
	}
	return [self _changeCurrentView:view transition:[PhoneMainView getBackwardTransition] animated:ANIMATED];
}

- (void) setPreviousViewName:(NSString*)previous{
	_previousView = previous;
}

- (NSString*) getPreviousViewName {
	return _previousView;
}

+ (NSString*) getPreviousViewName {
	return [self getPreviousViewName];
}

- (UICompositeViewDescription *)firstView {
	UICompositeViewDescription *view = nil;
	NSArray *viewStack = [RootViewManager instance].viewDescriptionStack;
	if ([viewStack count]) {
		view = [viewStack objectAtIndex:0];
	}
	return view;
}

- (void)displayCallError:(LinphoneCall *)call message:(NSString *)message {
	const char *lUserNameChars = linphone_address_get_username(linphone_call_get_remote_address(call));
	NSString *lUserName =
		lUserNameChars ? [[NSString alloc] initWithUTF8String:lUserNameChars] : NSLocalizedString(@"Unknown", nil);
	NSString *lMessage;
	NSString *lTitle;

	// get default proxy
	LinphoneProxyConfig *proxyCfg = linphone_core_get_default_proxy_config(LC);
	if (proxyCfg == nil) {
		lMessage = NSLocalizedString(@"Please make sure your device is connected to the internet and double check your "
									 @"SIP account configuration in the settings.",
									 nil);
	} else {
		lMessage = [NSString stringWithFormat:NSLocalizedString(@"Cannot call %@.", nil), lUserName];
	}

	switch (linphone_call_get_reason(call)) {
		case LinphoneReasonNotFound:
			lMessage = [NSString stringWithFormat:NSLocalizedString(@"%@ is not connected.", nil), lUserName];
			break;
		case LinphoneReasonBusy:
			lMessage = [NSString stringWithFormat:NSLocalizedString(@"%@ is busy.", nil), lUserName];
			break;
		default:
			if (message != nil) {
				lMessage = [NSString stringWithFormat:NSLocalizedString(@"%@\nReason was: %@", nil), lMessage, message];
			}
			break;
	}
    
    [self performSelector:@selector(playErrorRecording:) withObject:nil afterDelay:0.5];
    
    lTitle = NSLocalizedString(@"Call failed", nil);
    [self alertWithTitle:lTitle message:lMessage];
}

- (void) playErrorRecording:(id)sender {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [avCallFailedPlayer play];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (player != nil && [player isPlaying]) {
        [player stop];
    }
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)addInhibitedEvent:(id)event {
	[inhibitedEvents addObject:event];
}

- (BOOL)removeInhibitedEvent:(id)event {
	NSUInteger index = [inhibitedEvents indexOfObject:event];
	if (index != NSNotFound) {
		[inhibitedEvents removeObjectAtIndex:index];
		return TRUE;
	}
	return FALSE;
}

#pragma mark - ActionSheet Functions

- (void)displayIncomingCall:(LinphoneCall *)call {
	LinphoneCallLog *callLog = linphone_call_get_call_log(call);
	NSString *callId = [NSString stringWithUTF8String:linphone_call_log_get_call_id(callLog)];

	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
		LinphoneManager *lm = LinphoneManager.instance;
		BOOL callIDFromPush = [lm popPushCallID:callId];
		BOOL autoAnswer = [lm lpConfigBoolForKey:@"autoanswer_notif_preference"];

		if (callIDFromPush && autoAnswer) {
			// accept call automatically
			[CallManager.instance acceptCallWithCall:call hasVideo:YES];
		} else {
			AudioServicesPlaySystemSound(lm.sounds.vibrate);
			CallIncomingView *view = VIEW(CallIncomingView);
			[self changeCurrentView:view.compositeViewDescription];
			[view setCall:call];
			[view setDelegate:self];
		}
	}
}

- (void)batteryLevelChanged:(NSNotification *)notif {
	float level = [UIDevice currentDevice].batteryLevel;
	UIDeviceBatteryState state = [UIDevice currentDevice].batteryState;
	LOGD(@"Battery state:%d level:%.2f", state, level);

	LinphoneCall *call = linphone_core_get_current_call(LC);
	if (call && linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
		CallAppData *data = [CallManager getAppDataWithCall:call];
		if (data != nil) {
			if (state == UIDeviceBatteryStateUnplugged) {
				if (level <= 0.2f && !data.batteryWarningShown) {
					LOGI(@"Battery warning");
					DTActionSheet *sheet = [[DTActionSheet alloc]
						initWithTitle:NSLocalizedString(@"Battery is running low. Stop video ?", nil)];
					[sheet addCancelButtonWithTitle:NSLocalizedString(@"Continue video", nil) block:nil];
					[sheet
						addDestructiveButtonWithTitle:NSLocalizedString(@"Stop video", nil)
												block:^() {
												  LinphoneCallParams *params =
													  linphone_core_create_call_params(LC,call);
												  // stop video
												  linphone_call_params_enable_video(params, FALSE);
												  linphone_call_update(call, params);
												}];
					[sheet showInView:self.view];
					data.batteryWarningShown = TRUE;
				}
			}
			if (level > 0.2f) {
				data.batteryWarningShown = FALSE;
			}
			[CallManager setAppDataWithCall:call appData:data];
		}
	}
}

#pragma mark - IncomingCallDelegate Functions

- (void)incomingCallAborted:(LinphoneCall *)call {
}

- (void)incomingCallAccepted:(LinphoneCall *)call evenWithVideo:(BOOL)video {
	[CallManager.instance acceptCallWithCall:call hasVideo:video];
}

- (void)incomingCallDeclined:(LinphoneCall *)call {
	[CallManager.instance terminateCallWithCall:call];
}

// AWS Cognito is the primary way to login and pull account settings
- (void)setupCognito {
    if (!self.pool) {
        self.pool = [AWSCognitoIdentityUserPool defaultCognitoIdentityUserPool];
        self.pool.delegate = self;
    }
    
    self.auth = [AWSCognitoAuth defaultCognitoAuth];
}

- (void) teardownCognito {
    if(self.pool && [self.pool currentUser]) {
        [[self.pool currentUser] signOutAndClearLastKnownUser];
        self.pool = nil;
    }
    
    if (self.auth) {
        [self.auth signOut:^(NSError * _Nullable error) {
            // do nothing
            self.auth = nil;
        }];
    }
}

- (BOOL) coreSignedIn {
    BOOL isSignedIn = FALSE;
    if(self.pool && [self.pool currentUser]) {
        isSignedIn = [self.pool currentUser].signedIn;
    }
    
    return isSignedIn;
}

- (void) handleImportContacts {
    [self teardownCognito];
    
    contactsOnly = YES;
    if (![self coreSignedIn]) {
        [self displayAssistantView:NO];
    } else {
        [self.mainViewController hideSideMenu:YES];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self getUserDetails];
        });
    }
}

//set up password authentication ui to retrieve username and password from the user
-(id<AWSCognitoIdentityPasswordAuthentication>) startPasswordAuthentication {
    return VIEW(AssistantView);
 }

// set up reset password ui
-(id<AWSCognitoIdentityNewPasswordRequired>) startNewPasswordRequired {
    return VIEW(AssistantView);
}

-(void) getUserDetails {
    if(!self.user)
        self.user = [self.pool currentUser];
    
    [[self.user getDetails] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserGetDetailsResponse *> * _Nonnull task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(task.error){
                [self alertWithTitle:task.error.userInfo[@"__type"] message:@"Problems obtaining user information. Please try again or contact Glacier representative."];
            }else {
                if (contactsOnly) {
                    [self updateTempStatus:@"Updating contacts"];
                }
                
                self.userName = self.user.username;
                
                for (AWSCognitoIdentityProviderAttributeType *attr in task.result.userAttributes) {
                    if ([attr.name isEqualToString:@"custom:organization"]) {
                        self.bucketOrg = attr.value;
                    }
                }
                
                if (contactsOnly) {
                    [self returnToMainView];
                    [self getContacts];
                } else {
                    [self getAppSyncData];
                }
            }
        });
        
        return nil;
    }];
}

- (void) getAppSyncData {
    
    self.appSyncMgr = [[AppSyncMgr alloc] init];
    [self.appSyncMgr getUserInfoWithUsername:self.userName org:self.bucketOrg completion:^(GlacierUser *guser) {
        //use password and get org
        if (guser == nil || guser.password == nil || guser.username == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self removeSpinner];
                [self teardownCognito];
                [self displayAssistantView:YES];
                [self updateTempStatus:@"Could not find Glacier account"];
            });
            return;
        }
        
        NSUserDefaults *glacierDefaults = [[NSUserDefaults alloc] initWithSuiteName:GLACIER_APPLICATION_KEY];
        if (guser.organization != nil) {
            self.bucketOrg = guser.organization;
            [glacierDefaults setObject:guser.organization forKey:@"orgid"];
        }
        
        [glacierDefaults setObject:guser.displayName forKey:@"displayname"];
        [glacierDefaults setObject:@"none" forKey:@"connection"];
        [glacierDefaults setObject:guser.voiceext forKey:@"extension"];
        [glacierDefaults setObject:guser.username forKey:@"username"];
        
        if (guser.password) {
            [SAMKeychain setAccessibilityType:kSecAttrAccessibleWhenUnlockedThisDeviceOnly];
            
            NSError *error = nil;
            //TODO maybe check for existing ID here?
            //in case i'm coming back in for something else like just profile
            NSString *userid = [NSUUID UUID].UUIDString;
            BOOL idresult = [SAMKeychain setPassword:userid forService:GLACIER_APPLICATION_KEY account:GLACIER_ACCT_KEY accessGroup:GLACIER_APPLICATION_KEY error:&error];
            BOOL result = [SAMKeychain setPassword:guser.password forService:GLACIER_APPLICATION_KEY account:userid accessGroup:GLACIER_APPLICATION_KEY error:&error];
            if (!result || !idresult) {
                LOGE(@"Error saving id or password to keychain: %@%@", [error localizedDescription], [error userInfo]);
            } else { //if storing password succeeded, remove from defaults
                [glacierDefaults removeObjectForKey:@"password"];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupAccount];
            [self getContacts];
        });
    }];
}

- (void) getContacts {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.bucketOrg) {
            if ([self getS3Bucket]) {
                [self createListContactsRequest];
                return;
            }
        }
        
        [self alertWithTitle:@"Account Contacts" message:@"There was a problem updating your contacts. For assistance contact your Glacier account representative."];
        NSLog(@"Could not get S3 bucket due to no Org Id or Identity Pool Id");
    });
}

- (void) returnToMainView {
    StatusBarView *sbar = (StatusBarView *)[PhoneMainView.instance.mainViewController
                                            getCachedController:NSStringFromClass(StatusBarView.class)];
    if (sbar) {
        [sbar onClickClose:self];
    } else {
        [self changeCurrentView:DialerView.compositeViewDescription];
    }
}

- (BOOL) getS3Bucket {
    AWSServiceInfo *serviceInfo = [[AWSInfo defaultAWSInfo] defaultServiceInfo:@"CognitoUserPool"];
    if (serviceInfo.cognitoCredentialsProvider.identityPoolId == nil) {
        return NO;
    }
    NSString *test = serviceInfo.cognitoCredentialsProvider.identityPoolId;
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                                                          initWithRegionType:serviceInfo.region identityPoolId:test identityProviderManager:self.pool];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:serviceInfo.region credentialsProvider:credentialsProvider];
    
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    [AWSS3 registerS3WithConfiguration:configuration forKey:@"defaultKey"];
    [AWSS3TransferManager registerS3TransferManagerWithConfiguration:configuration forKey:@"defaultKey"];
    
    self.s3BucketName = [[secretDict objectForKey:@"s3BucketConstant"] stringByAppendingString:self.bucketOrg];
    
    return YES;
}

- (void) createListContactsRequest {
    if (self.bucketOrg) {
        AWSS3ListObjectsRequest *listObjectsRequest = [AWSS3ListObjectsRequest new];
        self.bucketPrefix = @"contacts";
        listObjectsRequest.prefix = self.bucketPrefix;
        
        // get AWS bucket name to pull account settings from
        if (secretDict != nil) {
            self.s3BucketName = [[secretDict objectForKey:@"s3BucketConstant"] stringByAppendingString:self.bucketOrg];
            
            listObjectsRequest.bucket = self.s3BucketName;
            [self listContactsObjects:listObjectsRequest];
        } else {
            NSLog(@"Could not createListObjectsRequestWithId due to no Secrets.plist in bundle");
        }
    } else {
        [self alertWithTitle:@"No Account" message:@"We cannot find your account information. For assistance contact your Glacier account representative."];
        NSLog(@"Could not createListObjectsRequestWithId due to no Org Id");
    }
}

- (void) listContactsObjects:(AWSS3ListObjectsRequest*)listObjectsRequest {
    AWSS3 *s3 = [AWSS3 S3ForKey:@"defaultKey"];
    [[s3 listObjects:listObjectsRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"listObjects failed: [%@]", task.error);
            // This happens if no bucket exists. Appropriate notification?
            dispatch_async(dispatch_get_main_queue(), ^{
                [self teardownCognito];
                [self updateTempStatus:@"Could not update contacts"];
            });
        } else {
            AWSS3ListObjectsOutput *listObjectsOutput = task.result;
            
            NSString *cstring = [self.userName stringByAppendingPathExtension:@"vcf"];
            NSString *globalstring = @"global.vcf";
            
            [self.dataArray removeAllObjects];
            
            for (AWSS3Object *s3Object in listObjectsOutput.contents) {
                NSString *downloadingFilePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"download"] stringByAppendingPathComponent:[s3Object.key lastPathComponent]];
                
                if ([[downloadingFilePath lastPathComponent] isEqualToString:cstring]) {
                    [self getVCardForUser:cstring];
                } else if ([[downloadingFilePath lastPathComponent] isEqualToString:globalstring]) {
                    [self getVCardForUser:globalstring];
                }
            }
        }
        return nil;
    }];
}

- (void) getVCardForUser:(NSString *)vcardFile {
    NSString *downloadingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"download"];
    LOGD(@"getVCardForUser");
    
    AWSS3TransferManagerDownloadRequest *vcardRequest = [AWSS3TransferManagerDownloadRequest new];
    vcardRequest.bucket = self.s3BucketName;
    NSString *vcf = [@"contacts" stringByAppendingPathComponent:vcardFile];
    vcardRequest.key = vcf;
    NSString *vcardFilePath = [downloadingFilePath stringByAppendingPathComponent:vcardFile];
    NSURL *vcardURL = [NSURL fileURLWithPath:vcardFilePath];
    vcardRequest.downloadingFileURL = vcardURL;
    [self download:vcardRequest];
}

- (void) getVCardForUser {
    self.s3BucketName = [[secretDict objectForKey:@"s3BucketConstant"] stringByAppendingString:self.bucketOrg];
    
    NSString *usercontacts = [self.user.username stringByAppendingPathExtension:@"vcf"];
    NSString *downloadingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"download"];
    LOGD(@"getVCardForUser");
        
    AWSS3TransferManagerDownloadRequest *globalRequest = [AWSS3TransferManagerDownloadRequest new];
    globalRequest.bucket = self.s3BucketName;
    NSString *globalvcf = [@"contacts" stringByAppendingPathComponent:@"global.vcf"];
    globalRequest.key = globalvcf;
    NSString *globalFilePath = [downloadingFilePath stringByAppendingPathComponent:@"global.vcf"];
    NSURL *globalURL = [NSURL fileURLWithPath:globalFilePath];
    globalRequest.downloadingFileURL = globalURL;
    [self download:globalRequest];
            
    AWSS3TransferManagerDownloadRequest *userRequest = [AWSS3TransferManagerDownloadRequest new];
    userRequest.bucket = self.s3BucketName;
    NSString *uservcf = [@"contacts" stringByAppendingPathComponent:usercontacts];
    userRequest.key = uservcf;
    NSString *userFilePath = [downloadingFilePath stringByAppendingPathComponent:usercontacts];
    userRequest.downloadingFileURL = [NSURL fileURLWithPath:userFilePath];
    [self download:userRequest];
}

- (void) handleVCard:(NSURL *)vcardURL {
    NSData *data = [NSData dataWithContentsOfURL:vcardURL];
    
    if (data == nil) {
        NSLog(@"Error reading file: %@", vcardURL.absoluteString);
        [self updateTempStatus:@"Could not update contacts"];
    } else {
        LinphoneProxyConfig *default_proxy = linphone_core_get_default_proxy_config(LC);
        if (default_proxy != NULL) {
            [[LinphoneManager.instance fastAddressBook] addContactRecordsWithVCardData:data];
            [LinphoneManager.instance fastAddressBook].needToUpdate = FALSE;
            [self updateTempStatus:@"Contacts updated"];
        }
    }
    NSLog(@"Finished processing file: %@", vcardURL.absoluteString);
}

- (void)download:(AWSS3TransferManagerDownloadRequest *)downloadRequest {
    AWSS3TransferManager *transferManager = [AWSS3TransferManager S3TransferManagerForKey:@"defaultKey"];
    [[transferManager download:downloadRequest] continueWithBlock:^id(AWSTask *task) {
        if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]
            && task.error.code == AWSS3TransferManagerErrorPaused) {
            NSLog(@"Download paused.");
        } else if (task.error) {
            NSLog(@"Download failed: [%@]", task.error);
            [self updateTempStatus:@"Could not update contacts"];
        } else {
            NSURL *downloadFileURL = downloadRequest.downloadingFileURL;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if ([[downloadFileURL pathExtension] isEqualToString:@"vcf"]) {
                    [self handleVCard:downloadFileURL];
                }
            });
        }
        
        return nil;
    }];
}

- (void)updateTempStatus:(NSString *)status {
    StatusBarView *sbar = (StatusBarView *)[PhoneMainView.instance.mainViewController
                                            getCachedController:NSStringFromClass(StatusBarView.class)];
    if (sbar) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [sbar updateTempStatus:status];
        });
    }
}

@end
