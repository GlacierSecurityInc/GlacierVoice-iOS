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
#import "UIToggleButton.h"
#import "ContactDetailsTableView.h"
#import "UIRoundedImageView.h"
#import "ImagePickerView.h"

@interface ContactDetailsView : TPMultiLayoutViewController <UICompositeViewDelegate, ImagePickerDelegate> {
	BOOL inhibUpdate;
}

@property(nonatomic, assign, setter=setContact:) Contact *contact;
@property(nonatomic) Contact *tmpContact;
@property(nonatomic, strong) IBOutlet ContactDetailsTableView *tableController;
@property(nonatomic, strong) IBOutlet UIToggleButton *editButton;
@property(nonatomic, strong) IBOutlet UIButton *backButton;
@property(nonatomic, strong) IBOutlet UIButton *cancelButton;
@property(weak, nonatomic) IBOutlet UIRoundedImageView *avatarImage;
@property(weak, nonatomic) IBOutlet UILabel *nameLabel;
@property(weak, nonatomic) IBOutlet UIToggleButton *deleteButton;
@property(weak, nonatomic) IBOutlet UIScrollView *contentView;
@property(weak, nonatomic) IBOutlet UILabel *emptyLabel;
@property BOOL isAdding;
@property (weak, nonatomic) IBOutlet UIView *waitView;

- (IBAction)onBackClick:(id)event;
- (IBAction)onCancelClick:(id)event;
- (IBAction)onEditClick:(id)event;
- (IBAction)onDeleteClick:(id)sender;
- (IBAction)onAvatarClick:(id)sender;

- (void)newContact;
- (void)newContact:(NSString *)address;
- (void)editContact:(Contact *)contact;
- (void)editContact:(Contact *)contact address:(NSString *)address;
- (void)setContact:(Contact *)contact;
@end
