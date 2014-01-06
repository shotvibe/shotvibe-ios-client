//
//  JSON.m
//  shotvibe
//
//  Created by benny on 8/20/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "JSON.h"

@implementation JSONException

- (id)initWithMessage:(NSString *)format, ...
{
    va_list vl;
    va_start(vl, format);

    NSString *reason = [[NSString alloc] initWithFormat:format arguments:vl];

    va_end(vl);

    self = [super initWithName:NSStringFromClass([self class]) reason:reason userInfo:nil];

    return self;
}

@end

static JSONObject *toJSONObject(id value)
{
    if (![value isKindOfClass:[NSDictionary class]]) {
        @throw [[JSONException alloc] initWithMessage:@"Expected a JSON Dictionary, got: %@", [value description]];
    }

    return [[JSONObject alloc] initWithDictionary:value];
}

static JSONArray *toJSONArray(id value)
{
    if (![value isKindOfClass:[NSArray class]]) {
        @throw [[JSONException alloc] initWithMessage:@"Expected a JSON Array, got: %@", [value description]];
    }

    return [[JSONArray alloc] initWithArray:value];
}

static NSString *toString(id value)
{
    if (![value isKindOfClass:[NSString class]]) {
        @throw [[JSONException alloc] initWithMessage:@"Expected a JSON String, got: %@", [value description]];
    }

    return value;
}

static NSNumber *toNumber(id value)
{
    if (![value isKindOfClass:[NSNumber class]]) {
        @throw [[JSONException alloc] initWithMessage:@"Expected a JSON Number, got: %@", [value description]];
    }

    return value;
}


static NSDate * toDate(id value)
{
    if (![value isKindOfClass:[NSString class]]) {
        @throw [[JSONException alloc] initWithMessage:@"Expected a JSON Date, got: %@", [value description]];
    }

    static NSDateFormatter *dateFormatter1 = nil;
    if (!dateFormatter1) {
        dateFormatter1 = [[NSDateFormatter alloc] init];
        [dateFormatter1 setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter1 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    }

    NSDateFormatter *dateFormatter2 = nil;
    if (!dateFormatter2) {
        dateFormatter2 = [[NSDateFormatter alloc] init];
        [dateFormatter2 setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter2 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    }

    NSDate *date = [dateFormatter1 dateFromString:value];

    if (!date) {
        date = [dateFormatter2 dateFromString:value];
        if (!date) {
            @throw [[JSONException alloc] initWithMessage:@"Could not parse JSON Date: %@", [value description]];
        }
    }

    return date;
}


@implementation JSONObject

- (id)initWithData:(NSData *)data;
{
    self = [super init];

    if (self) {
        NSError *error;
        id result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (!result) {
            @throw [[JSONException alloc] initWithMessage:@"Malformed JSON: %@", [error localizedDescription]];
        }

        if (![result isKindOfClass:[NSDictionary class]]) {
            @throw [[JSONException alloc] initWithMessage:@"Expected a JSON Dictionary, got: %@", [result description]];
        }

        dict = result;
    }

    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];

    if (self) {
        dict = dictionary;
    }

    return self;
}

- (id)getValue:(NSString *)key
{
    id result = [dict objectForKey:key];

    if (!result) {
        @throw [[JSONException alloc] initWithMessage:@"Key \"%@\" does not exist in %@", key, dict];
    }

    return result;
}


- (BOOL) isNull:(NSString *)key
{
    return [self getValue:key] == [NSNull null];
}


- (JSONArray *)getJSONArray:(NSString *)key
{
    return toJSONArray([self getValue:key]);
}

- (JSONObject *)getJSONObject:(NSString *)key
{
    return toJSONObject([self getValue:key]);
}

- (NSString *)getString:(NSString *)key
{
    return toString([self getValue:key]);
}

- (NSNumber *)getNumber:(NSString *)key
{
    return toNumber([self getValue:key]);
}

- (NSDate *)getDate:(NSString *)key
{
    return toDate([self getValue:key]);
}

@end


@implementation JSONArray

- (id)initWithData:(NSData *)data;
{
    self = [super init];

    if (self) {
        NSError *error;
        id result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (!result) {
            @throw [[JSONException alloc] initWithMessage:@"Malformed JSON: %@", [error localizedDescription]];
        }

        if (![result isKindOfClass:[NSArray class]]) {
            @throw [[JSONException alloc] initWithMessage:@"Expected a JSON Array, got: %@", [result description]];
        }

        arr = result;
    }

    return self;
}

- (id)initWithArray:(NSArray *)array
{
    self = [super init];

    if (self) {
        arr = array;
    }

    return self;
}

- (NSUInteger)count
{
    return [arr count];
}

- (JSONObject *)getJSONObject:(NSUInteger)index
{
    return toJSONObject([arr objectAtIndex:index]);
}

@end