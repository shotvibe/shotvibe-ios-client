//
//  RJTextView.m
//  RJTextViewDemo
//
//  Created by Rylan on 3/11/15.
//  Copyright (c) 2015 ArcSoft. All rights reserved.
//

#import "RJTextView.h"
//#import "UIView+ColorUiView.h"

#define TEST_CENTER_ALIGNMENT   0
#define PEN_ICON_SIZE           0
#define EDIT_BOX_LINE           0.0
#define MAX_FONT_SIZE           500
#define MAX_TEXT_LETH           50

#define IS_IOS_7 ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)

@implementation CTextView

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if ( action == @selector(paste:)     ||
         action == @selector(cut:)       ||
         action == @selector(copy:)      ||
         action == @selector(select:)    ||
         action == @selector(selectAll:) ||
         action == @selector(delete:) )
    {
        return NO;
    }
    return [super canPerformAction:action withSender:sender];
}

@end

@interface RJTextView () <UITextViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    BOOL _isDeleting;
}
@property (assign, nonatomic) BOOL        isEditting;
@property (assign, nonatomic) BOOL        hideView;
@property (retain, nonatomic) CTextView   *textView;
@property (retain, nonatomic) UIButton    *editButton;
@property (retain, nonatomic) UIImageView *indicatorView;
@property (retain, nonatomic) UIImageView *scaleView;
@property (retain, nonatomic) UIColor     *tColor;
@property (assign, nonatomic) CGPoint     textCenter;
@property (assign, nonatomic) CGSize      minSize;
@property (assign, nonatomic) CGFloat     minFontSize;
@property (retain, nonatomic) UIFont      *curFont;
@property (nonatomic, retain) UIScrollView * colors;
@property (nonatomic, retain) NSArray * colorArray;
@property (nonatomic, strong) NSMutableArray * colorViewsArray;
@property (nonatomic, strong) NSMutableArray * fonts;
@property (nonatomic, strong) UIScrollView * fontsScroller;

@property (nonatomic) CGFloat oldWidth;
@property (nonatomic) CGFloat oldHeigth;

@end

@implementation RJTextView

