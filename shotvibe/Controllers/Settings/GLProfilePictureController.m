//
//  SVProfileViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//
//#import "ContainerViewController.h"
#import "UIImage+Scale.h"
#import "GLProfilePictureController.h"
#import "SVDefines.h"
#import "MBProgressHUD.h"
#import "UIImageView+WebCache.h"
#import "UserSettings.h"
#import "SL/ShotVibeAPI.h"
#import "SL/AlbumUser.h"
#import "ShotVibeAppDelegate.h"
#import "ShotVibeAPITask.h"
#import "SVProfileViewController.h"
#import "GLContainersViewController.h"
@interface GLProfilePictureController ()

@property (nonatomic, strong) IBOutlet UITextField *nicknameField;
@property (nonatomic, strong) IBOutlet UIImageView *userPhoto;
@property (nonatomic, strong) IBOutlet UILabel *promptLabel;
@property (nonatomic, strong) IBOutlet UIButton *continueButton;

@property (nonatomic) BOOL shouldSave;

- (IBAction)changeProfilePicture:(id)sender;

- (IBAction)handleContinueButtonPressed:(id)sender;

@end


@implementation GLProfilePictureController {
    BOOL pickerIsOpen;
}



#pragma mark View lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.origiPictureTapped = NO;
    
    pickerIsOpen = NO;
    
    self.goButton.layer.cornerRadius = self.goButton.frame.size.width/2;
    //    self.userPhoto.alpha = 0;
    self.originalPictureView.backgroundColor = [UIColor whiteColor];
    self.originalPictureView.clipsToBounds = YES;
    self.originalPictureView.alpha = 1;
    self.originalPictureView.layer.cornerRadius = self.originalPictureView.frame.size.width/2;
    self.goButton.alpha = 1;
    
    
    
    
    
    UITapGestureRecognizer * selfPictureTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selfPicTapped)];
    self.originalPictureView.userInteractionEnabled = YES;
    [self.originalPictureView addGestureRecognizer:selfPictureTapped];
    
    self.title = NSLocalizedString(@"Profile", nil);
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingString:@"/avatar.jpg"];
    self.needToReUpload = NO;
    
    self.originalPictureView.image = [UIImage imageWithContentsOfFile:path];
    //    self.userPhoto.alpha = 0;
    
    
    SLShotVibeAPI *shotvibeAPI = [[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI];
    int64_t userId = [[shotvibeAPI getAuthData] getUserId];
    
    [KVNProgress show];
    //    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        SLAlbumUser *userProfile = nil;
        @try {
            userProfile = [shotvibeAPI getUserProfileWithLong:userId];
        } @catch (SLAPIException *exception) {
            // TODO: Shouldn't ignore this
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [KVNProgress dismiss];
            
            [[GLSharedCamera sharedInstance] setCameraIsBackView:YES];
            [[GLSharedCamera sharedInstance] flipCamera];
            
            
            CGRect frame = [[[GLSharedCamera sharedInstance] mainScrollView] frame];
            
            if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone6plus]){
                frame.origin.x -= ((self.view.frame.size.width - self.userPhoto.frame.size.width)/2)*1.103;
                frame.origin.y -= (self.userPhoto.frame.origin.y/2)*1.103;
                frame.size.width = frame.size.width*1.103;
                frame.size.height = frame.size.height*1.103;
            } else {
                frame.origin.x -= (self.view.frame.size.width - self.userPhoto.frame.size.width)/2;
                frame.origin.y -= self.userPhoto.frame.origin.y/2;
            }
            
            
            UIView * camWrapper = [[UIView alloc] initWithFrame:frame];
            //                camWrapper.backgroundColor = [UIColor purpleColor];
            [camWrapper addSubview:[[GLSharedCamera sharedInstance] mainScrollView]];
            [self.userPhoto addSubview:camWrapper];
            
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
                
                
                
                //                [UIView animateWithDuration:0.3 animations:^{
                //                    self.originalPictureView.alpha = 0;
                //                } completion:^(BOOL finished) {
                //                    [UIView animateWithDuration:0.3 animations:^{
                //
                //                    }];
                //                }];
                
                
                //                [[self.view addSubview:[GLSharedCamera sharedInstance] vid] ];
                self.userPhoto.userInteractionEnabled = YES;
                self.nicknameField.text = [userProfile getMemberNickname];
                [self.userPhoto setImageWithURL:[NSURL URLWithString:[userProfile getMemberAvatarUrl]]];
                [self.originalPictureView setImageWithURL:[NSURL URLWithString:[userProfile getMemberAvatarUrl]]];
                if (self.shouldPrompt) { // If we're prompting, focus on the name after it has been set
                    //                    [self.nicknameField becomeFirstResponder];
                }
            }
        });
    });
    
    
    if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone5]){
        
        [self resizeViewToIphone5:self.xButton width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.goPressed width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.originalPictureView width:YES height:YES cornerRadius:YES];
        [self resizeViewToIphone5:self.capButton width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.galButton width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone5:self.goButton width:YES height:YES cornerRadius:NO];
        
    } else if([[ShotVibeAppDelegate sharedDelegate] platformTypeIsIphone6plus]){
        [self resizeViewToIphone6plus:self.xButton width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.goPressed width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.originalPictureView width:YES height:YES cornerRadius:YES];
        [self resizeViewToIphone6plus:self.capButton width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.galButton width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.goButton width:YES height:YES cornerRadius:YES];
        [self resizeViewToIphone6plus:self.userPhoto width:YES height:YES cornerRadius:YES];
        [self resizeViewToIphone6plus:self.pageTitle width:YES height:YES cornerRadius:NO];
        [self resizeViewToIphone6plus:self.originalLogo width:YES height:YES cornerRadius:NO];
        
    }
}


