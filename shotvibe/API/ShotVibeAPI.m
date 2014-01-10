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
#import "AlbumUser.h"

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

@interface UploadListener : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, copy) void (^uploadProgress)(int, int);

- (NSHTTPURLResponse *)waitForResponse:(NSError **)error;

@end

@implementation UploadListener
{
    dispatch_semaphore_t finishedSemaphore_;
    NSHTTPURLResponse *httpResponse_;
    NSError *error_;
}

- (id)init
{
    self = [super init];

    if (self) {
        finishedSemaphore_ = dispatch_semaphore_create(0);
        httpResponse_ = nil;
        error_ = nil;

        self.uploadProgress = nil;
    }

    return self;
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (self.uploadProgress) {
        self.uploadProgress(totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    dispatch_semaphore_signal(finishedSemaphore_);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Ignore the response body
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    @synchronized (self) {
        error_ = error;
    }

    dispatch_semaphore_signal(finishedSemaphore_);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    @synchronized(self) {
        httpResponse_ = (NSHTTPURLResponse *)response;
    }
}

- (NSHTTPURLResponse *)waitForResponse:(NSError **)error
{
    dispatch_semaphore_wait(finishedSemaphore_, DISPATCH_TIME_FOREVER);

    @synchronized(self) {
        if (error_) {
            if (error) {
                *error = error_;
            }
            return nil;
        }
        else {
            return httpResponse_;
        }
    }
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


- (NSDictionary*)submitAddressBook:(NSDictionary *)body error:(NSError**)error {
	
    NSError *jsonError;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    NSAssert(jsonData != nil, @"Error serializing JSON data: %@", [jsonError localizedDescription]);
	NSDate *start = [NSDate date];
    NSError *responseError;
    Response *response = [self getResponse:@"/query_phone_numbers/" method:@"POST" body:jsonData error:&responseError];
	RCLog(@"time to get Response %f", (double)[start timeIntervalSinceNow]);
    if (response == nil) {
        *error = responseError;
        return nil;
    }
	
    if ([response isError]) {
        *error = [ShotVibeAPI createErrorFromResponse:response];
        return nil;
    }
	
	id result = [NSJSONSerialization JSONObjectWithData:response.body options:kNilOptions error:&jsonError];
	if (!result) {
		@throw [[JSONException alloc] initWithMessage:@"Malformed JSON: %@", [jsonError localizedDescription]];
	}
	
	if (![result isKindOfClass:[NSDictionary class]]) {
		@throw [[JSONException alloc] initWithMessage:@"Expected a JSON Dictionary, got: %@", [result description]];
	}
	RCLog(@"time to process json %f", (double)[start timeIntervalSinceNow]);
	return result;
}


- (BOOL)registerDevicePushWithDeviceToken:(NSString *)deviceToken error:(NSError**)error
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


- (BOOL)authenticateWithURL:(NSURL *)url
{
    RegistrationInfo *registrationInfo = [RegistrationInfo RegistrationInfoFromURL:url];

    if (registrationInfo == nil) {
        RCLog(@"Error reading RegistrationInfo from url");
    }
    else {

        if (registrationInfo.startWithAuth) {
            AuthData *authData = [[AuthData alloc] initWithUserID:registrationInfo.userId
                                                        authToken:registrationInfo.authToken
                                               defaultCountryCode:registrationInfo.countryCode];

            self.authData = authData;
            [UserSettings setAuthData:authData];

            return YES;
        }
        else {
            return NO;
        }
    }

    return NO;
}


- (AlbumUser *)getUserProfile:(int64_t)userId withError:(NSError **)error
{
    NSError *responseError;
    Response *response = [self getResponse:[NSString stringWithFormat:@"/users/%lld/", userId] method:@"GET" body:nil error:&responseError];

    if (!response) {
        *error = responseError;
        return nil;
    }

    if ([response isError]) {
        *error = [ShotVibeAPI createErrorFromResponse:response];
        return nil;
    }

    @try {
        JSONObject *profileObj = [[JSONObject alloc] initWithData:response.body];

        NSNumber *memberId = [profileObj getNumber:@"id"];
        NSString *nickname = [profileObj getString:@"nickname"];
        NSString *avatarUrl = [profileObj getString:@"avatar_url"];

        return [[AlbumUser alloc] initWithMemberId:[memberId longLongValue] nickname:nickname avatarUrl:avatarUrl];
    }
    @catch (JSONException *exception) {
        *error = [ShotVibeAPI createErrorFromJSONException:exception];
        return nil;
    }
}

- (BOOL)setUserNickname:(int64_t)userId nickname:(NSString *)nickname withError:(NSError **)error
{
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                          nickname, @"nickname",
                          nil];

    NSError *jsonError;

    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];

    NSAssert(jsonData != nil, @"Error serializing JSON data: %@", [jsonError localizedDescription]);

    NSError *responseError;
    Response *response = [self getResponse:[NSString stringWithFormat:@"/users/%lld/", userId] method:@"PATCH" body:jsonData error:&responseError];

    if (response == nil) {
        *error = responseError;
        return NO;
    }

    if ([response isError]) {
        *error = [ShotVibeAPI createErrorFromResponse:response];
        return NO;
    }

    // TODO Maybe parse the response body
    return YES;
}

- (BOOL)uploadUserAvatar:(int64_t)userId filePath:(NSString *)filePath uploadProgress:(void (^)(int, int))uploadProgress withError:(NSError **)error
{
    NSError *responseError;
    Response *response = [self putFile:[NSString stringWithFormat:@"/users/%lld/avatar/", userId]
                              filePath:filePath
                           contentType:@"application/octet-stream"
                        uploadProgress:uploadProgress
                             withError:&responseError];

    if (!response) {
        *error = responseError;
        return NO;
    }

    if ([response isError]) {
        *error = [ShotVibeAPI createErrorFromResponse:response];
        return NO;
    }

    return YES;
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
        //RCLog(@"\n\nresponse.body:\n%@", [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding]);
        for (int i = 0; i < [albumsArray count]; ++i) {
            JSONObject *albumObj = [albumsArray getJSONObject:i];

            NSString *etag = [albumObj getString:@"etag"];
            NSNumber *albumId = [albumObj getNumber:@"id"];
            NSString *name = [albumObj getString:@"name"];
            NSDate *dateUpdated = [albumObj getDate:@"last_updated"];
            NSNumber *numNewPhotos = [albumObj getNumber:@"num_new_photos"];
            NSDate *lastAccess = [albumObj isNull:@"last_access"] ? nil : [albumObj getDate:@"last_access"];

            RCLog(@"Fetched album #%@ (\"%@\") from server: dateUpdated: %@, numNewPhotos: %@, lastAccess: %@", albumId, name, dateUpdated, numNewPhotos, lastAccess);
            NSArray *latestPhotos = [ShotVibeAPI parsePhotoList:[albumObj getJSONArray:@"latest_photos"] albumLastAccess:lastAccess];

            AlbumSummary *albumSummary = [[AlbumSummary alloc] initWithAlbumId:[albumId longLongValue]
                                                                          etag:etag
                                                                          name:name
                                                                   dateCreated:nil
                                                                   dateUpdated:dateUpdated
                                                                  numNewPhotos:[numNewPhotos longLongValue]
                                                                    lastAccess:lastAccess
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


- (BOOL)markAlbumAsViewed:(int64_t)albumId lastAccess:(NSDate *)lastAccess withError:(NSError **)error
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    
    NSString *lastAccessStr = [dateFormatter stringFromDate:lastAccess];
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                          lastAccessStr, @"timestamp",
                          nil];

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    NSAssert(jsonData != nil, @"Error serializing JSON data: %@", [jsonError localizedDescription]);
    
    NSError *responseError;
    Response *response = [self getResponse:[NSString stringWithFormat:@"/albums/%lld/view/", albumId]
                                    method:@"POST"
                                      body:jsonData
                                     error:&responseError];

    if (!response) {
        *error = responseError;
        return NO;
    }

    if ([response isError]) {
        *error = [ShotVibeAPI createErrorFromResponse:response];
        return NO;
    }

    return YES;
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
    NSNumber *numNewPhotos = [obj getNumber:@"num_new_photos"];
    NSDate *lastAccess = [obj isNull:@"last_access"] ? nil : [obj getDate:@"last_access"];

    JSONArray *membersArray = [obj getJSONArray:@"members"];

    NSArray *photos = [ShotVibeAPI parsePhotoList:[obj getJSONArray:@"photos"] albumLastAccess:lastAccess];

    NSMutableArray *members = [[NSMutableArray alloc] init];
    for (int i = 0; i < membersArray.count; ++i) {
        JSONObject *memberObj = [membersArray getJSONObject:i];
        NSNumber *memberId = [memberObj getNumber:@"id"];
        NSString *memberNickname = [memberObj getString:@"nickname"];
        NSString *memberAvatarUrl = [memberObj getString:@"avatar_url"];
        NSString *inviteStatusStr = [memberObj getString:@"invite_status"];
        AlbumMemberInviteStatus inviteStatus;
        if ([inviteStatusStr isEqualToString:@"joined"]) {
            inviteStatus = AlbumMemberJoined;
        }
        else if ([inviteStatusStr isEqualToString:@"sms_sent"]) {
            inviteStatus = AlbumMemberSmsSent;
        }
        else if ([inviteStatusStr isEqualToString:@"invitation_viewed"]) {
            inviteStatus = AlbumMemberInvitationViewed;
        }
        else {
            @throw [[JSONException alloc] initWithMessage:@"Invalid `invite_status` value: %@", inviteStatusStr];
        }

        AlbumUser *user = [[AlbumUser alloc] initWithMemberId:[memberId longLongValue]
                                                     nickname:memberNickname
                                                    avatarUrl:memberAvatarUrl];

        [members addObject:[[AlbumMember alloc] initWithAlbumUser:user inviteStatus:inviteStatus]];
    }

    AlbumContents *albumContents = [[AlbumContents alloc] initWithAlbumId:[albumId longLongValue]
                                                                     etag:etag
                                                                     name:name
                                                              dateCreated:dateCreated
                                                              dateUpdated:dateUpdated
                                                             numNewPhotos:[numNewPhotos longLongValue]
                                                               lastAccess:lastAccess
                                                                   photos:photos
                                                                  members:members];

    return albumContents;
}

// May throw a JSONException!
+ (NSArray *)parsePhotoList:(JSONArray *)photosArray albumLastAccess:(NSDate *)albumLastAccess
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
        NSString *authorAvatarUrl = [authorObj getString:@"avatar_url"];

        AlbumUser *author = [[AlbumUser alloc] initWithMemberId:[authorId longLongValue] nickname:authorNickname avatarUrl:authorAvatarUrl];

        AlbumServerPhoto *albumServerPhoto = [[AlbumServerPhoto alloc] initWithPhotoId:photoId
                                                                                   url:photoUrl
                                                                                author:author
                                                                             dateAdded:photoDateCreated
                                                                            lastAccess:albumLastAccess];

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

- (NSArray *)photosUploadRequest:(int)numPhotos withError:(NSError **)error
{
    NSAssert(numPhotos >= 1, @"Invalid argument");

    NSError *responseError;
    Response *response = [self getResponse:[NSString stringWithFormat:@"/photos/upload_request/?num_photos=%d", numPhotos]
                                    method:@"POST"
                                      body:nil
                                     error:&responseError];

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
        JSONArray *responseArray = [[JSONArray alloc] initWithData:response.body];
        for (int i = 0; i < [responseArray count]; ++i) {
            JSONObject *photoUploadRequestObj = [responseArray getJSONObject:i];

            NSString *photoId = [photoUploadRequestObj getString:@"photo_id"];

            [results addObject:photoId];
        }
    }
    @catch (JSONException *exception) {
        *error = [ShotVibeAPI createErrorFromJSONException:exception];
        return nil;
    }

    return results;
}

- (BOOL)photoUpload:(NSString *)photoId filePath:(NSString *)filePath uploadProgress:(void (^)(int, int))uploadProgress withError:(NSError **)error
{
    NSError *responseError;
    Response *response = [self putFile:[NSString stringWithFormat:@"/photos/upload/%@/", photoId]
                              filePath:filePath
                           contentType:@"application/octet-stream"
                        uploadProgress:uploadProgress
                             withError:&responseError];

    if (!response) {
        *error = responseError;
        return NO;
    }

    if ([response isError]) {
        *error = [ShotVibeAPI createErrorFromResponse:response];
        return NO;
    }

    return YES;
}

- (AlbumContents *)albumAddPhotos:(int64_t)albumId photoIds:(NSArray *)photoIds withError:(NSError **)error
{
    NSMutableArray *photosArray = [[NSMutableArray alloc] init];
    for (NSString *photoId in photoIds) {
        NSDictionary *photoObj = [NSDictionary dictionaryWithObjectsAndKeys:
                                  photoId, @"photo_id",
                                  nil];
        [photosArray addObject:photoObj];
    }

    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                          photosArray, @"add_photos",
                          nil];

    NSError *jsonError;

    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];

    NSAssert(jsonData != nil, @"Error serializing JSON data: %@", [jsonError localizedDescription]);

    NSError *responseError;
    Response *response = [self getResponse:[NSString stringWithFormat:@"/albums/%lld/", albumId] method:@"POST" body:jsonData error:&responseError];

    if (response == nil) {
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

- (AlbumContents *)albumAddMembers:(int64_t)albumId phoneNumbers:(NSArray *)phoneNumbers withError:(NSError **)error
{
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                          phoneNumbers, @"add_members",
                          nil];
	
    NSError *jsonError;
	
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
	
    NSAssert(jsonData != nil, @"Error serializing JSON data: %@", [jsonError localizedDescription]);
	
    NSError *responseError;
    Response *response = [self getResponse:[NSString stringWithFormat:@"/albums/%lld/", albumId] method:@"POST" body:jsonData error:&responseError];
	
    if (response == nil) {
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


- (BOOL)deletePhotos:(NSArray *)photos withError:(NSError **)error
{
    NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
                          photos, @"photos",
                          nil];
	RCLog(@"body %@", body);
    NSError *jsonError;
	
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
	
    NSAssert(jsonData != nil, @"Error serializing JSON data: %@", [jsonError localizedDescription]);
	
    NSError *responseError;
    Response *response = [self getResponse:@"/photos/delete/" method:@"POST" body:jsonData error:&responseError];
	
    if (responseError != nil) {
		RCLog(@"responseError %@", responseError);
        *error = responseError;
		return NO;
    }
	
    if ([response isError]) {
		RCLog(@"response %@", response);
        *error = [ShotVibeAPI createErrorFromResponse:response];
		return NO;
    }
	return YES;
}


- (BOOL)leaveAlbumWithId:(int64_t)albumId
{
	NSDictionary *body = [[NSDictionary alloc] init];
	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:NULL];
	NSError *responseError;
    Response *response = [self getResponse:[NSString stringWithFormat:@"/albums/%lld/leave/", albumId]
									method:@"POST"
									  body:jsonData
									 error:&responseError];
	
	//RCLog(@"albumId %lli, response %i, %@ %@", albumId, response.responseCode, response.body, responseError);
	if (response.responseCode == 204) {
		return YES;
	}
	return NO;
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
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];

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

