//
//  SVSettingsViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//


#import "SVSettingsViewController.h"
#import "SL/AlbumSummary.h"
#import "SL/AlbumPhoto.h"
#import "SL/AlbumUser.h"
#import "SL/ShotVibeAPI.h"
#import "SVDefines.h"
#import "SVSettingsAboutViewController.h"
#import "SVProfileViewController.h"
#import "SVRegistrationViewController.h"
#import "AuthData.h"


@implementation SVSettingsViewController

#pragma mark - Initializers

#pragma mark - View Lifecycle


-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.tableView setContentInset:UIEdgeInsetsMake(60,0,0,0)];
    UIView * topHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
    UIVisualEffectView * effectView = [[UIVisualEffectView alloc] init];
    effectView.frame = CGRectMake(0, 0, self.view.frame.size.width, 80);
    effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    [topHeader addSubview:effectView];
    
    UIImageView * dmut = [[UIImageView alloc] initWithFrame:CGRectMake(60, 7, 256, 104)];
    dmut.image = [UIImage imageNamed:@"Dmut"];
    dmut.transform = CGAffineTransformScale(dmut.transform, 0.6, 0.6);
    self.tableView.scrollEnabled = NO;
    [self.navigationController.view addSubview:topHeader];
    [topHeader addSubview:dmut];
//    
//    UIImageView * bricks = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/5)];
//    bricks.image = [UIImage imageNamed:@"Bricks"];
//    
//    self.tableView.tableFooterView = bricks;
    
    UIButton * backButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 20, 40, 70)];
    [backButton setImage:[UIImage imageNamed:@"feedBackIcon"] forState:UIControlStateNormal];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(10, 15, 25, 0);
    [backButton addTarget:self action:@selector(backButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
    [topHeader addSubview:backButton];
}



-(void)backButtonPressed:(UIButton*)sender {
    
    
    if([[[self.navigationController viewControllers] lastObject] isKindOfClass:[self class]]){
        [UIView animateWithDuration:0.2 animations:^{
            [sender.superview removeFromSuperview];
        }];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.row == 0){
        SVProfileViewController * profileViewController = [[SVProfileViewController alloc] init];
        profileViewController.fromSettings = YES;
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
    
    if(indexPath.row == 1){
    
        SVWebViewController * webView = [[SVWebViewController alloc] init];
        webView.url = @"http://useglance.com";
        [self.navigationController pushViewController:webView animated:YES];
    
    }
    
    if (indexPath.row == 2) {
        // We've selected the email item
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
            [mailController setSubject:NSLocalizedString(@"Glance Support Request", @"")];
            [mailController setToRecipients:@[@"info@useglance.com"]];
            mailController.mailComposeDelegate = self;
			
			if (IS_IOS7) {
				[mailController.navigationBar setTintColor:[UIColor blackColor]];
			}
            
            [self presentViewController:mailController animated:YES completion:NULL];
        }
    }
    
    if(indexPath.row == 3){
        SVSettingsAboutViewController * settingsAbout = [[SVSettingsAboutViewController alloc] init];
        [self.navigationController pushViewController:settingsAbout animated:YES];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}


/*
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
}*/

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
// TODO:
//        [[self.albumManager getShotVibeAPI] logout];
        
		// Grab the storyboard
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
		
		// Grab the registration screen and make it our root view controller from the storyboard for this navigation controller
		SVRegistrationViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVRegistrationViewController"];
		
		[self.navigationController setViewControllers:@[rootView] animated:YES];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 
    NSArray * menuItems = @[@"Profile",@"About",@"Contact Support",@"More..."];
    
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settingsCell"];
    
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(18, 0, self.tableView.frame.size.width, [[UIScreen mainScreen] bounds].size.height/9)];
    title.text = [menuItems objectAtIndex:indexPath.row];
    title.font = [UIFont fontWithName:@"GothamRounded-Book" size:26];
    title.textColor = UIColorFromRGB(0x747575);
    [cell.contentView addSubview:title];
//    title.backgroundColor = [UIColor redColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
    
}

//- (NSInteger)hei
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //#warning Incomplete implementation, return the number of rows
    return 4;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[UIScreen mainScreen] bounds].size.height/9;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
//        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}
//-(void)viewWillDisAppear:(BOOL)animated {
//    [super viewWillDisAppear:animated];
//
//}

@end
