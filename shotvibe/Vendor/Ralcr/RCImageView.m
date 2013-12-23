//
//  RCImageView.m
//  IMAGIN
//
//  Created by Baluta Cristian on 4/7/10.
//  Copyright 2010 ralcr. All rights reserved.
//

#import "RCImageView.h"
#import "UIImageView+WebCache.h"
#import "SDImageCache.h"


@implementation RCImageView
@synthesize imageData, i, referer;


- (id)initWithFrame:(CGRect)frame delegate:(id<RCImageViewDelegate>)d {
	self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		delegate = d;
		i = -1;
		self.contentMode = UIViewContentModeScaleAspectFit;
		self.autosize = NO;
		//self.backgroundColor = [UIColor redColor];
    }
    return self;
}


- (void)cancel {
	[connection cancel];
	connection = nil;
	imageData = nil;
}



#pragma mark Load photo

- (void)loadNetworkImage:(NSString *)path {
	
	// Use the SDWebCache to load and cache the pictures
	__block id delegate_ = delegate;
	__block int i_ = i;
	[self setImageWithURL:[NSURL URLWithString:path] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
		if ([delegate_ respondsToSelector:@selector(onPhotoComplete:)]) {
			[delegate_ performSelector:@selector(onPhotoComplete:) withObject:[NSNumber numberWithInt:i_]];
		}
	}];
	
	// Use normal loading, no cache
	
//	imageData = [NSMutableData data];
//	
//	NSURL *url = [NSURL URLWithString:path];
//	//NSURLRequest *request = [NSURLRequest requestWithURL:url];
//	//RCLog(@"RCImageView %@", path);
//	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//	
//	if (referer != nil) {
//		// Trick the website the image is loaded from to think the request comes from a specific place
//		[request setValue:referer forHTTPHeaderField:@"Referer"];
//	}
//	
//	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}




#pragma mark NSURLConnection delegates

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
				  willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response {
	//gettimeofday (&t1, NULL);
	// this method is called when the server has determined that it
	// has enough information to create the NSURLResponse
	totalBytesExpected = (long long) [response expectedContentLength];
	totalBytesLoaded = 0;
	[imageData setLength:0];
	
	//RCLog(@"RCHttp didReceiveResponse totalBytesExpected = %qi", totalBytesExpected);
}


- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
	
    [imageData appendData:data];
	totalBytesLoaded = (long long) [imageData length];
	// calculate ration
	double ln = ((double)totalBytesLoaded) / ((double)totalBytesExpected);
	// format the ration nicely
	char buff[30];
	sprintf(buff, "%0.2f", ln);
	double pc = atof(buff);
	pc *= 100;
	//RCLog(@"RCImageView didReceiveData with Percentage: %3.0f%%", pc);
	
	if ([delegate respondsToSelector:@selector(onPhotoProgress:index:)]) {
		[delegate performSelector:@selector(onPhotoProgress:index:) withObject:[NSNumber numberWithDouble:pc] withObject:[NSNumber numberWithInt:i]];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
    //RCLog(@"RCImageView connectionDidFinishLoading %i", i);
	//RCLog(@"%i", [imageData length]);
	UIImage *image = [[UIImage alloc] initWithData:imageData];
	
	if (self.autosize) {
		CGRect frameSize = self.frame;
		frameSize.size.width = image.size.width;
		frameSize.size.height = image.size.height;
		self.frame = frameSize;
	}
	if (image.size.width < self.frame.size.width && image.size.height < self.frame.size.height) {
		self.contentMode = UIViewContentModeCenter;
	}
	
	[self setImage:image];
	self.opaque = YES;// explicitly opaque for performance
	
	//RCLog(@"RCImageView fin %i", [UIImageJPEGRepresentation (self.image, 0.8f) length]);
	if ([delegate respondsToSelector:@selector(onPhotoComplete:)]) {
		[delegate performSelector:@selector(onPhotoComplete:) withObject:[NSNumber numberWithInt:i]];
	}
	
	connection = nil;
}


- (void)setImage:(UIImage *)image {
	
	[self cancel];
	[super setImage:image];
}

@end