- (Response *)putFile:(NSString *)url filePath:(NSString *)filePath contentType:(NSString *)contentType uploadProgress:(void (^)(int, int))uploadProgress withError:(NSError **)error
{
    // TODO Some refactoring is in order to eliminate the duplicate code from the getResponse method

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[BASE_URL stringByAppendingString:url]]];
    [request setHTTPMethod:@"PUT"];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    if (self.authData != nil) {
        [request setValue:[@"Token " stringByAppendingString:self.authData.authToken] forHTTPHeaderField:@"Authorization"];
    }

    NSError *attributesError;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&attributesError];
    if (!attributes) {
        *error = attributesError;
        return nil;
    }

    NSNumber *fileSize = [attributes objectForKey:NSFileSize];

    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    [request setHTTPBodyStream:inputStream];

    [request setValue:[fileSize stringValue] forHTTPHeaderField:@"Content-Length"];


    UploadListener *uploadListener = [[UploadListener alloc] init];
    uploadListener.uploadProgress = uploadProgress;
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:uploadListener startImmediately:NO];
    [connection setDelegateQueue:[[NSOperationQueue alloc] init]];
    [connection start];

    NSError *responseError;
    NSHTTPURLResponse *httpResponse = [uploadListener waitForResponse:&responseError];
    if (!httpResponse) {
        *error = responseError;
        return nil;
    }

    Response *response = [[Response alloc] init];
    response.responseCode = [httpResponse statusCode];
    response.headers = [httpResponse allHeaderFields];

    // TODO return a real body:
    response.body = nil;

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