-(void)selfPicTapped {
    
    self.needToReUpload = NO;
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingString:@"/avatar.jpg"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    
    if(fileExists){
        [self imageSelected:[UIImage imageWithContentsOfFile:path]];
    } else {
        SLShotVibeAPI *shotvibeAPI = [[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI];
        int64_t userId = [[shotvibeAPI getAuthData] getUserId];
        SLAlbumUser * userProfile = [shotvibeAPI getUserProfileWithLong:userId];
        //        [self.userPhoto setImageWithURL:[NSURL URLWithString:[userProfile getMemberAvatarUrl]]];
        [UIView animateWithDuration:0.3 animations:^{
            
            [[[GLSharedCamera sharedInstance] mainScrollView] setAlpha:0];
            
            //            self.userPhoto.image = image;
            self.originalPictureView.alpha = 0;
            self.galButton.alpha = 0;
            self.capButton.alpha = 0;
            self.goButton.alpha = 1;
            self.xButton.alpha = 1;
            self.origiPictureTapped = YES;
        }];
    }
    
    //    self.originalPictureView.image = ;
    
    
}

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

-(void)resizeViewToIphone6plus:(UIView *)view width:(BOOL)width height:(BOOL)height cornerRadius:(BOOL)cornerRadius {
    
    CGRect f = view.frame;
    f.origin.x = f.origin.x*1.103;
    f.origin.y = f.origin.y*1.103;
    if(width){
        f.size.width = f.size.width*1.103;
    }
    if(height){
        f.size.height = f.size.height*1.103;
    }
    view.frame = f;
    if(cornerRadius){
        view.layer.cornerRadius = view.layer.cornerRadius*1.103;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
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
    //    self.userPhoto.backgroundColor = [UIColor orangeColor];
    
    UIView * borderBottom = [[UIView alloc] initWithFrame:CGRectMake(0, self.nicknameField.frame.size.height-1, self.nicknameField.frame.size.width, 1)];
    borderBottom.backgroundColor = self.nicknameField.textColor;
    [self.nicknameField addSubview:borderBottom];
    
    
    //    if(self.fromSettings){
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            CGRect titleframe = self.pageTitle.frame;
    //            titleframe.origin.y +=30;
    //            self.pageTitle.frame = titleframe;
    //        });
    //    }
    
    
    
    
    
}

- (void) viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
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
    //    ContainerViewController * container = [[ContainerViewController alloc] init];
    //    [self.navigationController pushViewController:container animated:YES];
    //    [self presentViewController:container animated:YES completion:^{}];
    //    [self.navigationController popViewControllerAnimated:YES];
    
    
}





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

-(void)openAppleImagePicker {
    
    pickerIsOpen = YES;
    
    GLSharedCamera * glcamera = [GLSharedCamera sharedInstance];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    //    glcamera.delegate = self;
    
    //    glcamera.delegate
    //     glcamera.imagePickerDelegate = picker.delegate;
    picker.delegate = self;
    
    
    //    fromImagePicker = YES;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:^{
        
        //        [appDelegate.window sendSubviewToBack:glcamera.view];
        
        [UIView animateWithDuration:0.3 animations:^{
            //            glcamera.view.alpha = 0;
            //            [glcamera hideForPicker:YES];
        }];
    }];
    
}

