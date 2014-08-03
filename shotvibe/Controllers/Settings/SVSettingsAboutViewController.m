//
//  SVSettingsAboutViewController.m
//  shotvibe
//
//  Created by Baluta Cristian on 19/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>

#import "SVSettingsAboutViewController.h"

@implementation SVSettingsAboutViewController


- (void)viewDidLoad
{
    [[Crashlytics sharedInstance] crash];

    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.title = @"About";

    // Set the version label

    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *name = [infoDict objectForKey:@"CFBundleDisplayName"];
    NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];

    NSString *versionString;

#if CONFIGURATION_Release
    versionString = [NSString stringWithFormat:@"%@: %@", name, version];
#else
    NSString *build = [infoDict objectForKey:@"CFBundleVersion"];
    versionString = [NSString stringWithFormat:@"%@: %@ (%@)", name, version, build];


    self.gitInfoLabel.text = [NSString stringWithFormat:@"%@ [%@]%@:%@:%@", kBuildTime, kShortSHA, (kIsDirty ? @"*" : @""), kCurrentBranch, kRemoteTracking];
    self.gitInfoLabel.hidden = NO;
#endif

    self.versionLabel.text = versionString;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	SVWebViewController *destination = (SVWebViewController *)segue.destinationViewController;
	
    if ([segue.identifier isEqualToString:@"SettingsAttributionsSegue"]) {
        destination.title = @"Open Source Attributions";
		destination.url = @"https://m.shotvibe.com/licenses.html";
    }
	else if ([segue.identifier isEqualToString:@"SettingsTermsSegue"]) {
        destination.title = @"Terms Of Service";
		destination.url = @"https://m.shotvibe.com/terms.html";
    }
	else if ([segue.identifier isEqualToString:@"SettingsPrivacySegue"]) {
        destination.title = @"Privacy Policy";
		destination.url = @"https://m.shotvibe.com/privacy.html";
    }
}

@end
