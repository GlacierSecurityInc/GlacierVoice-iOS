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

#import "LinphoneAppDelegate.h"
#import "ContactDetailsView.h"
#import "ContactsListView.h"
#import "PhoneMainView.h"
#import "ShopView.h"

#import "CoreTelephony/CTCallCenter.h"
#import "CoreTelephony/CTCall.h"

#import "LinphoneCoreSettingsStore.h"

#include "LinphoneManager.h"
#include "linphone/linphonecore.h"

#ifdef USE_CRASHLYTHICSS
#include "FIRApp.h"
#endif

@implementation LinphoneAppDelegate

@synthesize configURL;
@synthesize window;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super init];
	if (self != nil) {
		startedInBackground = FALSE;
	}
	_alreadyRegisteredForNotification = false;
    _onlyPortrait = FALSE;
	return self;
	[[UIApplication sharedApplication] setDelegate:self];
}

#pragma mark -

- (void)applicationDidEnterBackground:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	[LinphoneManager.instance enterBackgroundMode];
    [CoreManager.instance stopLinphoneCore];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [LinphoneManager.instance startLinphoneCore];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	LinphoneCall *call = linphone_core_get_current_call(LC);

	if (!call)
		return;

	/* save call context */
	LinphoneManager *instance = LinphoneManager.instance;
	instance->currentCallContextBeforeGoingBackground.call = call;
	instance->currentCallContextBeforeGoingBackground.cameraIsEnabled = linphone_call_camera_enabled(call);

	const LinphoneCallParams *params = linphone_call_get_current_params(call);
	if (linphone_call_params_video_enabled(params))
		linphone_call_enable_camera(call, false);
}

-(void)becameActive {
    if (!startedInBackground || PhoneMainView.instance.currentView == nil) {
        startedInBackground = TRUE;
        // initialize UI
        [PhoneMainView.instance startUp];
        [PhoneMainView.instance updateStatusBar:nil];
    }
    LinphoneManager *instance = LinphoneManager.instance;
    [instance becomeActive];

    if (instance.fastAddressBook.needToUpdate) {
        //Update address book for external changes
        if (PhoneMainView.instance.currentView == ContactsListView.compositeViewDescription || PhoneMainView.instance.currentView == ContactDetailsView.compositeViewDescription) {
            [PhoneMainView.instance changeCurrentView:DialerView.compositeViewDescription];
        }
                [instance.fastAddressBook fetchContactsInBackGroundThread];
                instance.fastAddressBook.needToUpdate = FALSE;
        }

        LinphoneCall *call = linphone_core_get_current_call(LC);

        if (call) {
          if (call == instance->currentCallContextBeforeGoingBackground.call) {
            const LinphoneCallParams *params =
                linphone_call_get_current_params(call);
            if (linphone_call_params_video_enabled(params)) {
              linphone_call_enable_camera(
                  call, instance->currentCallContextBeforeGoingBackground
                            .cameraIsEnabled);
            }
            instance->currentCallContextBeforeGoingBackground.call = 0;
          } else if (linphone_call_get_state(call) ==
                     LinphoneCallIncomingReceived) {
            if ((floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max)) {
              if ([LinphoneManager.instance lpConfigBoolForKey:@"autoanswer_notif_preference"]) {
                linphone_call_accept(call);
                [PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
              } else {
                [PhoneMainView.instance displayIncomingCall:call];
              }
            } else {
              // Click the call notification when callkit is disabled, show app view.
              [PhoneMainView.instance displayIncomingCall:call];
            }

            // in this case, the ringing sound comes from the notification.
            // To stop it we have to do the iOS7 ring fix...
            [self fixRing];
          }
        }
        [LinphoneManager.instance.iapManager check];
    if (_shortcutItem) {
        [self handleShortcut:_shortcutItem];
        _shortcutItem = nil;
    }
    [HistoryListTableView saveDataToUserDefaults];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));
    
    if (linphone_core_get_calls(LC) == NULL && [self getDomain]) {
        [self tryWaitForNetwork];
        [self setNetworkConnectingStatus];
        
        if (self.justLaunched) {
            self.justLaunched = FALSE;
        } else {
            [self registerForNotifications];
        }
    } else {
        [self becameActive];
    }
}

#pragma deploymate push "ignored-api-availability"

