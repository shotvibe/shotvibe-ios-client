//
//  SVProfileViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

//#import "ContainerViewController.h"
#import "SVProfileViewController.h"
#import "SVDefines.h"
#import "MBProgressHUD.h"
#import "UIImageView+WebCache.h"
#import "UserSettings.h"
#import "SL/ShotVibeAPI.h"
#import "SL/AlbumUser.h"
#import "GLProfilePictureController.h"
#import "ShotVibeAppDelegate.h"
#import "GLContainersViewController.h"
#import "GLSharedCamera.h"

@interface SVProfileViewController ()

@property (nonatomic, strong) IBOutlet UITextField *nicknameField;
@property (nonatomic, strong) IBOutlet UIImageView *userPhoto;
@property (nonatomic, strong) IBOutlet UILabel *promptLabel;
@property (nonatomic, strong) IBOutlet UIButton *continueButton;

@property (nonatomic) BOOL shouldSave;

- (IBAction)changeProfilePicture:(id)sender;

- (IBAction)handleContinueButtonPressed:(id)sender;

@end


@implementation SVProfileViewController



#pragma mark View lifecycle

-(void)resizeViewToIphone5:(UIView *)view width:(BOOL)width height:(BOOL)height cornerRadius:(BOOL)cornerRadius {
    
    CGRect f = view.frame;
    f.origin.x = f.origin.x/1.17;
    f.origin.y = f.origin.y/1.17;
    if(width){
        f.size.width = f.size.width/1.17;
    }
    if(height){
        f.size.height = f.size.height/1.17;
    }
    view.frame = f;
    if(cornerRadius){
        view.layer.cornerRadius = view.layer.cornerRadius/1.17;
    }
}

- (void)viewDidLoad {
	
    [super viewDidLoad];
	
    self.title = NSLocalizedString(@"Profile", nil);
	
//	NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//	path = [path stringByAppendingString:@"/avatar.jpg"];
//    
//    
//	self.userPhoto.image = [UIImage imageWithContentsOfFile:path];
//    self.userPhoto.alpha = 0;
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editPhoto)];
    self.userPhoto.userInteractionEnabled = YES;
    [self.userPhoto addGestureRecognizer:tap];
	
	
    SLShotVibeAPI *shotvibeAPI = [[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI];
    int64_t userId = [[shotvibeAPI getAuthData] getUserId];
	
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        SLAlbumUser *userProfile = nil;
        @try {
            userProfile = [shotvibeAPI getUserProfileWithLong:userId];
        } @catch (SLAPIException *exception) {
            // TODO: Shouldn't ignore this
        }

        dispatch_async(dispatch_get_main_queue(), ^{
			
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
			if (!userProfile) {
                // TODO Better error dialog with Retry option
				//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
				//                                                                message:[error description]
				//                                                               delegate:nil
				//                                                      cancelButtonTitle:@"OK"
				//                                                      otherButtonTitles:nil];
				//                [alert show];
            }
            else {
                self.nicknameField.text = [userProfile getMemberNickname];
                
                [[NSUserDefaults standardUserDefaults] setObject:[userProfile getMemberNickname] forKey:@"kUserNickName"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                
                
                [self.userPhoto setImageWithURL:[NSURL URLWithString:[userProfile getMemberAvatarUrl]]];
                if (self.shouldPrompt) { // If we're prompting, focus on the name after it has been set
//                    [self.nicknameField becomeFirstResponder];
                }
            }
        });
    });
    
    
    if(self.fromSettings){
    
        for(UIView * v in self.view.subviews){
        
            CGRect tFrame = v.frame;
            tFrame.origin.y -= 200;
            v.frame = tFrame;
            
        }
        
    } else {
        
        
    }
    [[GLSharedCamera sharedInstance] fixAfterLogin];
}


