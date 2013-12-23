
#import "SVCopyActivity.h"

@implementation SVCopyActivity


- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Copy", @"");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"IconCopy.png"];
}

-(BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
	
}

- (void)performActivity
{
	if (self.sharingImage) {
		NSData *imageData = UIImageJPEGRepresentation(self.sharingImage, 0.75f);
		[[UIPasteboard generalPasteboard] setData:imageData
								forPasteboardType:[UIPasteboardTypeListImage objectAtIndex:0]];
	}
}

@end