- (void)registerForNotifications {
    if (_alreadyRegisteredForNotification && [[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
        LOGI(@"[APNs] register for push notif");
        [[UIApplication sharedApplication] registerForRemoteNotifications];
		return;
    }

	_alreadyRegisteredForNotification = true;
	self.voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
	self.voipRegistry.delegate = self;

	// Initiate registration.
	LOGI(@"[PushKit] Connecting for push notifications");
	self.voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    
    // Register for remote notifications.
    LOGI(@"[APNs] register for push notif");
    [[UIApplication sharedApplication] registerForRemoteNotifications];

	[self configureUINotification];
}

- (void)configureUINotification {
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max)
		return;

	LOGI(@"Connecting for UNNotifications");
	// Call category
	UNNotificationAction *act_ans =
	[UNNotificationAction actionWithIdentifier:@"Answer"
										 title:NSLocalizedString(@"Answer", nil)
									   options:UNNotificationActionOptionForeground];
	UNNotificationAction *act_dec = [UNNotificationAction actionWithIdentifier:@"Decline"
																		 title:NSLocalizedString(@"Decline", nil)
																	   options:UNNotificationActionOptionNone];
	UNNotificationCategory *cat_call =
	[UNNotificationCategory categoryWithIdentifier:@"call_cat"
										   actions:[NSArray arrayWithObjects:act_ans, act_dec, nil]
								 intentIdentifiers:[[NSMutableArray alloc] init]
										   options:UNNotificationCategoryOptionCustomDismissAction];
	// Msg category
	UNTextInputNotificationAction *act_reply =
	[UNTextInputNotificationAction actionWithIdentifier:@"Reply"
												  title:NSLocalizedString(@"Reply", nil)
												options:UNNotificationActionOptionNone];
	UNNotificationAction *act_seen =
	[UNNotificationAction actionWithIdentifier:@"Seen"
										 title:NSLocalizedString(@"Mark as seen", nil)
									   options:UNNotificationActionOptionNone];
	UNNotificationCategory *cat_msg =
	[UNNotificationCategory categoryWithIdentifier:@"msg_cat"
										   actions:[NSArray arrayWithObjects:act_reply, act_seen, nil]
								 intentIdentifiers:[[NSMutableArray alloc] init]
										   options:UNNotificationCategoryOptionCustomDismissAction];

	// Video Request Category
	UNNotificationAction *act_accept =
	[UNNotificationAction actionWithIdentifier:@"Accept"
										 title:NSLocalizedString(@"Accept", nil)
									   options:UNNotificationActionOptionForeground];

	UNNotificationAction *act_refuse = [UNNotificationAction actionWithIdentifier:@"Cancel"
																			title:NSLocalizedString(@"Cancel", nil)
																		  options:UNNotificationActionOptionNone];
	UNNotificationCategory *video_call =
	[UNNotificationCategory categoryWithIdentifier:@"video_request"
										   actions:[NSArray arrayWithObjects:act_accept, act_refuse, nil]
								 intentIdentifiers:[[NSMutableArray alloc] init]
										   options:UNNotificationCategoryOptionCustomDismissAction];

	// ZRTP verification category
	UNNotificationAction *act_confirm = [UNNotificationAction actionWithIdentifier:@"Confirm"
																			 title:NSLocalizedString(@"Accept", nil)
																		   options:UNNotificationActionOptionNone];

	UNNotificationAction *act_deny = [UNNotificationAction actionWithIdentifier:@"Deny"
																		  title:NSLocalizedString(@"Deny", nil)
																		options:UNNotificationActionOptionNone];
	UNNotificationCategory *cat_zrtp =
	[UNNotificationCategory categoryWithIdentifier:@"zrtp_request"
										   actions:[NSArray arrayWithObjects:act_confirm, act_deny, nil]
								 intentIdentifiers:[[NSMutableArray alloc] init]
										   options:UNNotificationCategoryOptionCustomDismissAction];

	[UNUserNotificationCenter currentNotificationCenter].delegate = self;
	[[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
																		completionHandler:^(BOOL granted, NSError *_Nullable error) {
																			// Enable or disable features based on authorization.
																			if (error)
																				LOGD(error.description);
																		}];
    
	NSSet *categories = [NSSet setWithObjects:cat_call, cat_msg, video_call, cat_zrtp, nil];
	[[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:categories];
}

#pragma deploymate pop

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef USE_CRASHLYTHICSS
	[FIRApp configure];
#endif
    
    UIApplication *app = [UIApplication sharedApplication];
	UIApplicationState state = app.applicationState;

	LinphoneManager *instance = [LinphoneManager instance];
	//init logs asap
	[Log enableLogs:[[LinphoneManager instance] lpConfigIntForKey:@"debugenable_preference"]];
	
	//Starting with iOS 13, the CNCopyCurrentNetworkInfo API will no longer return valid Wi-Fi SSID and BSSID information.
	//Use the CoreLocation API to request the user’s consent to access location information.
	if (@available(iOS 13.0, *)) {
		CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
		switch(status) {
			case kCLAuthorizationStatusDenied:
			case kCLAuthorizationStatusRestricted:
			case kCLAuthorizationStatusNotDetermined:
				locationManager = [[CLLocationManager alloc]init];
				locationManager.delegate = self;
				[locationManager requestWhenInUseAuthorization];
				break;
			default:
				break;
		}
	}

	BOOL background_mode = [instance lpConfigBoolForKey:@"backgroundmode_preference"];
	BOOL start_at_boot = [instance lpConfigBoolForKey:@"start_at_boot_preference"];
	[self registerForNotifications]; // Register for notifications must be done ASAP to give a chance for first SIP register to be done with right token. Specially true in case of remote provisionning or re-install with new type of signing certificate, like debug to release.
    self.justLaunched = TRUE;

	if (state == UIApplicationStateBackground) {
		// we've been woken up directly to background;
		if (!start_at_boot || !background_mode) {
			// autoboot disabled or no background, and no push: do nothing and wait for a real launch
			//output a log with NSLog, because the ortp logging system isn't activated yet at this time
			NSLog(@"Linphone launch doing nothing because start_at_boot or background_mode are not activated.", NULL);
			return YES;
		}
		startedInBackground = true;
	}
	bgStartId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
	  LOGW(@"Background task for application launching expired.");
	  [[UIApplication sharedApplication] endBackgroundTask:bgStartId];
	}];
    
    [LinphoneManager.instance setConnectingToNetwork:TRUE];

	[LinphoneManager.instance launchLinphoneCore];
	LinphoneManager.instance.iapManager.notificationCategory = @"expiry_notification";
	// initialize UI
	[self.window makeKeyAndVisible];
	[RootViewManager setupWithPortrait:(PhoneMainView *)self.window.rootViewController];
    
    [PhoneMainView.instance updateStatusBar:nil];

	if (bgStartId != UIBackgroundTaskInvalid)
		[[UIApplication sharedApplication] endBackgroundTask:bgStartId];

    //Enable all notification type. VoIP Notifications don't present a UI but we will use this to show local nofications later
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert| UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];

    //register the notification settings
    [application registerUserNotificationSettings:notificationSettings];

    //output what state the app is in. This will be used to see when the app is started in the background
    LOGI(@"app launched with state : %li", (long)application.applicationState);
    LOGI(@"FINISH LAUNCHING WITH OPTION : %@", launchOptions.description);
    
    UIApplicationShortcutItem *shortcutItem = [launchOptions objectForKey:@"UIApplicationLaunchOptionsShortcutItemKey"];
    if (shortcutItem) {
        _shortcutItem = shortcutItem;
        return NO;
    }

	return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	LinphoneManager.instance.conf = TRUE;
	linphone_core_terminate_all_calls(LC);
	[CallManager.instance removeAllCallInfos];

	[LinphoneManager.instance destroyLinphoneCore];
    
    [PhoneMainView.instance teardownCognito];
}