-(void)imageSelected:(UIImage *)image {
    
    
    if(self.needToReUpload){
        
        UIImage *scaledImage = [image imageByScalingAndCroppingForSize:CGSizeMake(320, 320)];
        
        //    imageView.image = scaledImage;
        //    self.navigationItem.rightBarButtonItem.enabled = NO;
        //    self.title = NSLocalizedString(@"Uploading picture", @"");
        
        // Save image to disk
        NSError *err;
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        path = [path stringByAppendingString:@"/avatar.jpg"];
        [UIImageJPEGRepresentation(scaledImage, 0.9) writeToFile:path options:YES error:&err];
        
        if (err) {
            RCLog(@"some error ocured while saving the avatar to disk");
            return;
        }
        
        SLShotVibeAPI *shotvibeAPI = [[ShotVibeAppDelegate sharedDelegate].albumManager getShotVibeAPI];
        
        int64_t userId = [[shotvibeAPI getAuthData] getUserId];
        
        
        // Save avatar
        [ShotVibeAPITask runTask:self
         
                      withAction:
         ^id {
             [shotvibeAPI uploadUserAvatarWithLong:userId withNSString:path];
             
             return nil;
         }
         
         
                  onTaskComplete:
         ^(id dummy) {
             
             
             [KVNProgress dismiss];
             if(self.fromSettings){
                 
                 //                 [self.navigationController setNavigationBarHidden:NO animated:YES];
                 
                 [self.navigationController popViewControllerAnimated:YES];
                 
                 
             } else {
                 
                 //         UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
                 SVProfileViewController * profileViewController = [[SVProfileViewController alloc] init];
                 //         SVProfileViewController *profileController = [storyboard instantiateViewControllerWithIdentifier:@"SVProfileViewController"];
                 //         SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
                 
                 [[GLSharedCamera sharedInstance] setInFeedMode:NO dmutNeedTransform:NO];
                 GLSharedCamera * cam = [GLSharedCamera sharedInstance];
                         [[GLSharedCamera sharedInstance] setCameraIsBackView:YES];
                 cam.isInFeedMode = NO;
                 [[GLSharedCamera sharedInstance] showGlCameraView];
                 [self.navigationController setViewControllers:@[profileViewController] animated:YES];
                 //         [self performSegueWithIdentifier:@"GLProfilePictureController" sender:self];
                 
                 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kUserSettedPicture"];
                 
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 
             }
             
             
         }];
        
    } else {
        
        
        [UIView animateWithDuration:0.3 animations:^{
            
            [[[GLSharedCamera sharedInstance] mainScrollView] setAlpha:0];
            
            self.userPhoto.image = image;
            self.originalPictureView.alpha = 0;
            self.galButton.alpha = 0;
            self.capButton.alpha = 0;
            self.goButton.alpha = 1;
            self.xButton.alpha = 1;
            self.origiPictureTapped = YES;
        }];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kUserSettedPicture"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        
    }
    
    
}

