//
//  IosHTTPLib.m
//  shotvibe
//
//  Created by benny on 1/20/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "IosHTTPLib.h"

#import "java/util/Set.h"
#import "java/util/Map.h"
#import "java/lang/IllegalStateException.h"

#import "SL/APIException.h"
#import "SL/JSONObject.h"
#import "SL/JSONArray.h"

#import "IosHTTPResponse.h"

static SLHTTPResponse * sendRequest(NSString *method, NSString *url, id<JavaUtilMap> requestHeaders, NSData *body)
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:method];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];

    if (requestHeaders) {
        for (id<JavaUtilMap_Entry> entry in [requestHeaders entrySet]) {
            [request setValue:[entry getValue] forHTTPHeaderField:[entry getKey]];
        }
    }

    if (body) {
        [request setHTTPBody:body];
    }

    NSError *httpError;
    NSHTTPURLResponse *httpResponse;
    NSData *httpResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&httpResponse error:&httpError];

    if (httpResponseData == nil) {
        // TODO Add more info to exception
        @throw [[SLAPIException alloc] initWithNSString:httpError.description];
    }

    int statusCode = [httpResponse statusCode];
    NSDictionary *headers = [httpResponse allHeaderFields];
    SLHTTPResponse *response = [[IosHTTPResponse alloc] initWithStatusCode:statusCode withBody:httpResponseData withHeaders:headers];

    return response;
}


@implementation IosHTTPLib


- (SLHTTPResponse *)sendRequestWithNSString:(NSString *)httpMethod
                               withNSString:(NSString *)url
                            withJavaUtilMap:(id<JavaUtilMap>)requestHeaders
                               withNSString:(NSString *)body
{
    NSData *data = nil;
    if (body) {
        data = [body dataUsingEncoding:NSUTF8StringEncoding];
    }
    return sendRequest(httpMethod, url, requestHeaders, data);
}


- (SLHTTPResponse *)sendRequestWithNSString:(NSString *)httpMethod
                               withNSString:(NSString *)url
                            withJavaUtilMap:(id<JavaUtilMap>)requestHeaders
                           withSLJSONObject:(SLJSONObject *)body
{
    NSError *jsonError;
    NSData *data = [NSJSONSerialization dataWithJSONObject:body->dict_ options:kNilOptions error:&jsonError];
    if (!data) {
        // This should never happen, since SLJSONObject is built using a safe API that enforces correct JSON
        @throw [[JavaLangIllegalStateException alloc] initWithNSString:[NSString stringWithFormat:@"Impossible happened: %@", jsonError.description]];
    }
    return sendRequest(httpMethod, url, requestHeaders, data);
}


- (SLHTTPResponse *)sendRequestWithNSString:(NSString *)httpMethod
                               withNSString:(NSString *)url
                            withJavaUtilMap:(id<JavaUtilMap>)requestHeaders
                            withSLJSONArray:(SLJSONArray *)body
{
    NSError *jsonError;
    NSData *data = [NSJSONSerialization dataWithJSONObject:body->array_ options:kNilOptions error:&jsonError];
    if (!data) {
        // This should never happen, since SLJSONObject is built using a safe API that enforces correct JSON
        @throw [[JavaLangIllegalStateException alloc] initWithNSString:[NSString stringWithFormat:@"Impossible happened: %@", jsonError.description]];
    }
    return sendRequest(httpMethod, url, requestHeaders, data);
}


@end