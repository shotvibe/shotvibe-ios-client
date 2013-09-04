
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
	NSDictionary *userInfo = [[NSDictionary alloc] init];
        
	NSString *text = [userInfo objectForKey:@"text"];
	UIImage *image = [userInfo objectForKey:@"image"];
	NSURL *url = [userInfo objectForKey:@"url"];
	if (text)
		[UIPasteboard generalPasteboard].string = self.activityTitle;
	if (url)
		[UIPasteboard generalPasteboard].URL = url;
	if (image) {
		NSData *imageData = UIImageJPEGRepresentation(image, 0.75f);
		[[UIPasteboard generalPasteboard] setData:imageData
								forPasteboardType:[UIPasteboardTypeListImage objectAtIndex:0]];
	}
}

@end