- (id)initWithFrame:(CGRect)frame
        defaultText:(NSString *)text
               font:(UIFont *)font
              color:(UIColor *)color
            minSize:(CGSize)minSize
{
    self = [super initWithFrame:frame];
    if (self)
    {
        
        // Custom initialization
        BOOL sExtend = frame.size.height <=0 || frame.size.width <=0;
        BOOL oExtend = frame.origin.x    < 0 || frame.origin.y   < 0;
        
        if (sExtend || oExtend /*|| ![text length]*/) return nil;
        
        [self setBackgroundColor:[UIColor clearColor]];
        self.tColor = color; self.curFont = font; self.minFontSize = font.pointSize;
        [self createTextViewWithFrame:CGRectZero text:nil font:nil];

        UIButton *editButton = [[UIButton alloc] initWithFrame:CGRectZero];
//        [editButton setBackgroundImage:[UIImage imageNamed:@"pe_pen_icon"]
//                              forState:UIControlStateNormal];
//        [editButton setBackgroundImage:[UIImage imageNamed:@"pe_pen_icon_push"]
//                              forState:UIControlStateHighlighted];
        [editButton addTarget:self action:@selector(editTextView)
             forControlEvents:UIControlEventTouchUpInside];
        [editButton setExclusiveTouch:YES]; [self addSubview:editButton];
        [self setEditButton:editButton];// [editButton release];
        
        UIImageView *sView = [[UIImageView alloc] initWithFrame:CGRectZero];
//        [sView setImage:[UIImage imageNamed:@"pe_pen_scale"]];
//        [sView setHighlightedImage:[UIImage imageNamed:@"pe_pen_scale_push"]];
        [sView setUserInteractionEnabled:YES];
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(scaleTextView:)];
        [sView addGestureRecognizer:panGes]; //[panGes release];
        
        [sView setExclusiveTouch:YES]; [self addSubview:sView];
        [self setScaleView:sView]; //[sView release];
        
        [self layoutSubViewWithFrame:frame]; self.isEditting = YES;

        // temp init setting, replace later
        CGFloat cFont = 1; self.textView.text = text; self.minSize = minSize;
        
        if (minSize.height >  frame.size.height ||
            minSize.width  >  frame.size.width  ||
            minSize.height <= 0 || minSize.width <= 0)
        {
            self.minSize = CGSizeMake(frame.size.width/3.f, frame.size.height/3.f);
        }
        CGSize  tSize = IS_IOS_7?[self textSizeWithFont:cFont text:[text length]?nil:@"A"]:CGSizeZero;

        do
        {
            if (IS_IOS_7)
            {
                tSize = [self textSizeWithFont:++cFont text:[text length]?nil:@"A"];
            }
            else
            {
                [self.textView setFont:[self.curFont fontWithSize:++cFont]];
            }
        }
        while (![self isBeyondSize:tSize] && cFont < MAX_FONT_SIZE);
    
        if (cFont < /*self.minFontSize*/0) return nil;
        
        cFont = (cFont < MAX_FONT_SIZE) ? cFont : self.minFontSize;
        [self.textView setFont:[self.curFont fontWithSize:--cFont]];
        
        self.textCenter = CGPointMake(frame.origin.x+frame.size.width/2.f,
                                      frame.origin.y+frame.size.height/2.f);
        
        #if TEST_CENTER_ALIGNMENT
        self.indicatorView = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
        [self.indicatorView setBackgroundColor:[[UIColor redColor] colorWithAlphaComponent:0.5]];
        [self addSubview:self.indicatorView];
        #else
        // ...
        #endif
        
        [self centerTextVertically];
        
        CGRect sizeRect = [UIScreen mainScreen].applicationFrame;
        float width = sizeRect.size.width;
        
        
        self.colorArray = [[NSMutableArray alloc] init];
        self.colorArray = @[ @0x000000, @0x262626, @0x4d4d4d, @0x666666, @0x808080, @0x990000, @0xcc0000, @0xfe0000, @0xff5757, @0xffabab, @0xffabab, @0xffa757, @0xff7900, @0xcc6100, @0x994900, @0x996f00, @0xcc9400, @0xffb900, @0xffd157, @0xffe8ab, @0xfff4ab, @0xffe957, @0xffde00, @0xccb200, @0x998500, @0x979900, @0xcacc00, @0xfcff00, @0xfdff57, @0xfeffab, @0xf0ffab, @0xd2ff00, @0xa8cc00, @0x7e9900, @0x038001, @0x04a101, @0x05c001, @0x44bf41, @0x81bf80, @0x81c0b8, @0x41c0af, @0x00c0a7, @0x00a18c, @0x00806f, @0x040099, @0x0500cc, @0x0600ff, @0x5b57ff, @0xadabff, @0xd8abff, @0xb157ff, @0x6700bf, @0x5700a1, @0x450080, @0x630080, @0x7d00a1, @0x9500c0, @0xa341bf, @0xb180bf, @0xbf80b2, @0xbf41a6, @0xbf0199, @0xa10181, @0x800166, @0x999999, @0xb3b3b3, @0xcccccc, @0xe6e6e6, @0xffffff];
        
        int numOfColors = 69;
        
        
        
        self.colors = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, 50)];
        self.colors.backgroundColor = [UIColor clearColor];
        self.colors.delegate = self;
        
        UITapGestureRecognizer *colorSelectedGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(colorDidSelected:)];
        [colorSelectedGest setDelegate:self];
        
        [self.colors addGestureRecognizer:colorSelectedGest];

        self.colorViewsArray = [[NSMutableArray alloc] init];
        
        for(int x = 0; x < numOfColors;x++){
            
            
            UIView * colorView = [[UIView alloc] initWithFrame:CGRectMake(x*40, 4, 33, 33)];
            colorView.clipsToBounds = NO;
            colorView.layer.cornerRadius = 16.5;
            int c = (int)[self.colorArray objectAtIndex:x];
            colorView.backgroundColor = UIColorFromRGB(c);
            [self.colorViewsArray addObject:colorView];
            [self.colors addSubview:colorView];
            
        }
        
        self.colors.contentSize = CGSizeMake(numOfColors*40,50);
        
        self.fonts = [[NSMutableArray alloc] init];
        for (NSString* family in [UIFont familyNames])
        {
            for (NSString* name in [UIFont fontNamesForFamilyName: family])
            {
                
                if ([name rangeOfString:@"Helvetica"].location == NSNotFound) {
                    //                    NSLog(@"string does not contain bla");
                } else {
                    //                    NSLog(@"string contains bla!");
                    NSLog(@"  %@", name);
                    [self.fonts addObject:name];
                }
                
            }
        }

        self.fontsScroller  = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, width, 40)];
        self.fontsScroller.tag = ScrollerTypeFontsScroller;
        
        self.fontsScroller.backgroundColor = [UIColor clearColor];
        self.fontsScroller.delegate = self;
        
        for(int y = 0; y < 20; y++){
            
            UIView * fontView = [[UIView alloc] initWithFrame:CGRectMake(y * 45, 0, 40, 40)];
            fontView.backgroundColor = [UIColor clearColor];
            
            UILabel * lab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
            lab.textAlignment = NSTextAlignmentCenter;
            lab.text = @"T";
            lab.textColor = [UIColor whiteColor];
            
            [lab setFont:[UIFont fontWithName:[self.fonts objectAtIndex:y] size:18]];
            
            [fontView addSubview:lab];
            
            [self.fontsScroller addSubview:fontView];
            
        }
        self.fontsScroller.contentSize = CGSizeMake(20*45, 40);
        
        UITapGestureRecognizer *fontSelectedGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fontDidSelected:)];
        [self.fontsScroller setDelegate:self];
        [self.fontsScroller addGestureRecognizer:fontSelectedGest];
        
        
        UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 80)];
        numberToolbar.barStyle = UIBarStyleBlackTranslucent;
