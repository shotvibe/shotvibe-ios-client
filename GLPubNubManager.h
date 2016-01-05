//
//  GLPubNubManager.h
//  shotvibe
//
//  Created by Tsah Kashkash on 24/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShotVibeAppDelegate.h"
#import <PubNub/PubNub.h>
#import "UserSettings.h"


@protocol GLPubNubDelegate <NSObject>

@optional
- (void)pubNubRefreshTableView;
@end



@interface GLPubNubManager : NSObject
@property (nonatomic, assign) id<GLPubNubDelegate> delegate;
+ (GLPubNubManager *)sharedInstance;
@property (nonatomic) PubNub *pubNubCLient;
@property (nonatomic,weak) UITableView * tableViewToRefresh;
-(BOOL)statusForId:(NSString*)id;
-(void)reSubscribeToChannel;
-(NSNumber*)disconnectTimeForId:(NSString*)id;
//- (instancetype)initWithLisitiner:(ShotVibeAppDelegate*)listener;
@end
