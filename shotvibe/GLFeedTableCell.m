//
//  GLFeedTableCell.m
//  shotvibe
//
//  Created by Tsah Kashkash on 26/10/2015.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import "GLFeedTableCell.h"

@implementation GLFeedTableCell

- (void)awakeFromNib {
    // Initialization code
    NSLog(@"testtest");
    self.profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 60, 60)];
    [self addSubview:self.profileImageView];
    
    self.userName = [[UILabel alloc] initWithFrame:CGRectMake(80, 10, [[UIScreen mainScreen] bounds].size.width*0.5, 60)];
    self.userName.backgroundColor = [UIColor whiteColor];
    self.userName.textColor = UIColorFromRGB(0x626262);
    self.userName.font = [UIFont fontWithName:@"GothamRounded-Book" size:16];
    [self addSubview:self.userName];
    
    self.postedTime = [[UILabel alloc] initWithFrame:CGRectMake(self.userName.frame.size.width+self.userName.frame.origin.x+10, 10, [[UIScreen mainScreen] bounds].size.width*0.22, 60)];
    
    self.postedTime.backgroundColor = [UIColor whiteColor];
    self.postedTime.textAlignment = NSTextAlignmentRight;
    self.postedTime.font = [UIFont fontWithName:@"GothamRounded-Book" size:16];
    self.postedTime.textColor = UIColorFromRGB(0x626262);
    
    [self addSubview:self.postedTime];
    
    self.postImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 80, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height*0.75)];
    self.postedTime.contentMode = UIViewContentModeScaleAspectFit;
    self.postImage.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.postImage];
    
    self.postPannelWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, (self.postImage.frame.origin.y+self.postImage.frame.size.height)-self.postImage.frame.size.height*0.3, [[UIScreen mainScreen] bounds].size.width, self.postImage.frame.size.height*0.3)];
    
    self.commentScrollBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, self.postImage.frame.size.height*0.3)];
    self.commentScrollBgView.backgroundColor = [UIColor blackColor];
    self.commentScrollBgView.alpha = 0.5;
    
    
    
    
    self.commentsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 65, [[UIScreen mainScreen] bounds].size.width, 69)];
    self.commentsScrollView.pagingEnabled = YES;
    self.commentsScrollView.backgroundColor = [UIColor clearColor];
    
    
    self.addCommentButton = [[UIButton alloc] initWithFrame:CGRectMake(26, 38, 15, 20)];
    [self.addCommentButton setBackgroundImage:[UIImage imageNamed:@"feedCommentIcon"] forState:UIControlStateNormal];
    
    
    self.glancesCounter = [[UILabel alloc] initWithFrame:CGRectMake(self.addCommentButton.frame.origin.x+self.addCommentButton.frame.size.width, 26, 45, 35)];
    self.glancesCounter.backgroundColor = [UIColor clearColor];
    self.glancesCounter.text = @"5";
    self.glancesCounter.textAlignment = NSTextAlignmentCenter;
    self.glancesCounter.textColor = [UIColor whiteColor];
    self.glancesCounter.font = [UIFont fontWithName:@"GothamRounded-Book" size:42];
    
    self.glancesIcon = [[UIImageView alloc] initWithFrame:CGRectMake(self.glancesCounter.frame.size.width+self.glancesCounter.frame.origin.x, self.glancesCounter.frame.origin.y+3.5, self.frame.size.width/7, 27)];
    self.glancesIcon.userInteractionEnabled = YES;
    self.glancesIcon.image = [UIImage imageNamed:@"glancesIconRegular"];
    
    
    self.postForwardButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width-40, 28, 25, 25)];
    [self.postForwardButton setBackgroundImage:[UIImage imageNamed:@"feedMoveImageIcon"] forState:UIControlStateNormal];
    
    
    self.commentTextField = [[UITextField alloc] initWithFrame:CGRectMake(self.addCommentButton.frame.origin.x+self.addCommentButton.frame.size.width+10,self.glancesCounter.frame.origin.y+2, 0,35)];
    self.commentTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.commentTextField.font = [UIFont systemFontOfSize:15];
    self.commentTextField.placeholder = @"C'mon say somthing";
    //    cell.commentTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.commentTextField.keyboardType = UIKeyboardTypeDefault;
    self.commentTextField.returnKeyType = UIReturnKeyDone;
    //    cell.commentTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    //    cell.commentTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    self.commentTextField.keyboardAppearance = UIKeyboardAppearanceDark;
    
    self.postImage.alpha = 0;
    
    [self.postPannelWrapper addSubview:self.commentScrollBgView];
    [self addSubview:self.postPannelWrapper];
    [self.postPannelWrapper addSubview:self.commentsScrollView];
    [self.postPannelWrapper addSubview:self.commentTextField];
    [self.postPannelWrapper addSubview:self.glancesCounter];
    [self.postPannelWrapper addSubview:self.postForwardButton];
    [self.postPannelWrapper addSubview:self.addCommentButton];
    [self.postPannelWrapper addSubview:self.glancesIcon];

}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        
        
        
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