//        numberToolbar.items = [NSArray arrayWithObjects:
//                               [[UIBarButtonItem alloc]initWithTitle:@"Clear" style:UIBarButtonItemStyleBordered target:self action:@selector(clearNumberPad)],
//                               [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
//                               [[UIBarButtonItem alloc]initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)],
//                               nil];
//        [numberToolbar sizeToFit];
        
        UIView * t = [[UIView alloc] initWithFrame:CGRectMake(0, 0,  width, 50)];
        t.backgroundColor = [UIColor redColor];
        [numberToolbar addSubview:self.colors];
        [numberToolbar addSubview:self.fontsScroller];
        
        self.textView.inputAccessoryView = numberToolbar;
        
    }
    return self;
}

- (void)fontDidSelected:(UITapGestureRecognizer *)tapGesture {
    
    CGPoint touchPoint = [tapGesture locationInView: self.fontsScroller];
    NSLog(@"the x is: %f",(touchPoint.x/45));
    
    int tIndex = floor(touchPoint.x/45);
    
    [UIView transitionWithView:self.textView duration:0.20 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        [self.textView setFont:[UIFont fontWithName:[self.fonts objectAtIndex:tIndex] size:self.textView.font.pointSize]];
        self.textView.transform = CGAffineTransformScale(self.textView.transform, 1.20f, 1.20f);
        
    } completion:^(BOOL finished) {
        [UIView transitionWithView:self.textView duration:0.20 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.textView.transform = CGAffineTransformScale(self.textView.transform, 0.83f, 0.83f);
        } completion:nil];
    }];
    
    
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self.delegate focusOutTextField];
}


//-(void)textFieldDidBeginEditing:(UITextField *)textField
//{
//    [textField selectAll:self];
//    
//}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [textView selectAll:self];
//    });

//    [textView setText:@""];
//    [self.textView selectAll:nil];
//    
//    __weak typeof(self) weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        __strong __typeof(weakSelf) strongSelf = weakSelf;
//        
//    });
    
//    UITextRange *range = [textView textRangeFromPosition:textView.beginningOfDocument toPosition:textView.endOfDocument];
//    [textView setSelectedTextRange:range];
    
    
    
//    [self.textView setSelectedTextRange:range];
    
//    [self.textView setSelectedTextRange:[self.textView textRangeFromPosition:self.textView.beginningOfDocument toPosition:self.textView.endOfDocument]];
    
    [self.delegate focusOnTextField];
    
    return YES;
}