-(void)editPhoto {
    
    
    [[GLSharedCamera sharedInstance] hideGlCameraView];
    GLProfilePictureController *glprof = [[GLProfilePictureController alloc] init];
    if(self.fromSettings){
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        glprof.fromSettings = YES;
    }
    [self.navigationController pushViewController:glprof animated:NO];

}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    
    if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone5]){
        
        [self resizeViewToIphone5:self.nicknameField width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.promptLabel width:NO height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.userPhoto width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.goButton width:YES height:YES cornerRadius:NO];
        
    }
    
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingString:@"/avatar.jpg"];
    
    
    self.userPhoto.image = [UIImage imageWithContentsOfFile:path];

    if (IS_IOS7) {
		self.navigationController.navigationBar.translucent = NO;
	}

    if ([self shouldPrompt]) { // Prompt the user for a nick change and don't allow him to go back until he does
        self.navigationItem.title = NSLocalizedString(@"Set your profile", nil);
        self.navigationItem.hidesBackButton = YES;
        self.promptLabel.hidden = NO;
        self.nicknameField.enablesReturnKeyAutomatically = YES;
        self.continueButton.hidden = NO;
    }
    
    self.shouldSave = YES;
    self.userPhoto.layer.cornerRadius = self.userPhoto.frame.size.width/2;
    self.userPhoto.layer.masksToBounds = YES;
    self.userPhoto.clipsToBounds = YES;
    
    UIView * borderBottom = [[UIView alloc] initWithFrame:CGRectMake(0, self.nicknameField.frame.size.height-1, self.nicknameField.frame.size.width, 1)];
    borderBottom.backgroundColor = self.nicknameField.textColor;
    [self.nicknameField addSubview:borderBottom];
}

- (void) viewWillDisappear:(BOOL)animated {
	
	[super viewWillDisappear:animated];
	
	if (IS_IOS7) {
		self.navigationController.navigationBar.translucent = YES;
	}
}

#pragma mark Actions

- (IBAction)changeProfilePicture:(id)sender {
	
    self.shouldSave = NO;
	[self.nicknameField resignFirstResponder];
	[self performSegueWithIdentifier:@"ProfilePicSegue" sender:self];
}


- (IBAction)handleContinueButtonPressed:(id)sender
{
    // TODO: Having to press this after pressing Done on the keyboard is awkward, but
    // when improving this behavior, we have to make sure the nickname is always first
    // responder, except before the server update is received. (which may happen while in
    // the profile pic selection screen)
    
//    [self dismissViewControllerAnimated:YES completion:^{
//        
//    }];
    
    
    
    if(self.fromSettings){
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
            [[NSUserDefaults standardUserDefaults] setInteger:[[[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI] getUserGlanceScoreWithLong:[[[[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI] getAuthData] getUserId]] forKey:@"kUserScore"];
        
        
        
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
               [[[GLSharedCamera sharedInstance] userScore] updateScoreFromPush:(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"kUserScore"]];
            });
        
            
            
//            [[[GLSharedCamera sharedInstance] userScore] showUserScore];
            
//            [[[[GLSharedCamera sharedInstance] userScore] userScoreLabel] setHidden:NO];
//            [[[[GLSharedCamera sharedInstance] userScore] userScoreLabel] setAlpha:1];
            //            GLSharedCamera share
            
        });
    
        GLContainersViewController * containersViewControllers = [[GLContainersViewController alloc] init];
        
//        [self.navigationController.view addSubview:[[GLSharedCamera sharedInstance] cameraViewBackground]];
        [self.navigationController pushViewController:containersViewControllers animated:YES];
//        ContainerViewController * container = [[ContainerViewController alloc] init];
//        [[GLSharedCamera sharedInstance] setDelegate:container];
//        [self.navigationController pushViewController:container animated:YES];
    }
//    [self presentViewController:container animated:YES completion:^{}];
//    [self.navigationController popViewControllerAnimated:YES];
    

}


//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//	
//	if ([segue.identifier isEqualToString:@"ProfilePicSegue"]) {
//		
//		SVProfilePicViewController *destination = segue.destinationViewController;
//        destination.image = self.userPhoto.image;
//        destination.delegate = self;
//
//		// Set the text of the back button of the next screen
//		UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: @"Back" style: UIBarButtonItemStyleBordered target: nil action: nil];
//		[self.navigationItem setBackBarButtonItem:newBackButton];
//    }
//}


