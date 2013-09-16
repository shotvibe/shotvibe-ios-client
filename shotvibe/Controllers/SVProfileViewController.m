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

@interface SVProfileViewController ()

@property (nonatomic, strong) IBOutlet UITextField *nicknameField;
@property (nonatomic, strong) IBOutlet RCImageView *userPhoto;

- (IBAction)doneButtonPressed:(id)sender;

@end

@implementation SVProfileViewController


- (IBAction)doneButtonPressed:(id)sender
{
    NSString *newNickname = [self.nicknameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    ShotVibeAPI *shotvibeAPI = [self.albumManager getShotVibeAPI];

    int64_t userId = shotvibeAPI.authData.userId;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        BOOL success = [shotvibeAPI setUserNickname:userId nickname:newNickname withError:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (!success) {
                // TODO Better error dialog with Retry option
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:[error description]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else {
                [self.navigationController popViewControllerAnimated:YES];
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
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:[error description]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else {
                self.nicknameField.text = userProfile.nickname;
				[self.userPhoto loadNetworkImage:userProfile.avatarUrl];
            }
        });
    });
	
	self.title = @"Profile";
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}


#pragma mark - UITextFieldDelegate Method

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	if (!saveButton) {
		saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(doneButtonPressed:)];
		NSDictionary *att = @{UITextAttributeFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeTextShadowColor:[UIColor clearColor]};
		[saveButton setTitleTextAttributes:att forState:UIControlStateNormal];
		//[saveButton setTitlePositionAdjustment:UIOffsetMake(15,0) forBarMetrics:UIBarMetricsDefault];
		self.navigationItem.rightBarButtonItem = saveButton;
	}
	return YES;
}

@end