- (void)colorDidSelected:(UITapGestureRecognizer *)tapGesture {
    
    CGPoint touchPoint = [tapGesture locationInView: self.colors];
    NSLog(@"the x is: %f",(touchPoint.x/40));
    
    int tIndex = floor(touchPoint.x/40);
    
    int tempColor = (int)[self.colorArray objectAtIndex:tIndex];

    UIView * selectedColorView = [self.colorViewsArray objectAtIndex:tIndex];
    
    for(UIView * colorV in self.colorViewsArray){
            if(colorV == selectedColorView){
                colorV.clipsToBounds = YES;
                
                [UIView animateWithDuration:0.3 animations:^{
                    
                    colorV.transform = CGAffineTransformScale(colorV.transform, 0.3, 0.3);
                    
                } completion:^(BOOL finished){
                    [UIView animateWithDuration:0.3 animations:^{
                        colorV.transform = CGAffineTransformScale(colorV.transform, 2, 2);
                    }];
                    
                }];
                
            } else {
                if(colorV.clipsToBounds){
                    colorV.clipsToBounds = NO;
                    [UIView animateWithDuration:0.3 animations:^{
                        colorV.transform = CGAffineTransformScale(colorV.transform, 1.6, 1.6);
                    }];
                }
            }
    }

    
    [UIView transitionWithView:self.textView duration:0.20 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [self.textView setTextColor:UIColorFromRGB(tempColor)];
        self.textView.transform = CGAffineTransformScale(self.textView.transform, 1.20f, 1.20f);
    } completion:^(BOOL finished) {
        [UIView transitionWithView:self.textView duration:0.20 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
         self.textView.transform = CGAffineTransformScale(self.textView.transform, 0.83f, 0.83f);
        } completion:nil];
    }];
    
}


- (void)createTextViewWithFrame:(CGRect)frame text:(NSString *)text font:(UIFont *)font
{
    CTextView *textView = [[CTextView alloc] initWithFrame:frame];
    textView.delegate = self;
    
    textView.scrollEnabled = NO; [textView setDelegate:self];
//    textView.keyboardType  = UIKeyboardTypeASCIICapable;
    textView.returnKeyType = UIReturnKeyDone;
    textView.keyboardAppearance = UIKeyboardAppearanceAlert;
    textView.textAlignment = NSTextAlignmentCenter;

    [textView setBackgroundColor:[UIColor clearColor]];
    [textView setTextColor:self.tColor];
    [textView setText:text];
    [textView setFont:font];
    [textView setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self addSubview:textView]; [self sendSubviewToBack:textView];
    
    if (IS_IOS_7)
    {
        textView.textContainerInset = UIEdgeInsetsZero;
    }
    else
    {
        textView.contentOffset = CGPointZero;
    }
    
    [self setTextView:textView]; //[textView release];
}

- (void)layoutSubViewWithFrame:(CGRect)frame
{
    CGRect tRect = frame;
    
    tRect.size.width  = self.frame.size.width -PEN_ICON_SIZE-EDIT_BOX_LINE;
    tRect.size.height = self.frame.size.height-PEN_ICON_SIZE-EDIT_BOX_LINE;
    
    tRect.origin.x = (self.frame.size.width -tRect.size.width) /2.;
    tRect.origin.y = (self.frame.size.height-tRect.size.height)/2.;
    
    [self.textView setFrame:tRect];

    [self.editButton setFrame:CGRectMake(0, self.frame.size.height-PEN_ICON_SIZE,
                                         PEN_ICON_SIZE, PEN_ICON_SIZE)];
    [self.scaleView  setFrame:CGRectMake(self.frame.size.width-PEN_ICON_SIZE,
                                         0, PEN_ICON_SIZE, PEN_ICON_SIZE)];
}

- (void)editTextView
{
    NSString *text = self.textView.text;  UIFont *font = self.textView.font;
    CGRect   frame = self.textView.frame; [self.textView removeFromSuperview];
    
    self.isEditting = YES; [self showTextViewBox];
    
    [self createTextViewWithFrame:frame text:text font:font];
    [self centerTextVertically]; [self.textView becomeFirstResponder];
}

- (void)hideTextViewBox
{
    [self.editButton setHidden:YES];
    [self.scaleView  setHidden:YES];

    [self endEditing:YES]; self.isEditting = NO;    
    self.hideView = YES; [self setNeedsDisplay];
}

- (void)showTextViewBox
{
    [self.editButton setHidden:NO];
    [self.scaleView  setHidden:NO];
    
    self.hideView = NO;  [self setNeedsDisplay];
}

