//
//  SVSidebarAlbumManagementSection.h
//  shotvibe
//
//  Created by Baluta Cristian on 02/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SVSidebarAlbumManagementSectionDelegate;


@interface SVSidebarAlbumManagementSection : UITableViewHeaderFooterView {
	
}

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *disclosureButton;
@property (nonatomic, weak) IBOutlet UIImageView *icon;
@property (nonatomic, weak) IBOutlet id <SVSidebarAlbumManagementSectionDelegate> delegate;

@property (nonatomic) NSInteger section;
@property (nonatomic) BOOL selected;

-(void)toggleOpenWithUserAction:(BOOL)userAction;

@end


/*
 Protocol to be adopted by the section header's delegate; the section header tells its delegate when the section should be opened and closed.
 */
@protocol SVSidebarAlbumManagementSectionDelegate <NSObject>

@optional
-(void)sectionHeaderView:(SVSidebarAlbumManagementSection*)sectionHeaderView sectionOpened:(NSInteger)section;
-(void)sectionHeaderView:(SVSidebarAlbumManagementSection*)sectionHeaderView sectionClosed:(NSInteger)section;

@end