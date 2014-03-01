//
//  ShotVibeAPI.m
//  shotvibe
//
//  Created by benny on 8/10/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "ShotVibeAPI.h"
#import "JSON.h"
#import "SL/AlbumSummary.h"
#import "SL/AlbumPhoto.h"
#import "SL/AlbumServerPhoto.h"
#import "SL/AlbumMember.h"
#import "SL/AlbumUser.h"
#import "SL/ArrayList.h"
#import "SL/DateTime.h"
#import "SL/ShotVibeAPI.h"
#import "SL/AuthData.h"
#import "UserSettings.h"
#import "IosHTTPLib.h"
#import "ShotVibeAppDelegate.h"

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
    SLShotVibeAPI *libShotVibeAPI_;
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

    libShotVibeAPI_ = nil;
    [self setAuthData:authData];
    authConfirmationKey = nil;

    return self;
}


- (void)setAuthData:(AuthData *)authData
{
    _authData = authData;

    if (authData && authData.authToken && authData.defaultCountryCode) {
        ShotVibeAppDelegate *app = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];

        id<SLHTTPLib> httpLib = [[IosHTTPLib alloc] init];
        SLAuthData *slAuthData = [[SLAuthData alloc] initWithLong:authData.userId withNSString:authData.authToken withNSString:authData.defaultCountryCode];
        libShotVibeAPI_ = [[SLShotVibeAPI alloc] initWithSLHTTPLib:httpLib
                                        withSLNetworkStatusManager:app.networkStatusManager
                                                    withSLAuthData:slAuthData];
    }
}


- (void)logout
{
    _authData = [[AuthData alloc] initWithUserID:0 authToken:nil defaultCountryCode:nil];
    [UserSettings setAuthData:_authData];
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

    // TODO This is ugly hacky code for sending custom payload set from a special invite URL
    NSString *endPoint;
    if (globalInviteURLCustomPayload) {
        NSString *escapedPayload = [globalInviteURLCustomPayload stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        endPoint = [NSString stringWithFormat:@"/auth/confirm_sms_code/%@/?custom_payload=%@", authConfirmationKey, escapedPayload];
    } else {
        endPoint = [NSString stringWithFormat:@"/auth/confirm_sms_code/%@/", authConfirmationKey];
    }

    NSError *responseError;
    Response *response = [self getResponse:endPoint
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

        AuthData *authData = [[AuthData alloc] initWithUserID:userId authToken:authToken defaultCountryCode:defaultCountryCode];
        [self setAuthData:authData];
        [UserSettings setAuthData:authData];

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
        return NO;
    } else {
        if (registrationInfo.startWithAuth) {
            AuthData *authData = [[AuthData alloc] initWithUserID:registrationInfo.userId
                                                        authToken:registrationInfo.authToken
                                               defaultCountryCode:registrationInfo.countryCode];

            [self setAuthData:authData];
            [UserSettings setAuthData:authData];

            return YES;
        } else {
            return NO;
        }
    }
}


- (SLAlbumUser *)getUserProfile:(int64_t)userId withError:(NSError **)error
{
    [[Mixpanel sharedInstance] track:@"getUserProfile" properties:@{ @"userId" : [NSString stringWithFormat:@"%lld", userId] }];

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

        return [[SLAlbumUser alloc] initWithLong:[memberId longLongValue] withNSString:nickname withNSString:avatarUrl];
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


- (NSArray *)getAlbums
{
    SLArrayList *albums = [libShotVibeAPI_ getAlbums];
    return albums.array;
}


- (void)markAlbumAsViewed:(int64_t)albumId lastAccess:(SLDateTime *)lastAccess
{
    [libShotVibeAPI_ markAlbumAsViewedWithLong:albumId withSLDateTime:lastAccess];
}


- (SLAlbumContents *)getAlbumContents:(int64_t)albumId
{
    return [libShotVibeAPI_ getAlbumContentsWithLong:albumId];
}


- (SLAlbumContents *)createNewBlankAlbum:(NSString *)albumName
{
    return [libShotVibeAPI_ createNewBlankAlbumWithNSString:albumName];
}

- (NSArray *)photosUploadRequest:(int)numPhotos
{
    SLArrayList *result = [libShotVibeAPI_ photosUploadRequestWithInt:numPhotos];

    return result.array;
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

- (SLAlbumContents *)albumAddPhotos:(int64_t)albumId photoIds:(SLArrayList *)photoIds
{
    return [libShotVibeAPI_ albumAddPhotosWithLong:albumId withJavaLangIterable:photoIds];
}

- (SLArrayList *)albumAddMembers:(int64_t)albumId withMemberAddRequests:(id<JavaUtilList>)memberAddRequests withDefaultCountry:(NSString *)defaultCountry
{
    return [libShotVibeAPI_ albumAddMembersWithLong:albumId withJavaUtilList:memberAddRequests withNSString:defaultCountry];
}


- (void)deletePhotos:(SLArrayList *)photos
{
    [libShotVibeAPI_ deletePhotosWithJavaLangIterable:photos];
}


- (void)leaveAlbumWithId:(int64_t)albumId
{
    [libShotVibeAPI_ leaveAlbumWithLong:albumId];
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


@end