- (void)scaleTextViewByFrame:(CGRect)frame {
    
    
    self.frame = frame;
    
    CGPoint translation = frame.origin;
    CGFloat x = translation.x;
    CGFloat y = -translation.y;
    

    CGFloat wScale = x / self.frame.size.width +1;
    CGFloat hScale = y / self.frame.size.height+1;
    
    CGFloat scale    = MIN(wScale, hScale);
    CGRect  tempRect = self.frame;
    tempRect.size.width  *= scale;
    tempRect.size.height *= scale;
    

    BOOL beyondMin = tempRect.size.width <self.minSize.width ||
    tempRect.size.height<self.minSize.height;
    
    if (x < 0 && beyondMin) tempRect.size = self.minSize;
    
    tempRect.origin.x = self.textCenter.x- tempRect.size.width/2;
    tempRect.origin.y = self.textCenter.y-tempRect.size.height/2;
    
    if (tempRect.origin.x < 0)
    {
        CGPoint pC = self.textCenter;
        
        pC.x = tempRect.size.width/2.f;  self.textCenter = pC;
    }
    
    if (tempRect.origin.y < 0)
    {
        CGPoint pC = self.textCenter;
        
        pC.y = tempRect.size.height/2.f; self.textCenter = pC;
    }
    
    if (tempRect.origin.x+tempRect.size.width > self.superview.frame.size.width)
    {
        CGPoint pC = self.textCenter;
        pC.x -= (tempRect.origin.x+tempRect.size.width-self.superview.frame.size.width);
        self.textCenter = pC;
    }
    
    if (tempRect.origin.y+tempRect.size.height > self.superview.frame.size.height)
    {
        CGPoint pC = self.textCenter;
        pC.y -= (tempRect.origin.y+tempRect.size.height-self.superview.frame.size.height);
        self.textCenter = pC;
    }
    
    [self setFrame:tempRect]; [self setCenter:self.textCenter];
    
    [self layoutSubViewWithFrame:tempRect];
    
    if (IS_IOS_7)
    {
        self.textView.textContainerInset = UIEdgeInsetsZero;
    }
    else
    {
        self.textView.contentOffset = CGPointZero;
    }
    
    if ([self.textView.text length])
    {
        CGFloat cFont = self.textView.font.pointSize;
        CGSize  tSize = IS_IOS_7?[self textSizeWithFont:cFont text:nil]:CGSizeZero;
        
        if (x > 0.f && y > 0.f)
        {
            do
            {
                if (IS_IOS_7)
                {
                    tSize = [self textSizeWithFont:++cFont text:nil];
                }
                else
                {
                    [self.textView setFont:[self.curFont fontWithSize:++cFont]];
                }
            }
            while (![self isBeyondSize:tSize] && cFont < MAX_FONT_SIZE);
            
            cFont = (cFont < MAX_FONT_SIZE) ? cFont : self.minFontSize;
            [self.textView setFont:[self.curFont fontWithSize:--cFont]];
        }
        else
        {
            while ([self isBeyondSize:tSize] && cFont > 0)
            {
                if (IS_IOS_7)
                {
                    tSize = [self textSizeWithFont:--cFont text:nil];
                }
                else
                {
                    [self.textView setFont:[self.curFont fontWithSize:--cFont]];
                }
            }
            
            [self.textView setFont:[self.curFont fontWithSize:cFont]];
        }
    }

    CGFloat cFont = self.textView.font.pointSize;
    CGSize  tSize = [self textSizeWithFont:cFont text:nil];
    do
    {
        
        tSize = [self textSizeWithFont:++cFont text:nil];
        
    }
    while (![self isBeyondSize:tSize] && cFont < MAX_FONT_SIZE);
    
    cFont = (cFont < MAX_FONT_SIZE) ? cFont : self.minFontSize;
    [self.textView setFont:[self.curFont fontWithSize:--cFont]];
    
    
    [self centerTextVertically]; [self setNeedsDisplay];
    
    
}

