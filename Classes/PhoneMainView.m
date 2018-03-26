/* PhoneMainView.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioServices.h>
#import "LinphoneAppDelegate.h"
#import "Log.h"
#import "PhoneMainView.h"

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

#pragma mark - Lifecycle Functions

- (void)initPhoneMainView {
	currentView = nil;
	_currentRoom = NULL;
	_currentName = NULL;
	inhibitedEvents = [[NSMutableArray alloc] init];
    
    self.dataArray = [NSMutableArray new];
    
    // custom unable to complete call message
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"glacier_unable_to_complete_call"
                                              withExtension:@"mp3"];
    avCallFailedPlayer = [[AVAudioPlayer alloc]
                          initWithContentsOfURL:soundURL error:nil];
    avCallFailedPlayer.delegate = self;
    
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
        NSUserDefaults *glacierDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.glaciersec.apps"];
        _accountType = [glacierDefaults stringForKey:@"connection"];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[NSNotificationCenter.defaultCenter removeObserver:self];
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:NO];
    [self removeLocalVPNFiles];
}

// from commit 6491cce43c5c840940bcd30cbaca7cd3fe9b2e22
/* IPHONE X specific : hide the HomeIndcator when not used */  
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_X (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 812.0)
#define IPHONE_STATUSBAR_HEIGHT (IS_IPHONE_X ? 35 : 20)

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(IS_IPHONE_X){
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
    return UIInterfaceOrientationMaskPortrait; // UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
								duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[mainViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self orientationUpdate:toInterfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										 duration:(NSTimeInterval)duration {
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
	LinphoneAddress *from = [[notif.userInfo objectForKey:@"from_address"] pointerValue];
	NSString *callID = [notif.userInfo objectForKey:@"call-id"];
	[self updateApplicationBadgeNumber];
	LinphoneChatRoom *room = from ? linphone_core_get_chat_room(LC, from) : NULL;

	if (from == nil || room == NULL)
		return;

	ChatConversationView *view = VIEW(ChatConversationView);
	// if we already are in the conversation, we should not ring/vibrate
	if (view.chatRoom && linphone_address_weak_equal(linphone_chat_room_get_peer_address(room),
													 linphone_chat_room_get_peer_address(view.chatRoom)))
		return;

	if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
		return;

	LinphoneManager *lm = LinphoneManager.instance;
	// if the message was already received through a push notif, we don't need to ring
	if (![lm popPushCallID:callID]) {
		[lm playMessageSound];
	}
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
			[self changeCurrentView:view.compositeViewDescription];
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
			if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max && call) {
				NSString *callId =
					[NSString stringWithUTF8String:linphone_call_log_get_call_id(linphone_call_get_call_log(call))];
				NSUUID *uuid = [LinphoneManager.instance.providerDelegate.uuids objectForKey:callId];
				if (uuid) {
					[LinphoneManager.instance.providerDelegate.provider reportOutgoingCallWithUUID:uuid
																		   startedConnectingAtDate:nil];
				}
			}
			break;
		}
		case LinphoneCallStreamsRunning: {
			[self changeCurrentView:CallView.compositeViewDescription];
			if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max && call) {
				NSString *callId =
					[NSString stringWithUTF8String:linphone_call_log_get_call_id(linphone_call_get_call_log(call))];
				NSUUID *uuid = [LinphoneManager.instance.providerDelegate.uuids objectForKey:callId];
				if (uuid) {
					[LinphoneManager.instance.providerDelegate.provider reportOutgoingCallWithUUID:uuid
																				   connectedAtDate:nil];
					NSString *address = [FastAddressBook displayNameForAddress:linphone_call_get_remote_address(call)];
					CXCallUpdate *update = [[CXCallUpdate alloc] init];
					update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:address];
					update.supportsGrouping = TRUE;
					update.supportsDTMF = TRUE;
					update.supportsHolding = TRUE;
					update.supportsUngrouping = TRUE;
					[LinphoneManager.instance.providerDelegate.provider reportCallWithUUID:uuid updated:update];
				}
			}
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
			break;
		}
		case LinphoneCallEnd: {
			const MSList *calls = linphone_core_get_calls(LC);
			if (calls == NULL) {
				while ((currentView == CallView.compositeViewDescription) ||
					   (currentView == CallIncomingView.compositeViewDescription) ||
					   (currentView == CallOutgoingView.compositeViewDescription)) {
					[self popCurrentView];
				}
			} else {
				linphone_call_resume((LinphoneCall *)calls->data);
				while (calls) {
					if (linphone_call_get_state((LinphoneCall *)calls->data) == LinphoneCallIncomingReceived ||
						linphone_call_get_state((LinphoneCall *)calls->data) == LinphoneCallIncomingEarlyMedia) {
						[self displayIncomingCall:(LinphoneCall *)calls->data];
						break;
					}
					calls = calls->next;
				}
				if (calls == NULL) {
					[self changeCurrentView:CallView.compositeViewDescription];
				}
			}
			break;
		}
		case LinphoneCallEarlyUpdatedByRemote:
		case LinphoneCallEarlyUpdating:
		case LinphoneCallIdle:
			break;
		case LinphoneCallOutgoingEarlyMedia:
		case LinphoneCallOutgoingProgress: {
			if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max && call &&
				(linphone_core_get_calls_nb(LC) < 2)) {
				// Link call ID to UUID
				NSString *callId =
					[NSString stringWithUTF8String:linphone_call_log_get_call_id(linphone_call_get_call_log(call))];
				NSUUID *uuid = [LinphoneManager.instance.providerDelegate.uuids objectForKey:@""];
				if (uuid) {
					[LinphoneManager.instance.providerDelegate.uuids removeObjectForKey:@""];
					[LinphoneManager.instance.providerDelegate.uuids setObject:uuid forKey:callId];
					[LinphoneManager.instance.providerDelegate.calls setObject:callId forKey:uuid];
				}
			}
			break;
		}
		case LinphoneCallOutgoingRinging:
		case LinphoneCallPaused:
		case LinphoneCallPausing:
		case LinphoneCallRefered:
		case LinphoneCallReleased:
			break;
		case LinphoneCallResuming: {
			if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max && call) {
				NSUUID *uuid = (NSUUID *)[LinphoneManager.instance.providerDelegate.uuids
					objectForKey:[NSString stringWithUTF8String:linphone_call_log_get_call_id(
																	linphone_call_get_call_log(call))]];
				if (!uuid) {
					return;
				}
				CXSetHeldCallAction *act = [[CXSetHeldCallAction alloc] initWithCallUUID:uuid onHold:NO];
				CXTransaction *tr = [[CXTransaction alloc] initWithAction:act];
				[LinphoneManager.instance.providerDelegate.controller requestTransaction:tr
																			  completion:^(NSError *err){
																			  }];
			}
			break;
		}
		case LinphoneCallUpdating:
			break;
	}
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
		LinphoneCall *call = linphone_core_get_current_call(LC);
		if (call && linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
			// Orientation has changed, must call update call
			linphone_core_update_call(LC, call, NULL);
		}
	}
}
- (void)startUp {
	@try {
        // (may not have logged out when app closed)
        [self setupCognito];
        [self teardownCognito];
        
		LinphoneManager *lm = LinphoneManager.instance;
        LOGE(@"%s", linphone_global_state_to_string(
                    linphone_core_get_global_state(LC)));
        if (linphone_core_get_global_state(LC) != LinphoneGlobalOn) {
            [self changeCurrentView:DialerView.compositeViewDescription];
        } else if ([LinphoneManager.instance
            lpConfigBoolForKey:@"enable_first_login_view_preference"] == true) {
            [PhoneMainView.instance changeCurrentView:FirstLoginView.compositeViewDescription];
        } else {
            // always start to dialer when testing
            // Change to default view
            const MSList *list = linphone_core_get_proxy_config_list(LC);
            if (list != NULL ||
                ([lm lpConfigBoolForKey:@"hide_assistant_preference"] == true) || lm.isTesting) {
                    [self changeCurrentView:DialerView.compositeViewDescription];
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
                                           initWithSuiteName:@"group.com.glaciersec.apps"];
        NSString *extvalue = [glacierDefaults stringForKey:@"extension"];
        NSString *passvalue = [glacierDefaults stringForKey:@"password"];
        NSString *displayvalue = [glacierDefaults stringForKey:@"displayname"];
        NSString *connectionvalue = [glacierDefaults stringForKey:@"connection"];
        
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
                if ([connectionvalue isEqualToString:@"openvpn"]) {
                    if ([self needsOpenVPN]) {
                        [self returnToMainView];
                        return;
                    }
                }
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
                    [[LinphoneManager.instance fastAddressBook] reload];
                    
                    SettingsView *sview = VIEW(SettingsView);
                    if (sview) {
                        [sview trySynchronize];
                    }
                    [self returnToMainView];
                    
                    UIApplication *app = [UIApplication sharedApplication];
                    LinphoneAppDelegate *delegate = (LinphoneAppDelegate *)app.delegate;
                    [delegate registerForNotifications:app];
                    [delegate tryWaitForNetwork];
                    
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
    [self setupCognito];
    
    AssistantView *view = VIEW(AssistantView);
    [self changeCurrentView:view.compositeViewDescription];
    [view reset:needsNewAccount];
    
    //on initial load set the user and refresh to get attributes
    [self getUserDetails];
}

- (void)updateApplicationBadgeNumber {
	int count = 0;
	count += linphone_core_get_missed_calls_count(LC);
	count += [LinphoneManager unreadMessageCount];
	count += linphone_core_get_calls_nb(LC);
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
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

	if ([old equal:ChatsListView.compositeViewDescription]) {
		if ([new equal:ContactsListView.compositeViewDescription] || [new equal:DialerView.compositeViewDescription] ||
			[new equal:HistoryListView.compositeViewDescription]) {
			left = true;
		}
	} else if ([old equal:SettingsView.compositeViewDescription]) {
		if ([new equal:DialerView.compositeViewDescription] || [new equal:ContactsListView.compositeViewDescription] ||
			[new equal:HistoryListView.compositeViewDescription] ||
			[new equal:ChatsListView.compositeViewDescription]) {
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
		NSMutableArray *viewStack = [RootViewManager instance].viewDescriptionStack;
		[viewStack addObject:view];
		if (animated && transition == nil)
			transition = [PhoneMainView getTransition:vc.currentView new:view];
		[vc.mainViewController setViewTransition:(animated ? transition : nil)];
		[vc updateStatusBar:view];
		[vc.mainViewController changeView:view];
		vc->currentView = view;
	}

	//[[RootViewManager instance] setViewControllerForDescription:view];

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
			lMessage = [NSString stringWithFormat:NSLocalizedString(@"%@ is not registered.", nil), lUserName];
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
	UIAlertController *errView = [UIAlertController alertControllerWithTitle:lTitle
																	 message:lMessage
															  preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
															style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * action) {}];
	
	[errView addAction:defaultAction];
	[self presentViewController:errView animated:YES completion:nil];
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
			[lm acceptCall:call evenWithVideo:YES];
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
		LinphoneCallAppData *callData = (__bridge LinphoneCallAppData *)linphone_call_get_user_data(call);
		if (callData != nil) {
			if (state == UIDeviceBatteryStateUnplugged) {
				if (level <= 0.2f && !callData->batteryWarningShown) {
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
												  linphone_core_update_call(LC, call, params);
												}];
					[sheet showInView:self.view];
					callData->batteryWarningShown = TRUE;
				}
			}
			if (level > 0.2f) {
				callData->batteryWarningShown = FALSE;
			}
		}
	}
}

