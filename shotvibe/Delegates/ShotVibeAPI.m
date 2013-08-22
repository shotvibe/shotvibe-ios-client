//
//  ShotVibeAPI.m
//  shotvibe
//
//  Created by benny on 8/10/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "ShotVibeAPI.h"
#import "JSON.h"
#import "AlbumSummary.h"
#import "AlbumPhoto.h"
#import "AlbumServerPhoto.h"
#import "AlbumMember.h"

@interface Response : NSObject

@property (nonatomic, copy) NSData *body;
@property (nonatomic) NSInteger responseCode;
@property (nonatomic, copy) NSDictionary *headers;

- (bool)isError;

@end


@implementation Response

- (bool) isError
{
    return self.responseCode >= 400;
}

@end


@implementation ShotVibeAPI
{
    NSString *authConfirmationKey;
}

static NSString * const BASE_URL = @"https://api.shotvibe.com";

static NSString * const SHOTVIBE_API_ERROR_DOMAIN = @"com.shotvibe.shotvibe.ShotVibeAPI.ErrorDomain";

- (id)init
{
    return [self initWithAuthData:nil];
}


- (id)initWithAuthData:(AuthData *)authData
{
    self = [super init];

    _authData = authData;
    authConfirmationKey = nil;

    return self;
}


- (BOOL)registerDevicePushWithDeviceToken:(NSString *)deviceToken error:(NSError**)error;
{
    NSString* app;
#if CONFIGURATION_Debug
    app = @"dev";
#elif CONFIGURATION_AdHoc
    app = @"adhoc";
#elif CONFIGURATION_Release
    app = @"prod";
#else
#error "UNKNOWN CONFIGURATION"
#endif

    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"apns", @"type",
                          app, @"app",
                          deviceToken, @"device_token",
                          nil];

    NSError *jsonError;

    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];

    NSAssert(jsonData != nil, @"Error serializing JSON data: %@", [jsonError localizedDescription]);

    NSError *responseError;
    Response *response = [self getResponse:@"/register_device_push/" method:@"POST" body:jsonData error:&responseError];

    if (response == nil) {
        *error = responseError;
        return NO;
    }

    if ([response isError]) {
        *error = [ShotVibeAPI createErrorFromResponse:response];
        return NO;
    }

    return YES;
}

- (AuthorizePhoneNumberResult)authorizePhoneNumber:(NSString *)phoneNumber defaultCountry:(NSString *)defaultCountry error:(NSError**)error
{
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                          phoneNumber, @"phone_number",
                          defaultCountry, @"default_country",
                          nil];

    NSError *jsonError;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    NSAssert(jsonData != nil, @"Error serializing JSON data: %@", [jsonError localizedDescription]);

    NSError *responseError;
    Response *response = [self getResponse:@"/auth/authorize_phone_number/" method:@"POST" body:jsonData error:&responseError];

    if (response == nil) {
        *error = responseError;
        return AuthorizePhoneNumberError;
    }

    // We want to explicitly check for this error code:
    // It means that the phone number was invalid
    const NSInteger HTTP_BAD_REQUEST = 400;
    if (response.responseCode == HTTP_BAD_REQUEST) {
        return AuthorizePhoneNumberInvalidNumber;
    }

    if ([response isError]) {
        *error = [ShotVibeAPI createErrorFromResponse:response];
        return AuthorizePhoneNumberError;
    }

    @try {
        JSONObject *responseObj = [[JSONObject alloc] initWithData:response.body];
        authConfirmationKey = [responseObj getString:@"confirmation_key"];
        return AuthorizePhoneNumberOk;
    }
    @catch (JSONException *exception) {
        *error = [ShotVibeAPI createErrorFromJSONException:exception];
        return AuthorizePhoneNumberError;
    }
}

- (ConfirmSMSCodeResult)confirmSMSCode:(NSString *)confirmationCode
               deviceDeviceDescription:(NSString *)deviceDescription
                    defaultCountryCode:(NSString *)defaultCountryCode
                                 error:(NSError **)error
{
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                          confirmationCode, @"confirmation_code",
                          deviceDescription, @"device_description",
                          nil];

    NSError *jsonError;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    NSAssert(jsonData != nil, @"Error serializing JSON data: %@", [jsonError localizedDescription]);

    NSError *responseError;
    Response *response = [self getResponse:[NSString stringWithFormat:@"/auth/confirm_sms_code/%@/", authConfirmationKey]
                                    method:@"POST"
                                      body:jsonData
                                     error:&responseError];

    if (response == nil) {
        *error = responseError;
        return ConfirmSMSCodeError;
    }

    const NSInteger HTTP_FORBIDDEN = 403;
    const NSInteger HTTP_GONE = 410;

    // We want to explicitly check for this error code:
    // It means that the SMS Code was incorrect
    if (response.responseCode == HTTP_FORBIDDEN) {
        return ConfirmSMSCodeIncorrectCode;
    }
    else if (response.responseCode == HTTP_GONE) {
        // This error code means that the confirmation_key has expired.

        // TODO We should call authorizePhoneNumber again here and then
        // recursively try calling confirmSMSCode again
    }

    if ([response isError]) {
        *error = [ShotVibeAPI createErrorFromResponse:response];
        return ConfirmSMSCodeError;
    }

    @try {
        JSONObject *responseObj = [[JSONObject alloc] initWithData:response.body];
        int64_t userId = [[responseObj getNumber:@"user_id"] longLongValue];
        NSString *authToken = [responseObj getString:@"auth_token"];

        _authData = [[AuthData alloc] initWithUserID:userId authToken:authToken defaultCountryCode:defaultCountryCode];
        return ConfirmSMSCodeOk;
    }
    @catch (JSONException *exception) {
        *error = [ShotVibeAPI createErrorFromJSONException:exception];
        return ConfirmSMSCodeError;
    }
}

