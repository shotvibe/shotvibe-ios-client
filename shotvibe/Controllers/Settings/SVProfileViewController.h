//
//  SVProfileViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 4/16/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SL/AlbumManager.h"
#import "SVProfilePicViewController.h"


@interface SVProfileViewController : UIViewController <UITextFieldDelegate, SVImageCropDelegate>

@property (nonatomic, assign) BOOL fromSettings;
@property (nonatomic, assign) BOOL shouldPrompt; // if YES, prompt the user to change the nickname and avatar
- (IBAction)goPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *goButton;
@property (weak, nonatomic) IBOutlet UIImageView *image1;
@property (weak, nonatomic) IBOutlet UIButton *openProfilePicEditorButton;
@property (weak, nonatomic) IBOutlet UIView *textFieldWrapper;

@end