#pragma mark - IncomingCallDelegate Functions

- (void)incomingCallAborted:(LinphoneCall *)call {
}

- (void)incomingCallAccepted:(LinphoneCall *)call evenWithVideo:(BOOL)video {
	[LinphoneManager.instance acceptCall:call evenWithVideo:video];
}

- (void)incomingCallDeclined:(LinphoneCall *)call {
	linphone_call_terminate(call);
}

// here to end AWS Cognito is the primary way to login and pull account settings
- (void)setupCognito {
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"download"] withIntermediateDirectories:YES
                                                    attributes:nil error:&error]) {
        LOGW(@"Creating 'download' directory failed. Error: [%@]", error);
    }
    
    if (!self.pool) {
        AWSServiceConfiguration *serviceConfiguration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
        
        // get Cognito login IDs
        if (secretDict != nil) {
            NSString *cognitoId = [secretDict objectForKey:@"cognitoClientID"];
            NSString *cognitoSecret = [secretDict objectForKey:@"cognitoClientSecret"];
            NSString *cognitoPoolId = [secretDict objectForKey:@"cognitoPoolID"];
            AWSCognitoIdentityUserPoolConfiguration *configuration = [[AWSCognitoIdentityUserPoolConfiguration alloc] initWithClientId:cognitoId clientSecret:cognitoSecret poolId:cognitoPoolId];
            [AWSCognitoIdentityUserPool registerCognitoIdentityUserPoolWithConfiguration:serviceConfiguration userPoolConfiguration:configuration forKey:@"GlacierUserPool"];
        } else {
            LOGW(@"Problem getting Cognito login info");
        }
        self.pool = [AWSCognitoIdentityUserPool CognitoIdentityUserPoolForKey:@"GlacierUserPool"];
        self.pool.delegate = self;
    }
}

