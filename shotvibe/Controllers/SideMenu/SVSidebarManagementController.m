//
//  SVSidebarManagementViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 3/29/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVSidebarManagementController.h"
#import "ShotVibeAppDelegate.h"
#import "SL/AlbumContents.h"
#import "SL/ShotVibeAPI.h"
#import "SVAlbumGridViewController.h"
#import "SVDefines.h"
#import "MFSideMenu.h"

@interface SVSidebarManagementController ()

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UINavigationBar *sidebarNav;

- (IBAction)settingsButtonPressed:(id)sender;
- (IBAction)sharePressed:(id)sender;
- (IBAction)natificationsPressed:(id)sender;
- (IBAction)leavePressed:(id)sender;

@end

@implementation SVSidebarManagementController


#pragma mark - Actions

- (IBAction)settingsButtonPressed:(id)sender
{
	[self.parentController.menuContainerViewController setMenuState:MFSideMenuStateClosed];
    [self.parentController performSegueWithIdentifier:@"SettingsSegue" sender:nil];
}
- (IBAction)sharePressed:(id)sender {
	//[self.parentController performSelector:@selector(<#selector#>)];
}
- (IBAction)natificationsPressed:(id)sender {
	
}
- (IBAction)leavePressed:(id)sender {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Leave album", @"")
													message:NSLocalizedString(@"Are you sure you want to leave this album?", @"")
												   delegate:nil
										  cancelButtonTitle:NSLocalizedString(@"No", @"")
										  otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
	alert.delegate = self;
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 1) {
        SLShotVibeAPI *shotvibeAPI = [[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            @try {
                [shotvibeAPI leaveAlbumWithLong:[self.albumContents getId]];
            } @catch (SLAPIException *exception) {
                // Ignore
            }

			dispatch_async(dispatch_get_main_queue(), ^{
				
			});
		});
	}
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
	
	self.tableView.sectionHeaderHeight = 35;
	self.openSectionIndex = NSNotFound;
	
    UINib *sectionHeaderNib = [UINib nibWithNibName:@"SVSidebarAlbumManagementSection" bundle:nil];
    [self.tableView registerNib:sectionHeaderNib forHeaderFooterViewReuseIdentifier:@"SVSidebarAlbumManagementSection"];
}

- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
	
    
}



#pragma mark - Properties

- (void)setAlbumContents:(SLAlbumContents *)albumContents
{
    _albumContents = albumContents;
    self.sidebarNav.topItem.title = [_albumContents getName];
	
	/*
     Check whether the section info array has been created, and if so whether the section count still matches the current section count.
	 In general, you need to keep the section info synchronized with the rows and section.
	 If you support editing in the table view, you need to appropriately update the section info during editing operations.
     */
	if ((self.sectionInfoArray == nil) || ([self.sectionInfoArray count] != [self numberOfSectionsInTableView:self.tableView])) {
		
		// Section 1
		
		NSMutableArray *arr = [NSMutableArray arrayWithObjects:@"You created the album", nil];
		
		NSMutableArray *infoArray = [[NSMutableArray alloc] init];
		
		SVSidebarAlbumSection *sectionInfo = [[SVSidebarAlbumSection alloc] init];
		sectionInfo.open = NO;
		sectionInfo.rows = arr;
		[infoArray addObject:sectionInfo];
		
		
		// Section 2
        
        NSMutableArray *arr2 = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"Name: %@", [_albumContents getName]],
                                [NSString stringWithFormat:@"Date Created: %@", @"TODO"],
								//[NSString stringWithFormat:@"Created by: %@", @""],
                                [NSString stringWithFormat:@"Total Members: TODO"],
                                [NSString stringWithFormat:@"Total Pictures: TODO"], nil];
        
		
		SVSidebarAlbumSection *sectionInfo2 = [[SVSidebarAlbumSection alloc] init];
		sectionInfo2.open = NO;
		sectionInfo2.rows = arr2;
		[infoArray addObject:sectionInfo2];
		
		
		self.sectionInfoArray = infoArray;
	}
	
    [self.tableView reloadData];
}