- (BOOL)handleShortcut:(UIApplicationShortcutItem *)shortcutItem {
    BOOL success = NO;
    //
    return success;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    completionHandler([self handleShortcut:shortcutItem]);
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options{
	NSString *scheme = [[url scheme] lowercaseString];
	if ([scheme isEqualToString:@"linphone-config"] || [scheme isEqualToString:@"linphone-config"]) {
		NSString *encodedURL =
			[[url absoluteString] stringByReplacingOccurrencesOfString:@"linphone-config://" withString:@""];
		self.configURL = [encodedURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Remote configuration", nil)
																		 message:NSLocalizedString(@"This operation will load a remote configuration. Continue ?", nil)
																  preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil)
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];

		UIAlertAction* yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil)
																style:UIAlertActionStyleDefault
														  handler:^(UIAlertAction * action) {
															  [self showWaitingIndicator];
															  [self attemptRemoteConfiguration];
														  }];

		[errView addAction:defaultAction];
		[errView addAction:yesAction];

		[PhoneMainView.instance presentViewController:errView animated:YES completion:nil];
    } else if ([scheme isEqualToString:@"sip"]) {
        // remove "sip://" from the URI, and do it correctly by taking resourceSpecifier and removing leading and
        // trailing "/"
        NSString *sipUri = [[url resourceSpecifier] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        [VIEW(DialerView) setAddress:sipUri];
    } else if ([scheme isEqualToString:@"linphone-widget"]) {
        if ([[url host] isEqualToString:@"call_log"] &&
            [[url path] isEqualToString:@"/show"]) {
            [VIEW(HistoryDetailsView) setCallLogId:[url query]];
            [PhoneMainView.instance changeCurrentView:HistoryDetailsView.compositeViewDescription];
        }
    } else if ([scheme isEqualToString:@"glaciervoice"]) {
        NSString *test = [options objectForKey:@"UIApplicationOpenURLOptionsSourceApplicationKey"];
        if (![test isEqualToString:@"com.glacier.Messenger"]) {
            // maybe check what is in options?
            return [[AWSCognitoAuth defaultCognitoAuth] application:application openURL:url options:options];
        }
    }
    return YES;
}

// used for callkit. Called when active video.
- (BOOL)application:(UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
	if ([userActivity.activityType isEqualToString:@"INStartVideoCallIntent"]) {
		LOGI(@"CallKit: satrt video.");
		CallView *view = VIEW(CallView);
		[view.videoButton toggle];
	}
	return YES;
}

- (NSString *)valueForKey:(NSString *)key fromQueryItems:(NSArray *)queryItems {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
    NSURLQueryItem *queryItem = [[queryItems filteredArrayUsingPredicate:predicate] firstObject];
    return queryItem.value;
}

