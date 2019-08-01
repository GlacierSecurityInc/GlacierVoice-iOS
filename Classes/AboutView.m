/* AboutViewController.m
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

#import "PhoneMainView.h"
#import "LinphoneManager.h"
#import "LinphoneIOSVersion.h"

@implementation AboutView

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
	}
	return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
	return self.class.compositeViewDescription;
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];
    
	NSString *name = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	_nameLabel.text = name;
    
    LinphoneProxyConfig *default_proxy = linphone_core_get_default_proxy_config(LC);
    
    if (default_proxy != NULL) {
        NSString *name = [NSString
                          stringWithUTF8String:linphone_address_get_username(linphone_proxy_config_get_identity_address(default_proxy))];
        _extentionLabel.text = [NSString stringWithFormat:@"Extension: %@", name];
        
    } else {
        _extentionLabel.text = NSLocalizedString(@"No address", nil);
    }
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    _appVersionLabel.text = [NSString stringWithFormat:@"Version %@", version];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setExternalNumber];
    [self setConnectionState];
}

- (void) setConnectionState {
    LinphoneRegistrationState state = LinphoneRegistrationNone;
    NSString *message = nil;
    LinphoneGlobalState gstate = linphone_core_get_global_state(LC);
    LinphoneProxyConfig *default_proxy = linphone_core_get_default_proxy_config(LC);
    _statusLabel.textColor = [UIColor darkGrayColor];
    
    if ([LinphoneManager.instance isConnectingToNetwork]) {
        message = @"Connecting";
    } else if (gstate == LinphoneGlobalOn && !linphone_core_is_network_reachable(LC)) {
        _statusLabel.textColor = [UIColor redColor];
        message = NSLocalizedString(@"Network down", nil);
    } else if (gstate == LinphoneGlobalConfiguring) {
        message = NSLocalizedString(@"Fetching remote configuration", nil);
    } else if (default_proxy == NULL) {
        state = LinphoneRegistrationNone;
        if (linphone_core_get_proxy_config_list(LC) != NULL) {
            message = NSLocalizedString(@"No default account", nil);
        } else {
            message = NSLocalizedString(@"No account configured", nil);
        }
    } else {
        state = linphone_proxy_config_get_state(default_proxy);
        
        switch (state) {
            case LinphoneRegistrationOk:
                message = @"Connected";
                break;
            case LinphoneRegistrationNone:
            case LinphoneRegistrationCleared:
                message = NSLocalizedString(@"Not registered", nil);
                break;
            case LinphoneRegistrationFailed:
                message = NSLocalizedString(@"Registration failed", nil);
                break;
            case LinphoneRegistrationProgress:
                message = @"Connecting";
                break;
            default:
                break;
        }
    }
    
    _statusLabel.text = [NSString stringWithFormat:@"Network Status: %@", message];
}

- (void)setExternalNumber {
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"VoiceInfo.plist"];
    NSString *extNum = @"None";
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSDictionary *pdict = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        extNum = [pdict objectForKey:@"account_external_number_preference"];
        if ([extNum length] < 6)
        {
            extNum = @"None";
        }
        else{
            extNum = [self convertPhoneNumber:extNum];
        }
    }
    _externalNumLabel.text = [NSString stringWithFormat:@"External Number: %@", extNum];
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

// Tapping 5 times brings user to Settings
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *aTouch in touches) {
        if (aTouch.tapCount >= 5) {
            StatusBarView *sbar = (StatusBarView *)[PhoneMainView.instance.mainViewController
                    getCachedController:NSStringFromClass(StatusBarView.class)];
            if (sbar) {
                [sbar hideMenu];
            }
            [PhoneMainView.instance changeCurrentView:SettingsView.compositeViewDescription]; 
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}


#pragma mark - Action Functions

- (IBAction)onLinkTap:(id)sender {
	UIGestureRecognizer *gest = sender;
	NSString *url = ((UILabel *)gest.view).text;
	if (![UIApplication.sharedApplication openURL:[NSURL URLWithString:url]]) {
		LOGE(@"Failed to open %@, invalid URL", url);
	}
}

- (IBAction)onDialerBackClick:(id)sender {
	[PhoneMainView.instance popToView:DialerView.compositeViewDescription];
}
@end
