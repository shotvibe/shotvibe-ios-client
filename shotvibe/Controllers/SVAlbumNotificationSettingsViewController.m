//
//  SVAlbumNotificationSettingsViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/17/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumNotificationSettingsViewController.h"
#import "Album.h"
#import "MagicalRecordShorthand.h"
#import "MagicalRecord+Actions.h"

@interface SVAlbumNotificationSettingsViewController ()
@property (nonatomic, strong) IBOutlet UILabel *photoUploadedToneLabel;
@property (nonatomic, strong) IBOutlet UISwitch *pushNotificationsSwitch;
@property (nonatomic, strong) IBOutlet UISwitch *notificationSwitch;

- (void)configureSettings;
- (IBAction)switchTriggered:(id)sender;
@end

@implementation SVAlbumNotificationSettingsViewController

#pragma mark - Actions

- (IBAction)switchTriggered:(id)sender
{
    UISwitch *triggeredSwitch = (UISwitch *)sender;
    
    Album *albumObject = (Album *)[[NSManagedObjectContext defaultContext] objectWithID:self.currentAlbum.objectID];
    
    if (triggeredSwitch == self.pushNotificationsSwitch) {        
        albumObject.pushNotificationsOption = [NSNumber numberWithBool:triggeredSwitch.isOn];
    }
    else if (triggeredSwitch == self.notificationSwitch)
    {
        albumObject.notificationsOption = [NSNumber numberWithBool:triggeredSwitch.isOn];
    }
    
    [[NSManagedObjectContext defaultContext] save:nil];
    
    self.currentAlbum = albumObject;
}


#pragma mark - Initializer

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


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Private Methods

- (void)configureSettings
{
    [self.pushNotificationsSwitch setOn:[self.currentAlbum.pushNotificationsOption boolValue] animated:NO];
    [self.notificationSwitch setOn:[self.currentAlbum.notificationsOption boolValue] animated:NO];
}

@end