#pragma mark ImageCrop Delegate

- (void) didCropImage:(UIImage*)image {
	
	self.userPhoto.image = image;
	[self.navigationController popToViewController:self animated:YES];
}


#pragma mark - UITextFieldDelegate Method

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    
    CGRect cameraFrame = [[[GLSharedCamera sharedInstance] cameraViewBackground] frame];
    
    NSTimeInterval animationDuration = 0.300000011920929;
    CGRect frame = self.view.frame;
    frame.origin.y -= 200;
    cameraFrame.origin.y -= 125;
    frame.size.height += 200;
//    cameraFrame.size.
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    [[[GLSharedCamera sharedInstance] cameraViewBackground] setFrame:cameraFrame];
    self.userPhoto.transform = CGAffineTransformScale(self.userPhoto.transform, 0.85, 0.85);
    self.view.frame = frame;
    [UIView commitAnimations];
    
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
    
    CGRect cameraFrame = [[[GLSharedCamera sharedInstance] cameraViewBackground] frame];
    
    NSTimeInterval animationDuration = 0.300000011920929;
    CGRect frame = self.view.frame;
    frame.origin.y += 200;
    cameraFrame.origin.y += 125;
    frame.size.height -= 200;
    //    cameraFrame.size.
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    [[[GLSharedCamera sharedInstance] cameraViewBackground] setFrame:cameraFrame];
    self.userPhoto.transform = CGAffineTransformIdentity;
    self.view.frame = frame;
    [UIView commitAnimations];
    
    if (self.shouldSave) {

        [textField resignFirstResponder];
        
        NSString *newNickname = [self.nicknameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        SLShotVibeAPI *shotvibeAPI = [[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI];
        
        int64_t userId = [[shotvibeAPI getAuthData] getUserId];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            // Save nickname
            BOOL success = NO;
            @try {
                [shotvibeAPI setUserNicknameWithLong:userId withNSString:newNickname];
                success = YES;
            } @catch (SLAPIException *exception) {
                // TODO Better error handling
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                
                if (!success) {
                    // TODO Better error dialog with Retry option
                    //                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                    //                                                                message:[error description]
                    //                                                               delegate:nil
                    //                                                      cancelButtonTitle:@"OK"
                    //                                                      otherButtonTitles:nil];
                    //                [alert show];
                    if (self.shouldPrompt) {
                        [UserSettings setNicknameSet:NO]; // since the update failed, we revert this setting, so the user will be prompted again later
                    }
                }
                else {
                    //self.navigationItem.rightBarButtonItem = nil;
                    //nameChanged = NO;
                    [self handleContinueButtonPressed:nil];
                }
            });
        });
        [UserSettings setNicknameSet:YES];
    }
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	return YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.nicknameField resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
}

- (BOOL)shouldAutorotate
{
    return NO;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}


- (IBAction)goPressed:(id)sender {
    
    
    if (self.shouldSave) {
        
        [self.nicknameField resignFirstResponder];
        
        NSString *newNickname = [self.nicknameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        SLShotVibeAPI *shotvibeAPI = [[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI];
        
        int64_t userId = [[shotvibeAPI getAuthData] getUserId];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            // Save nickname
            BOOL success = NO;
            @try {
                [shotvibeAPI setUserNicknameWithLong:userId withNSString:newNickname];
                success = YES;
            } @catch (SLAPIException *exception) {
                // TODO Better error handling
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                
                if (!success) {
                    // TODO Better error dialog with Retry option
                    //                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                    //                                                                message:[error description]
                    //                                                               delegate:nil
                    //                                                      cancelButtonTitle:@"OK"
                    //                                                      otherButtonTitles:nil];
                    //                [alert show];
                    if (self.shouldPrompt) {
                        [UserSettings setNicknameSet:NO]; // since the update failed, we revert this setting, so the user will be prompted again later
                    }
                }
                else {
                    //self.navigationItem.rightBarButtonItem = nil;
                    //nameChanged = NO;
                    [self handleContinueButtonPressed:nil];
                }
            });
        });
        [UserSettings setNicknameSet:YES];
    }

    
}
@end
