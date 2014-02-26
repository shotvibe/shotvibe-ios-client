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
#import "SL/APIException.h"
#import "UserSettings.h"
#import "IosHTTPLib.h"

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

    dispatch_queue_t uploadQueue_; // Queue for uploading photos on iOS < 7, where NSURLSession is not available

    NSOperationQueue *completionQueue_; // Operation queue for executing NSURLSession completion handlers

    NSURLSession *uploadNSURLSession_;
}

static NSString * const SHOTVIBE_API_ERROR_DOMAIN = @"com.shotvibe.shotvibe.ShotVibeAPI.ErrorDomain";

NSString *const kUploadSessionId = @"shotvibe.uploadSession";

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

    [self initUploadSession];

    return self;
}


- (void)setAuthData:(AuthData *)authData
{
    _authData = authData;

    if (authData && authData.authToken && authData.defaultCountryCode) {
        id<SLHTTPLib> httpLib = [[IosHTTPLib alloc] init];
        SLAuthData *slAuthData = [[SLAuthData alloc] initWithLong:authData.userId withNSString:authData.authToken withNSString:authData.defaultCountryCode];
        libShotVibeAPI_ = [[SLShotVibeAPI alloc] initWithSLHTTPLib:httpLib withSLAuthData:slAuthData];
    }
}


- (void)initUploadSession
{
    UploadSessionDelegate *uploadListener = [[UploadSessionDelegate alloc] init];

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:kUploadSessionId];
    //NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];

    completionQueue_ = [[NSOperationQueue alloc] init];

    uploadNSURLSession_ = [NSURLSession sessionWithConfiguration:config delegate:uploadListener delegateQueue:completionQueue_];

    // *INDENT-OFF* Uncrustify @""/cast problem https://github.com/shotvibe/shotvibe-ios-client/issues/260
    [uploadNSURLSession_ getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        RCLog(@"NSURLSession with id %@, nr of current upload tasks: %d\n", kUploadSessionId, [uploadTasks count]);
        for (NSURLSessionUploadTask *task in uploadTasks) {
            RCLog(@"Cancelling upload task #%d", task.taskIdentifier);
            [task cancel];
            /* We currently don't support tasks that persist after the app was terminated, as this requires us to restore the task-specific delegates and upload and uploaded queues.
             For now, background tasks finishing while the app was terminated, or that were still running when the
             app started will be canceled.
             TODO: provide a fail safe similar to Android, or resurrect the previous tasks
             */
        }
    }];
    // *INDENT-ON*
    uploadQueue_ = dispatch_queue_create(NULL, NULL);
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
                           isPhotoUpload:NO
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

