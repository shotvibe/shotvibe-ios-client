//
//  SVProfileViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SL/AlbumManager.h"
#import "GLProfilePictureController.h"
#import "GLSharedCamera.h"


@interface GLProfilePictureController : UIViewController <UITextFieldDelegate,GLSharedCameraDelegatte,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, assign) BOOL shouldPrompt; // if YES, prompt the user to change the nickname and avatar
@property (weak, nonatomic) IBOutlet UIButton *goButton;
- (IBAction)goPressed:(id)sender;
- (IBAction)captureSelfie:(id)sender;
- (IBAction)libraryProfilePick:(id)sender;
- (IBAction)backToCamBut:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *xButton;
@property (weak, nonatomic) IBOutlet UIButton *goPressed;
@property (weak, nonatomic) IBOutlet UIImageView *originalPictureView;
@property (nonatomic) BOOL needToReUpload;
@property (nonatomic) BOOL origiPictureTapped;
@property (weak, nonatomic) IBOutlet UIButton *capButton;
@property(nonatomic) BOOL fromSettings;
@property (weak, nonatomic) IBOutlet UIButton *galButton;

@end