- (void)fixRing {
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
		// iOS7 fix for notification sound not stopping.
		// see http://stackoverflow.com/questions/19124882/stopping-ios-7-remote-notification-sound
		[[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
		[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	}
}

- (void)processRemoteNotification:(NSDictionary *)userInfo {
	NSDictionary *aps = [userInfo objectForKey:@"aps"];
    
    NSString *callId = [userInfo objectForKey:@"call-id"];
    if (callId == nil) {
        NSDictionary *alert = [aps objectForKey:@"alert"];
        if (alert != nil) {
            NSString *loc_key = [alert objectForKey:@"loc-key"];
            if (loc_key != nil) {
                callId = [userInfo objectForKey:@"call-id"];
            }
        }
    }
    if (callId == nil) { callId = @"";}

	if([CallManager callKitEnabled]) {
		// Since ios13, a new Incoming call must be displayed when the callkit is enabled and app is in background.
		// Otherwise it will cause a crash.
        [CallManager.instance displayIncomingCallWithCallId:callId];
	} else {
		if (linphone_core_get_calls(LC)) {
			// if there are calls, obviously our TCP socket shall be working
			LOGD(@"Notification [%p] has no need to be processed because there already is an active call.", userInfo);
            self.pushInfo = nil;
			return;
		}

		if ([callId isEqualToString:@""]) {
			// Present apn pusher notifications for info
			LOGD(@"Notification [%p] came from flexisip-pusher.", userInfo);
			if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
				UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
				content.title = @"APN Pusher";
				content.body = @"Push notification received !";

				UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"call_request" content:content trigger:NULL];
				[[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:req withCompletionHandler:^(NSError * _Nullable error) {
					// Enable or disable features based on authorization.
					if (error) {
						LOGD(@"Error while adding notification request :");
						LOGD(error.description);
					}
				}];
			}
		}
	}

    LOGI(@"Notification [%p] processed", userInfo);
	// Tell the core to make sure that we are registered.
	// It will initiate socket connections, which seems to be required.
	// Indeed it is observed that if no network action is done in the notification handler, then
	// iOS kills us.
	linphone_core_ensure_registered(LC);
    self.pushInfo = nil;
}

- (BOOL)addLongTaskIDforCallID:(NSString *)callId {
	if (!callId)
		return FALSE;

	if ([callId isEqualToString:@""])
		return FALSE;

	NSDictionary *dict = LinphoneManager.instance.pushDict;
	if ([[dict allKeys] indexOfObject:callId] != NSNotFound)
		return FALSE;

	LOGI(@"Adding long running task for call id : %@ with index : 1", callId);
	[dict setValue:[NSNumber numberWithInt:1] forKey:callId];
	return TRUE;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	LOGI(@"%@ : %@", NSStringFromSelector(_cmd), userInfo);
	[self processRemoteNotification:userInfo];
}

- (LinphoneChatRoom *)findChatRoomForContact:(NSString *)contact {
	const MSList *rooms = linphone_core_get_chat_rooms(LC);
	const char *from = [contact UTF8String];
	while (rooms) {
		const LinphoneAddress *room_from_address = linphone_chat_room_get_peer_address((LinphoneChatRoom *)rooms->data);
		char *room_from = linphone_address_as_string_uri_only(room_from_address);
		if (room_from && strcmp(from, room_from) == 0){
			ms_free(room_from);
			return rooms->data;
		}
		if (room_from) ms_free(room_from);
		rooms = rooms->next;
	}
	return NULL;
}

#pragma mark - PushNotification Functions

- (void)application:(UIApplication *)application
	didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	LOGI(@"[APNs] %@ : %@", NSStringFromSelector(_cmd), deviceToken);
    [LinphoneManager.instance setRemoteNotificationToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	LOGI(@"[APNs] %@ : %@", NSStringFromSelector(_cmd), [error localizedDescription]);
    [LinphoneManager.instance setRemoteNotificationToken:nil];
}

#pragma mark - PushKit Functions

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type {
	LOGI(@"[PushKit] credentials updated with voip token: %@", credentials.token);
	dispatch_async(dispatch_get_main_queue(), ^{ 
        [LinphoneManager.instance setPushKitToken:credentials.token];
        [self sendDeviceToken:credentials.token];
	});
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(NSString *)type {
    LOGI(@"[PushKit] Token invalidated");
    dispatch_async(dispatch_get_main_queue(), ^{[LinphoneManager.instance setPushKitToken:nil];});
}

- (void)processPush:(NSDictionary *)userInfo {
	LOGI(@"[PushKit] Notification [%p] received with payload : %@", userInfo, userInfo.description);
    
    // prevent app to crash if PushKit received for msg
    if ([userInfo[@"aps"][@"loc-key"] isEqualToString:@"IM_MSG"]) {
        LOGE(@"Received a legacy PushKit notification for a chat message");
        return;
    }
    [LinphoneManager.instance startLinphoneCore];
    
    self.pushInfo = userInfo;
    
	[self configureUINotification];
	//to avoid IOS to suspend the app before being able to launch long running task
	[self processRemoteNotification:userInfo];
    
    if ([LinphoneManager.instance lpConfigBoolForKey:@"account_watch_notification"]) {
        [self watchNotification];
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion {
	[self processPush:payload.dictionaryPayload];
	dispatch_async(dispatch_get_main_queue(), ^{completion();});
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        return;
    }
	[self processPush:payload.dictionaryPayload];
}

- (void)tryWaitForNetwork {
    [LinphoneManager.instance setConnectingToNetwork:TRUE];
    
    if ([LinphoneManager.instance lpConfigBoolForKey:@"account_bypass_network_check"] && !self.pushInfo) {
        [self pingResult:[NSNumber numberWithBool:YES]];
    } else {
        self.pingCtr = 9;
        [self ping];
    }
}

// ping for VPN/network check to make sure we can get to server
- (void)pingResult:(NSNumber*)success {
    [self pingDealloc];
    if (success.boolValue) {
        self.pingCtr = 0;
        [LinphoneManager.instance setConnectingToNetwork:FALSE];
        LOGI(@"PING_SUCCESS");
        if (self.pushInfo) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self processRemoteNotification:self.pushInfo];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (linphone_core_get_calls(LC) == NULL) {
                    [self reregister];
                }
                [self becameActive];
            });
        }
    } else {
        LOGI(@"PING_FAILURE %@, with number %d", [self getDomain], self.pingCtr);
        self.pingCtr--;
        if (self.pingCtr > 0) { //retry ping if ctr not finished
            if (self.pingCtr <= 2 && [LinphoneManager.instance lpConfigBoolForKey:@"account_bypass_network_check"]) {
                [self pingResult:[NSNumber numberWithBool:YES]];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self ping];
                });
            }
        } else {
            [LinphoneManager.instance setConnectingToNetwork:FALSE];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setNetworkDownStatus];
                if (self.pushInfo) {
                    [self missedRemoteNotification];
                    self.pushInfo = nil;
                }
            });
        }
    }
}

- (void) setNetworkConnectingStatus {

    LinphoneRegistrationState state = LinphoneRegistrationOk;
    LinphoneProxyConfig *default_proxy = linphone_core_get_default_proxy_config(LC);
    NSString *message = @"";
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:state], @"state", [NSValue valueWithPointer:default_proxy], @"cfg", message, @"message", nil];
    
    [NSNotificationCenter.defaultCenter postNotificationName:kLinphoneRegistrationUpdate object:self userInfo:dict];
}

- (void) setNetworkDownStatus {
    LinphoneRegistrationState downState = LinphoneRegistrationFailed;
    LinphoneProxyConfig *default_proxy = linphone_core_get_default_proxy_config(LC);
    NSString *message = @"Unable to connect"; //, check VPN connection!";
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:downState], @"state", [NSValue valueWithPointer:default_proxy], @"cfg", message, @"message", nil];
    
    [NSNotificationCenter.defaultCenter postNotificationName:kLinphoneRegistrationUpdate object:self userInfo:dict];
}

