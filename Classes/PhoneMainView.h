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

#import <MediaPlayer/MediaPlayer.h>
#import <MessageUI/MessageUI.h>

/* These imports are here so that we can import PhoneMainView.h without bothering to import all the rest of the view headers */
#import "StatusBarView.h"
#import "TabBarView.h"

#import "AboutView.h"
#import "AcknowledgementsView.h"
#import "AssistantLinkView.h"
#import "AssistantView.h"
#import "CallIncomingView.h"
#import "CallOutgoingView.h"
#import "CallSideMenuView.h"
#import "CallView.h"
#import "ContactDetailsView.h"
#import "ContactsListView.h"
#import "CountryListView.h"
#import "DTActionSheet.h"
#import "DialerView.h"
#import "FirstLoginView.h"
#import "HistoryDetailsView.h"
#import "HistoryListView.h"
#import "ImageView.h"
#import "RecordingsListView.h"
#import "SettingsView.h"
#import "SideMenuView.h"
#import "UIConfirmationDialog.h"
#import "Utils.h"
#import "LaunchScreen.h"

#import <AVFoundation/AVFoundation.h>
#import "AWSCognitoIdentityProvider.h"
#import <AWSCore/AWSCore.h>
#import <AWSCognito/AWSCognito.h>
#import <AWSS3/AWSS3.h>
#import <AWSCognito/AWSCognitoService.h>
#import "AWSCognitoAuth.h"

#define DYNAMIC_CAST(x, cls)                                                                                           \
	({                                                                                                                 \
		cls *inst_ = (cls *)(x);                                                                                       \
		[inst_ isKindOfClass:[cls class]] ? inst_ : nil;                                                               \
	})

#define VIEW(x)                                                                                                        \
	DYNAMIC_CAST([PhoneMainView.instance.mainViewController getCachedController:x.compositeViewDescription.name], x)

#define LINPHONE_DUMMY_SUBJECT "dummy subject"

@class PhoneMainView;

@interface RootViewManager : NSObject

@property(nonatomic, strong) PhoneMainView *portraitViewController;
@property(nonatomic, strong) PhoneMainView *rotatingViewController;
@property(nonatomic, strong) NSMutableArray *viewDescriptionStack;

+(RootViewManager*)instance;
+ (void)setupWithPortrait:(PhoneMainView*)portrait;
- (PhoneMainView*)currentView;

@end

@interface PhoneMainView : UIViewController<IncomingCallViewDelegate, AVAudioPlayerDelegate, AWSCognitoIdentityInteractiveAuthenticationDelegate, AWSCognitoAuthDelegate> {
    @private
    NSMutableArray *inhibitedEvents;
}

@property(nonatomic, strong) IBOutlet UIView *statusBarBG;
@property(nonatomic, strong) IBOutlet UICompositeView *mainViewController;

@property(nonatomic, strong) NSString *currentName;
@property(nonatomic, strong) NSString *previousView;
@property(nonatomic, strong) NSString *name;
@property(weak, readonly) UICompositeViewDescription *currentView;
@property LinphoneChatRoom* currentRoom;
@property(readonly, strong) MPVolumeView *volumeView;
@property (weak, nonatomic) UIView *waitView;

@property (nonatomic, strong) NSString *accountType;
@property (nonatomic, strong) AppSyncMgr *appSyncMgr;

@property (nonatomic,strong) AWSCognitoIdentityUserGetDetailsResponse * response;
@property (nonatomic, strong) AWSCognitoIdentityUser * user;
@property (nonatomic, strong) AWSCognitoIdentityUserPool * pool;
@property (nonatomic, strong) AWSCognitoAuth * auth;
@property (nonatomic, strong) AWSCognitoAuthUserSession * session;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) UIDocumentInteractionController *controller;
@property (nonatomic, strong) NSURL *glacierData;
@property (nonatomic, strong) NSString *bucketPrefix;
@property (nonatomic, strong) NSString *bucketOrg;
@property (nonatomic, strong) NSString *s3BucketName;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) UIView *vSpinner;
- (void)teardownCognito;
- (void)setupAccount;
- (void) handleImportContacts;
- (void) displayAssistantView:(BOOL)needsNewAccount;
- (void) handleLoginSelection:(BOOL)cognitoLogin; 

- (void)changeCurrentView:(UICompositeViewDescription *)view;
- (UIViewController*)popCurrentView;
- (UIViewController *)popToView:(UICompositeViewDescription *)currentView;
- (void) setPreviousViewName:(NSString*)previous;
- (NSString*) getPreviousViewName;
+ (NSString*) getPreviousViewName;
- (UICompositeViewDescription *)firstView;
- (void)hideStatusBar:(BOOL)hide;
- (void)hideTabBar:(BOOL)hide;
- (void)fullScreen:(BOOL)enabled;
- (void)updateStatusBar:(UICompositeViewDescription*)to_view;
- (void)startUp;
- (void)displayIncomingCall:(LinphoneCall*) call;
- (void)setVolumeHidden:(BOOL)hidden;

- (void)addInhibitedEvent:(id)event;
- (BOOL)removeInhibitedEvent:(id)event;

- (void)updateApplicationBadgeNumber;
+ (PhoneMainView*) instance;

- (BOOL)isIphoneXDevice;
+ (int)iphoneStatusBarHeight;

@end