- (IBAction)goPressed:(id)sender {
    
    //    self.needToReUpload
    
    //    RCLog(@"didSelectPhoto %@", thePhoto);
    [[GLSharedCamera sharedInstance] setDelegate:self];
    GLSharedCamera * cam = [GLSharedCamera sharedInstance];
    cam.isInFeedMode = YES;
    cam.afterLogin = YES;
    //    [[GLSharedCamera sharedInstance] setIsInFeedMode:YES];
    
    if(!self.needToReUpload){
        
        
        if(self.fromSettings){
            
            //            [self.navigationController setNavigationBarHidden:NO animated:YES];
            [self.navigationController popViewControllerAnimated:YES];
            
        } else {
            //        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
            //        SVProfileViewController *profileController = [storyboard instantiateViewControllerWithIdentifier:@"SVProfileViewController"];
            //        SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
            
            //         [[GLSharedCamera sharedInstance] setInFeedMode:YES dmutNeedTransform:NO];
            SVProfileViewController * profileViewController = [[SVProfileViewController alloc] init];
            //            GLContainersViewController * albumListViewController = [[GLContainersViewController alloc] init];
            GLSharedCamera * cam = [GLSharedCamera sharedInstance];
            
            cam.isInFeedMode = NO;
                                     [[GLSharedCamera sharedInstance] setCameraIsBackView:YES];
            [[GLSharedCamera sharedInstance] showGlCameraView];
            
            [self.navigationController pushViewController:profileViewController animated:YES];
            
            //        [self.navigationController setViewControllers:@[rootView, profileController] animated:YES];
            //         [self performSegueWithIdentifier:@"GLProfilePictureController" sender:self];
            
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kUserSettedPicture"];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        }
        
        
    } else {
        [[GLSharedCamera sharedInstance] finalProcessTapped];
    }
    
    
    
    
    //
    //    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    //    SVProfileViewController *profileController = [storyboard instantiateViewControllerWithIdentifier:@"SVProfileViewController"];
    //    SVAlbumListViewController *rootView = [storyboard instantiateViewControllerWithIdentifier:@"SVAlbumListViewController"];
    //
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //        [self.navigationController setViewControllers:@[rootView, profileController] animated:NO];
    ////        [v removeFromSuperview];
    //        //        [[[GLSharedCamera sharedInstance] cameraViewBackground] setAlpha:0];
    //
    //    });
    
    
}

- (IBAction)captureSelfie:(id)sender {
    self.needToReUpload = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.xButton.alpha = 1;
        self.goButton.alpha = 1;
        self.galButton.alpha = 0;
        self.capButton.alpha = 0;
        self.originalPictureView.alpha = 0;
    } completion:^(BOOL finished) {
        [[GLSharedCamera sharedInstance] captureTapped];
    }];
    
    
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if(!pickerIsOpen){
        [[GLSharedCamera sharedInstance] setCameraIsBackView:YES];
        [[GLSharedCamera sharedInstance] flipCamera];
        [[GLSharedCamera sharedInstance] createMainScrollView];
        //        [[GLSharedCamera sharedInstance] ]
    }
}

- (IBAction)libraryProfilePick:(id)sender {
    
    
    self.needToReUpload = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.originalPictureView.alpha = 0;
        //        self.originalPictureView.alpha = 0;
        self.galButton.alpha = 0;
        self.capButton.alpha = 0;
        //        self.goButton.alpha = 1;
        //        self.xButton.alpha = 1;
    }];
    [self openAppleImagePicker];
    //    [[GLContainersViewController sharedInstance] openAppleImagePicker];
    //    [[GLSharedCamera sharedInstance] captureTapped];
    
}

- (IBAction)backToCamBut:(id)sender {
    
    self.needToReUpload = NO;
    if(self.origiPictureTapped){
        
        [UIView animateWithDuration:0.2 animations:^{
            self.xButton.alpha = 0;
            self.goButton.alpha = 0;
            
            [[[GLSharedCamera sharedInstance] mainScrollView] setAlpha:1];
            
            //            self.userPhoto.image = image;
            self.originalPictureView.alpha = 1;
            self.galButton.alpha = 1;
            self.capButton.alpha = 1;
            self.goButton.alpha = 0;
            self.xButton.alpha = 0;
            self.origiPictureTapped = NO;
            //            self.origiPictureTapped = NO;
            
        } completion:^(BOOL finished) {
            //            [[GLSharedCamera sharedInstance] backToCameraFromEditPallette:sender];
        }];
        
    } else {
        
        [UIView animateWithDuration:0.2 animations:^{
            self.xButton.alpha = 0;
            self.galButton.alpha = 1;
            self.capButton.alpha = 1;
            self.goButton.alpha = 0;
            self.originalPictureView.alpha = 1;
        } completion:^(BOOL finished) {
            [[GLSharedCamera sharedInstance] backToCameraFromEditPallette:sender];
        }];
        
    }
    
    
    
    
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    pickerIsOpen = NO;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.xButton.alpha = 0;
        self.galButton.alpha = 1;
        self.capButton.alpha = 1;
        self.goButton.alpha = 0;
        self.originalPictureView.alpha = 1;
    } completion:^(BOOL finished) {
        [[GLSharedCamera sharedInstance] backToCameraFromEditPallette:self.xButton];
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    pickerIsOpen = NO;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.xButton.alpha = 1;
        self.goButton.alpha = 1;
    } completion:^(BOOL finished) {
        
        [[[GLSharedCamera sharedInstance] videoCamera] stopCameraCapture];
        [self dismissViewControllerAnimated:YES completion:^{
            [[GLSharedCamera sharedInstance] retrievePhotoFromLoginPicker:info[UIImagePickerControllerEditedImage]];
        }];
        
    }];
    
    
}

@end