- (NSArray *)getAlbumsWithError:(NSError **)error
{
    NSError *responseError;
    Response *response = [self getResponse:@"/albums/" method:@"GET" body:nil error:&responseError];

    if (!response) {
        *error = responseError;
        return nil;
    }

    if ([response isError]) {
        *error = [ShotVibeAPI createErrorFromResponse:response];
        return nil;
    }

    NSMutableArray *results = [[NSMutableArray alloc] init];

    @try {
        JSONArray *albumsArray = [[JSONArray alloc] initWithData:response.body];
        for (int i = 0; i < [albumsArray count]; ++i) {
            JSONObject *albumObj = [albumsArray getJSONObject:i];

            NSString *etag = [albumObj getString:@"etag"];
            NSNumber *albumId = [albumObj getNumber:@"id"];
            NSString *name = [albumObj getString:@"name"];
            NSDate *dateUpdated = [albumObj getDate:@"last_updated"];

            NSArray *latestPhotos = [ShotVibeAPI parsePhotoList:[albumObj getJSONArray:@"latest_photos"]];

            AlbumSummary *albumSummary = [[AlbumSummary alloc] initWithAlbumId:[albumId longLongValue]
                                                                          etag:etag
                                                                          name:name
                                                                   dateCreated:nil
                                                                   dateUpdated:dateUpdated
                                                                  latestPhotos:latestPhotos];
            [results addObject:albumSummary];
        }
    }
    @catch (JSONException *exception) {
        *error = [ShotVibeAPI createErrorFromJSONException:exception];
        return nil;
    }

    return results;
}

- (AlbumContents *)getAlbumContents:(int64_t)albumId withError:(NSError **)error
{
    NSError *responseError;
    Response *response = [self getResponse:[NSString stringWithFormat:@"/albums/%lld/", albumId] method:@"GET" body:nil error:&responseError];

    if (!response) {
        *error = responseError;
        return nil;
    }

    if ([response isError]) {
        *error = [ShotVibeAPI createErrorFromResponse:response];
        return nil;
    }

    @try {
        return [ShotVibeAPI parseAlbumContents:[[JSONObject alloc] initWithData:response.body]
                                          etag:[ShotVibeAPI responseGetEtag:response]];
    }
    @catch (JSONException *exception) {
        *error = [ShotVibeAPI createErrorFromJSONException:exception];
        return nil;
    }
}

// May throw a JSONException!
+ (AlbumContents *)parseAlbumContents:(JSONObject *)obj etag:(NSString *)etag
{
    NSNumber *albumId = [obj getNumber:@"id"];

    NSString *name = [obj getString:@"name"];
    NSDate *dateCreated = [obj getDate:@"date_created"];
    NSDate *dateUpdated = [obj getDate:@"last_updated"];

    JSONArray *membersArray = [obj getJSONArray:@"members"];

    NSArray *photos = [ShotVibeAPI parsePhotoList:[obj getJSONArray:@"photos"]];

    NSMutableArray *members = [[NSMutableArray alloc] init];
    for (int i = 0; i < membersArray.count; ++i) {
        JSONObject *memberObj = [membersArray getJSONObject:i];
        NSNumber *memberId = [memberObj getNumber:@"id"];
        NSString *memberNickname = [memberObj getString:@"nickname"];
        NSString *memberAvatarUrl = [memberObj getString:@"avatar_url"];

        AlbumMember *albumMember = [[AlbumMember alloc] initWithMemberId:[memberId longLongValue]
                                                                nickname:memberNickname
                                                               avatarUrl:memberAvatarUrl];

        [members addObject:albumMember];
    }

    AlbumContents *albumContents = [[AlbumContents alloc] initWithAlbumId:[albumId longLongValue]
                                                                     etag:etag
                                                                     name:name
                                                              dateCreated:dateCreated
                                                              dateUpdated:dateUpdated
                                                                   photos:photos
                                                                  members:members];

    return albumContents;
}

