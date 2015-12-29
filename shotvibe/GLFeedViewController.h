//
//  GLFeedViewController.h
//  shotvibe
//
//  Created by Tsah Kashkash on 26/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVNotificationHandler.h"
#import "GLPubNubManager.h"

typedef enum FeedScrollDirection {
    FeedScrollDirectionUp,
    FeedScrollDirectionDown
} FeedScrollDirection;

//#import ""
//#import ""
@interface GLFeedViewController : UIViewController <NotificationManagerDelegate,UIScrollViewDelegate,UITextFieldDelegate,UIActionSheetDelegate,GLPubNubDelegate>

@property(nonatomic) long long int albumId;
@property(nonatomic) long long int prevAlbumId;
@property (retain, nonatomic) NSMutableArray *posts;
@property(nonatomic) BOOL startImidiatly;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) FeedScrollDirection feedScrollDirection;
@property(nonatomic, retain) SLAlbumContents * contentsFromOutside;
@property(nonatomic) BOOL scrollToComment;
@property(nonatomic, retain) NSString * photoToScrollToCommentsId;
@property (assign, nonatomic) int indexNumber;
@property (nonatomic, retain) UITableView * tableView;
@property(nonatomic) BOOL startImidiatlyVideoUpload;

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) NSInteger totalPages;
@property (nonatomic, assign) NSInteger totalItems;


@property (retain, nonatomic) NSMutableArray *feedItems;

-(void)imageSelected:(UIImage*)image;
-(void)backPressed;
-(void)videoSelected;

@end
