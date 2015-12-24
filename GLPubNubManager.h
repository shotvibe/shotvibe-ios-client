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

@interface GLPubNubManager : NSObject

+ (GLPubNubManager *)sharedInstance;
@property (nonatomic) PubNub *pubNubCLient;
//- (instancetype)initWithLisitiner:(ShotVibeAppDelegate*)listener;
@end