- (void)setParentController:(SVAlbumGridViewController *)parentController
{
	_parentController = parentController;
	[self.tableView reloadData];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sectionInfoArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	SVSidebarAlbumSection *s = (self.sectionInfoArray)[section];
	NSInteger nr = [s.rows count];
	
    return s.open ? nr : (nr > 3 ? 3 : nr);
}


- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
	
	SVSidebarAlbumManagementSection *sectionHeaderView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"SVSidebarAlbumManagementSection"];
	
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
    sectionHeaderView.section = section;
	
    return sectionHeaderView;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
	SVSidebarAlbumSection *info = (SVSidebarAlbumSection*)[self.sectionInfoArray objectAtIndex:indexPath.section];
	
	switch (indexPath.section) {
		case 0: {
			SVSidebarAlbumManagementActivityCell *cell = (SVSidebarAlbumManagementActivityCell*)[tableView dequeueReusableCellWithIdentifier:@"AlbumManagementActivityCell"];
			
			cell.memberLabel.text = info.rows[indexPath.row];
			cell.icon.image = [UIImage imageNamed:@"AlbumActivityPicsIcon.png"];
			
			return cell;
			
		}break;
		
		case 1: {
			cell = [tableView dequeueReusableCellWithIdentifier:@"AlbumManagementInfoCell"];
			
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AlbumManagementInfoCell"];
			}
			
			cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
			cell.textLabel.textColor = [UIColor whiteColor];
			cell.textLabel.text = info.rows[indexPath.row];
			
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





#pragma mark - Section header delegate

-(void)sectionHeaderView:(SVSidebarAlbumManagementSection*)sectionHeaderView sectionOpened:(NSInteger)sectionOpened {
	
	SVSidebarAlbumSection *sectionInfo = self.sectionInfoArray[sectionOpened];
	sectionInfo.open = YES;
	
	/*
     Create an array containing the index paths of the rows to insert: These correspond to the rows for each quotation in the current section.
     */
    NSInteger countOfRowsToInsert = [sectionInfo.rows count];
    NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
    for (NSInteger i = 3; i < countOfRowsToInsert; i++) {
        [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:sectionOpened]];
    }
	
	
	/*
     Create an array containing the index paths of the rows to delete:
	 These correspond to the rows for each quotation in the previously-open section, if there was one.
     */
    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
	
    NSInteger previousOpenSectionIndex = self.openSectionIndex;
    if (previousOpenSectionIndex != NSNotFound) {
		SVSidebarAlbumSection *previousOpenSection = (self.sectionInfoArray)[previousOpenSectionIndex];
        previousOpenSection.open = NO;
        [previousOpenSection.headerView toggleOpenWithUserAction:NO];
        NSInteger countOfRowsToDelete = [previousOpenSection.rows count];
        for (NSInteger i = 3; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:previousOpenSectionIndex]];
        }
    }
	
    // Style the animation so that there's a smooth flow in either direction.
    UITableViewRowAnimation insertAnimation;
    UITableViewRowAnimation deleteAnimation;
    if (previousOpenSectionIndex == NSNotFound || sectionOpened < previousOpenSectionIndex) {
        insertAnimation = UITableViewRowAnimationTop;
        deleteAnimation = UITableViewRowAnimationBottom;
    }
    else {
        insertAnimation = UITableViewRowAnimationBottom;
        deleteAnimation = UITableViewRowAnimationTop;
    }
	
    // Apply the updates.
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:insertAnimation];
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:deleteAnimation];
    [self.tableView endUpdates];
    self.openSectionIndex = sectionOpened;
	
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:sectionOpened] atScrollPosition:UITableViewScrollPositionTop animated:YES];
	
}


-(void)sectionHeaderView:(SVSidebarAlbumManagementSection*)sectionHeaderView sectionClosed:(NSInteger)sectionClosed {
	RCLog(@"close section %i", sectionClosed);
	
	/*
     Create an array of the index paths of the rows in the section that was closed, then delete those rows from the table view.
     */
	SVSidebarAlbumSection *sectionInfo = (self.sectionInfoArray)[sectionClosed];
    sectionInfo.open = NO;
	
    NSInteger countOfRowsToDelete = [sectionInfo.rows count];
	
    if (countOfRowsToDelete > 3) {
        NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
        for (NSInteger i = 3; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:sectionClosed]];
        }
        [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
    }
    self.openSectionIndex = NSNotFound;
}




@end
