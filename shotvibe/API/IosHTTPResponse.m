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
    NSString *method_;
    NSString *url_;
    long long requestTime_;

    int statusCode_;
    NSData *body_;
    NSDictionary *headers_;
}


- (id)initWithMethod:(NSString *)method withUrl:(NSString *)url withRequestTime:(long long)requestTime withStatusCode:(int)statusCode withBody:(NSData *)body withHeaders:(NSDictionary *)headers;
{
    self = [super init];

    if (self) {
        method_ = method;
        url_ = url;
        requestTime_ = requestTime;
        statusCode_ = statusCode;
        body_ = body;
        headers_ = headers;
    }

    return self;
}


- (NSString *)getMethod
{
    return method_;
}


- (NSString *)getUrl
{
    return url_;
}


- (long long int)getRequestTime
{
    return requestTime_;
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
    // headers_ is a special dictionary from NSHTTPURLResponse.allHeaderFields that treats the key as case-insensitive
    return [headers_ objectForKey:headerName];
}


@end