- (BOOL)photoUpload:(NSString *)photoId filePath:(NSString *)filePath isFullRes:(BOOL)isFullRes uploadProgress:(void (^)(int, int))uploadProgress withError:(NSError **)error
{
    NSError *responseError;
    NSString *url = [NSString stringWithFormat:@"/photos/upload/%@/%@", photoId, isFullRes ? @"original/":@""];
    RCLog(@"photoUpload: putFile with url %@", url);
    Response *response = [self putFile:url
                                filePath:filePath
                           isPhotoUpload:YES
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
    [request setURL:[NSURL URLWithString:[[SLShotVibeAPI BASE_URL] stringByAppendingString:url]]];
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

// TODO: isPhotoUpload parameter is temporary, until we use the urls from photosUploadRequest
- (Response *)putFile:(NSString *)url filePath:(NSString *)filePath isPhotoUpload:(BOOL)isPhotoUpload contentType:(NSString *)contentType uploadProgress:(void (^)(int, int))uploadProgress withError:(NSError **)error
{
    // TODO Some refactoring is in order to eliminate the duplicate code from the getResponse method

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *baseUrl = isPhotoUpload ? [SLShotVibeAPI BASE_UPLOAD_URL] : [SLShotVibeAPI BASE_URL];
    [request setURL:[NSURL URLWithString:[baseUrl stringByAppendingString:url]]];
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


// TODO: cleanup and refactor when combining with old ShotVibeAPI

static const NSTimeInterval RETRY_TIME = 5;

- (void)photoUploadAsync:(NSString *)photoId filePath:(NSString *)filePath isFullRes:(BOOL)isFullRes progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler
{
    if (!uploadNSURLSession_) { // if there's no session, we're on iOS < 7
        RCLog(@"Starting asynchronous upload task as UIBackgroundTask (max 10 minutes)");
        [self photoUploadAsyncNoSession:photoId filePath:filePath isFullRes:isFullRes progressHandler:progressHandler completionHandler:completionHandler];
    } else {
        RCLog(@"Starting asynchronous upload task in NSURLSession");
        NSURL *uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/photos/upload/%@/%@", [SLShotVibeAPI BASE_UPLOAD_URL], photoId, isFullRes ? @"original/":@""]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:uploadURL];
        [request setHTTPMethod:@"PUT"];
        if (self.authData != nil) {
            [request setValue:[@"Token " stringByAppendingString : self.authData.authToken] forHTTPHeaderField:@"Authorization"];
        } else { // This is a serious error; it should not be possible to start tasks without authentication.
            RCLog(@"ERROR: upload task started without authentication.\nFile: %@", filePath);
        }

        NSURL *photoFileUrl = [NSURL fileURLWithPath:filePath];

        NSURLSessionUploadTask *uploadTask = [uploadNSURLSession_ uploadTaskWithRequest:request fromFile:photoFileUrl];
        RCLog(@"Created %@ task for URL: %@", request.HTTPMethod, uploadURL);

        [((UploadSessionDelegate *)[uploadNSURLSession_ delegate])setDelegateForTask : uploadTask progressHandler : progressHandler completionHandler : completionHandler];

        [uploadTask resume];
    }
}


// Asynchronous upload for iOS <7, when NSURLSession is not available
// Note: callee must guarantee this function can execute in the background
- (void)photoUploadAsyncNoSession:(NSString *)photoId filePath:(NSString *)filePath isFullRes:(BOOL)isFullRes progressHandler:(ProgressHandlerType)progressHandler completionHandler:(CompletionHandlerType)completionHandler
{
    // *INDENT-OFF* Uncrustify block problem: https://github.com/bengardner/uncrustify/pull/233
    dispatch_async(uploadQueue_, ^{ // TODO: also want parallelism here?
        NSError *error;
        [self photoUpload:photoId filePath:filePath isFullRes:(BOOL)isFullRes uploadProgress:^(int bytesUploaded, int bytesTotal) {
            if (progressHandler) {
                progressHandler(bytesUploaded, bytesTotal);
            }
        } withError:&error];

        completionHandler(error);
    });
    // *INDENT-ON*
}


- (void)albumAddPhotosAsync:(int64_t)albumId photoIds:(NSArray *)photoIds completionHandler:(CompletionHandlerType)completionHandler
{
    if (!uploadNSURLSession_) { // if there's no session, we're on iOS < 7
        RCLog(@"Starting asynchronous add-photos task as UIBackgroundTask (max 10 minutes)");
        [self albumAddPhotosAsyncNoSession:albumId photoIds:photoIds completionHandler:completionHandler];
    } else {
        RCLog(@"Starting asynchronous add-photos task in NSURLSession");

        // NOTE: duplicated code from ShotVibeAPI albumAddPhotos
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

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];

        NSAssert(jsonData != nil, @"Error serializing JSON data: %@", [jsonError localizedDescription]);
        // End of duplicated code

        NSURL *uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/albums/%lld/", [SLShotVibeAPI BASE_URL], albumId]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:uploadURL];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        if (self.authData != nil) {
            [request setValue:[@"Token " stringByAppendingString : self.authData.authToken] forHTTPHeaderField:@"Authorization"];
        } else { // This is a serious error; it should not be possible to start tasks without authentication.
            RCLog(@"ERROR: albumAddPhotos task started without authentication.\nAlbum: %lld", albumId);
        }

        // We need to save the request body to a file, since only tasks using files are allowed in the background
        NSString *jsonDataFilePath = [self createTempFileWithPrefix:@"albumAddPhotosRequestData"];
        [jsonData writeToFile:jsonDataFilePath atomically:YES];
        NSURL *jsonDataUrl = [NSURL fileURLWithPath:jsonDataFilePath];

        NSURLSessionUploadTask *uploadTask = [uploadNSURLSession_ uploadTaskWithRequest:request fromFile:jsonDataUrl];
        RCLog(@"Created %@ task for URL: %@", request.HTTPMethod, uploadURL);

        [((UploadSessionDelegate *)[uploadNSURLSession_ delegate])setDelegateForTask : uploadTask progressHandler : nil completionHandler : completionHandler];
        [uploadTask resume];
        RCLog(@"Started asynchronous add-photos task in NSURLSession");
    }
}


// Asynchronous add to album for iOS <7, when NSURLSession is not available
// Note: callee must guarantee this function can execute in the background
- (void)albumAddPhotosAsyncNoSession:(int64_t)albumId photoIds:(NSArray *)photoIds completionHandler:(CompletionHandlerType)completionHandler
{
    // *INDENT-OFF* Uncrustify block problem: https://github.com/bengardner/uncrustify/pull/233
    dispatch_async(uploadQueue_, ^{ // TODO: also want parallelism here?
        @try {
            [self albumAddPhotos:albumId photoIds:[[SLArrayList alloc] initWithInitialArray:[NSMutableArray arrayWithArray:photoIds]]];
            completionHandler(nil);
        }
        @catch (SLAPIException *exception) {
            RCLog(@"Error adding photos to album: %lld %@", albumId, exception.description);
            // TODO: we need to figure out whether to use exceptions or errors
            NSError *errorForException = [[NSError alloc] initWithDomain:@"com.shotvibe.shotvibe.TemporaryErrorDomain" code:44 userInfo:@{NSLocalizedDescriptionKey: exception.description}];

            completionHandler(errorForException);
        }
    });
    // *INDENT-ON*
}


- (NSString *)createTempFileWithPrefix:prefix
{
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *uniqueFileName = [NSString stringWithFormat:@"%@_%@", prefix, guid];

    return [NSTemporaryDirectory() stringByAppendingPathComponent:uniqueFileName];
}


@end
