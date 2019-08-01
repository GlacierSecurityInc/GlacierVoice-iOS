/* LinphoneAppDelegate.m
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
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

#import "LinphoneAppDelegate.h"
#import "AddressBook/ABPerson.h"
#import "ContactDetailsView.h"
#import "ContactsListView.h"
#import "PhoneMainView.h"
#import "ShopView.h"

#import "CoreTelephony/CTCallCenter.h"
#import "CoreTelephony/CTCall.h"

#import "LinphoneCoreSettingsStore.h"

#include "LinphoneManager.h"
#include "linphone/linphonecore.h"

@implementation LinphoneAppDelegate

@synthesize configURL;
@synthesize window;


#pragma mark - Lifecycle Functions

- (id)init {
	self = [super init];
	if (self != nil) {
		startedInBackground = FALSE;
	}
	return self;
	[[UIApplication sharedApplication] setDelegate:self];
}

#pragma mark -

- (void)applicationDidEnterBackground:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	[LinphoneManager.instance enterBackgroundMode];
    [PhoneMainView.instance removeLocalVPNFiles]; //delete locally stored VPN profiles
}

- (void)applicationWillResignActive:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	LinphoneCall *call = linphone_core_get_current_call(LC);

	if (call) {
		/* save call context */
		LinphoneManager *instance = LinphoneManager.instance;
		instance->currentCallContextBeforeGoingBackground.call = call;
		instance->currentCallContextBeforeGoingBackground.cameraIsEnabled = linphone_call_camera_enabled(call);

		const LinphoneCallParams *params = linphone_call_get_current_params(call);
		if (linphone_call_params_video_enabled(params)) {
			linphone_call_enable_camera(call, false);
		}
	}

	if (![LinphoneManager.instance resignActive]) {
	}
}

-(void)becameActive {
    if (startedInBackground) {
        startedInBackground = FALSE;
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
        const MSList *lists = linphone_core_get_friends_lists(LC);
        while (lists) {
            linphone_friend_list_update_subscriptions(lists->data);
            lists = lists->next;
        }
    }
    
    LinphoneCall *call = linphone_core_get_current_call(LC);
    
    if (call) {
        if (call == instance->currentCallContextBeforeGoingBackground.call) {
            const LinphoneCallParams *params = linphone_call_get_current_params(call);
            if (linphone_call_params_video_enabled(params)) {
                linphone_call_enable_camera(call, instance->currentCallContextBeforeGoingBackground.cameraIsEnabled);
            }
            instance->currentCallContextBeforeGoingBackground.call = 0;
        } else if (linphone_call_get_state(call) == LinphoneCallIncomingReceived) {
            LinphoneCallAppData *data = (__bridge LinphoneCallAppData *)linphone_call_get_user_data(call);
            if (data && data->timer) {
                [data->timer invalidate];
                data->timer = nil;
            }
            if ((floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max)) {
                if ([LinphoneManager.instance lpConfigBoolForKey:@"autoanswer_notif_preference"]) {
                    linphone_call_accept(call);
                    [PhoneMainView.instance changeCurrentView:CallView.compositeViewDescription];
                } else {
                    [PhoneMainView.instance displayIncomingCall:call];
                }
            } else if (linphone_core_get_calls_nb(LC) > 1) {
                [PhoneMainView.instance displayIncomingCall:call];
            }
            
            // in this case, the ringing sound comes from the notification.
            // To stop it we have to do the iOS7 ring fix...
            [self fixRing];
        }
    }
    [LinphoneManager.instance.iapManager check];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));
    
    if (linphone_core_get_calls(LC) == NULL && [self getDomain]) {
        [self tryWaitForNetwork];
        [self setNetworkConnectingStatus];
        
        if (self.justLaunched) {
            self.justLaunched = FALSE;
        } else {
            [self registerForNotifications:[UIApplication sharedApplication]];
        }
    } else {
        [self becameActive];
    }
}

