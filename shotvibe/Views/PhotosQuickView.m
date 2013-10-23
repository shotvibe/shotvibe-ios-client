//
//  PhotosQuickView.m
//  shotvibe
//
//  Created by Baluta Cristian on 23/10/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "PhotosQuickView.h"

@implementation PhotosQuickView {
	BOOL s;
}

- (id)initWithFrame:(CGRect)frame delegate:(id)d
{
    self = [super initWithFrame:frame delegate:d];
    if (self) {
        s = YES;
		self.selectionButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width-60, 0, 60, 60)];
		[self.selectionButton setImage:[UIImage imageNamed:@"imageSelected.png"] forState:UIControlStateNormal];
		[self.selectionButton addTarget:self action:@selector(checkmarkTouched:) forControlEvents:UIControlEventTouchUpInside];
		
		self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];
    }
    return self;
}


- (void)checkmarkTouched:(id)sender {
	s = !s;
	[self.selectionButton setImage:[UIImage imageNamed:s?@"imageSelected.png":@"imageUnselected.png"] forState:UIControlStateNormal];
	[self.quickDelegate photoDidCheck:self.indexPath];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[self.quickDelegate photoDidClose:self];
}

@end
