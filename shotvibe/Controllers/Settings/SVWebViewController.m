//
//  SVWebViewController.m
//  shotvibe
//
//  Created by Baluta Cristian
//  Copyright (c) 2013 Baluta Cristian. All rights reserved.
//
#import "SVWebViewController.h"

@implementation SVWebViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.url]];
    [self.webView loadRequest:req];
}

//- (void) setUrl:(NSString *)url {
//	
//	
//}

@end
