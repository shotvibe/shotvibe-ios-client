//
//  LDCollectionViewCell.m
//  LivelyDemo
//
//  Created by Patrick Nollet on 07/03/2014.
//
//

#import "LDCollectionViewCell.h"

@implementation LDCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib {
    self.videoBadge = [[UIImageView alloc]initWithFrame:CGRectMake(7, 7, 20, 20)];
    self.videoBadge.alpha = 0;
    self.videoBadge.image = [UIImage imageNamed:@"glanceVideoIcon"];
    [self.cellImage addSubview:self.videoBadge];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc {
//    [_textLabel release];
//    [super dealloc];
}
@end