- (void) teardownCognito {
    if(self.pool && [self.pool currentUser]) {
        [[self.pool currentUser] signOut];
        self.pool = nil;
    }
}

- (BOOL) coreSignedIn {
    BOOL isSignedIn = FALSE;
    if(self.pool && [self.pool currentUser]) {
        isSignedIn = [self.pool currentUser].signedIn;
    }
    
    return isSignedIn;
}

- (void) handleAddVpnProfile {
    if (_accountType != nil && ![_accountType isEqualToString:@"openvpn"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Account notification" message:@"Your account does not support adding VPN configurations. Contact your administrator for more information." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if (![self coreSignedIn]) {
        [self displayAssistantView:NO];
    } else {
        [self getUserDetails];
        
        [self returnToMainView];
    }
}

//set up password authentication ui to retrieve username and password from the user
-(id<AWSCognitoIdentityPasswordAuthentication>) startPasswordAuthentication {
    return VIEW(AssistantView);
 }

-(void) getUserDetails {
    if(!self.user)
        self.user = [self.pool currentUser];
    
    [[self.user getDetails] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserGetDetailsResponse *> * _Nonnull task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(task.error){
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:task.error.userInfo[@"__type"] message:@"Some error." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:cancel];
                [self presentViewController:alert animated:YES completion:nil];
            }else {
                [self getS3Bucket];
            }
        });
        
        return nil;
    }];
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

