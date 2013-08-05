//
//  SVSidebarManagementViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 3/29/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "Album.h"
#import "SVAlbumGridViewController.h"
#import "SVDefines.h"
#import "SVSidebarAlbumManagementViewController.h"
#import "MagicalRecordShorthand.h"
#import "MagicalRecord+Actions.h"

@interface SVSidebarAlbumManagementViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UINavigationBar *sidebarNav;

- (IBAction)settingsButtonPressed:(id)sender;

@end

@implementation SVSidebarAlbumManagementViewController


#pragma mark - Actions
- (IBAction)homePressed:(id)sender
{
    [self.parentController.navigationController popViewControllerAnimated:YES];
}

- (IBAction)settingsButtonPressed:(id)sender
{
    [self.parentController performSegueWithIdentifier:@"SettingsSegue" sender:nil];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    {
        UIImage *baseImage = [UIImage imageNamed:@"sidebarMenuNavbar.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 0, 20);
        UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets];
        
        [self.sidebarNav setBackgroundImage:resizableImage forBarMetrics:UIBarMetricsDefault];
    }
    
	self.sidebarNav.topItem.title = self.parentController.selectedAlbum.name;
	
	self.tableView.sectionHeaderHeight = 35;
	
    [self fetchedResultsController];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
	
    SVSidebarAlbumManagementSection *sectionHeaderView = [[SVSidebarAlbumManagementSection alloc] initWithReuseIdentifier:@"SVSidebarAlbumManagementSection"];
	//[self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"SVSidebarAlbumManagementSection"];
	
	switch (section) {
		case 0: {
			sectionHeaderView.icon.image = [UIImage imageNamed:@"AlbumActivityIcon.png"];
			sectionHeaderView.titleLabel.text = @"Album Activity";
		}break;
		case 1: {
			sectionHeaderView.icon.image = [UIImage imageNamed:@"AlbumInfoIcon.png"];
			sectionHeaderView.titleLabel.text = @"Album Info";
		}break;
	}
    sectionHeaderView.delegate = self;
    
    return sectionHeaderView;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 0: {
			
			return 11;
		}break;
		case 1: {
			
			return 5;
		}break;
	}
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
	
	switch (indexPath.section) {
		case 0: {
			SVSidebarAlbumManagementActivityCell *cell = (SVSidebarAlbumManagementActivityCell*)[tableView dequeueReusableCellWithIdentifier:@"AlbumManagementActivityCell"];
			
			NSArray *arr = [NSArray arrayWithObjects:@"You created the album",
			@"XXXX added pics",
			@"XXX added video",
			@"XXX deleted pics",
			@"XXXX deleted video",
			@"XXXX edited photo",
			@"XXXX invited YYYY",
			@"XXX joined the album",
			@"XXXX left album",
			@"XXXX invited YYYYY",
			@"XXXX joined the album", nil];
			
			cell.memberLabel.text = arr[indexPath.row];
			cell.icon.image = [UIImage imageNamed:@"AlbumActivityPicsIcon.png"];
			
			return cell;
			
		}break;
		
		case 1: {
			cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumManagementInfoCell"];
			
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AlbumManagementInfoCell"];
			}
			
			NSArray *arr = [NSArray arrayWithObjects:[NSString stringWithFormat:@"Name: %@", self.parentController.selectedAlbum.name],
							[NSString stringWithFormat:@"Date Created: %@", self.parentController.selectedAlbum.date_created],
							@"Created by: Baluta Cristian",
							@"Total Members ",
							@"Total Pictures ", nil];
			
			cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
			cell.textLabel.textColor = [UIColor whiteColor];
			cell.textLabel.text = arr[indexPath.row];
			
			return cell;
			
		}break;
	}
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
