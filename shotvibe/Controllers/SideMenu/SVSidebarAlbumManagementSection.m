//
//  SVSidebarAlbumManagementSection.m
//  shotvibe
//
//  Created by Baluta Cristian on 02/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVSidebarAlbumManagementSection.h"

@implementation SVSidebarAlbumManagementSection

-(void)awakeFromNib {
	
    // Set up the tap gesture recognizer.
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOpen:)];
    [self addGestureRecognizer:tapGesture];
	
	self.selected = NO;
}


-(IBAction)toggleOpen:(id)sender {
    
    [self toggleOpenWithUserAction:YES];
}


-(void)toggleOpenWithUserAction:(BOOL)userAction {
    
    // Toggle the disclosure button state.
	self.selected = !self.selected;
	
    
    // If this was a user action, send the delegate the appropriate message.
	
	if (self.selected) {
		CGAffineTransform t = CGAffineTransformIdentity;
		self.disclosureButton.transform = CGAffineTransformRotate(t, 90 * M_PI / 180);
		if ([self.delegate respondsToSelector:@selector(sectionHeaderView:sectionOpened:)]) {
			[self.delegate sectionHeaderView:self sectionOpened:self.section];
		}
	}
	else {
		CGAffineTransform t = CGAffineTransformIdentity;
		self.disclosureButton.transform = t;
		if ([self.delegate respondsToSelector:@selector(sectionHeaderView:sectionClosed:)]) {
			[self.delegate sectionHeaderView:self sectionClosed:self.section];
		}
	}
}

@end