- (void)missedRemoteNotification {
    
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Missed Call";
    content.body = @"Unable to connect to network, check VPN connection!";
    
    if (self.pushInfo) {
        NSString *callId = [self.pushInfo objectForKey:@"call-id"];
        if (callId) {
            NSString *dname = [self getDisplayNameFromCallId:callId];
            content.title = [NSString stringWithFormat:@"Missed Call from %@", dname];
        } else {
            return;
        }
    }
    
    UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"missed_call" content:content trigger:NULL];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:req withCompletionHandler:^(NSError * _Nullable error) {
        // Enable or disable features based on authorization.
        if (error) {
            LOGD(@"Error while adding notification request :");
            LOGD(error.description);
        }
    }];
}

- (void)watchNotification {
    
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Incoming Call";
    content.body = @"Incoming Call";
    content.sound = [UNNotificationSound defaultSound];
    
    if (self.pushInfo) {
        NSString *callId = [self.pushInfo objectForKey:@"call-id"];
        
        if (callId) {
            content.title = [self getDisplayNameFromCallId:callId];
        } else {
            return;
        }
    } else {
        return;
    }
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:3
                                                                                                    repeats:NO];
    UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"new_call" content:content trigger:trigger];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:req withCompletionHandler:^(NSError * _Nullable error) {
        // Enable or disable features based on authorization.
        if (error) {
            LOGD(@"Error while adding notification request :");
            LOGD(error.description);
        }
    }];
}

- (NSString *)getDisplayNameFromCallId:(NSString *)callId {
    LinphoneAddress *addr = nil;
    NSString *callName = nil;
    
    if (callId.length < 7) {
        addr = linphone_address_new([NSString stringWithFormat:@"sip:%@@%@", callId, [self getDomain]].UTF8String);
    } else {
        addr = linphone_address_new(callId.UTF8String);
    }
    
    if (addr) {
        const bctbx_list_t *logs = linphone_core_get_call_history_for_address(LC, addr);
        while (logs != NULL) {
            LinphoneCallLog *log = (LinphoneCallLog *)logs->data;
            const LinphoneAddress *remoteaddr = linphone_call_log_get_remote_address(log);
            if (linphone_address_weak_equal(remoteaddr, addr)) {
                NSString *display = [FastAddressBook displayNameForAddress:remoteaddr];
                if (display && ![display isEqualToString:callId]) {
                    callName = display;
                    break;
                }
            }
            logs = bctbx_list_next(logs);
        }
        linphone_address_destroy(addr);
    }
    
    if (callName) {
        return callName;
    } else if (callId.length >= 10) {
        callId = [self convertPhoneNumber:callId];
    }
    
    return callId;
}

-(NSString*) convertPhoneNumber:(NSString *)extNumString{
    static NSCharacterSet* set = nil;
    if (set == nil){
        set = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    }
    NSString* phoneString = [[extNumString componentsSeparatedByCharactersInSet:set] componentsJoinedByString:@""];
    switch (phoneString.length) {
        case 7: return [NSString stringWithFormat:@"%@-%@", [phoneString substringToIndex:3], [phoneString substringFromIndex:3]];
        case 10: return [NSString stringWithFormat:@"(%@) %@-%@", [phoneString substringToIndex:3], [phoneString substringWithRange:NSMakeRange(3, 3)],[phoneString substringFromIndex:6]];
        case 11: return [NSString stringWithFormat:@"%@ (%@) %@-%@", [phoneString substringToIndex:1], [phoneString substringWithRange:NSMakeRange(1, 3)], [phoneString substringWithRange:NSMakeRange(4, 3)], [phoneString substringFromIndex:7]];
        case 12: return [NSString stringWithFormat:@"+%@ (%@) %@-%@", [phoneString substringToIndex:2], [phoneString substringWithRange:NSMakeRange(2, 3)], [phoneString substringWithRange:NSMakeRange(5, 3)], [phoneString substringFromIndex:8]];
        default: return extNumString;
    }
}

- (void)reregister {
    if (linphone_core_get_default_proxy_config(LC)) {
        linphone_core_refresh_registers(LC);
        linphone_core_iterate(LC);
    }
}


#pragma mark - Run it

// Pings the address, and calls the selector when done. Selector must take a NSnumber which is a bool for success
- (void)ping {
    // The helper retains itself through the timeout function
    self.simplePing = [[SimplePing alloc] initWithHostName:[self getDomain]];
    if (self.simplePing != nil) {
        self.simplePing.delegate = self;
        [self pingGo];
    }
}

#pragma mark - Init/dealloc

- (void)pingDealloc {
    self.simplePing = nil;
}

#pragma mark - Go

- (void)pingGo {
    
    [self.simplePing start];
    [self performSelector:@selector(endTime) withObject:nil afterDelay:1]; // This timeout is what retains the ping helper
}

#pragma mark - Finishing and timing out

// Called on success or failure to clean up
- (void)killPing {
    [self.simplePing stop];
    self.simplePing = nil;
}

- (void)successPing {
    [self killPing];
    [self pingResult:[NSNumber numberWithBool:YES]];
}

- (void)failPing:(NSString*)reason {
    [self killPing];
    LOGE(reason);
    [self pingResult:[NSNumber numberWithBool:NO]];
}

// Called 1s after ping start, to check if it timed out
- (void)endTime {
    if (self.simplePing) { // If it hasn't already been killed, then it's timed out
        [self failPing:@"timeout"];
    }
}

#pragma mark - Pinger delegate

