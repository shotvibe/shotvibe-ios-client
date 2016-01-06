//
//  GLEmojiKeyboard.h
//  shotvibe
//
//  Created by Tsah Kashkash on 06/01/2016.
//  Copyright © 2016 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLEmojiKeyboard : NSObject

@property (nonatomic,retain) UIView * view;
@property (nonatomic,retain) UIScrollView * scrollView;
@property (nonatomic,retain) NSArray * allEmojisArray;
-(void)slideKeyBoardIn;

@end
