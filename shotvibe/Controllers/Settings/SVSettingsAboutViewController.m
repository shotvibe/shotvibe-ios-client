//
//  SVSettingsAboutViewController.m
//  shotvibe
//
//  Created by Baluta Cristian on 19/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVSettingsAboutViewController.h"

@implementation SVSettingsAboutViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.tableView setContentInset:UIEdgeInsetsMake(60,0,0,0)];
    
    
	self.title = @"About";

//    // Set the version label
//
//    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
//    NSString *name = [infoDict objectForKey:@"CFBundleDisplayName"];
//    NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
//
//    NSString *versionString;
//
//#if CONFIGURATION_Release
//    versionString = [NSString stringWithFormat:@"%@: %@", name, version];
//#else
//    NSString *build = [infoDict objectForKey:@"CFBundleVersion"];
//    versionString = [NSString stringWithFormat:@"%@: %@ (%@)", name, version, build];
//
//
//    self.gitInfoLabel.text = [NSString stringWithFormat:@"%@ [%@]%@:%@:%@", kBuildTime, kShortSHA, (kIsDirty ? @"*" : @""), kCurrentBranch, kRemoteTracking];
//    self.gitInfoLabel.hidden = NO;
//#endif
//
//    self.versionLabel.text = versionString;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.row == 0){
        SVWebViewController * webView = [[SVWebViewController alloc] init];
        webView.url = @"https://m.shotvibe.com/terms.html";
        [self.navigationController pushViewController:webView animated:YES];
    }
    if(indexPath.row == 1){
        SVWebViewController * webView = [[SVWebViewController alloc] init];
        webView.url = @"https://m.shotvibe.com/privacy.html";
        [self.navigationController pushViewController:webView animated:YES];
    }
    if(indexPath.row == 2){
        SVWebViewController * webView = [[SVWebViewController alloc] init];
        webView.url = @"http://www.useglance.com/licenses.html";
        [self.navigationController pushViewController:webView animated:YES];

    }
    
    
}


//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//	SVWebViewController *destination = (SVWebViewController *)segue.destinationViewController;
//	
//    if ([segue.identifier isEqualToString:@"SettingsAttributionsSegue"]) {
//        destination.title = @"Open Source Attributions";
//		destination.url = @"https://m.shotvibe.com/licenses.html";
//    }
//	else if ([segue.identifier isEqualToString:@"SettingsTermsSegue"]) {
//        destination.title = @"Terms Of Service";
//		destination.url = @"https://m.shotvibe.com/terms.html";
//    }
//	else if ([segue.identifier isEqualToString:@"SettingsPrivacySegue"]) {
//        destination.title = @"Privacy Policy";
//		destination.url = @"https://m.shotvibe.com/privacy.html";
//    }
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    // Set the version label
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *name = [infoDict objectForKey:@"CFBundleDisplayName"];
    NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
    
    NSString *versionString;
    
//#if CONFIGURATION_Release
//    versionString = [NSString stringWithFormat:@"%@: %@", name, version];
//#else
    NSString *build = [infoDict objectForKey:@"CFBundleVersion"];
    versionString = [NSString stringWithFormat:@"%@.%@", version, build];
    
    
//    self.gitInfoLabel.text = [NSString stringWithFormat:@"%@ [%@]%@:%@:%@", kBuildTime, kShortSHA, (kIsDirty ? @"*" : @""), kCurrentBranch, kRemoteTracking];
//    self.gitInfoLabel.hidden = NO;
//#endif
    
//    self.versionLabel.text = versionString;
    
    NSArray * menuItems = @[@"Terms of Service",@"Privacy Policy",@"Open Source Attributions",[NSString stringWithFormat:@"Version: %@ ",versionString]];
    
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settingsCell"];
    
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(18, 0, self.tableView.frame.size.width, [[UIScreen mainScreen] bounds].size.height/9)];
    title.text = [menuItems objectAtIndex:indexPath.row];
    title.font = [UIFont fontWithName:@"GothamRounded-Book" size:24];
    title.textColor = UIColorFromRGB(0x747575);
    [cell.contentView addSubview:title];
    //    title.backgroundColor = [UIColor redColor];
    if(indexPath.row < 3){
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        title.textColor = UIColorFromRGB(0xF07480);
    }
    
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

@end