- (void) getS3Bucket {
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                                                          initWithRegionType:AWSRegionUSEast1
                                                          identityPoolId:@"us-east-1:81149e88-648e-4a66-a912-e062ce781cec" identityProviderManager:self.pool];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
    
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    [AWSS3 registerS3WithConfiguration:configuration forKey:@"defaultKey"];
    
    [self createListObjectsRequest];
}

- (void) createListObjectsRequest {
    NSUserDefaults *glacierDefaults = [[NSUserDefaults alloc]
                                       initWithSuiteName:@"group.com.glaciersec.apps"];
    self.bucketOrg = [glacierDefaults objectForKey:@"orgid"];
    if (self.bucketOrg) {
        AWSS3ListObjectsRequest *listObjectsRequest = [AWSS3ListObjectsRequest new];
        self.bucketPrefix = @"users"; //identityId;
        listObjectsRequest.prefix = self.bucketPrefix;
        
        // get AWS bucket name to pull account settings from
        if (secretDict != nil) {
            self.s3BucketName = [[secretDict objectForKey:@"s3BucketConstant"] stringByAppendingString:self.bucketOrg];
            listObjectsRequest.bucket = self.s3BucketName;
            [self listObjects:listObjectsRequest];
        } else {
            NSLog(@"Could not createListObjectsRequestWithId due to no Secrets.plist in bundle");
        }
    } else {
        NSLog(@"Could not createListObjectsRequestWithId due to no Org Id");
    }
}

