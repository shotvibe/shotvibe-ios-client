//
//  SVAPIClient.m
//  shotvibe
//
//  Created by Fredrick Gabelmann on 6/25/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "AFJSONRequestOperation.h"
#import "SVJSONAPIClient.h"
#import "SVDefines.h"

#ifdef CONFIGURATION_Debug
static NSString * const kTestAuthToken = @"Token 8d437481bdf626a9e9cd6fa2236d113eb1c9786d";
#elif CONFIGURATION_Adhoc
static NSString * const kTestAuthToken = @"Token 1d591bfa90ed6aee747a5009ccf6ef27246f6ae6";
#endif

@interface SVJSONAPIClient ()
- (NSMutableURLRequest *)GETRequestForPath:(NSString *)path parameters:(NSDictionary *)parameters;
@end

@implementation SVJSONAPIClient

#pragma mark - Initialization

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setParameterEncoding:AFJSONParameterEncoding];
        [self setDefaultHeader:@"Authorization" value:kTestAuthToken];
    }
    
    return self;
}


#pragma mark - Private Methods

- (NSMutableURLRequest *)GETRequestForPath:(NSString *)path parameters:(NSDictionary *)parameters
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:parameters];
    
    return request;
}


#pragma mark - Class Methods

+ (SVJSONAPIClient *)sharedClient
{
    static SVJSONAPIClient *sharedClient = nil;
    static dispatch_once_t apiClientToken;
    dispatch_once(&apiClientToken, ^{
        sharedClient = [[SVJSONAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIBaseURLString]];
    });
    
    return sharedClient;
}


#pragma mark - Instance Methods


- (NSMutableURLRequest *)GETRequestForAllRecordsAtPath:(NSString *)path withParameters:(NSDictionary *)parameters andHeaders:(NSDictionary *)headers
{
    __block NSMutableURLRequest *request = [self GETRequestForPath:path parameters:parameters];
    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        [request setValue:obj forHTTPHeaderField:key];
        
    }];
    
    return request;
}
@end