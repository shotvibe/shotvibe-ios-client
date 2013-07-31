//
//  SVSettingsViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//


#import "SVSettingsViewController.h"
#import "Album.h"
#import "SVAlbumNotificationSettingsViewController.h"
#import "SVDefines.h"

@interface SVSettingsViewController ()

@end

@implementation SVSettingsViewController

#pragma mark - Initializers

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mainBg.png"]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AlbumSettingsSegue"]) {
        SVAlbumNotificationSettingsViewController *destination = (SVAlbumNotificationSettingsViewController *)segue.destinationViewController;
        
        destination.currentAlbum = self.currentAlbum;
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 7) {
        // We've selected the email item
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
            [mailController setSubject:NSLocalizedString(@"ShotVibe Support Request", @"")];
            [mailController setToRecipients:@[@"Apple-support@shotvibe.com"]];
            mailController.mailComposeDelegate = self;
            
            [self presentViewController:mailController animated:YES completion:NULL];
        }
    }
}


#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}



- (IBAction)doUsage:(id)sender {
	
}

- (IBAction)doLogout:(id)sender {
	
	[[NSUserDefaults standardUserDefaults] setObject:nil forKey:kApplicationUserId];
	[[NSUserDefaults standardUserDefaults] setObject:nil forKey:kApplicationUserAuthToken];
	
	[self.navigationController popToRootViewControllerAnimated:YES];
	
	// Grab the storyboard
	//UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    
    // Grab the deal and make it our root view controller from the storyboard for this navigation controller
    //SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
    
    //[self.navigationController setViewControllers:@[rootView] animated:YES];
}

@end