- (void) listObjects:(AWSS3ListObjectsRequest*)listObjectsRequest {
    AWSS3 *s3 = [AWSS3 S3ForKey:@"defaultKey"];
    [[s3 listObjects:listObjectsRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"listObjects failed: [%@]", task.error);
            // This happens is we fat fingered the org and no bucket exists. Appropriate notification?
            // Go back to login screen?
            [self returnToMainView]; // temp solution
        } else {
            AWSS3ListObjectsOutput *listObjectsOutput = task.result;
            NSString *undername = [@"_" stringByAppendingString:self.user.username];
            NSString *gstring = [self.user.username stringByAppendingPathExtension:@"glacier"];
            NSString *ostring = [undername stringByAppendingPathExtension:@"ovpn"];
            
            [self.dataArray removeAllObjects];
            
            for (AWSS3Object *s3Object in listObjectsOutput.contents) {
                NSString *downloadingFilePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"download"] stringByAppendingPathComponent:[s3Object.key lastPathComponent]];
                NSURL *downloadingFileURL = [NSURL fileURLWithPath:downloadingFilePath];
                
                if ([[downloadingFilePath lastPathComponent] isEqualToString:gstring]) { //hasSuffix:gstring]) {
                    self.glacierData = downloadingFileURL;
                } else if ([downloadingFilePath hasSuffix:ostring]) {
                    [self.dataArray addObject:downloadingFileURL];
                }
            }
            
            [self getGlacierData];
            
            if (self.dataArray.count > 0 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"openvpn://"]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    CZPickerView *picker = [[CZPickerView alloc] initWithHeaderTitle:@"Add VPN Connection"
                                                                   cancelButtonTitle:@"Cancel"
                                                                  confirmButtonTitle:@"Confirm"];
                    picker.delegate = self;
                    picker.dataSource = self;
                    /** picker header background color */
                    picker.headerBackgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"color_Gl.png"]];

                    [picker show];
                });
            }
        }
        return nil;
    }];
}

- (void) getGlacierData {
    if (self.glacierData) {
        NSString *downloadingFilePath = self.glacierData.absoluteString;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:downloadingFilePath]) {
            [self readAndStoreGlacierData];
        } else {
            AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
            downloadRequest.bucket = self.s3BucketName;
            NSString *keytest = [self.bucketPrefix stringByAppendingPathComponent:[self.glacierData lastPathComponent]];
            downloadRequest.key = keytest;
            downloadRequest.downloadingFileURL = self.glacierData;
            [self download:downloadRequest];
        }
    } else {
        [self returnToMainView];
    }
}

- (void) readAndStoreGlacierData {
    // read file
    if (!self.glacierData) {
        return;
    }
    
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfURL:self.glacierData encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
        NSLog(@"Error reading file: %@", error.localizedDescription);
    
    // maybe for debugging...
    //NSLog(@"contents: %@", fileContents);
    
    NSArray *listArray = [fileContents componentsSeparatedByString:@"\n"];
    
    if (listArray.count) {
        NSUserDefaults *glacierDefaults = [[NSUserDefaults alloc]
                                           initWithSuiteName:@"group.com.glaciersec.apps"];
        
        for (NSString *gTemp in listArray) {
            NSArray *props = [gTemp componentsSeparatedByString:@"="];
            if (props.count == 2) {
                [glacierDefaults setObject:props.lastObject forKey:props.firstObject];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupAccount];
        });
    }
}

