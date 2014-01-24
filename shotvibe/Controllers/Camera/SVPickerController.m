//
//  SBPickerController.m
//  test
//
//  Created by Salvatore Balzano on 20/01/14.
//  Copyright (c) 2014 MobiApps. All rights reserved.
//

#import "SVPickerController.h"
#import "SVPictureConfirmViewController.h"

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
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];

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
    NSMutableArray *array = [NSMutableArray array];
    [array addObjectsFromArray:self.container.images];

    UIImage *originalImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    UIImage *scaledImage = originalImage;

    // Take as many pictures as you want. Save the path and the thumb and the picture
    __block NSString *filePath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i.jpg", array.count]];
    __block NSString *thumbPath = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Library/Caches/Photo%i_thumb.jpg", array.count]];

    [array addObject:filePath];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
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

//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.albumPreviewImage.image = thumbImage;
//        });
    }


                   );

    if (self.container) {
        //This code is called when we're taking subsequent images
        self.container.images = array;
        self.shouldShowPicker = NO;
        [self dismissViewControllerAnimated:YES completion:^{
            [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        }


        ];
    } else {
        //This code is called when we're taking the first image
        SVPictureConfirmViewController *c = [[SVPictureConfirmViewController alloc] init];
        c.images = array;
        c.albumId = self.albumId;
        c.albumManager = self.albumManager;

        self.shouldShowPicker = NO;
        [self dismissViewControllerAnimated:NO completion:^{
            [self.navigationController pushViewController:c animated:YES];
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
