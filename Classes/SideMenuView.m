//
//  SideMenuViewController.m
//  linphone
//
//  Created by Gautier Pelloux-Prayer on 28/07/15.
//
//

#import "SideMenuView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"

@implementation SideMenuView

- (void)viewDidLoad {
	[super viewDidLoad];

#pragma deploymate push "ignored-api-availability"
	if (UIDevice.currentDevice.systemVersion.doubleValue >= 7) {
		// it's better to detect only pan from screen edges
		UIScreenEdgePanGestureRecognizer *pan =
			[[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(onLateralSwipe:)];
		pan.edges = UIRectEdgeRight;
		[self.view addGestureRecognizer:pan];
		_swipeGestureRecognizer.enabled = NO;
	}
#pragma deploymate pop
    
    CGFloat vheight = [[UIScreen mainScreen] bounds].size.height;
    if (vheight == 812.0) {
        self.topConstraint.constant = 35;
    }
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[_sideMenuTableViewController viewWillAppear:animated];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(registrationUpdateEvent:)
											   name:kLinphoneRegistrationUpdate
											 object:nil];

	[self updateHeader];
	[_sideMenuTableViewController.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	_grayBackground.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	_grayBackground.hidden = YES;
	// should be better than that with alpha animation..
}

- (void)updateHeader {
	LinphoneProxyConfig *default_proxy = linphone_core_get_default_proxy_config(LC);

	if (default_proxy != NULL) {
		const LinphoneAddress *addr = linphone_proxy_config_get_identity_address(default_proxy);
		[ContactDisplay setDisplayNameLabel:_nameLabel forAddress:addr];
        
        _addressLabel.text = [NSString stringWithUTF8String:linphone_address_get_username(addr)];
        if ([_addressLabel.text isEqualToString:_nameLabel.text]) {
            _addressLabel.text = nil;
        }
        
		_presenceImage.image = [StatusBarView imageForState:linphone_proxy_config_get_state(default_proxy)];
	} else {
        _nameLabel.text = @"No account"; 
        _addressLabel.text = nil;
		_presenceImage.image = nil;
	}
	_avatarImage.image = [LinphoneUtils selfAvatar];
}

#pragma deploymate push "ignored-api-availability"
- (void)onLateralSwipe:(UIScreenEdgePanGestureRecognizer *)pan {
	
}
#pragma deploymate pop

- (IBAction)onHeaderClick:(id)sender {
	[PhoneMainView.instance.mainViewController hideSideMenu:YES];
}

- (IBAction)onAvatarClick:(id)sender {
	// hide ourself because we are on top of image picker
	/*if (!IPAD) {
		[PhoneMainView.instance.mainViewController hideSideMenu:YES];
	}
	[ImagePickerView SelectImageFromDevice:self atPosition:_avatarImage inView:self.view];*/
}

- (IBAction)onBackgroundClicked:(id)sender {
	[PhoneMainView.instance.mainViewController hideSideMenu:YES];
}

- (IBAction)onAddVpnProfle:(id)sender {
    StatusBarView *sbar = (StatusBarView *)[PhoneMainView.instance.mainViewController
                                            getCachedController:NSStringFromClass(StatusBarView.class)];
    if (sbar) {
        [sbar hideMenu];
    }
    [PhoneMainView.instance handleAddVpnProfile];
}

- (IBAction)onPrivacyPolicy:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.glaciersecurity.com/privacy-policy/"]];
    [PhoneMainView.instance.mainViewController hideSideMenu:YES];
}

- (IBAction)onAcknowledgements:(id)sender {
    [PhoneMainView.instance changeCurrentView:AcknowledgementsView.compositeViewDescription];
    StatusBarView *sbar = (StatusBarView *)[PhoneMainView.instance.mainViewController
                                     getCachedController:NSStringFromClass(StatusBarView.class)];
    if (sbar) {
        [sbar hideMenu];
    }
}

