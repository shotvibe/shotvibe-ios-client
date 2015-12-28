//
//  GLPubNubManager.m
//  shotvibe
//
//  Created by Tsah Kashkash on 24/12/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLPubNubManager.h"
@interface GLPubNubManager() <PNObjectEventListener>

@property(nonatomic,retain) NSMutableDictionary * usersArray;

@end

@implementation GLPubNubManager

+ (instancetype)sharedInstance {
    static GLPubNubManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GLPubNubManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        PNConfiguration *configuration = [PNConfiguration configurationWithPublishKey:@"pub-c-fac181cd-3a33-4f76-af72-5d447077c0c6" subscribeKey:@"sub-c-97ae8d80-a9c0-11e5-8d24-0619f8945a4f"];
        //    [PNConfiguration confi]
        
        
        
        configuration.uuid = [NSString stringWithFormat:@"%lld",[[UserSettings getAuthData] getUserId]];
        //    configuration
        
        self.usersArray = [[NSMutableDictionary alloc] init];
        
        self.pubNubCLient = [PubNub clientWithConfiguration:configuration];
        
        [self.pubNubCLient addListener:self];
        //    [self.pubNubCLient subscr];
        [self.pubNubCLient subscribeToChannels:@[@"UseGlanceAppChannel"] withPresence:YES];
//
        
        [self checkWhosHereNow];
//        self.usersArray = [self getUsersArray];
        
    }
    return self;
}


-(void)reSubscribeToChannel {
    [self.pubNubCLient subscribeToChannels:@[@"UseGlanceAppChannel"] withPresence:YES];
}

-(void)checkWhosHereNow {

    [self.pubNubCLient hereNowForChannel: @"UseGlanceAppChannel" withVerbosity:PNHereNowUUID
                        completion:^(PNPresenceChannelHereNowResult *result,
                                     PNErrorStatus *status) {
                            
                            // Check whether request successfully completed or not.
                            if (!status.isError) {
                                
                                for(NSString * string in [[result data] uuids]){
//                                    NSLog(@"%@",string);
                                    [self updateUsersDictionaryWithUserAndStatus:@[string,@"join"]];
                                }
                                
                                // Handle downloaded presence information using:
                                //   result.data.uuids - list of uuids.
                                //   result.data.occupancy - total number of active subscribers.
                            }
                            // Request processing failed.
                            else {
                                
                                // Handle presence audit error. Check 'category' property to find
                                // out possible issue because of which request did fail.
                                //
                                // Request can be resent using: [status retry];
                            }
                        }];

}

//- (NSMutableDictionary*)getUsersArray {
//    
//    NSMutableDictionary * usersDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"kPubNubUsersDict"]];
//    return usersDict;
//}
//


-(BOOL)statusForId:(NSString*)id {
    
    if ([[self.usersArray objectForKey:id] isEqualToString:@"join"]) {
        return YES;
    } else {
        return NO;
    }
    
}

-(void)updateUsersDictionaryWithUserAndStatus:(NSArray*)dict {
 
//    [self.usersArray setValue:@"" forKey:@""];
//    self.usersArray setva
    [self.usersArray setValue:[dict objectAtIndex:1] forKey:[dict objectAtIndex:0]];
    if(self.tableViewToRefresh){
        [self.tableViewToRefresh reloadData];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kUpdateUsersStatus" object:nil];
    NSLog(@"");
}
//
////
////    [[NSUserDefaults standardUserDefaults] setObject:[self getUsersArray] forKey:@"kPubNubUsersDict"];
////    [[NSUserDefaults standardUserDefaults] synchronize];
////    
////    self.usersArray = [self getUsersArray];
////    self.pubNubCLient pre
//    
//}

- (void)client:(PubNub *)client didReceivePresenceEvent:(PNPresenceEventResult *)event {
    
    
//    NSLog(@"");
//    NSArray * t = [self.pubNubCLient presenceChannels];
    [self updateUsersDictionaryWithUserAndStatus:@[[[[event data] presence] uuid],[[event data] presenceEvent]]];
    
//    [[[event data] presence] uuid]
    
//    [KVNProgress showSuccessWithStatus:[NSString stringWithFormat:@"%@ - %@",[[[event data] presence] uuid],[[event data] presenceEvent]]];
    NSLog(@"");    
}

- (void)client:(PubNub *)client didReceiveStatus:(PNStatus *)status {
    
    if (status.category == PNUnexpectedDisconnectCategory) {
        
        // This event happens when radio / connectivity is lost
        NSLog(@"");
    }
    else if (status.category == PNConnectedCategory) {
        NSLog(@"");
        // Connect event. You can do stuff like publish, and know you'll get it.
        // Or just use the connected event to confirm you are subscribed for
        // UI / internal notifications, etc
    }
    else if (status.category == PNReconnectedCategory) {
        NSLog(@"");
        // Happens as part of our regular operation. This event happens when
        // radio / connectivity is lost, then regained.
    }
    else if (status.category == PNDisconnectedCategory) {
        NSLog(@"");
        // Disconnection event. After this moment any messages from unsubscribed channel
        // won't reach this callback.
    }
    else if (status.category == PNDecryptionErrorCategory) {
        NSLog(@"");
        // Handle messsage decryption error. Probably client configured to
        // encrypt messages and on live data feed it received plain text.
    }
}

- (void)client:(PubNub *)client didReceiveMessage:(PNMessageResult *)message {
    
    // Handle new message stored in message.data.message
    if (message.data.actualChannel != nil) {
        
        // Message has been received on channel group stored in
        // message.data.subscribedChannel
    }
    else {
        
        // Message has been received on channel stored in
        // message.data.subscribedChannel
    }
    
    //    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"PubNub Incoming MSG" message:<#(nullable NSString *)#> delegate:<#(nullable id)#> cancelButtonTitle:<#(nullable NSString *)#> otherButtonTitles:<#(nullable NSString *), ...#>, nil];
    
    [KVNProgress showErrorWithStatus:[message.data.message valueForKey:@"text"]];
    
    NSLog(@"Received message: %@ on channel %@ at %@", message.data.message,
          (message.data.actualChannel?: message.data.subscribedChannel), message.data.timetoken);
}

@end