// When the pinger starts, send the ping immediately
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
    [self.simplePing sendPingWithData:nil];
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
    [self failPing:@"didFailWithError"];
    [self failPing:error.localizedDescription];
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
    // Eg they're not connected to any network
    [self failPing:@"didFailToSendPacket"];
    [self failPing:error.localizedDescription];
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber{
    [self successPing];
}


// to send push token to push module
-(void)placePostRequestWithURL:(NSString *)action withData:(NSDictionary *)dataToSend withHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *error))ourBlock {
    NSString *urlString = [NSString stringWithFormat:@"%@", action];
    NSLog(@"%@", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataToSend options:0 error:&error];
    
    NSString *jsonString;
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSData *requestData = [NSData dataWithBytes:[jsonString UTF8String] length:[jsonString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
        
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody: requestData];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:ourBlock];
    }
}

-(void)placePostRequestNoHandler:(NSString *)action withData:(NSDictionary *)dataToSend {
    NSString *urlString = [NSString stringWithFormat:@"%@", action];
    NSLog(@"%@", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataToSend options:0 error:&error];
    
    NSString *jsonString;
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSData *requestData = [NSData dataWithBytes:[jsonString UTF8String] length:[jsonString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
        
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody: requestData];
        
        __block NSURLConnection *dconn = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            dconn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        });
    }
}

#pragma mark NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    _responseData = [[NSMutableData alloc] init];
    _response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    NSString *string = [[NSString alloc] initWithData:_responseData
                                             encoding:NSUTF8StringEncoding];
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)_response;
    NSInteger code = [httpResponse statusCode];
    NSLog(@"%ld", (long)code);
    
    if (!(code >= 200 && code < 300)) {
        NSLog(@"ERROR (%ld): %@", (long)code, string);
        [self performSelector:@selector(sendPushCredentialsFailure:) withObject:string];
    } else {
        NSLog(@"OK");
        
        NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                                string, @"id",
                                nil];
        [self performSelector:@selector(sendPushCredentialsDidEnd:) withObject:result];
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSString *string = [[NSString alloc] initWithData:_responseData
                                             encoding:NSUTF8StringEncoding];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)_response;
    NSInteger code = [httpResponse statusCode];
    NSLog(@"%ld", (long)code);
    
    if (!(code >= 200 && code < 300)) {
        NSLog(@"ERROR (%ld): %@", (long)code, string);
        [self performSelector:@selector(sendPushCredentialsFailure:) withObject:string];
    }
}

// to deal with self-signed certificates
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod
            isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod
         isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        NSString *appBundle = [[NSBundle mainBundle] bundlePath];
        appBundle = [appBundle stringByAppendingPathComponent:@"InAppSettings.bundle"];
        NSString *secPath = [appBundle stringByAppendingPathComponent:@"Secrets.plist"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:secPath]) {
            NSDictionary *secretDict = [[NSDictionary alloc] initWithContentsOfFile:secPath];
            NSString *domainvalue = [secretDict objectForKey:@"defaultDomainAddress"];
            
            if ([challenge.protectionSpace.host isEqualToString:domainvalue]) // we only trust our own domain //
            {
                NSURLCredential *credential =
                [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
            }
        }
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}


// to send push token to push module
- (void)sendDeviceToken:(NSData*)deviceToken {
    
    NSString *hexToken = [self hexaString:deviceToken];
    //NSString *hexToken = @"111111abfd9060e40dc26c2dd192b2028b91f081c3428adcff27a60b0e22f389";
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *deviceId = [[currentDevice identifierForVendor] UUIDString];
    NSString *exten = [self getExtension];
    NSString *displayName = [self getDisplayName];
    
    NSString *domaintest = [self getDomain];
    if (!domaintest || !exten)
        return;
    
    NSString *pushport = nil;
    NSString *appBundle = [[NSBundle mainBundle] bundlePath];
    appBundle = [appBundle stringByAppendingPathComponent:@"InAppSettings.bundle"];
    NSString *secPath = [appBundle stringByAppendingPathComponent:@"Secrets.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:secPath]) {
        NSDictionary *secretDict = [[NSDictionary alloc] initWithContentsOfFile:secPath];
        pushport = [secretDict objectForKey:@"defaultPushPort"];
    }
    
    NSString *pushPath = [NSString stringWithFormat: @"https://%@/iospush_json.php", domaintest];
    
    if (pushport) {
        pushPath = [NSString stringWithFormat: @"https://%@:%@/iospush_json.php", domaintest, pushport];
    }
        
    NSDictionary *dataToSend = [NSDictionary dictionaryWithObjectsAndKeys:
                                deviceId, @"device_id",
                                hexToken, @"token_id",
                                exten, @"exten",
                                displayName, @"displayname", nil];
    
    [self placePostRequestNoHandler:pushPath withData:dataToSend];
}

