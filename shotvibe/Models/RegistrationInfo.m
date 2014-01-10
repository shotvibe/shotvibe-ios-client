//
//  RegistrationInfo.m
//  shotvibe
//
//  Created by Baluta Cristian on 11/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "RegistrationInfo.h"

@implementation RegistrationInfo

+ (RegistrationInfo *)RegistrationInfoFromURL:(NSURL *)url
{
    RegistrationInfo *result = [[RegistrationInfo alloc] init];
	
    NSDictionary* queryParameters = parseQueryParameters([url query]);
	
    result.countryCode = [queryParameters objectForKey:@"country_code"];
    if(result.countryCode == nil) {
        RCLog(@"Error: No country_code query parameter found in %@", [url description]);
        return nil;
    }
	
    for (NSString *seg in [url pathComponents]) {
        if([seg isEqualToString:@"start_with_auth"]) {
            result.startWithAuth = YES;
			
            result.authToken = [queryParameters objectForKey:@"auth_token"];
            if(result.authToken == nil) {
                RCLog(@"Error: No auth_token query parameter found in %@", [url description]);
                return nil;
            }
			
            NSString *userIdStr = [queryParameters objectForKey:@"user_id"];
            if(userIdStr == nil) {
                RCLog(@"Error: No user_id query parameter found  in %@", [url description]);
                return nil;
            }
			
            result.userId = [userIdStr longLongValue];
			
            return result;
        }
        else if([seg isEqualToString:@"start_unregistered"]) {
            result.startWithAuth = NO;
			
            return result;
        }
    }
	
    return nil;
}


+ (NSString *)countryCodeFromURL:(NSURL *)url {
    NSDictionary* queryParameters = parseQueryParameters([url query]);
    NSString *countryCode = [queryParameters objectForKey:@"country_code"];
    if(countryCode == nil) {
        RCLog(@"Error: No country_code query parameter found in %@", [url description]);
        return nil;
    }
    return countryCode;
}


NSDictionary * parseQueryParameters(NSString * query)
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
	
    NSArray *components = [query componentsSeparatedByString:@"&"];
    for (NSString *component in components) {
        NSArray *subcomponents = [component componentsSeparatedByString:@"="];
        if ([subcomponents count] >= 1) {
            NSString *key = [subcomponents objectAtIndex:0];
            NSString *value;
            if([subcomponents count] >= 2) {
                value = [subcomponents objectAtIndex:1];
            }
            else {
                value = @"";
            }
			
            NSString *decodedKey = [key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *decodedValue = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
            [parameters setObject:decodedValue forKey:decodedKey];
        }
    }
	
    return parameters;
}

@end

