//
//  GLProfilePageViewController.h
//  shotvibe
//
//  Created by Tsah Kashkash on 16/11/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "SL/AlbumMember.h"

@interface GLProfilePageViewController : UIViewController <UIAlertViewDelegate, MFMessageComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UIImageView *userProfileImage;
@property (weak, nonatomic) IBOutlet UILabel *userNickName;
@property (weak, nonatomic) IBOutlet UILabel *userScore;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;
@property (weak, nonatomic) IBOutlet UIButton *reinviteButton;
@property(nonatomic,retain) SLAlbumMember * slMemberObject;
@property (nonatomic) long long int albumId;
@property (nonatomic) long long userId;
@property (nonatomic) BOOL imAdmin;
- (IBAction)removePressed:(id)sender;
- (IBAction)reinvitePressed:(id)sender;


@property (nonatomic) BOOL fromPublicFeed;


@end