- (NSString *)hexaString:(NSData*)someData {
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
    
    const unsigned char *dataBuffer = (const unsigned char *)[someData bytes];
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger          dataLength  = [someData length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    
    return [NSString stringWithString:hexString];
}


- (void)sendPushCredentialsDidEnd:(id)result{
    NSLog(@"sendPushCredentialsSuccess:");
    // Do your actions
}

- (void)sendPushCredentialsFailure:(id)result{
    NSLog(@"sendPushCredentialsFailure:");
    // Do your actions
}

- (NSString *)getDomain {
    
    LinphoneProxyConfig *default_proxy = linphone_core_get_default_proxy_config(LC);
    
    if (default_proxy != NULL) {
        return [NSString stringWithUTF8String:linphone_address_get_domain(linphone_proxy_config_get_identity_address(default_proxy))];
    }
    return nil;
}

- (NSString *)getExtension {
    LinphoneProxyConfig *default_proxy = linphone_core_get_default_proxy_config(LC);
    
    if (default_proxy != NULL) {
        return [NSString stringWithUTF8String:linphone_address_get_username(linphone_proxy_config_get_identity_address(default_proxy))];
    }
    return nil;
}

- (NSString *)getDisplayName {
    LinphoneProxyConfig *default_proxy = linphone_core_get_default_proxy_config(LC);
    
    if (default_proxy != NULL && linphone_address_get_display_name(linphone_proxy_config_get_identity_address(default_proxy)) != NULL) {
        return [NSString stringWithUTF8String:linphone_address_get_display_name(linphone_proxy_config_get_identity_address(default_proxy))];
    }
    return nil;
}


#pragma mark - UNUserNotifications Framework

- (void) userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    // If an app extension launch a user notif while app is in fg, it is catch by the app
    NSString *category = [[[notification request] content] categoryIdentifier];
    if (category && [category isEqualToString:@"app_active"]) {
        return;
    }
	completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
    didReceiveNotificationResponse:(UNNotificationResponse *)response
             withCompletionHandler:(void (^)(void))completionHandler {
	LOGD(@"UN : response received");
	LOGD(response.description);

	NSString *callId = (NSString *)[response.notification.request.content.userInfo objectForKey:@"CallId"];
    if (!callId) {
		return;
    }

	LinphoneCall *call = [CallManager.instance findCallWithCallId:callId];

	if ([response.actionIdentifier isEqual:@"Answer"]) {
		// use the standard handler
		[PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
		linphone_call_accept(call);
	} else if ([response.actionIdentifier isEqual:@"Decline"]) {
		linphone_call_decline(call, LinphoneReasonDeclined);
	} else if ([response.actionIdentifier isEqual:@"Reply"]) {
	  	NSString *replyText = [(UNTextInputNotificationResponse *)response userText];
	  	NSString *peer_address = [response.notification.request.content.userInfo objectForKey:@"peer_addr"];
	  	NSString *local_address = [response.notification.request.content.userInfo objectForKey:@"local_addr"];
	  	LinphoneAddress *peer = linphone_address_new(peer_address.UTF8String);
		LinphoneAddress *local = linphone_address_new(local_address.UTF8String);
	  	//

	  	linphone_address_unref(peer);
	  	linphone_address_unref(local);
  	} else if ([response.actionIdentifier isEqual:@"Seen"]) {
	  	NSString *peer_address = [response.notification.request.content.userInfo objectForKey:@"peer_addr"];
	  	NSString *local_address = [response.notification.request.content.userInfo objectForKey:@"local_addr"];
	  	LinphoneAddress *peer = linphone_address_new(peer_address.UTF8String);
	  	LinphoneAddress *local = linphone_address_new(local_address.UTF8String);
	  	//

	  	linphone_address_unref(peer);
	  	linphone_address_unref(local);
	} else if ([response.actionIdentifier isEqual:@"Cancel"]) {
	  	LOGI(@"User declined video proposal");
	  	if (call != linphone_core_get_current_call(LC))
		  	return;

	  	LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
	  	linphone_call_accept_update(call, params);
	  	linphone_call_params_destroy(params);
  	} else if ([response.actionIdentifier isEqual:@"Accept"]) {
		LOGI(@"User accept video proposal");
	  	if (call != linphone_core_get_current_call(LC))
			return;

		[[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
	  	[PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
      	LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
      	linphone_call_params_enable_video(params, TRUE);
      	linphone_call_accept_update(call, params);
      	linphone_call_params_destroy(params);
  	} else if ([response.actionIdentifier isEqual:@"Confirm"]) {
	  	if (linphone_core_get_current_call(LC) == call)
		  	linphone_call_set_authentication_token_verified(call, YES);
  	} else if ([response.actionIdentifier isEqual:@"Deny"]) {
	  	if (linphone_core_get_current_call(LC) == call)
		  	linphone_call_set_authentication_token_verified(call, NO);
  	} else if ([response.actionIdentifier isEqual:@"Call"]) {
	  	return;
  	} else { // in this case the value is : com.apple.UNNotificationDefaultActionIdentifier or com.apple.UNNotificationDismissActionIdentifier
	  	if ([response.notification.request.content.categoryIdentifier isEqual:@"call_cat"]) {
			if ([response.actionIdentifier isEqualToString:@"com.apple.UNNotificationDismissActionIdentifier"])
				// clear notification
				linphone_call_decline(call, LinphoneReasonDeclined);
			else
		  		[PhoneMainView.instance displayIncomingCall:call];
	  	} else if ([response.notification.request.content.categoryIdentifier isEqual:@"zrtp_request"]) {
			if (!call)
				return;
			
			NSString *code = [NSString stringWithUTF8String:linphone_call_get_authentication_token(call)];
			NSString *myCode;
			NSString *correspondantCode;
			if (linphone_call_get_dir(call) == LinphoneCallIncoming) {
				myCode = [code substringToIndex:2];
				correspondantCode = [code substringFromIndex:2];
			} else {
				correspondantCode = [code substringToIndex:2];
				myCode = [code substringFromIndex:2];
			}
		  	NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Confirm the following SAS with peer:\n"
																			 @"Say : %@\n"
																			 @"Your correspondant should say : %@", nil), myCode, correspondantCode];
			UIConfirmationDialog *securityDialog = [UIConfirmationDialog ShowWithMessage:message
									cancelMessage:NSLocalizedString(@"DENY", nil)
								   confirmMessage:NSLocalizedString(@"ACCEPT", nil)
									onCancelClick:^() {
										if (linphone_core_get_current_call(LC) == call)
											linphone_call_set_authentication_token_verified(call, NO);
								  	}
							  onConfirmationClick:^() {
								  if (linphone_core_get_current_call(LC) == call)
									  linphone_call_set_authentication_token_verified(call, YES);
							  }];
			[securityDialog setSpecialColor];
		} else if ([response.notification.request.content.categoryIdentifier isEqual:@"lime"]) {
			return;
        } else { // Missed call
			[PhoneMainView.instance changeCurrentView:HistoryListView.compositeViewDescription];
		}
	}
}

- (void)dismissVideoActionSheet:(NSTimer *)timer {
	UIConfirmationDialog *sheet = (UIConfirmationDialog *)timer.userInfo;
	[sheet dismiss];
}

#pragma mark - NSUser notifications
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

- (void)application:(UIApplication *)application
	handleActionWithIdentifier:(NSString *)identifier
		  forLocalNotification:(UILocalNotification *)notification
			 completionHandler:(void (^)(void))completionHandler {

	LinphoneCall *call = linphone_core_get_current_call(LC);
	LOGI(@"%@", NSStringFromSelector(_cmd));
	if (floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_9_0) {
		LOGI(@"%@", NSStringFromSelector(_cmd));
		if ([notification.category isEqualToString:@"incoming_call"]) {
			if ([identifier isEqualToString:@"answer"]) {
				// use the standard handler
				[PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
				linphone_call_accept(call);
			} else if ([identifier isEqualToString:@"decline"]) {
				LinphoneCall *call = linphone_core_get_current_call(LC);
				if (call)
					linphone_call_decline(call, LinphoneReasonDeclined);
			}
		} 
	}
	completionHandler();
}

- (void)application:(UIApplication *)application
	handleActionWithIdentifier:(NSString *)identifier
		  forLocalNotification:(UILocalNotification *)notification
			  withResponseInfo:(NSDictionary *)responseInfo
			 completionHandler:(void (^)(void))completionHandler {

	LinphoneCall *call = linphone_core_get_current_call(LC);
	if ([notification.category isEqualToString:@"incoming_call"]) {
		if ([identifier isEqualToString:@"answer"]) {
			// use the standard handler
			[PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
			linphone_call_accept(call);
		} else if ([identifier isEqualToString:@"decline"]) {
			LinphoneCall *call = linphone_core_get_current_call(LC);
			if (call)
				linphone_call_decline(call, LinphoneReasonDeclined);
		}
	} else if ([notification.category isEqualToString:@"incoming_msg"] &&
			   [identifier isEqualToString:@"reply_inline"]) {
		NSString *replyText = [responseInfo objectForKey:UIUserNotificationActionResponseTypedTextKey];
		NSString *peer_address = [responseInfo objectForKey:@"peer_addr"];
		NSString *local_address = [responseInfo objectForKey:@"local_addr"];
		LinphoneAddress *peer = linphone_address_new(peer_address.UTF8String);
		LinphoneAddress *local = linphone_address_new(local_address.UTF8String);
		LinphoneChatRoom *room = linphone_core_find_chat_room(LC, peer, local);
		if (room)
			[LinphoneManager.instance send:replyText toChatRoom:room];

		linphone_address_unref(peer);
		linphone_address_unref(local);
	}
	completionHandler();
}
#pragma clang diagnostic pop
#pragma deploymate pop

#pragma mark - Remote configuration Functions (URL Handler)

- (void)ConfigurationStateUpdateEvent:(NSNotification *)notif {
	LinphoneConfiguringState state = [[notif.userInfo objectForKey:@"state"] intValue];
	if (state == LinphoneConfiguringSuccessful) {
		[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneConfiguringStateUpdate object:nil];
		[_waitingIndicator dismissViewControllerAnimated:YES completion:nil];
		UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Success", nil)
																		 message:NSLocalizedString(@"Remote configuration successfully fetched and applied.", nil)
																  preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];

		[errView addAction:defaultAction];
		[PhoneMainView.instance presentViewController:errView animated:YES completion:nil];

		[PhoneMainView.instance startUp];
	}
	if (state == LinphoneConfiguringFailed) {
		[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneConfiguringStateUpdate object:nil];
		[_waitingIndicator dismissViewControllerAnimated:YES completion:nil];
		UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Failure", nil)
																		 message:NSLocalizedString(@"Failed configuring from the specified URL.", nil)
																  preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];

		[errView addAction:defaultAction];
		[PhoneMainView.instance presentViewController:errView animated:YES completion:nil];
	}
}

- (void)showWaitingIndicator {
	_waitingIndicator = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Fetching remote configuration...", nil)
															message:@""
													 preferredStyle:UIAlertControllerStyleAlert];

	UIActivityIndicatorView *progress = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(125, 60, 30, 30)];
	progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;

	[_waitingIndicator setValue:progress forKey:@"accessoryView"];
	[progress setColor:[UIColor blackColor]];

	[progress startAnimating];
	[PhoneMainView.instance presentViewController:_waitingIndicator animated:YES completion:nil];
}

- (void)attemptRemoteConfiguration {

	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(ConfigurationStateUpdateEvent:)
											   name:kLinphoneConfiguringStateUpdate
											 object:nil];
	linphone_core_set_provisioning_uri(LC, [configURL UTF8String]);
	[LinphoneManager.instance destroyLinphoneCore];
	[LinphoneManager.instance launchLinphoneCore];
    [LinphoneManager.instance.fastAddressBook fetchContactsInBackGroundThread];
}

#pragma mark - Prevent ImagePickerView from rotating

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
	if ([[(PhoneMainView*)self.window.rootViewController currentView] equal:ImagePickerView.compositeViewDescription] || _onlyPortrait)
	{
		//Prevent rotation of camera
		NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
		[[UIDevice currentDevice] setValue:value forKey:@"orientation"];
		return UIInterfaceOrientationMaskPortrait;
	} else return UIInterfaceOrientationMaskPortrait;
}

@end
