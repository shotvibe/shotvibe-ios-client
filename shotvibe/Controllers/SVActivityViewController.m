//
//  SVActivityViewController.m
//  shotvibe
//
//  Created by Baluta Cristian on 20/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVActivityViewController.h"
#import "SVActivityButton.h"
#import "SVLinkActivity.h"
#import "SVCopyActivity.h"
#import "SVMoveActivity.h"
#import "SVFacebookActivity.h"
#import "SVMailActivity.h"
#import "SVTumblrActivity.h"
#import "SVTwitterActivity.h"
#import "SVActivity.h"
#import "SVProfilePicActivity.h"

@implementation SVActivityViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
	if (self) {
        // Custom initialization
		self.activityButtons = [[NSMutableArray alloc] init];
		
		self.socialActivities = @[
		[[SVMailActivity alloc] init],
//		[[SVTwitterActivity alloc] init],
		[[SVFacebookActivity alloc] init]];
		
		self.localActivities = @[
		[[SVCopyActivity alloc] init],
//		[[SVMoveActivity alloc] init],
		[[SVLinkActivity alloc] init],
		[[SVProfilePicActivity alloc] init]];
    }
    return self;
}

- (void)viewDidLoad {
	
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	int i = 0, j = 0;
	for (UIActivity *a in self.socialActivities) {
		SVActivityButton *but = [[SVActivityButton alloc] initWithFrame:CGRectMake(12+(61+15)*i, 0, 61, 61)];
		but.clipsToBounds = NO;
		but.tag = j;
		but.label.text = a.activityTitle;
		[but setImage:a.activityImage forState:UIControlStateNormal];
		[but addTarget:self action:@selector(activityHandler:) forControlEvents:UIControlEventTouchUpInside];
		[self.scrollSocialButtons addSubview:but];
		[self.activityButtons addObject:but];
		i++;
		j++;
	}
	self.scrollSocialButtons.contentSize = CGSizeMake(12+(61+15)*i, 61+20);
	i = 0;
	for (UIActivity *a in self.localActivities) {
		SVActivityButton *but = [[SVActivityButton alloc] initWithFrame:CGRectMake(12+(61+15)*i, 0, 61, 61)];
		but.clipsToBounds = NO;
		but.tag = j;
		but.label.text = a.activityTitle;
		[but setImage:a.activityImage forState:UIControlStateNormal];
		[but addTarget:self action:@selector(activityHandler:) forControlEvents:UIControlEventTouchUpInside];
		[self.scrollLocalButtons addSubview:but];
		[self.activityButtons addObject:but];
		i++;
		j++;
	}
	self.scrollLocalButtons.contentSize = CGSizeMake(12+(61+15)*i, 61+20);
	
	// Make over effect on cancel button
	
	UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake (0, 0, self.butCancel.frame.size.width, self.butCancel.frame.size.height)];
    colorView.backgroundColor = [UIColor darkGrayColor];
    UIGraphicsBeginImageContext(colorView.bounds.size);
    [colorView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *colorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.butCancel setBackgroundImage:colorImage forState:UIControlStateHighlighted];
    colorView = nil;
    colorImage = nil;
}


- (void)activityHandler:(id)sender {
	
	NSUInteger index = ((UIButton*)sender).tag;
	SVActivity *activity;
	
	if (index < self.socialActivities.count) {
		activity = [self.socialActivities objectAtIndex:index];
	}
	else {
		activity = [self.localActivities objectAtIndex:index-self.socialActivities.count];
	}
	
	activity.controller = self.controller;
	activity.delegate = self;
	activity.sharingText = self.activityDescription;
	activity.sharingUrl = self.activityUrl;
	activity.sharingImage = self.activityImage;
	[activity performActivity];
	
	if ([activity canClose] && [self.delegate respondsToSelector:@selector(activityDidStartSharing)]) {
		[self.delegate activityDidStartSharing];
	}
}

- (IBAction)cancelHandler:(id)sender {
	
	if (self.miniAlbumList != nil) {
		
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
			
			CGRect rect = self.miniAlbumList.frame;
			
			self.scrollLocalButtons.alpha = 1;
			self.scrollLocalButtons.frame = rect;
			
			rect.origin.x = 320;
			self.miniAlbumList.frame = rect;
			
		}completion:^(BOOL finished) {
			[self.miniAlbumList removeFromSuperview];
			self.miniAlbumList = nil;
		}];
	}
	else {
		[self closeAndClean:YES];
	}
}

- (void)closeAndClean:(BOOL)dispatch {
	RCLog(@"closeAndClean %i", dispatch);
	__block CGRect rect = self.activityView.frame;
	
	[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
		rect.origin.y = self.view.frame.size.height;
		self.view.alpha = 0;
		self.activityView.frame = rect;
	}
					 completion:^(BOOL finished) {
		if (dispatch) {
			[self.view removeFromSuperview];
			if ([self.delegate respondsToSelector:@selector(activityDidClose)]) {
				[self.delegate activityDidClose];
			}
		}
		
	}];
}

- (void)openAlbumList {
	RCLog(@"open album list");
	// Create albums list
	self.miniAlbumList = [[SVMiniAlbumList alloc] initWithFrame:CGRectMake(320, self.scrollLocalButtons.frame.origin.y, 320, self.scrollLocalButtons.frame.size.height)];
	self.miniAlbumList.albums = self.albums;
	[self.activityView addSubview:self.miniAlbumList];
	
	// Hide buttons and show albums
	[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
		
		CGRect rect = self.scrollLocalButtons.frame;
		
		self.miniAlbumList.frame = rect;
		
		rect.origin.x = -320;
		self.scrollLocalButtons.alpha = 0;
		self.scrollLocalButtons.frame = rect;
		
	}completion:^(BOOL finished) {
		
	}];
}


@end
