//
//  SVGeneralNotificationSettingsViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/17/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVGeneralNotificationSettingsViewController.h"
#import "SVDefines.h"

@interface SVGeneralNotificationSettingsViewController ()
@property (nonatomic, strong) IBOutlet UILabel *photoUploadedToneLabel;
@property (nonatomic, strong) IBOutlet UISwitch *notificationSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *vibrationSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *soundSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *previewSwitch;

- (void)configureSettings;
- (void)resetDefaultSettings;
- (IBAction)switchTriggered:(id)sender;
@end

@implementation SVGeneralNotificationSettingsViewController

#pragma mark - Actions

- (IBAction)switchTriggered:(id)sender
{
    UISwitch *triggeredSwitch = (UISwitch *)sender;
    
    if (triggeredSwitch == self.notificationSwitch) {
        [[NSUserDefaults standardUserDefaults] setBool:triggeredSwitch.isOn forKey:@"GENERAL_NOTIFICATION"];
    }
    else if (triggeredSwitch == self.vibrationSwitch)
    {
        [[NSUserDefaults standardUserDefaults] setBool:triggeredSwitch.isOn forKey:@"GENERAL_VIBRATION"];
    }
    else if (triggeredSwitch == self.soundSwitch)
    {
        [[NSUserDefaults standardUserDefaults] setBool:triggeredSwitch.isOn forKey:@"GENERAL_SOUND"];
    }
    else if (triggeredSwitch == self.previewSwitch)
    {
        [[NSUserDefaults standardUserDefaults] setBool:triggeredSwitch.isOn forKey:@"GENERAL_PREVIEW_MODE"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}


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

    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mainBg.png"]];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configureSettings];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 40.0;
    }
    else
    {
        return 0.0;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40.0)];
        headerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        headerView.backgroundColor = [UIColor clearColor];
        
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 10, 40)];
        headerLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17];
        headerLabel.textColor = [UIColor colorWithRed:0.25 green:0.29 blue:0.31 alpha:1.0];
        headerLabel.numberOfLines = 1;
        
        headerLabel.text = NSLocalizedString(@"Album Notification", @"");
        
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 4) {
        [self resetDefaultSettings];
    }
}


#pragma mark - Private Methods

- (void)configureSettings
{
    [self.notificationSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"GENERAL_NOTIFICATION"] animated:NO];
    [self.vibrationSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"GENERAL_VIBRATION"] animated:NO];
    [self.soundSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"GENERAL_SOUND"] animated:NO];
    [self.previewSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"GENERAL_PREVIEW_MODE"] animated:NO];

}


- (void)resetDefaultSettings
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GENERAL_NOTIFICATION"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GENERAL_VIBRATION"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GENERAL_SOUND"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GENERAL_PREVIEW_MODE"];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HAS_SET_NOTIFICATION_DEFAULTS"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.notificationSwitch setOn:YES animated:YES];
    [self.vibrationSwitch setOn:YES animated:YES];
    [self.soundSwitch setOn:YES animated:YES];
    [self.previewSwitch setOn:YES animated:YES];
}


@end