// May throw a JSONException!
+ (NSArray *)parsePhotoList:(JSONArray *)photosArray
{
    NSMutableArray *results = [[NSMutableArray alloc] init];

    for (int i = 0; i < [photosArray count]; ++i) {
        JSONObject *photoObj = [photosArray getJSONObject:i];
        NSString *photoId = [photoObj getString:@"photo_id"];
        NSString *photoUrl = [photoObj getString:@"photo_url"];
        NSDate *photoDateCreated = [photoObj getDate:@"date_created"];

        JSONObject *authorObj = [photoObj getJSONObject:@"author"];
        NSNumber *authorId = [authorObj getNumber:@"id"];
        NSString *authorNickname = [authorObj getString:@"nickname"];

        AlbumServerPhoto *albumServerPhoto = [[AlbumServerPhoto alloc] initWithPhotoId:photoId
                                                                                   url:photoUrl
                                                                          authorUserId:[authorId longLongValue]
                                                                        authorNickname:authorNickname
                                                                             dateAdded:photoDateCreated];
        AlbumPhoto *albumPhoto = [[AlbumPhoto alloc] initWithAlbumServerPhoto:albumServerPhoto];
        [results addObject:albumPhoto];
    }

    return results;
}

- (AlbumContents *)createNewBlankAlbum:(NSString *)albumName withError:(NSError **)error
{
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                          albumName, @"album_name",
                          [[NSArray alloc] init], @"photos",
                          [[NSArray alloc] init], @"members",
                          nil];

    NSError *jsonError;

    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];

    NSAssert(jsonData != nil, @"Error serializing JSON data: %@", [jsonError localizedDescription]);

    NSError *responseError;
    Response *response = [self getResponse:@"/albums/" method:@"POST" body:jsonData error:&responseError];

    if (response == nil) {
        *error = responseError;
        return NO;
    }

    if ([response isError]) {
        *error = [ShotVibeAPI createErrorFromResponse:response];
        return NO;
    }

    @try {
        return [ShotVibeAPI parseAlbumContents:[[JSONObject alloc] initWithData:response.body]
                                          etag:[ShotVibeAPI responseGetEtag:response]];
    }
    @catch (JSONException *exception) {
        *error = [ShotVibeAPI createErrorFromJSONException:exception];
        return nil;
    }
}

+ (NSError *)createErrorFromResponse:(Response *)response
{
    // TODO better errorCode:
    NSInteger errorCode = 42;

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              NSLocalizedDescriptionKey, [NSString stringWithFormat:@"HTTP Status Code: %d", [response responseCode]],
                              nil];

    return [[NSError alloc] initWithDomain:SHOTVIBE_API_ERROR_DOMAIN code:errorCode userInfo:userInfo];
}

+ (NSError *)createErrorFromJSONException:(JSONException *)exception
{
    // TODO better errorCode:
    NSInteger errorCode = 43;

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              NSLocalizedDescriptionKey, [NSString stringWithFormat:@"Invalid JSON Response: %@", [exception reason]],
                              nil];

    return [[NSError alloc] initWithDomain:SHOTVIBE_API_ERROR_DOMAIN code:errorCode userInfo:userInfo];
}

- (Response *)getResponse:(NSString *)url method:(NSString *)method body:(NSData *)body error:(NSError **)error
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[BASE_URL stringByAppendingString:url]]];
    [request setHTTPMethod:method];

    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    if (self.authData != nil) {
        [request setValue:[@"Token " stringByAppendingString:self.authData.authToken] forHTTPHeaderField:@"Authorization"];
    }

    if (body != nil) {
        [request setHTTPBody:body];
    }

    NSError *httpError;
    NSHTTPURLResponse *httpResponse;
    NSData *httpResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&httpResponse error:&httpError];

    if (httpResponseData == nil) {
        if (error != NULL) {
            *error = httpError;
            return nil;
        }
    }

    Response *response = [[Response alloc] init];
    response.responseCode = [httpResponse statusCode];
    response.headers = [httpResponse allHeaderFields];
    response.body = httpResponseData;

    return response;
}

+ (NSString *)responseGetEtag:(Response *)response
{
    for (NSString *key in response.headers) {
        if ([[key lowercaseString] isEqualToString:@"etag"]) {
            NSString *value = [response.headers objectForKey:key];

            if ([value length] < 2 ||
                [value characterAtIndex:0] != '"' ||
                [value characterAtIndex:[value length] - 1] != '"') {
                // Malformed ETag header
                // TODO Might want to log this
                return nil;
            }

            // Remove the quote('"') characters from the beginning and end of the string.
            // TODO To be really correct, should properly unescape the string
            return [[value substringToIndex:[value length] - 1] substringFromIndex:1];
        }
    }

    // "etag" header not found
    return nil;
}

@end