- (IBAction)onAbout:(id)sender {
    [PhoneMainView.instance changeCurrentView:AboutView.compositeViewDescription];
    StatusBarView *sbar = (StatusBarView *)[PhoneMainView.instance.mainViewController
                                            getCachedController:NSStringFromClass(StatusBarView.class)];
    if (sbar) {
        [sbar hideMenu];
        [sbar openingAbout];
    }
}

- (IBAction)onSupport:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://0z0g1.typeform.com/to/GA6wp3"]];
    [PhoneMainView.instance.mainViewController hideSideMenu:YES];
}

- (IBAction)onLogout:(id)sender {
    UIAlertController *errView = [UIAlertController alertControllerWithTitle:@"Warning"
                                                    message:@"Are you sure to want to logout?"
                                                    preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {}];
    
    UIAlertAction* continueAction = [UIAlertAction actionWithTitle:@"Yes"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    [self logout:sender];
                                                }];
    
    [errView addAction:defaultAction];
    [errView addAction:continueAction];
    [self presentViewController:errView animated:YES completion:nil];
}

- (void) logout:(id)sender {
    SettingsView *sview = (SettingsView *)[PhoneMainView.instance.mainViewController
                                            getCachedController:NSStringFromClass(SettingsView.class)];
    if (sview) {
        [sview tryRemoveAccount];
    }
    
    NSUserDefaults *glacierDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.glaciersec.apps"];
    NSString *saveorg = [glacierDefaults stringForKey:@"orgid"];
    [glacierDefaults removePersistentDomainForName:@"group.com.glaciersec.apps"];
    [glacierDefaults synchronize];
    if (saveorg) {
        glacierDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.glaciersec.apps"];
        [glacierDefaults setObject:saveorg forKey:@"orgid"];
    }
    
    StatusBarView *sbar = (StatusBarView *)[PhoneMainView.instance.mainViewController
                                            getCachedController:NSStringFromClass(StatusBarView.class)];
    if (sbar) {
        [sbar hideMenu];
    }
    
    [PhoneMainView.instance teardownCognito];
    [PhoneMainView.instance setupAccount];
}


- (void)registrationUpdateEvent:(NSNotification *)notif {
	[self updateHeader];
	[_sideMenuTableViewController.tableView reloadData];
}

#pragma mark - Image picker delegate

- (void)imagePickerDelegateImage:(UIImage *)image info:(NSDictionary *)info {
	// When getting image from the camera, it may be 90° rotated due to orientation
	// (image.imageOrientation = UIImageOrientationRight). Just rotate it to be face up.
	if (image.imageOrientation != UIImageOrientationUp) {
		UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale);
		[image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}

	// Dismiss popover on iPad
	if (IPAD) {
		[VIEW(ImagePickerView).popoverController dismissPopoverAnimated:TRUE];
	} else {
		[PhoneMainView.instance.mainViewController hideSideMenu:NO];
	}

	NSURL *url = [info valueForKey:UIImagePickerControllerReferenceURL];

	// taken from camera, must be saved to device first
	if (!url) {
		[LinphoneManager.instance.photoLibrary
			writeImageToSavedPhotosAlbum:image.CGImage
							 orientation:(ALAssetOrientation)[image imageOrientation]
						 completionBlock:^(NSURL *assetURL, NSError *error) {
						   if (error) {
							   LOGE(@"Cannot save image data downloaded [%@]", [error localizedDescription]);
						   } else {
							   LOGI(@"Image saved to [%@]", [assetURL absoluteString]);
						   }
						   [LinphoneManager.instance lpConfigSetString:assetURL.absoluteString forKey:@"avatar"];
						   _avatarImage.image = [LinphoneUtils selfAvatar];
						 }];
	} else {
		[LinphoneManager.instance lpConfigSetString:url.absoluteString forKey:@"avatar"];
		_avatarImage.image = [LinphoneUtils selfAvatar];
	}
}

@end
