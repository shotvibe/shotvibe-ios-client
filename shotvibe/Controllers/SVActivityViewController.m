//
//  SVActivityViewController.m
//  shotvibe
//
//  Created by Baluta Cristian on 20/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVActivityViewController.h"

@interface SVActivityViewController ()

@end

@implementation SVActivityViewController

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
	// Do any additional setup after loading the view.
	
	//self.view.backgroundColor = [UIColor whiteColor];
//	UIActivityListView *listView;
	
	for (UIView *v in self.view.subviews) {
		NSLog(@"%@", v);
		for (UIView *v1 in v.subviews) {
			NSLog(@"%@", v1);
		}
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
