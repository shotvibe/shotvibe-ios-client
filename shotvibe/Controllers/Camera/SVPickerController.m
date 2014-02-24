//
//  SBPickerController.m
//  shotvibe
//
//  Created by Salvatore Balzano on 20/01/14.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVPickerController.h"
#import "SVPictureConfirmViewController.h"
#import "SVImagePickerController.h"

@interface SVPickerController ()

@property (nonatomic) BOOL shouldShowPicker;

@end

@implementation SVPickerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.shouldShowPicker = YES;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.shouldShowPicker) {
        //When dismissing a picker, we don't want to show it again
        SVImagePickerController *picker = [[SVImagePickerController alloc] init];

#if (TARGET_IPHONE_SIMULATOR)
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
#else
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
#endif
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *originalImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    UIImage *scaledImage = originalImage;

    // Take as many pictures as you want. Save the path and the thumb and the picture
    __block NSString *filePath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i.jpg", self.container.images.count]];
    __block NSString *thumbPath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i_thumb.jpg", self.container.images.count]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Save large image
        [UIImageJPEGRepresentation(scaledImage, 1.0) writeToFile:filePath atomically:YES];

        CGSize newSize = CGSizeMake(200, 200);
        float oldWidth = scaledImage.size.width;
        float scaleFactor = newSize.width / oldWidth;
        float newHeight = scaledImage.size.height * scaleFactor;
        float newWidth = oldWidth * scaleFactor;

        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
        [scaledImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
        UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        // Save thumb image
        [UIImageJPEGRepresentation(thumbImage, 0.5) writeToFile:thumbPath atomically:YES];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kPickedImageSaved" object:nil];
        }


                       );
    }


                   );


    if (self.container) {
        //This code is called when we're taking subsequent images
        [self.container.images addObject:filePath];
        self.container.waitingForMostRecentImage = YES;

        self.shouldShowPicker = NO;
        [self dismissViewControllerAnimated:NO completion:^{
            [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        }


        ];
    } else {
        //This code is called when we're taking the first image
        SVPictureConfirmViewController *c = [[SVPictureConfirmViewController alloc] init];
        c.images = [NSMutableArray arrayWithObject:filePath];
        c.waitingForMostRecentImage = YES;
        c.albumId = self.albumId;
        c.albumManager = self.albumManager;

        self.shouldShowPicker = NO;
        [self dismissViewControllerAnimated:NO completion:^{
            [self.navigationController pushViewController:c animated:NO];
        }


        ];
    }
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    self.shouldShowPicker = NO;
    [self dismissViewControllerAnimated:YES completion:^{
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }


    ];
}


@end


@implementation UINavigationController (StatusBarStyle)
- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.topViewController;
}


@end
