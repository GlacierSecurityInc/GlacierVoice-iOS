/* StatusBarViewController.m
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
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "StatusBarView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "LinphoneAppDelegate.h"
#import <UserNotifications/UserNotifications.h>

@implementation StatusBarView {

    __weak IBOutlet UIButton *smenuBtn;
    __weak IBOutlet UIButton *scloseBtn;
	NSTimer *callQualityTimer;
	NSTimer *callSecurityTimer;
	int messagesUnreadCount;
    BOOL onAbout;
    
    NSString *tempStatus;
    CFTimeInterval lastUpdate;
}

#pragma mark - Lifecycle Functions

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self];
	[callQualityTimer invalidate];
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// Set observer
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(registrationUpdate:)
											   name:kLinphoneRegistrationUpdate
											 object:nil];

	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(globalStateUpdate:)
											   name:kLinphoneGlobalStateUpdate
											 object:nil];

	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(notifyReceived:)
											   name:kLinphoneNotifyReceived
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(mainViewChanged:)
											   name:kLinphoneMainViewChange
											 object:nil];

	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(callUpdate:)
											   name:kLinphoneCallUpdate
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(onCallEncryptionChanged:)
											   name:kLinphoneCallEncryptionChanged
											 object:nil];

	// Update to default state
	LinphoneProxyConfig *config = linphone_core_get_default_proxy_config(LC);
	messagesUnreadCount = lp_config_get_int(linphone_core_get_config(LC), "app", "voice_mail_messages_count", 0);
    tempStatus = nil;

	[self proxyConfigUpdate:config];
	[self updateUI:linphone_core_get_calls_nb(LC)];
	[self updateVoicemail];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	// Remove observer
	[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneRegistrationUpdate object:nil];
	[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneGlobalStateUpdate object:nil];
	[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneNotifyReceived object:nil];
	[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneCallUpdate object:nil];
	[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneMainViewChange object:nil];

	if (callQualityTimer != nil) {
		[callQualityTimer invalidate];
		callQualityTimer = nil;
	}
	if (callSecurityTimer != nil) {
		[callSecurityTimer invalidate];
		callSecurityTimer = nil;
	}

	if (securityDialog != nil) {
		[securityDialog dismiss];
		securityDialog = nil;
	}
}

#pragma mark - Event Functions

- (void)registrationUpdate:(NSNotification *)notif {
	LinphoneProxyConfig *config = linphone_core_get_default_proxy_config(LC);
	[self proxyConfigUpdate:config];
}

- (void)globalStateUpdate:(NSNotification *)notif {
	[self registrationUpdate:nil];
}

- (void)mainViewChanged:(NSNotification *)notif {
	[self registrationUpdate:nil];
}

- (void)onCallEncryptionChanged:(NSNotification *)notif {
	LinphoneCall *call = linphone_core_get_current_call(LC);

	if (call && (linphone_call_params_get_media_encryption(linphone_call_get_current_params(call)) ==
				 LinphoneMediaEncryptionZRTP) &&
		(!linphone_call_get_authentication_token_verified(call))) {
		[self onSecurityClick:nil];
	}
}

- (void)notifyReceived:(NSNotification *)notif {
	const LinphoneContent *content = [[notif.userInfo objectForKey:@"content"] pointerValue];

	if ((content == NULL) || (strcmp("application", linphone_content_get_type(content)) != 0) ||
		(strcmp("simple-message-summary", linphone_content_get_subtype(content)) != 0) ||
		(linphone_content_get_buffer(content) == NULL)) {
		return;
	}
	const char *body = linphone_content_get_buffer(content);
	if ((body = strstr(body, "Voice-Message: ")) == NULL) {
		LOGW(@"Received new NOTIFY from voice mail but could not find 'voice-message' in BODY. Ignoring it.");
		return;
	}

	sscanf(body, "Voice-Message: %d", &messagesUnreadCount);

	LOGI(@"Received new NOTIFY from voice mail: there is/are now %d message(s) unread", messagesUnreadCount);

	// save in lpconfig for future
	lp_config_set_int(linphone_core_get_config(LC), "app", "voice_mail_messages_count", messagesUnreadCount);

	[self updateVoicemail];
}

- (void)updateVoicemail {
    if (onAbout) {
        _voicemailButton.hidden = YES;
        _voicemailButton.enabled = NO;
    } else {
        _voicemailButton.hidden = (messagesUnreadCount <= 0);
        _voicemailButton.enabled = (messagesUnreadCount > 0);
    }
    
    [self.voicemailButton setTitle:[NSString stringWithFormat:@" %@", @(messagesUnreadCount).stringValue] forState:UIControlStateNormal];
}

- (void)callUpdate:(NSNotification *)notif {
	// show voice mail only when there is no call
	[self updateUI:linphone_core_get_calls(LC) != NULL];
	[self updateVoicemail];
}

#pragma mark -

+ (UIImage *)imageForState:(LinphoneRegistrationState)state {
	switch (state) {
		case LinphoneRegistrationFailed:
			return [UIImage imageNamed:@"led_error.png"];
		case LinphoneRegistrationCleared:
		case LinphoneRegistrationNone:
			return [UIImage imageNamed:@"led_disconnected.png"];
		case LinphoneRegistrationProgress:
			return [UIImage imageNamed:@"led_inprogress.png"];
		case LinphoneRegistrationOk:
			return [UIImage imageNamed:@"led_connected.png"];
	}
}
- (void)proxyConfigUpdate:(LinphoneProxyConfig *)config {
	LinphoneRegistrationState state = LinphoneRegistrationNone;
	NSString *message = nil;
	LinphoneGlobalState gstate = linphone_core_get_global_state(LC);
	
	if ([PhoneMainView.instance.currentView equal:AssistantView.compositeViewDescription] || [PhoneMainView.instance.currentView equal:CountryListView.compositeViewDescription]) {
		message = NSLocalizedString(@"Configuring account", nil);
    } else if ([LinphoneManager.instance isConnectingToNetwork]) {
        message = NSLocalizedString(@"Registration in progress", nil);
    } else if (gstate == LinphoneGlobalOn && !linphone_core_is_network_reachable(LC)) {
        NSString *acctType = PhoneMainView.instance.accountType;
        if (acctType == nil || [acctType isEqualToString:@"none"]) {
            message = @"Offline - Tap to try again";
        } else if ([acctType isEqualToString:@"ipsec"]) {
            message = @"Offline - Enable VPN in iOS Settings";
        } else {
            message = @"Offline - Tap for OpenVPN";
        }
        
	} else if (gstate == LinphoneGlobalConfiguring) {
		message = NSLocalizedString(@"Fetching remote configuration", nil);
	} else if (config == NULL) {
		state = LinphoneRegistrationNone;
		if (linphone_core_get_proxy_config_list(LC) != NULL) {
			message = NSLocalizedString(@"No default account", nil);
		} else {
			message = NSLocalizedString(@"No account configured", nil);
		}
    } else if (tempStatus) {
        message = tempStatus;
    } else {
		state = linphone_proxy_config_get_state(config);

		switch (state) {
			case LinphoneRegistrationOk:
				message = nil;
				break;
			case LinphoneRegistrationNone:
			case LinphoneRegistrationCleared:
				message = NSLocalizedString(@"Not registered", nil);
				break;
			case LinphoneRegistrationFailed:
				message = NSLocalizedString(@"Registration failed", nil);
				break;
			case LinphoneRegistrationProgress:
				message = NSLocalizedString(@"Registration in progress", nil);
				break;
			default:
				break;
		}
	}
	[_registrationState setTitle:message forState:UIControlStateNormal];
	_registrationState.accessibilityValue = message;
    [_registrationState setImage:nil forState:UIControlStateNormal];
}

#pragma mark -

- (void)updateUI:(BOOL)inCall {
	BOOL hasChanged = (_outcallView.hidden != inCall);

	_outcallView.hidden = inCall;
	_incallView.hidden = !inCall;

	if (!hasChanged)
		return;

	if (callQualityTimer) {
		[callQualityTimer invalidate];
		callQualityTimer = nil;
	}
	if (callSecurityTimer) {
		[callSecurityTimer invalidate];
		callSecurityTimer = nil;
	}
	if (securityDialog) {
		[securityDialog dismiss];
	}

	// if we are in call, we have to update quality and security icons every sec
	if (inCall) {
		callQualityTimer = [NSTimer scheduledTimerWithTimeInterval:1
															target:self
														  selector:@selector(callQualityUpdate)
														  userInfo:nil
														   repeats:YES];
		callSecurityTimer = [NSTimer scheduledTimerWithTimeInterval:1
															 target:self
														   selector:@selector(callSecurityUpdate)
														   userInfo:nil
															repeats:YES];
	}
}

- (void)callSecurityUpdate {
	BOOL pending = false;
	BOOL security = true;

	const MSList *list = linphone_core_get_calls(LC);
	if (list == NULL) {
		if (securityDialog) {
			[securityDialog dismiss];
		}
	} else {
		_callSecurityButton.hidden = NO;
		while (list != NULL) {
			LinphoneCall *call = (LinphoneCall *)list->data;
			LinphoneMediaEncryption enc =
				linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
			if (enc == LinphoneMediaEncryptionNone)
				security = false;
			else if (enc == LinphoneMediaEncryptionZRTP) {
				if (!linphone_call_get_authentication_token_verified(call)) {
					pending = true;
				}
			}
			list = list->next;
		}
		NSString *imageName =
			(security ? (pending ? @"security_pending.png" : @"security_ok.png") : @"security_ko.png");
		[_callSecurityButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
	}
}

- (void)callQualityUpdate {
	LinphoneCall *call = linphone_core_get_current_call(LC);
	if (call != NULL) {
		int quality = MIN(4, floor(linphone_call_get_current_quality(call)));
		NSString *accessibilityValue = [NSString stringWithFormat:NSLocalizedString(@"Call quality: %d", nil), quality];
		if (![accessibilityValue isEqualToString:_callQualityButton.accessibilityValue]) {
			_callQualityButton.accessibilityValue = accessibilityValue;
			_callQualityButton.hidden = NO; //(quality == -1.f);
			UIImage *image =
				(quality == -1.f)
					? [UIImage imageNamed:@"call_quality_indicator_0.png"] // nil
					: [UIImage imageNamed:[NSString stringWithFormat:@"call_quality_indicator_%d.png", quality]];
			[_callQualityButton setImage:image forState:UIControlStateNormal];
		}
	}
}

#pragma mark - Action Functions

- (IBAction)onSecurityClick:(id)sender {
	if (linphone_core_get_calls_nb(LC)) {
		LinphoneCall *call = linphone_core_get_current_call(LC);
		if (call != NULL) {
			LinphoneMediaEncryption enc =
				linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
			if (enc == LinphoneMediaEncryptionZRTP) {
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
				NSString *message =
					[NSString stringWithFormat:NSLocalizedString(@"Confirm the following SAS with peer:\n"
																 @"Say : %@\n"
																 @"Your correspondant should say : %@",
																 nil),
											   myCode, correspondantCode];

				if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive &&
					floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
					UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
					content.title = NSLocalizedString(@"ZRTP verification", nil);
					content.body = message;
					content.categoryIdentifier = @"zrtp_request";
					content.userInfo = @{
						@"CallId" : [NSString
							stringWithUTF8String:linphone_call_log_get_call_id(linphone_call_get_call_log(call))]
					};

					UNNotificationRequest *req =
						[UNNotificationRequest requestWithIdentifier:@"zrtp_request" content:content trigger:NULL];
					[[UNUserNotificationCenter currentNotificationCenter]
						addNotificationRequest:req
						 withCompletionHandler:^(NSError *_Nullable error) {
						   // Enable or disable features based on authorization.
						   if (error) {
							   LOGD(@"Error while adding notification request :");
							   LOGD(error.description);
						   }
						 }];
				} else {
					if (securityDialog == nil) {
						__block __strong StatusBarView *weakSelf = self;
						securityDialog = [UIConfirmationDialog ShowWithMessage:message
							cancelMessage:NSLocalizedString(@"DENY", nil)
							confirmMessage:NSLocalizedString(@"ACCEPT", nil)
							onCancelClick:^() {
							  if (linphone_core_get_current_call(LC) == call) {
								  linphone_call_set_authentication_token_verified(call, NO);
							  }
							  weakSelf->securityDialog = nil;
							}
							onConfirmationClick:^() {
							  if (linphone_core_get_current_call(LC) == call) {
								  linphone_call_set_authentication_token_verified(call, YES);
							  }
							  weakSelf->securityDialog = nil;
							}];
					}
				}
			}
		}
	}
}

- (IBAction)onVoicemailClick:(id)sender {
    DialerView *view = VIEW(DialerView);
    [view onOneLongClick:sender];
}

- (IBAction)onSideMenuClick:(id)sender {
        UICompositeView *cvc = PhoneMainView.instance.mainViewController;
        CGRect sframe = cvc.sideMenuView.frame;
        [cvc hideSideMenu:(sframe.origin.x > -350)];
}

- (void) openingAbout {
    onAbout = YES;
}

- (void) updateTempStatus:(NSString *)status {
    tempStatus = status;
    
    if (status != nil) {
        [self registrationUpdate:nil];
        lastUpdate = CACurrentMediaTime();
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateTempStatus:nil];
        });
    } else {
        CFTimeInterval elapsedTime = CACurrentMediaTime() - lastUpdate;
        if (elapsedTime > 3.0) {
            [self registrationUpdate:nil];
        }
    }
}

- (void) hideMenu {
    [scloseBtn setImage:[UIImage imageNamed:@"close.png"] forState:UIControlStateNormal];
    [smenuBtn setImage:nil forState:UIControlStateNormal];
    [smenuBtn setEnabled:NO];
    
    [scloseBtn setEnabled:YES];
    _voicemailButton.hidden = YES;
    _voicemailButton.enabled = NO;
}

- (IBAction)onClickClose:(id)sender {
        [PhoneMainView.instance changeCurrentView:DialerView.compositeViewDescription];
        [scloseBtn setImage:nil forState:UIControlStateNormal];
        [smenuBtn setImage:[UIImage imageNamed:@"menu.png"] forState:UIControlStateNormal];
        [smenuBtn setEnabled:YES];
    
        [scloseBtn setEnabled:NO];
        _voicemailButton.hidden = (messagesUnreadCount <= 0);
        _voicemailButton.enabled = (messagesUnreadCount > 0);
        
        onAbout = NO;
}

- (IBAction)onRegistrationStateClick:(id)sender {
	if (linphone_core_get_default_proxy_config(LC)) {
        // handle various vpn types
        if (!linphone_core_is_network_reachable(LC)) { 
            UIApplication *app = [UIApplication sharedApplication];
            LinphoneAppDelegate *delegate = (LinphoneAppDelegate *)app.delegate;
            
            NSString* msg = _registrationState.currentTitle;
            if ([msg hasSuffix:@"OpenVPN"]) {  // open the OpenVPN Connect app to check connection status
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"openvpn://"]]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"openvpn://"]];
                    });
                } else {
                    [self noOpenVPNAlert]; // connection type openvpn but OpenVPN Connect is not on device
                }
            } else {
                [delegate tryWaitForNetwork];
                [delegate setNetworkConnectingStatus];
            }
        } else {
            linphone_core_refresh_registers(LC);
        }
	} else if (linphone_core_get_proxy_config_list(LC)) {
		[PhoneMainView.instance changeCurrentView:SettingsView.compositeViewDescription];
	} else {
		[PhoneMainView.instance changeCurrentView:AssistantView.compositeViewDescription];
	}
}

- (void) noOpenVPNAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OpenVPN Connect not installed" message:@"No way to get to OpenVPN Connect. Please download OpenVPN Connect from the App Store." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