#pragma deploymate push "ignored-api-availability"
- (UIUserNotificationCategory *)getMessageNotificationCategory {
	NSArray *actions;

	if ([[UIDevice.currentDevice systemVersion] floatValue] < 9 ||
		[LinphoneManager.instance lpConfigBoolForKey:@"show_msg_in_notif"] == NO) {

		UIMutableUserNotificationAction *reply = [[UIMutableUserNotificationAction alloc] init];
		reply.identifier = @"reply";
		reply.title = NSLocalizedString(@"Reply", nil);
		reply.activationMode = UIUserNotificationActivationModeForeground;
		reply.destructive = NO;
		reply.authenticationRequired = YES;

		UIMutableUserNotificationAction *mark_read = [[UIMutableUserNotificationAction alloc] init];
		mark_read.identifier = @"mark_read";
		mark_read.title = NSLocalizedString(@"Mark Read", nil);
		mark_read.activationMode = UIUserNotificationActivationModeBackground;
		mark_read.destructive = NO;
		mark_read.authenticationRequired = NO;

		actions = @[ mark_read, reply ];
	} else {
		// iOS 9 allows for inline reply. We don't propose mark_read in this case
		UIMutableUserNotificationAction *reply_inline = [[UIMutableUserNotificationAction alloc] init];

		reply_inline.identifier = @"reply_inline";
		reply_inline.title = NSLocalizedString(@"Reply", nil);
		reply_inline.activationMode = UIUserNotificationActivationModeBackground;
		reply_inline.destructive = NO;
		reply_inline.authenticationRequired = NO;
		reply_inline.behavior = UIUserNotificationActionBehaviorTextInput;

		actions = @[ reply_inline ];
	}

	UIMutableUserNotificationCategory *localRingNotifAction = [[UIMutableUserNotificationCategory alloc] init];
	localRingNotifAction.identifier = @"incoming_msg";
	[localRingNotifAction setActions:actions forContext:UIUserNotificationActionContextDefault];
	[localRingNotifAction setActions:actions forContext:UIUserNotificationActionContextMinimal];

	return localRingNotifAction;
}

- (UIUserNotificationCategory *)getCallNotificationCategory {
	UIMutableUserNotificationAction *answer = [[UIMutableUserNotificationAction alloc] init];
	answer.identifier = @"answer";
	answer.title = NSLocalizedString(@"Answer", nil);
	answer.activationMode = UIUserNotificationActivationModeForeground;
	answer.destructive = NO;
	answer.authenticationRequired = YES;
    
	UIMutableUserNotificationAction *decline = [[UIMutableUserNotificationAction alloc] init];
	decline.identifier = @"decline";
	decline.title = NSLocalizedString(@"Decline", nil);
	decline.activationMode = UIUserNotificationActivationModeBackground;
	decline.destructive = YES;
	decline.authenticationRequired = NO;

	NSArray *localRingActions = @[ decline, answer ];

	UIMutableUserNotificationCategory *localRingNotifAction = [[UIMutableUserNotificationCategory alloc] init];
	localRingNotifAction.identifier = @"incoming_call";
	[localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextDefault];
	[localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextMinimal];

	return localRingNotifAction;
}

- (UIUserNotificationCategory *)getAccountExpiryNotificationCategory {
	
	UIMutableUserNotificationCategory *expiryNotification = [[UIMutableUserNotificationCategory alloc] init];
	expiryNotification.identifier = @"expiry_notification";
	return expiryNotification;
}


- (void)registerForNotifications:(UIApplication *)app {
	self.voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
	self.voipRegistry.delegate = self;

	// Initiate registration.
	self.voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];

	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
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
		[[UNUserNotificationCenter currentNotificationCenter]
			requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound |
											 UNAuthorizationOptionBadge)
						  completionHandler:^(BOOL granted, NSError *_Nullable error) {
							// Enable or disable features based on authorization.
							if (error) {
								LOGD(error.description);
							}
						  }];
		NSSet *categories = [NSSet setWithObjects:cat_call, cat_msg, video_call, cat_zrtp, nil];
		[[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:categories];
	}
}
#pragma deploymate pop

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    UIApplication *app = [UIApplication sharedApplication];
	UIApplicationState state = app.applicationState;
 
	LinphoneManager *instance = [LinphoneManager instance];
	BOOL background_mode = [instance lpConfigBoolForKey:@"backgroundmode_preference"];
	BOOL start_at_boot = [instance lpConfigBoolForKey:@"start_at_boot_preference"];
	[self registerForNotifications:app];
    self.justLaunched = TRUE;

	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
		self.del = [[ProviderDelegate alloc] init];
		[LinphoneManager.instance setProviderDelegate:self.del];
	}

	if (state == UIApplicationStateBackground) {
		// we've been woken up directly to background;
		if (!start_at_boot || !background_mode) {
			// autoboot disabled or no background, and no push: do nothing and wait for a real launch
			//output a log with NSLog, because the ortp logging system isn't activated yet at this time
			NSLog(@"Linphone launch doing nothing because start_at_boot or background_mode are not activated.", NULL);
			return YES;
		}
	}
	bgStartId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
	  LOGW(@"Background task for application launching expired.");
	  [[UIApplication sharedApplication] endBackgroundTask:bgStartId];
	}];
    
    [LinphoneManager.instance setConnectingToNetwork:TRUE];

	[LinphoneManager.instance startLinphoneCore];
	LinphoneManager.instance.iapManager.notificationCategory = @"expiry_notification";
	// initialize UI
	[self.window makeKeyAndVisible];
	[RootViewManager setupWithPortrait:(PhoneMainView *)self.window.rootViewController];
	[PhoneMainView.instance startUp];
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
    
    //Log
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    //NSString *documentsDirectory = [paths objectAtIndex:0];
    //NSString *fileName =[NSString stringWithFormat:@"%@.log",[NSDate date]];
    //NSString *logFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    //freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
    
	return YES;
}


