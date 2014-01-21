//
//  IosHTTPResponse.m
//  shotvibe
//
//  Created by benny on 1/20/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "IosHTTPResponse.h"

#import "SL/JSONObject.h"
#import "SL/JSONArray.h"

@implementation IosHTTPResponse
{
    int statusCode_;
    NSData *body_;
    NSDictionary *headers_;
}


- (id)initWithStatusCode:(int)statusCode withBody:(NSData *)body withHeaders:(NSDictionary *)headers
{
    self = [super init];

    if (self) {
        statusCode_ = statusCode;
        body_ = body;
        headers_ = headers;
    }

    return self;
}


- (int)getStatusCode
{
    return statusCode_;
}


- (SLJSONObject *)bodyAsJSONObject
{
    return [SLJSONObject Parse:body_];
}


- (SLJSONArray *)bodyAsJSONArray
{
    return [SLJSONArray Parse:body_];
}


- (NSString *)bodyAsUTF8String
{
    return [[NSString alloc] initWithData:body_ encoding:NSUTF8StringEncoding];
}


- (NSString *)getHeaderValueWithNSString:(NSString *)headerName
{
    return [headers_ objectForKey:headerName];
}


@end
