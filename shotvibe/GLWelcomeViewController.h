//
//  GLWelcomeViewController.h
//  shotvibe
//
//  Created by Tsah Kashkash on 05/11/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^CompletionBlock2)(id);

@interface GLWelcomeViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *orCreateAccountButton;
@property (weak, nonatomic) IBOutlet UIImageView *dmut;
@property (readwrite, copy) CompletionBlock2 onClose;
@end
