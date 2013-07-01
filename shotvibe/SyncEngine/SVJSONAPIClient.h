//
//  SVAPIClient.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 6/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AFHTTPClient.h"

@interface SVJSONAPIClient : AFHTTPClient

#pragma mark - Class Methods

+ (SVJSONAPIClient *)sharedClient;


#pragma mark - Instance Methods

- (NSMutableURLRequest *)GETRequestForAllRecordsAtPath:(NSString *)path withParameters:(NSDictionary *)parameters andHeaders:(NSDictionary *)headers;
@end
