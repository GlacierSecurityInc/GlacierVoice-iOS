/* IncomingCallViewController.m
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

#import "CallIncomingView.h"
#import "LinphoneManager.h"
#import "FastAddressBook.h"
#import "PhoneMainView.h"
#import "Utils.h"

@implementation CallIncomingView

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(callUpdateEvent:)
											   name:kLinphoneCallUpdate
											 object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneCallUpdate object:nil];
	_call = NULL;
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:self.class
															  statusBar:StatusBarView.class
																 tabBar:nil
															   sideMenu:nil
															 fullscreen:false
														 isLeftFragment:YES
														   fragmentWith:nil];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
	return self.class.compositeViewDescription;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	if (_call) {
		[self update];
	}
}

#pragma mark - Event Functions

- (void)callUpdateEvent:(NSNotification *)notif {
	LinphoneCall *acall = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState astate = [[notif.userInfo objectForKey:@"state"] intValue];
	[self callUpdate:acall state:astate];
}

- (void)callUpdate:(LinphoneCall *)acall state:(LinphoneCallState)astate {
	if (_call == acall && (astate == LinphoneCallEnd || astate == LinphoneCallError)) {
		[_delegate incomingCallAborted:_call];
	} else if ([LinphoneManager.instance lpConfigBoolForKey:@"auto_answer"]) {
		LinphoneCallState state = linphone_call_get_state(_call);
		if (state == LinphoneCallIncomingReceived) {
			LOGI(@"Auto answering call");
			[self onAcceptClick:nil];
		}
	}
}

#pragma mark -

- (void)update {
	const LinphoneAddress *addr = linphone_call_get_remote_address(_call);
	[ContactDisplay setDisplayNameLabel:_nameLabel forAddress:addr];
	char *uri = linphone_address_as_string_uri_only(addr);
	_addressLabel.text = [NSString stringWithUTF8String:uri];
	ms_free(uri);
	[_avatarImage setImage:[FastAddressBook imageForAddress:addr] bordered:YES withRoundedRadius:YES];
    
    // trying to get correct display name instead of extension
    const bctbx_list_t *logs = linphone_core_get_call_history_for_address(LC, addr);
    while (logs != NULL) {
        LinphoneCallLog *log = (LinphoneCallLog *)logs->data;
        LinphoneAddress *remoteaddr = linphone_call_log_get_remote_address(log);
        if (linphone_address_weak_equal(remoteaddr, addr)) {
            NSString *display = [FastAddressBook displayNameForAddress:remoteaddr];
            if (display && ![display isEqualToString:_nameLabel.text] &&
                ![display isEqualToString:@"Unknown"]) {
                _nameLabel.text = display;
                break;
            }
        }
        logs = bctbx_list_next(logs);
    }

	_tabBar.hidden = linphone_call_params_video_enabled(linphone_call_get_remote_params(_call));
	_tabVideoBar.hidden = !_tabBar.hidden;
}

#pragma mark - Property Functions

- (void)setCall:(LinphoneCall *)call {
	_call = call;
	[self update];
	[self callUpdate:_call state:linphone_call_get_state(call)];
}

#pragma mark - Action Functions

- (IBAction)onAcceptClick:(id)event {
	[_delegate incomingCallAccepted:_call evenWithVideo:YES];
}

- (IBAction)onDeclineClick:(id)event {
	[_delegate incomingCallDeclined:_call];
}

- (IBAction)onAcceptAudioOnlyClick:(id)sender {
	[_delegate incomingCallAccepted:_call evenWithVideo:NO];
}

@end
