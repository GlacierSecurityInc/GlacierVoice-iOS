/* AcknowledgementsViewController.m
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

@implementation AcknowledgementsView

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
    
    UITapGestureRecognizer *tapGestureRecognizerLicence =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onLicenceTap)];
    tapGestureRecognizerLicence.numberOfTapsRequired = 1;
    [_licenceLabel addGestureRecognizer:tapGestureRecognizerLicence];
    _licenceLabel.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGestureRecognizerLinLink =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onLinLinkTap)];
    tapGestureRecognizerLinLink.numberOfTapsRequired = 1;
    [_siteURLLabel addGestureRecognizer:tapGestureRecognizerLinLink];
    _siteURLLabel.userInteractionEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


#pragma mark - Action Functions

- (IBAction)onLicenceTap {
    NSString *url = @"https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html";
    if (![UIApplication.sharedApplication openURL:[NSURL URLWithString:url]]) {
        LOGE(@"Failed to open %@, invalid URL", url);
    }
}

- (IBAction)onLinLinkTap {
	NSString *url = @"https://www.linphone.org";
	if (![UIApplication.sharedApplication openURL:[NSURL URLWithString:url]]) {
		LOGE(@"Failed to open %@, invalid URL", url);
	}
}

- (IBAction)onDialerBackClick:(id)sender {
	[PhoneMainView.instance popToView:DialerView.compositeViewDescription];
}
@end