- (void)applicationWillTerminate:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	LinphoneManager.instance.conf = TRUE;
	linphone_core_terminate_all_calls(LC);

	// destroyLinphoneCore automatically unregister proxies but if we are using
	// remote push notifications, we want to continue receiving them
	if (LinphoneManager.instance.pushNotificationToken != nil) {
		// trick me! setting network reachable to false will avoid sending unregister
		const MSList *proxies = linphone_core_get_proxy_config_list(LC);
		BOOL pushNotifEnabled = NO;
		while (proxies) {
			const char *refkey = linphone_proxy_config_get_ref_key(proxies->data);
			pushNotifEnabled = pushNotifEnabled || (refkey && strcmp(refkey, "push_notification") == 0);
			proxies = proxies->next;
		}
		// but we only want to hack if at least one proxy config uses remote push..
		if (pushNotifEnabled) {
			linphone_core_set_network_reachable(LC, FALSE);
		}
	}

	[LinphoneManager.instance destroyLinphoneCore];
    
    [PhoneMainView.instance teardownCognito];
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
    } else if([[url scheme] isEqualToString:@"message-linphone"]) {
        [PhoneMainView.instance popToView:ChatsListView.compositeViewDescription];
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

	if (aps != nil) {
		NSDictionary *alert = [aps objectForKey:@"alert"];
		NSString *loc_key = [aps objectForKey:@"loc-key"];
		NSString *callId = [aps objectForKey:@"call-id"];
		if (alert != nil) {
			loc_key = [alert objectForKey:@"loc-key"];
			/*if we receive a remote notification, it is probably because our TCP background socket was no more working.
			 As a result, break it and refresh registers in order to make sure to receive incoming INVITE or MESSAGE*/
			if (linphone_core_get_calls(LC) == NULL) { // if there are calls, obviously our TCP socket shall be working
                
                [self reregister];
                

				if (loc_key != nil) {

					callId = [userInfo objectForKey:@"call-id"];
					if (callId != nil) {
						if ([callId isEqualToString:@""]){
							//Present apn pusher notifications for info
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
							} else {
								UILocalNotification *notification = [[UILocalNotification alloc] init];
								notification.repeatInterval = 0;
								notification.alertBody = @"Push notification received !";
								notification.alertTitle = @"APN Pusher";
								[[UIApplication sharedApplication] presentLocalNotificationNow:notification];
							}
						} else {
							[LinphoneManager.instance addPushCallId:callId];
						}
					} else  if ([callId  isEqual: @""]) {
						LOGE(@"PushNotification: does not have call-id yet, fix it !");
					}
				}
			}
		}

        if (callId && [self addLongTaskIDforCallID:callId]) {
			if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive && loc_key &&
				index > 0) {
				if ([loc_key isEqualToString:@"IC_MSG"]) {
					[LinphoneManager.instance startPushLongRunningTask:FALSE callId:callId];
					[self fixRing];
				} else if ([loc_key isEqualToString:@"IM_MSG"]) {
					[LinphoneManager.instance startPushLongRunningTask:TRUE callId:callId];
				}
			}
		}
	}
    LOGI(@"Notification %@ processed", userInfo.description);
    self.pushInfo = nil;
}