- (void)scaleTextView:(UIPanGestureRecognizer *)panGes {
    if (panGes.state == UIGestureRecognizerStateBegan)
    {
//        [self endEditing:YES]; self.isEditting = NO;
        self.textCenter = self.center; [self.scaleView setHighlighted:YES];
    }
    
    if (panGes.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [panGes translationInView:self];
        CGFloat x = translation.x;
        CGFloat y = -translation.y;

//        if ( (x >  2.f && y >  2.f ) || (x < -2.f && y < -2.f) )
//        {
            CGFloat wScale = x / self.frame.size.width +1;
            CGFloat hScale = y / self.frame.size.height+1;
        
            CGFloat scale    = MIN(wScale, hScale);
            CGRect  tempRect = self.frame;
            tempRect.size.width  *= scale;
            tempRect.size.height *= scale;

            if (x > 0.f && y > 0.f) // zoom out
            {
                CGFloat cX = self.superview.frame.size.width -tempRect.size.width;
                CGFloat cY = self.superview.frame.size.height-tempRect.size.height;
                
                if (cX > 0 && cY < 0)
                {
                    CGFloat scale = tempRect.size.width/tempRect.size.height;
                    tempRect.size.height += cY;
                    tempRect.size.width   = tempRect.size.height*scale;
                }
                else if (cX < 0 && cY > 0)
                {
                    CGFloat scale = tempRect.size.height/tempRect.size.width;
                    tempRect.size.width += cX;
                    tempRect.size.height = tempRect.size.width*scale;
                }
                else if (cX < 0 && cY < 0)
                {
                    if (cX < cY)
                    {
                        CGFloat scale = tempRect.size.height/tempRect.size.width;
                        tempRect.size.width += cX;
                        tempRect.size.height = tempRect.size.width*scale;
                    }
                    else
                    {
                        CGFloat scale = tempRect.size.width/tempRect.size.height;
                        tempRect.size.height += cY;
                        tempRect.size.width   = tempRect.size.height*scale;
                    }
                }
            }
            
            BOOL beyondMin = tempRect.size.width <self.minSize.width ||
                             tempRect.size.height<self.minSize.height;
            
            if (x < 0 && beyondMin) tempRect.size = self.minSize;
            
            tempRect.origin.x = self.textCenter.x- tempRect.size.width/2;
            tempRect.origin.y = self.textCenter.y-tempRect.size.height/2;

            if (tempRect.origin.x < 0)
            {
                CGPoint pC = self.textCenter;
                
                pC.x = tempRect.size.width/2.f;  self.textCenter = pC;
            }
            
            if (tempRect.origin.y < 0)
            {
                CGPoint pC = self.textCenter;
                
                pC.y = tempRect.size.height/2.f; self.textCenter = pC;
            }
            
            if (tempRect.origin.x+tempRect.size.width > self.superview.frame.size.width)
            {
                CGPoint pC = self.textCenter;
                pC.x -= (tempRect.origin.x+tempRect.size.width-self.superview.frame.size.width);
                self.textCenter = pC;
            }
            
            if (tempRect.origin.y+tempRect.size.height > self.superview.frame.size.height)
            {
                CGPoint pC = self.textCenter;
                pC.y -= (tempRect.origin.y+tempRect.size.height-self.superview.frame.size.height);
                self.textCenter = pC;
            }

            [self setFrame:tempRect]; [self setCenter:self.textCenter];

            [self layoutSubViewWithFrame:tempRect];
            
            if (IS_IOS_7)
            {
                self.textView.textContainerInset = UIEdgeInsetsZero;
            }
            else
            {
                self.textView.contentOffset = CGPointZero;
            }
            
            if ([self.textView.text length])
            {
                CGFloat cFont = self.textView.font.pointSize;
                CGSize  tSize = IS_IOS_7?[self textSizeWithFont:cFont text:nil]:CGSizeZero;
                
                if (x > 0.f && y > 0.f)
                {
                    do
                    {
                        if (IS_IOS_7)
                        {
                            tSize = [self textSizeWithFont:++cFont text:nil];
                        }
                        else
                        {
                            [self.textView setFont:[self.curFont fontWithSize:++cFont]];
                        }
                    }
                    while (![self isBeyondSize:tSize] && cFont < MAX_FONT_SIZE);
                    
                    cFont = (cFont < MAX_FONT_SIZE) ? cFont : self.minFontSize;
                    [self.textView setFont:[self.curFont fontWithSize:--cFont]];
                }
                else
                {
                    while ([self isBeyondSize:tSize] && cFont > 0)
                    {
                        if (IS_IOS_7)
                        {
                            tSize = [self textSizeWithFont:--cFont text:nil];
                        }
                        else
                        {
                            [self.textView setFont:[self.curFont fontWithSize:--cFont]];
                        }
                    }
                    
                    [self.textView setFont:[self.curFont fontWithSize:cFont]];
                }
            }
            
//            if (!IS_IOS_7) // solve strange bugs for iOS 6
//            {
//                NSString *text = self.textView.text; UIFont *font = self.textView.font;
//                CGRect frame = self.textView.frame; [self.textView removeFromSuperview];
//                
//                [self createTextViewWithFrame:frame text:text font:font];
//            }
        
            [self centerTextVertically]; [self setNeedsDisplay];
            [panGes setTranslation:CGPointZero inView:self];
//        }
    }

    if (panGes.state == UIGestureRecognizerStateEnded     ||
        panGes.state == UIGestureRecognizerStateCancelled ||
        panGes.state == UIGestureRecognizerStateFailed    )
    {
        [self.scaleView setHighlighted:NO]; [self centerTextVertically];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [self endEditing:YES];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidEndEditing:)])
        {
            [self.delegate textViewDidEndEditing:self];
        }
        return NO;
    }
    
    _isDeleting = (range.length >= 1 && text.length == 0);
    
    if (textView.font.pointSize <= self.minFontSize && !_isDeleting) return NO;
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSString *calcStr = textView.text;
    
    if (![textView.text length]) [self.textView setText:@"A"];
    
    CGFloat cFont = self.textView.font.pointSize;
    CGSize  tSize = IS_IOS_7?[self textSizeWithFont:cFont text:nil]:CGSizeZero;
    
    if (IS_IOS_7)
    {
        self.textView.textContainerInset = UIEdgeInsetsZero;
    }
    else
    {
        self.textView.contentOffset = CGPointZero;
    }
    
    if (_isDeleting)
    {
        do
        {
            if (IS_IOS_7)
            {
                tSize = [self textSizeWithFont:++cFont text:nil];
            }
            else
            {
                [self.textView setFont:[self.curFont fontWithSize:++cFont]];
            }
        }
        while (![self isBeyondSize:tSize] && cFont < MAX_FONT_SIZE);
        
        cFont = (cFont < MAX_FONT_SIZE) ? cFont : self.minFontSize;
        [self.textView setFont:[self.curFont fontWithSize:--cFont]];
    }
    else
    {
        while ([self isBeyondSize:tSize] && cFont > 0)
        {
            if (IS_IOS_7)
            {
                tSize = [self textSizeWithFont:--cFont text:nil];
            }
            else
            {
                [self.textView setFont:[self.curFont fontWithSize:--cFont]];
            }
        }
        
        [self.textView setFont:[self.curFont fontWithSize:cFont]];
    }
    
    [self centerTextVertically]; [self.textView setText:calcStr];
}

