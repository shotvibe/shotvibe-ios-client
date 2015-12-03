//
//  ShotVibeAPITask.m
//  shotvibe
//
//  Created by benny on 6/6/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "ShotVibeAPITask.h"
#import "MBProgressHUD.h"
#import "SL/APIException.h"
#import "KVNProgress.h"


@interface TaskErrorDialogDelegate : NSObject <UIAlertViewDelegate>

- (id)initWith:(UIViewController *)viewController withAction:(id (^)())run onTaskComplete:(void (^)(id))onTaskComplete;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@implementation TaskErrorDialogDelegate
{
    UIViewController *viewController_;
    id (^ run_)();
    void (^ onTaskComplete_)(id);

    // A hack to prevent ARC from releasing the delegate
    id selfLoop_;
}

- (id)initWith:(UIViewController *)viewController withAction:(id (^)())run onTaskComplete:(void (^)(id))onTaskComplete
{
    self = [super init];

    if (self) {
        viewController_ = viewController;
        run_ = run;
        onTaskComplete_ = onTaskComplete;

        selfLoop_ = self;
    }

    return self;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger retryButton = 1;

    if (buttonIndex == retryButton) {
        [ShotVibeAPITask runTask:viewController_
                      withAction:run_
                  onTaskComplete:onTaskComplete_];
    }

    // Break the cycle so that ARC will release the delegate
    selfLoop_ = nil;
}


@end

@implementation ShotVibeAPITask


+ (void)runTask:(UIViewController *)viewController withAction:(id (^)())run onTaskComplete:(void (^)(id))onTaskComplete withSuccess:(BOOL)withSuccess withFailure:(BOOL)withFailure successText:(NSString*)successText failureText:(NSString*)failureText showLoadingText:(BOOL)showLoadingText loadingText:(NSString*)loadingText
{
    
    
    
//    if(withSuccess){
//        
//    }
    
//    if(withFailure){
//        [KVNProgress dismissWithCompletion:^{
//            
//        }];
//        [KVNProgress showSuccessWithStatus:loadingText];
//    }
    
//    if(showLoadingText){
//        [KVNProgress showWithStatus:loadingText];
//    }
    
    [KVNProgress showWithStatus:loadingText];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        id result;
        @try {
            result = run();
        } @catch (SLAPIException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //                [viewController.view.window setUserInteractionEnabled:YES];
                //                [MBProgressHUD hideHUDForView:viewController.view animated:YES];
//                [KVNProgress dismiss];
                
                TaskErrorDialogDelegate *delegate = [[TaskErrorDialogDelegate alloc] initWith:viewController
                                                                                   withAction:run
                                                                               onTaskComplete:onTaskComplete];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Internet Connection Error"
                                                                message:[exception getUserFriendlyMessage]
                                                               delegate:delegate
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Retry", nil];
                [alert show];
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //            [KVNProgress showSuccess];
            //            [viewController.view.window setUserInteractionEnabled:YES];
            //            [MBProgressHUD hideHUDForView:viewController.view animated:YES];
//            [KVNProgress dismiss];
            //            [KVNProgress showSuccessWithStatus:@"Success"];
            onTaskComplete(result);
        });
    });
    
    
}

+ (void)runTask:(UIViewController *)viewController withAction:(id (^)())run onTaskComplete:(void (^)(id))onTaskComplete
{
//    [MBProgressHUD showHUDAddedTo:viewController.view animated:YES];
    
    
    
    
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        //        self.basicConfiguration.tapBlock = nil;
//        
//    });
    
//    [viewController.view.window setUserInteractionEnabled:NO];
    [KVNProgress show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        id result;
        @try {
            result = run();
        } @catch (SLAPIException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
//                [viewController.view.window setUserInteractionEnabled:YES];
//                [MBProgressHUD hideHUDForView:viewController.view animated:YES];
                [KVNProgress dismiss]; 

                TaskErrorDialogDelegate *delegate = [[TaskErrorDialogDelegate alloc] initWith:viewController
                                                                                   withAction:run
                                                                               onTaskComplete:onTaskComplete];

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Internet Connection Error"
                                                                message:[exception getUserFriendlyMessage]
                                                               delegate:delegate
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Retry", nil];
                [alert show];
            });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            
//            [KVNProgress showSuccess];
//            [viewController.view.window setUserInteractionEnabled:YES];
//            [MBProgressHUD hideHUDForView:viewController.view animated:YES];
            [KVNProgress dismiss];
//            [KVNProgress showSuccessWithStatus:@"Success"];
            onTaskComplete(result);
            [KVNProgress dismiss];
        });
    });
}


@end
