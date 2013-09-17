//
//  SVProfileViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVProfileViewController.h"
#import "SVDefines.h"
#import "MBProgressHUD.h"
#import "RCImageView.h"
#import "SVImagePickerListViewController.h"
#import "CaptureNavigationController.h"

@interface SVProfileViewController () {
	UIBarButtonItem *saveButton;
}

@property (nonatomic, strong) IBOutlet UITextField *nicknameField;
@property (nonatomic, strong) IBOutlet RCImageView *userPhoto;
@property (nonatomic) BOOL userPhotoChanged;

@property (weak, nonatomic) UIActionSheet *actionSheet;
@property (nonatomic, retain) CaptureNavigationController *cameraNavController;

- (IBAction)changeProfilePicture:(id)sender;
- (IBAction)doneButtonPressed:(id)sender;

@end


@implementation SVProfileViewController
@synthesize cameraNavController = _cameraNavController;

- (IBAction)doneButtonPressed:(id)sender
{
	[self.nicknameField resignFirstResponder];
	
    NSString *newNickname = [self.nicknameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    ShotVibeAPI *shotvibeAPI = [self.albumManager getShotVibeAPI];

    int64_t userId = shotvibeAPI.authData.userId;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		// Save nickname
        NSError *error;
        BOOL success = [shotvibeAPI setUserNickname:userId nickname:newNickname withError:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (!success) {
                // TODO Better error dialog with Retry option
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                message:[error description]
//                                                               delegate:nil
//                                                      cancelButtonTitle:@"OK"
//                                                      otherButtonTitles:nil];
//                [alert show];
            }
            else {
				self.navigationItem.rightBarButtonItem.enabled = NO;
            }
        });
    });
}

-(IBAction)changeProfilePicture:(id)sender {
	[self.nicknameField resignFirstResponder];
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Chose a new profile picture from"
															 delegate:self
													cancelButtonTitle:@"Cancel"
											   destructiveButtonTitle:nil
													otherButtonTitles:OPTIONS, nil];
	[actionSheet showFromRect:self.view.frame inView:self.view animated:YES];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *choice = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (buttonIndex == [actionSheet destructiveButtonIndex]) {
        // destroy something
        NSLog(@"Destroy");
    }
	else if ([choice isEqualToString:@"Camera"]){
		
//        _cameraNavController = [[CaptureNavigationController alloc] init];
//		_cameraNavController.cameraDelegate = self;
//		_cameraNavController.albums = nil;
//		_cameraNavController.nav = self.navigationController;// this is set last
//		_cameraNavController.oneImagePicker = YES;
//		
		SVCameraPickerController *cameraController = [[SVCameraPickerController alloc] initWithNibName:@"SVCameraOverlay" bundle:[NSBundle mainBundle]];
		cameraController.delegate = self;
		cameraController.cropDelegate = self;
		cameraController.oneImagePicker = YES;
		[self.navigationController pushViewController:cameraController animated:YES];
    }
	else if ([choice isEqualToString:@"Photo Gallery"]){
        // do something else
        [self performSegueWithIdentifier:@"PhotoGallerySegue" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"PhotoGallerySegue"]) {
		
		SVImagePickerListViewController *destination = segue.destinationViewController;
        destination.albumManager = self.albumManager;
		destination.oneImagePicker = YES;
		destination.cropDelegate = self;
    }
}

- (void) didCropImage:(UIImage*)image {
	NSLog(@"image did crop");
	self.userPhoto.image = image;
	[self.navigationController popToViewController:self animated:YES];
	self.userPhotoChanged = YES;
	
	// Save image to disk
	NSError *err;
	NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	path = [path stringByAppendingString:@"/avatar.jpg"];
	[UIImageJPEGRepresentation(image, 1.0) writeToFile:path options:NSAtomicWrite error:&err];
	
	if (err) {
		NSLog(@"some rror ocured while saving the avatar to disk");
	}
	
	
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
    ShotVibeAPI *shotvibeAPI = [self.albumManager getShotVibeAPI];
	
    int64_t userId = shotvibeAPI.authData.userId;
	
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		// Save avatar
		NSError *error2;
		BOOL success = [shotvibeAPI uploadUserAvatar:userId filePath:path uploadProgress:^(int i, int j){
			NSLog(@"upload avatar %i %i", i, j);
		}withError:&error2];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[MBProgressHUD hideHUDForView:self.view animated:YES];
			if (!success) {
				NSLog(@"err avatar upload");
			}
			else {
				self.navigationItem.rightBarButtonItem = nil;
			}
		});
	});
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    NSAssert(self.albumManager, @"SVProfileViewController started without setting albumManager property");

    ShotVibeAPI *shotvibeAPI = [self.albumManager getShotVibeAPI];

    int64_t userId = shotvibeAPI.authData.userId;

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        AlbumMember *userProfile = [shotvibeAPI getUserProfile:userId withError:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (!userProfile) {
                // TODO Better error dialog with Retry option
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                message:[error description]
//                                                               delegate:nil
//                                                      cancelButtonTitle:@"OK"
//                                                      otherButtonTitles:nil];
//                [alert show];
            }
            else {
                self.nicknameField.text = userProfile.nickname;
				[self.userPhoto loadNetworkImage:userProfile.avatarUrl];
            }
        });
    });
	
	self.title = @"Profile";
	
	saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(doneButtonPressed:)];
	NSDictionary *att = @{UITextAttributeFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeTextShadowColor:[UIColor clearColor]};
	[saveButton setTitleTextAttributes:att forState:UIControlStateNormal];
	[saveButton setTitlePositionAdjustment:UIOffsetMake(7,0) forBarMetrics:UIBarMetricsDefault];
	self.navigationItem.rightBarButtonItem = nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return 50.0;
    }
    else
    {
        return 0.0;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50.0)];
        headerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        headerView.backgroundColor = [UIColor clearColor];
        
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.bounds];
        headerLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:12];
        headerLabel.textColor = [UIColor colorWithRed:0.34 green:0.39 blue:0.42 alpha:1.0];
        headerLabel.numberOfLines = 2;
        
        if (IS_IOS6_OR_GREATER) {
            headerLabel.textAlignment = NSTextAlignmentCenter;
        }
        else
        {
            headerLabel.textAlignment = NSTextAlignmentCenter;
        }
        
        headerLabel.text = NSLocalizedString(@"You can insert your email\n address and password, to log in our web site.", @"");
        
        [headerView addSubview:headerLabel];
        
        return headerView;
    }
    else
    {
        return nil;
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


#pragma mark - UITextFieldDelegate Method

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.navigationItem.rightBarButtonItem = saveButton;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	return YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.nicknameField resignFirstResponder];
}

@end
