//
//  SVSettingsViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//


#import "SVSettingsViewController.h"
#import "Album.h"
#import "AlbumPhoto.h"
#import "OldMember.h"
#import "SVAlbumNotificationSettingsViewController.h"
#import "SVDefines.h"
#import "SVRegistrationViewController.h"
#import "SVEntityStore.h"

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
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *url = [NSURL URLWithString:@"SVImages/" relativeToURL:applicationDocumentsDirectory];
	
	NSArray *contents = [fileManager contentsOfDirectoryAtPath:[url path] error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
	
    NSString *file;
    unsigned long long int folderSize = 0;
	int fnr = 0;
	
    while (file = [contentsEnumurator nextObject]) {
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[[url path] stringByAppendingPathComponent:file] error:nil];
        folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
		fnr++;
    }
	
    //This line will give you formatted size from bytes ....
    NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleFile];
    
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Usage", @"")
													message:[NSString stringWithFormat:@"You are using %@ and %i photos", folderSizeStr, fnr/2]
												   delegate:nil
										  cancelButtonTitle:NSLocalizedString(@"Ok", @"")
										  otherButtonTitles:nil];
	[alert show];
}

- (IBAction)doLogout:(id)sender {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Log Out", @"")
													message:NSLocalizedString(@"Logging out will delete all the data from the app, are you sure you want to continue?", @"")
												   delegate:self
										  cancelButtonTitle:NSLocalizedString(@"No", @"")
										  otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 1) {
		
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:kApplicationUserId];
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:kApplicationUserAuthToken];
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserAlbumsLastRequestedDate];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
		[OldMember MR_truncateAllInContext:localContext];
		[Album MR_truncateAllInContext:localContext];
		[AlbumPhoto MR_truncateAllInContext:localContext];
		[localContext MR_saveToPersistentStoreAndWait];
		
		[[SVEntityStore sharedStore] wipe];
		
		// Grab the storyboard
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
		
		// Grab the deal and make it our root view controller from the storyboard for this navigation controller
		SVRegistrationViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVRegistrationViewController"];
		
		[self.navigationController setViewControllers:@[rootView] animated:YES];
	}
}


@end