- (CGSize)textSizeWithFont:(CGFloat)font text:(NSString *)string
{
    NSString *text = string ? string : self.textView.text;
    
    CGFloat pO = self.textView.textContainer.lineFragmentPadding * 2;
    CGFloat cW = self.textView.frame.size.width - pO;
    
    CGSize  tH = [text sizeWithFont:[self.curFont fontWithSize:font]
                  constrainedToSize:CGSizeMake(cW, MAXFLOAT)
                      lineBreakMode:NSLineBreakByWordWrapping];
    return  tH;
}

- (BOOL)isBeyondSize:(CGSize)size
{
    if (IS_IOS_7)
    {
        CGFloat ost = _textView.textContainerInset.top + _textView.textContainerInset.bottom;
        
        return size.height + ost > self.textView.frame.size.height;
    }
    else
    {
        return self.textView.contentSize.height > self.textView.frame.size.height;
    }
}

- (void)centerTextVertically
{
    if (IS_IOS_7)
    {
        CGSize  tH     = [self textSizeWithFont:self.textView.font.pointSize text:nil];
        CGFloat offset = (self.textView.frame.size.height - tH.height)/2.f;
        
        self.textView.textContainerInset = UIEdgeInsetsMake(offset, 0, offset, 0);
    }
    else
    {
        CGFloat fH = self.textView.frame.size.height;
        CGFloat cH = self.textView.contentSize.height;
        
        [self.textView setContentOffset:CGPointMake(0, (cH-fH)/2.f)];
    }
    
    #if TEST_CENTER_ALIGNMENT
    [self.indicatorView setFrame:CGRectMake(0, offset, self.frame.size.width, tH.height)];
    #else
    // ...
    #endif
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetRGBStrokeColor(context, 1, 1, 1, !_hideView);
    CGContextSetLineWidth(context, EDIT_BOX_LINE);
    
    CGRect drawRect       = self.textView.frame;
    drawRect.size.width  += EDIT_BOX_LINE;
    drawRect.size.height += EDIT_BOX_LINE;
    drawRect.origin.x     = (self.frame.size.width-drawRect.size.width)/2.f;
    drawRect.origin.y     = (self.frame.size.height-drawRect.size.height)/2.f;

    CGContextAddRect(context, drawRect);
    
    CGContextStrokePath(context);
}


@end
