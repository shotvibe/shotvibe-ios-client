#import "PageControl.h"

@implementation PageControl

-(void) updateDots {
    for (int i = 0; i < [self.subviews count]; i++)
    {
        UIView* dotView = [self.subviews objectAtIndex:i];
        UIImageView* dot = nil;
        
        for (UIView* subview in dotView.subviews)
        {
            if ([subview isKindOfClass:[UIImageView class]])
            {
                dot = (UIImageView*)subview;
                break;
            }
        }
        
        if (dot == nil)
        {
            dot = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 9, 9)];
            [dotView addSubview:dot];
        }
        
        if (i == self.currentPage)
        {
            dot.image = [UIImage imageNamed:@"PageControlDotSelected"];
        }
        else
        {
            dot.image = [UIImage imageNamed:@"PageControlDotUnselected"];
        }
    }
}

-(void) setCurrentPage:(NSInteger)page {
    [super setCurrentPage:page];
    [self updateDots];
}

@end
