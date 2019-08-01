/* HistoryDetailsViewController.m
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

#import "HistoryDetailsView.h"
#import "PhoneMainView.h"
#import "FastAddressBook.h"

@implementation HistoryDetailsView

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:self.class
															  statusBar:StatusBarView.class
																 tabBar:TabBarView.class
															   sideMenu:SideMenuView.class
															 fullscreen:false
														 isLeftFragment:NO
														   fragmentWith:HistoryListView.class];
	}
	return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
	return self.class.compositeViewDescription;
}

#pragma mark - Property Functions

- (void)setCallLogId:(NSString *)acallLogId {
	_callLogId = [acallLogId copy];
	[self update];
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];

	// if we use fragments, remove back button
	if (IPAD) {
		_backButton.hidden = YES;
		_backButton.alpha = 0;
		
	}

	UITapGestureRecognizer *headerTapGesture =
		[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onContactClick:)];
	[_headerView addGestureRecognizer:headerTapGesture];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self update];

	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(update)
											   name:kLinphoneAddressBookUpdate
											 object:nil];

	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(coreUpdateEvent:)
											   name:kLinphoneCoreUpdate
											 object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(deviceOrientationDidChange:)
												 name: UIDeviceOrientationDidChangeNotification
											   object: nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - Event Functions

- (void)coreUpdateEvent:(NSNotification *)notif {
	@try {
		[self update];
	}
	@catch (NSException *exception) {
		if ([exception.name isEqualToString:@"LinphoneCoreException"]) {
			LOGE(@"Core already destroyed");
			return;
		}
		LOGE(@"Uncaught exception : %@", exception.description);
		abort();
	}
}

- (void) deviceOrientationDidChange:(NSNotification*) notif {
	if (IPAD) {
		[self update];
	}
}

#pragma mark -

- (void)update {
	// Look for the call log
	callLog = NULL;
	if (_callLogId) {
		const MSList *list = linphone_core_get_call_logs(LC);
		while (list != NULL) {
			LinphoneCallLog *log = (LinphoneCallLog *)list->data;
			const char *cid = linphone_call_log_get_call_id(log);
			if (cid != NULL && [_callLogId isEqualToString:[NSString stringWithUTF8String:cid]]) {
				callLog = log;
				break;
			}
			list = list->next;
		}
	}

	// Pop if callLog is null
	if (callLog == NULL) {
		_emptyLabel.hidden = NO;
		_addContactButton.hidden = YES;
		return;
	}
	_emptyLabel.hidden = YES;

	const LinphoneAddress *addr = linphone_call_log_get_remote_address(callLog);
	_addContactButton.hidden = ([FastAddressBook getContactWithAddress:addr] != nil);
	[ContactDisplay setDisplayNameLabel:_contactLabel forAddress:addr];
	[_avatarImage setImage:[FastAddressBook imageForAddress:addr] bordered:NO withRoundedRadius:YES];
	char *addrURI = linphone_address_as_string_uri_only(addr);
	_addressLabel.text = [NSString stringWithUTF8String:addrURI];
    
    //trying to show display name instead of extension if known
    const bctbx_list_t *logs = linphone_core_get_call_history_for_address(LC, addr);
    while (logs != NULL) {
        LinphoneCallLog *log = (LinphoneCallLog *)logs->data;
        const LinphoneAddress *remoteaddr = linphone_call_log_get_remote_address(log);
        if (linphone_address_weak_equal(remoteaddr, addr)) {
            NSString *display = [FastAddressBook displayNameForAddress:remoteaddr];
            if (display && ![display isEqualToString:_contactLabel.text] &&
                ![display isEqualToString:@"Unknown"]) {
                _contactLabel.text = display;
                break;
            }
        }
        logs = bctbx_list_next(logs);
    }
    
    char *num_address = NULL;
    num_address = ms_strdup(linphone_address_get_username(addr));
    NSString *num_str = [NSString stringWithUTF8String:num_address];
    if (![num_str isEqualToString:_contactLabel.text]) {
        _contactNumLabel.text = num_str;
    } else {
        _contactNumLabel.text = nil;
    }
    ms_free(num_address);
    
	ms_free(addrURI);

	[_tableView loadDataForAddress:(callLog ? linphone_call_log_get_remote_address(callLog) : NULL)];
}

#pragma mark - Action Functions

- (IBAction)onBackClick:(id)event {
	HistoryListView *view = VIEW(HistoryListView);
	[PhoneMainView.instance popToView:view.compositeViewDescription];
}

- (IBAction)onContactClick:(id)event {
	const LinphoneAddress *addr = linphone_call_log_get_remote_address(callLog);
	Contact *contact = [FastAddressBook getContactWithAddress:addr];
	if (contact) {
		ContactDetailsView *view = VIEW(ContactDetailsView);
		[PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
		[ContactSelection setSelectionMode:ContactSelectionModeNone];
		[view setContact:contact];
	}
}

- (IBAction)onAddContactClick:(id)event {
	const LinphoneAddress *addr = linphone_call_log_get_remote_address(callLog);
	char *lAddress = linphone_address_as_string_uri_only(addr);
	if (lAddress != NULL) {
        NSString *input = [[NSString alloc] initWithUTF8String:lAddress];
        [ContactSelection setAddAddress:[input stringByReplacingOccurrencesOfString:@"sip:" withString:@""]];
        
		[ContactSelection setSelectionMode:ContactSelectionModeEdit];

		[ContactSelection setSipFilter:nil];
		[ContactSelection enableEmailFilter:FALSE];
		[ContactSelection setNameOrEmailFilter:nil];
		[PhoneMainView.instance changeCurrentView:ContactsListView.compositeViewDescription];
		ms_free(lAddress);
	}
}

- (IBAction)onCallClick:(id)event {
    LinphoneAddress *addr = [LinphoneUtils normalizeFromAddr:linphone_call_log_get_remote_address(callLog)];
    [LinphoneManager.instance call:addr];
    if (addr)
        linphone_address_destroy(addr);
}


- (IBAction)onChatClick:(id)event {
    [self goGlacierMessenger];
}

//go to Glacier Messenger app if possible
- (void)goGlacierMessenger
{
    NSString *customURL = @"glaciermessenger://";
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:customURL]])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:customURL]];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Messenger not installed"
                                                        message:[NSString stringWithFormat:@"Please download Glacier Messenger from the App store."]
                                                       delegate:self cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
}


@end