- (BOOL)addLongTaskIDforCallID:(NSString *)callId {
	NSDictionary *dict = LinphoneManager.instance.pushDict;
	if ([[dict allKeys] indexOfObject:callId] != NSNotFound) {
		return FALSE;
	}

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
		if (room_from && strcmp(from, room_from) == 0) {
			return rooms->data;
		}
		rooms = rooms->next;
	}
	return NULL;
}

#pragma mark - PushNotification Functions

- (void)application:(UIApplication *)application
	didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	LOGI(@"%@ : %@", NSStringFromSelector(_cmd), deviceToken);
	[LinphoneManager.instance setPushNotificationToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	LOGI(@"%@ : %@", NSStringFromSelector(_cmd), [error localizedDescription]);
	[LinphoneManager.instance setPushNotificationToken:nil];
}

#pragma mark - PushKit Functions

- (void)pushRegistry:(PKPushRegistry *)registry
didInvalidatePushTokenForType:(NSString *)type {
    LOGI(@"PushKit Token invalidated");
    dispatch_async(dispatch_get_main_queue(), ^{[LinphoneManager.instance setPushNotificationToken:nil];});
}

- (void)pushRegistry:(PKPushRegistry *)registry
	didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
							  forType:(NSString *)type {

	LOGI(@"PushKit : incoming voip notfication: %@", payload.dictionaryPayload);
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        return;
    }
    
	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) { // Call category
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
		[[UNUserNotificationCenter currentNotificationCenter]
			requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound |
											 UNAuthorizationOptionBadge)
						  completionHandler:^(BOOL granted, NSError *_Nullable error) {
							// Enable or disable features based on authorization.
							if (error) {
								LOGD(error.description);
							}
						  }];
		NSSet *categories = [NSSet setWithObjects:cat_call, cat_msg, video_call, cat_zrtp, nil];
		[[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:categories];
	}
	
    self.pushInfo = payload.dictionaryPayload;
    
    if ([LinphoneManager.instance lpConfigBoolForKey:@"account_watch_notification"]) {
        [self watchNotification];
    }
    
    [LinphoneManager.instance setupNetworkReachabilityCallback];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self tryWaitForNetwork];
    });
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

- (void)pushRegistry:(PKPushRegistry *)registry
	didUpdatePushCredentials:(PKPushCredentials *)credentials
					 forType:(PKPushType)type {
	LOGI(@"PushKit credentials updated");
	LOGI(@"voip token: %@", (credentials.token));
	dispatch_async(dispatch_get_main_queue(), ^{
	    [LinphoneManager.instance setPushNotificationToken:credentials.token];
        [self sendDeviceToken:credentials.token];
	});
}

//ping for VPN/network check to make sure we can get to server
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
    linphone_core_set_network_reachable(LC, false);
    LinphoneManager.instance.connectivity = none; //Force connectivity to be discovered again
    LinphoneRegistrationState downState = LinphoneRegistrationFailed;
    LinphoneProxyConfig *default_proxy = linphone_core_get_default_proxy_config(LC);
    NSString *message = @"Unable to connect, check VPN connection!";
    
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
    LinphoneManager.instance.connectivity = none; //Force connectivity to be discovered again
    [LinphoneManager.instance setupNetworkReachabilityCallback];
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
    //LOGI(@"PING_START");
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
    //LOGE(@"************************");
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


//to send push token to push module
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

//to send push token to push module
- (void)sendDeviceToken:(NSData*)deviceToken {
    
    NSString *hexToken = [self hexaString:deviceToken];
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
	completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionAlert);
}

