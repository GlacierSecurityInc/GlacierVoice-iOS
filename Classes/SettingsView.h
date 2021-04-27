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

#import "UICompositeView.h"
#import "IASKAppSettingsViewController.h"
#import "LinphoneCoreSettingsStore.h"

@interface SettingsView
	: UIViewController <IASKSettingsDelegate, UICompositeViewDelegate, MFMailComposeViewControllerDelegate> {
  @private
	LinphoneCoreSettingsStore *settingsStore;
		BOOL isRoot;
}

@property(nonatomic, strong) IBOutlet UINavigationController *navigationController;
@property(nonatomic, strong) IBOutlet IASKAppSettingsViewController *settingsController;
@property(weak, nonatomic) IBOutlet UIView *subView;
@property(weak, nonatomic) IBOutlet UIButton *backButton;
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(nonatomic) NSString* tmpPwd;

- (IBAction)onDialerBackClick:(id)sender;
- (IBAction)onBackClick:(id)sender;

- (void)tryRemoveAccount;
- (void)trySynchronize;

- (void)trySetBypass:(BOOL)shouldBypass;

@end