- (void)download:(AWSS3TransferManagerDownloadRequest *)downloadRequest {
    
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    [[transferManager download:downloadRequest] continueWithBlock:^id(AWSTask *task) {
        if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]
            && task.error.code == AWSS3TransferManagerErrorPaused) {
            NSLog(@"Download paused.");
        } else if (task.error) {
            NSLog(@"Download failed: [%@]", task.error);
        } else {
            NSURL *downloadFileURL = downloadRequest.downloadingFileURL;
            if ([[downloadFileURL pathExtension] isEqualToString:@"glacier"]) {
                [self readAndStoreGlacierData];
            } else if ([[downloadFileURL pathExtension] isEqualToString:@"ovpn"]) {
                [self tryOpenUrl:downloadFileURL];
            }
        }
        return nil;
    }];
}

- (UIDocumentInteractionController *)controller {
    
    if (!_controller) {
        _controller = [[UIDocumentInteractionController alloc]init];
        _controller.delegate = self;
        _controller.UTI = @"net.openvpn.formats.ovpn";
    }
    return _controller;
}

- (void) tryOpenUrl:(NSURL *)fileURL {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (fileURL) {
            //Starting to send this to net.openvpn.connect.app
            self.controller.URL = fileURL;
            [self.controller presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
        }
    });
}

// Remove VPN profiles that were pulled from S3 bucket
- (void) removeLocalVPNFiles {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSURL *url in self.dataArray) {
        NSString *filePath = [url path];
        NSError *error;
        if ([fileManager fileExistsAtPath:filePath]) {
            BOOL success = [fileManager removeItemAtPath:filePath error:&error];
            if (success) {
                NSLog(@"Success removing profile");
            } else {
                NSLog(@"Failure removing profile: %@", [error localizedDescription]);
            }
        }
    }
    
    [self.dataArray removeAllObjects];
}

- (BOOL) needsOpenVPN {
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"openvpn://"]])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"You do not have an app that can open this file. Please download OpenVPN Connect from the App Store." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
        return true;
    }
    
    return false;
}

#pragma mark - Delegate Methods
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return  self;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application {
    NSLog(@"Starting to send this puppy to %@", application);
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
    NSLog(@"We're done sending the document.");
}

#pragma mark - CZPickerViewDataSource

/* number of items for picker */
- (NSInteger)numberOfRowsInPickerView:(CZPickerView *)pickerView {
    return [self.dataArray count];
}

/* picker item title for each row */
- (NSString *)czpickerView:(CZPickerView *)pickerView titleForRow:(NSInteger)row {
    NSURL *url = self.dataArray[row];
    return [[url lastPathComponent] stringByDeletingPathExtension];
}

#pragma mark - CZPickerViewDelegate
/** delegate method for picking one item */
- (void)czpickerView:(CZPickerView *)pickerView didConfirmWithItemAtRow:(NSInteger)row {
    
    NSURL *downloadingFileURL = self.dataArray[row];
    NSString *downloadingFilePath = downloadingFileURL.absoluteString;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadingFilePath]) {
        [self tryOpenUrl:downloadingFileURL];
    } else {
        AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
        downloadRequest.bucket = self.s3BucketName;
        NSString *keytest = [self.bucketPrefix stringByAppendingPathComponent:[downloadingFileURL lastPathComponent]];
        downloadRequest.key = keytest;
        downloadRequest.downloadingFileURL = downloadingFileURL;
        [self download:downloadRequest];
    }
}

/** delegate method for canceling */
- (void)czpickerViewDidClickCancelButton:(CZPickerView *)pickerView {
    
}

@end