#ifdef __IPHONE_11_0
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
    didReceiveNotificationResponse:(UNNotificationResponse *)response
             withCompletionHandler:(void (^)(void))completionHandler {

#else
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
    didReceiveNotificationResponse:(UNNotificationResponse *)response
             withCompletionHandler:(void (^)())completionHandler {
#endif

  LOGD(@"UN : response received");
  LOGD(response.description);

  NSString *callId = (NSString *)[response.notification.request.content.userInfo
      objectForKey:@"CallId"];
  if (!callId) {
    return;
  }
  LinphoneCall *call = [LinphoneManager.instance callByCallId:callId];
  if (call) {
    LinphoneCallAppData *data =
        (__bridge LinphoneCallAppData *)linphone_call_get_user_data(call);
    if (data->timer) {
      [data->timer invalidate];
      data->timer = nil;
    }
  }

  if ([response.actionIdentifier isEqual:@"Answer"]) {
    // use the standard handler
    [PhoneMainView.instance
        changeCurrentView:CallView.compositeViewDescription];
    linphone_call_accept(call);
  } else if ([response.actionIdentifier isEqual:@"Decline"]) {
    linphone_call_decline(call, LinphoneReasonDeclined);
  } else if ([response.actionIdentifier isEqual:@"Reply"]) {
    NSString *replyText =
        [(UNTextInputNotificationResponse *)response userText];
    NSString *from = [response.notification.request.content.userInfo
        objectForKey:@"from_addr"];
    [LinphoneManager.instance send:replyText to:from];
  } else if ([response.actionIdentifier isEqual:@"Seen"]) {
    NSString *from = [response.notification.request.content.userInfo
        objectForKey:@"from_addr"];
    LinphoneChatRoom *room =
        linphone_core_get_chat_room_from_uri(LC, [from UTF8String]);
    if (room) {
      linphone_chat_room_mark_as_read(room);
      TabBarView *tab = (TabBarView *)[PhoneMainView.instance.mainViewController
          getCachedController:NSStringFromClass(TabBarView.class)];
      [tab update:YES];
      [PhoneMainView.instance updateApplicationBadgeNumber];
    }

  } else if ([response.actionIdentifier isEqual:@"Cancel"]) {
    LOGI(@"User declined video proposal");
    if (call == linphone_core_get_current_call(LC)) {
      LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
      linphone_call_accept_update(call, params);
      linphone_call_params_destroy(params);
    }
  } else if ([response.actionIdentifier isEqual:@"Accept"]) {
    LOGI(@"User accept video proposal");
    if (call == linphone_core_get_current_call(LC)) {
      [[UNUserNotificationCenter currentNotificationCenter]
          removeAllDeliveredNotifications];
      [PhoneMainView.instance
          changeCurrentView:CallView.compositeViewDescription];
      LinphoneCallParams *params = linphone_core_create_call_params(LC, call);
      linphone_call_params_enable_video(params, TRUE);
      linphone_call_accept_update(call, params);
      linphone_call_params_destroy(params);
    }
  } else if ([response.actionIdentifier isEqual:@"Confirm"]) {
    if (linphone_core_get_current_call(LC) == call) {
      linphone_call_set_authentication_token_verified(call, YES);
    }
  } else if ([response.actionIdentifier isEqual:@"Deny"]) {
    if (linphone_core_get_current_call(LC) == call) {
      linphone_call_set_authentication_token_verified(call, NO);
    }
  } else if ([response.actionIdentifier isEqual:@"Call"]) {

  } else { // in this case the value is :
           // com.apple.UNNotificationDefaultActionIdentifier
    if ([response.notification.request.content.categoryIdentifier
            isEqual:@"call_cat"]) {
      [PhoneMainView.instance displayIncomingCall:call];
    } else if ([response.notification.request.content.categoryIdentifier
                   isEqual:@"msg_cat"]) {
      [PhoneMainView.instance
          changeCurrentView:ChatsListView.compositeViewDescription];
    } else if ([response.notification.request.content.categoryIdentifier
                   isEqual:@"video_request"]) {
      [PhoneMainView.instance
          changeCurrentView:CallView.compositeViewDescription];
      NSTimer *videoDismissTimer = nil;

      UIConfirmationDialog *sheet = [UIConfirmationDialog
          ShowWithMessage:response.notification.request.content.body
          cancelMessage:nil
          confirmMessage:NSLocalizedString(@"ACCEPT", nil)
          onCancelClick:^() {
            LOGI(@"User declined video proposal");
            if (call == linphone_core_get_current_call(LC)) {
              LinphoneCallParams *params =
                  linphone_core_create_call_params(LC, call);
              linphone_call_accept_update(call, params);
              linphone_call_params_destroy(params);
              [videoDismissTimer invalidate];
            }
          }
          onConfirmationClick:^() {
            LOGI(@"User accept video proposal");
            if (call == linphone_core_get_current_call(LC)) {
              LinphoneCallParams *params =
                  linphone_core_create_call_params(LC, call);
              linphone_call_params_enable_video(params, TRUE);
              linphone_call_accept_update(call, params);
              linphone_call_params_destroy(params);
              [videoDismissTimer invalidate];
            }
          }
          inController:PhoneMainView.instance];

      videoDismissTimer = [NSTimer
          scheduledTimerWithTimeInterval:30
                                  target:self
                                selector:@selector(dismissVideoActionSheet:)
                                userInfo:sheet
                                 repeats:NO];
    } else if ([response.notification.request.content.categoryIdentifier
                   isEqual:@"zrtp_request"]) {
      NSString *code = [NSString
          stringWithUTF8String:linphone_call_get_authentication_token(call)];
      NSString *myCode;
      NSString *correspondantCode;
      if (linphone_call_get_dir(call) == LinphoneCallIncoming) {
        myCode = [code substringToIndex:2];
        correspondantCode = [code substringFromIndex:2];
      } else {
        correspondantCode = [code substringToIndex:2];
        myCode = [code substringFromIndex:2];
      }
      NSString *message = [NSString
          stringWithFormat:NSLocalizedString(
                               @"Confirm the following SAS with peer:\n"
                               @"Say : %@\n"
                               @"Your correspondant should say : %@",
                               nil),
                           myCode, correspondantCode];
      [UIConfirmationDialog ShowWithMessage:message
          cancelMessage:NSLocalizedString(@"DENY", nil)
          confirmMessage:NSLocalizedString(@"ACCEPT", nil)
          onCancelClick:^() {
            if (linphone_core_get_current_call(LC) == call) {
              linphone_call_set_authentication_token_verified(call, NO);
            }
          }
          onConfirmationClick:^() {
            if (linphone_core_get_current_call(LC) == call) {
              linphone_call_set_authentication_token_verified(call, YES);
            }
          }];
    } else if ([response.notification.request.content.categoryIdentifier
                   isEqual:@"lime"]) {
      return;
    } else { // Missed call
      [PhoneMainView.instance
          changeCurrentView:HistoryListView.compositeViewDescription];
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
			 completionHandler:(void (^)())completionHandler {

	LinphoneCall *call = linphone_core_get_current_call(LC);
	if (call) {
		LinphoneCallAppData *data = (__bridge LinphoneCallAppData *)linphone_call_get_user_data(call);
		if (data->timer) {
			[data->timer invalidate];
			data->timer = nil;
		}
	}
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
		} else if ([notification.category isEqualToString:@"incoming_msg"]) {
			if ([identifier isEqualToString:@"reply"]) {
				// use the standard handler
				[PhoneMainView.instance changeCurrentView:ChatsListView.compositeViewDescription];
			} else if ([identifier isEqualToString:@"mark_read"]) {
				NSString *from = [notification.userInfo objectForKey:@"from_addr"];
				LinphoneChatRoom *room = linphone_core_get_chat_room_from_uri(LC, [from UTF8String]);
				if (room) {
					if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
						linphone_chat_room_mark_as_read(room);
					TabBarView *tab = (TabBarView *)[PhoneMainView.instance.mainViewController
						getCachedController:NSStringFromClass(TabBarView.class)];
					[tab update:YES];
					[PhoneMainView.instance updateApplicationBadgeNumber];
				}
			}
		}
	}
	completionHandler();
}

- (void)application:(UIApplication *)application
	handleActionWithIdentifier:(NSString *)identifier
		  forLocalNotification:(UILocalNotification *)notification
			  withResponseInfo:(NSDictionary *)responseInfo
			 completionHandler:(void (^)())completionHandler {

	LinphoneCall *call = linphone_core_get_current_call(LC);
	if (call) {
		LinphoneCallAppData *data = (__bridge LinphoneCallAppData *)linphone_call_get_user_data(call);
		if (data->timer) {
			[data->timer invalidate];
			data->timer = nil;
		}
	}
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
		NSString *from = [notification.userInfo objectForKey:@"from_addr"];
		[LinphoneManager.instance send:replyText to:from];
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
	[LinphoneManager.instance startLinphoneCore];
	[LinphoneManager.instance.fastAddressBook fetchContactsInBackGroundThread];
}

#pragma mark - Prevent ImagePickerView from rotating

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
	if ([[(PhoneMainView*)self.window.rootViewController currentView] equal:ImagePickerView.compositeViewDescription])
	{
		//Prevent rotation of camera
		NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
		[[UIDevice currentDevice] setValue:value forKey:@"orientation"];
		return UIInterfaceOrientationMaskPortrait;
	}
    else return UIInterfaceOrientationMaskPortrait; 
}

@end
