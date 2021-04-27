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

#import <UIKit/UIKit.h>
#import <PushKit/PushKit.h>

#import "LinphoneCoreSettingsStore.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import <CoreLocation/CoreLocation.h>
#import "SimplePing.h"
#import "linphoneapp-Swift.h"

@interface LinphoneAppDelegate : NSObject <UIApplicationDelegate, PKPushRegistryDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate, SimplePingDelegate, NSURLConnectionDelegate> {
    @private
	UIBackgroundTaskIdentifier bgStartId;
    BOOL startedInBackground;
	CLLocationManager* locationManager;
    
    NSMutableData * _responseData;
    NSURLResponse * _response;
}

- (void)registerForNotifications;

// to verify that we can reach network before accessing Voice server
- (void)tryWaitForNetwork;
- (void)setNetworkConnectingStatus;

- (NSString *)getDisplayNameFromCallId:(NSString *)callId;
- (NSString *)getDisplayName;

@property (nonatomic, retain) UIAlertController *waitingIndicator;
@property (nonatomic, retain) NSString *configURL;
@property (nonatomic, strong) UIWindow* window;
@property PKPushRegistry* voipRegistry;
@property BOOL alreadyRegisteredForNotification;
@property BOOL onlyPortrait;
@property UIApplicationShortcutItem *shortcutItem;
@property (nonatomic, retain) SimplePing* simplePing;
@property int pingCtr;
@property (nonatomic, retain) NSDictionary *pushInfo;
@property BOOL justLaunched;
@property (nonatomic, retain) NSString *pushToken; 

@end

