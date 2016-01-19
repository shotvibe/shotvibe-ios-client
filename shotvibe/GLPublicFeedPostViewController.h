//
//  GLFeedViewController.h
//  shotvibe
//
//  Created by Tsah Kashkash on 26/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVNotificationHandler.h"
#import "AlbumPhoto.h"

typedef void (^CompletionBlock3)(id);
@interface GLPublicFeedPostViewController : UITableViewController <UIScrollViewDelegate,UITextFieldDelegate,UIActionSheetDelegate>
@property(nonatomic) long long int albumId;
@property(nonatomic) long long int prevAlbumId;
@property (retain, nonatomic) NSMutableArray *posts;
@property(nonatomic) BOOL startImidiatly;
@property(nonatomic, retain) SLAlbumContents * contentsFromOutside;
@property(nonatomic) BOOL scrollToComment;
@property(nonatomic, retain) NSString * photoToScrollToCommentsId;
@property (assign, nonatomic) int indexNumber;
@property (retain, nonatomic) SLAlbumPhoto * singleAlbumPhoto;
@property (readwrite, copy) CompletionBlock3 onClose;
-(void)imageSelected:(UIImage*)image;
-(void)backPressed;
@end
