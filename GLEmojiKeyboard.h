//
//  GLEmojiKeyboard.h
//  shotvibe
//
//  Created by Tsah Kashkash on 06/01/2016.
//  Copyright © 2016 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GLEmojiKeyboard : NSObject <UIInputViewAudioFeedback>

@property (nonatomic,retain) UIView * view;
@property (nonatomic,retain) UIView * contentView;
@property (nonatomic,retain) UIScrollView * scrollView;
@property (nonatomic,retain) NSArray * allEmojisArray;
@property (nonatomic,retain) NSMutableArray * allEmojisLabelsArray;
@property (nonatomic,retain) UITextField * textField;
-(void)slideKeyBoardIn;
-(void)backSpacePressed;
-(void)slideKeyBoardOut;
- (instancetype)initWithView:(UIView*)view;
@property(nonatomic,retain) UIDynamicAnimator * animator;
@property(nonatomic) int numberOfClicks;

@end
