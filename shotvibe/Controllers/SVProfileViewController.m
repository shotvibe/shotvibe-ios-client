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

@interface SVProfileViewController () {
	UIBarButtonItem *saveButton;
	BOOL nameChanged;
}

@property (nonatomic, strong) IBOutlet UITextField *nicknameField;
@property (nonatomic, strong) IBOutlet RCImageView *userPhoto;

- (IBAction)changeProfilePicture:(id)sender;
- (IBAction)doneButtonPressed:(id)sender;

@end


@implementation SVProfileViewController

- (IBAction)doneButtonPressed:(id)sender
{
	[self.nicknameField resignFirstResponder];
	self.navigationItem.rightBarButtonItem = nil;
	
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
				self.navigationItem.rightBarButtonItem = saveButton;
                // TODO Better error dialog with Retry option
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                message:[error description]
//                                                               delegate:nil
//                                                      cancelButtonTitle:@"OK"
//                                                      otherButtonTitles:nil];
//                [alert show];
            }
            else {
				//self.navigationItem.rightBarButtonItem = nil;
				nameChanged = NO;
            }
        });
    });
}

- (IBAction)changeProfilePicture:(id)sender {
	[self.nicknameField resignFirstResponder];
	[self performSegueWithIdentifier:@"ProfilePicSegue" sender:self];
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"ProfilePicSegue"]) {
		
		SVProfilePicViewController *destination = segue.destinationViewController;
        destination.image = self.userPhoto.image;
		destination.delegate = self;
		destination.albumManager = self.albumManager;
    }
}


#pragma mark 

- (void) didCropImage:(UIImage*)image {
	
	NSLog(@"image did crop and save");
	self.userPhoto.image = image;
	[self.navigationController popToViewController:self animated:YES];
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
	//self.navigationItem.rightBarButtonItem = nil;
}


#pragma mark - Table view data source
/*
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
*/

#pragma mark - UITextFieldDelegate Method

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	if (nameChanged) {
		self.navigationItem.rightBarButtonItem = saveButton;
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if (!self.navigationItem.rightBarButtonItem) {
		self.navigationItem.rightBarButtonItem = saveButton;
		nameChanged = YES;
	}
	return YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.nicknameField resignFirstResponder];
	self.navigationItem.rightBarButtonItem = nil;
}

@end
