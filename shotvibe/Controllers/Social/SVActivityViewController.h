//
//  SVActivityViewController.h
//  shotvibe
//
//  Created by Baluta Cristian on 20/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVMiniAlbumList.h"

@protocol SVActivityViewControllerDelegate <NSObject>
@required
-(void)activityDidClose;
-(void)activityDidStartSharing;

@end

@interface SVActivityViewController : UIViewController <UIAppearanceContainer>

@property (nonatomic, strong) NSArray *albums;
@property (nonatomic, strong) SVMiniAlbumList *miniAlbumList;

@property (nonatomic, retain) id<SVActivityViewControllerDelegate> delegate;
@property (nonatomic, retain) UIViewController *controller;
@property (nonatomic, retain) IBOutlet UIView *activityView;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollSocialButtons;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollLocalButtons;
@property (nonatomic, retain) IBOutlet UIButton *butCancel;
@property (nonatomic, retain) NSArray *socialActivities;
@property (nonatomic, retain) NSArray *localActivities;
@property (nonatomic, retain) NSMutableArray *activityButtons;

@property (nonatomic, retain) NSString *activityDescription;
@property (nonatomic, retain) NSURL *activityUrl;
@property (nonatomic, retain) UIImage *activityImage;


- (IBAction)cancelHandler:(id)sender;
- (void)closeAndClean:(BOOL)dispatch;
- (void)openAlbumList;

@end
