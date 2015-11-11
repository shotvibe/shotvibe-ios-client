//
//  SVAddFriendsViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 4/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SL/PhoneContactsManager.h"
#import "SL/AlbumManager.h"
#import "SVAlbumListViewController.h"


typedef enum SVAddFriendsState {
    SVAddFriendsMainWithoutIamge,
    SVAddFriendsMainWithImage,
    SVAddFriendsFromAddFriendButton,
    SVAddFriendsFromMove
} SVAddFriendsState;

@protocol AddFriendsDelegate <NSObject>

@optional

- (void)goToPage:(int)num;
//- (void)goToAlbumId:(long long)num;
- (void)goToPage:(int)num andTransitToFeedAt:(long long int)albumId startUploadImidiatly:(BOOL)start afterMove:(BOOL)afterMove;

@end

@interface SVAddFriendsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, SLPhoneContactsManager_Listener>
- (IBAction)nvBackTapped:(id)sender;
- (IBAction)contactsButtonTapped:(id)sender;
- (IBAction)groupsButtonTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *friendsSourceButton;
@property (weak, nonatomic) IBOutlet UIButton *proceedButton;
- (IBAction)proceedTapped:(id)sender;

- (IBAction)friendsButtonTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *backBut;
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (nonatomic) SVAddFriendsState state;
@property (weak, nonatomic) IBOutlet UIView *contactSourceButtonsView;
@property (nonatomic, assign) id<AddFriendsDelegate> delegate;
@property (nonatomic, assign) int64_t albumId;
@property (assign, nonatomic) NSInteger indexNumber;
@property (nonatomic) BOOL fromCameraMainScreen;
@property (nonatomic) BOOL showGroupsSegment;
@property(nonatomic) BOOL friendsFromMainWithPicture;
@property(nonatomic) BOOL fromMove;

@property (weak, nonatomic) IBOutlet UIButton *contactsSourceButton;
@property (assign, nonatomic) NSString * photoToMoveId;
@property (weak, nonatomic) IBOutlet UIButton *groupsSourceButton;

@end
