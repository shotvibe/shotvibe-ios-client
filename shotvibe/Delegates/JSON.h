//
//  JSON.h
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface JSONException : NSException;

- (id)initWithMessage:(NSString *)format, ...;
@end

@class JSONArray;

@interface JSONObject : NSObject
{
    NSDictionary *dict;
}

// Will throw a `JSONException` on error
- (id)initWithData:(NSData *)data;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (NSString *)getString:(NSString *)key;
- (NSNumber *)getNumber:(NSString *)key;
- (NSDate *)getDate:(NSString *)key;
- (JSONArray *)getJSONArray:(NSString *)key;
- (JSONObject *)getJSONObject:(NSString *)key;

@end


@interface JSONArray : NSObject
{
    NSArray *arr;
}

// Will throw a `JSONException` on error
- (id)initWithData:(NSData *)data;

- (id)initWithArray:(NSArray *)array;

- (NSUInteger)count;

- (JSONObject *)getJSONObject:(NSUInteger)index;

@end
