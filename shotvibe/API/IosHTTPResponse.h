//
//  IosHTTPResponse.h
//  shotvibe
//
//  Created by benny on 1/20/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SL/HTTPResponse.h"

@interface IosHTTPResponse : SLHTTPResponse

- (id)initWithStatusCode:(int)statusCode withBody:(NSData *)body withHeaders:(NSDictionary *)headers;

@end
