//
//  SVImageCropViewController.h
//  shotvibe
//
//  Created by Baluta Cristian on 17/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SVImageCropDelegate <NSObject>
@required
- (void)didCropImage:(UIImage *)thePhoto;
@end


@interface SVImageCropViewController : UIViewController {
	
	IBOutlet UIScrollView *scrollView;
	IBOutlet UIView *topView;
	IBOutlet UIView *bottomView;
	UIImageView *imageView;
}

@property (nonatomic) id <SVImageCropDelegate> delegate;
@property (nonatomic, retain) UIImage *image;

@end

