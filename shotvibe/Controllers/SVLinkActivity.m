
#import "SVLinkActivity.h"

@implementation SVLinkActivity


- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Get link", @"");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"IconLink.png"];
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
	if (self.sharingUrl) {
		[UIPasteboard generalPasteboard].URL = self.sharingUrl;
	}
}

@end
