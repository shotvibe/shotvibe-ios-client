//
//  RCImageView.m
//  IMAGIN
//
//  Created by Baluta Cristian on 4/7/10.
//  Copyright 2010 ralcr. All rights reserved.
//

#import "RCImageView.h"


@implementation RCImageView
@synthesize imageData, i, referer;


- (id)initWithFrame:(CGRect)frame delegate:(id)d {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		delegate = d;
		i = -1;
		self.contentMode = UIViewContentModeScaleAspectFit;
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
	
	imageData = [NSMutableData data];
	
	NSURL *url = [NSURL URLWithString:path];
	//NSURLRequest *request = [NSURLRequest requestWithURL:url];
	//NSLog(@"RCImageView %@", path);
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//	if (referer != nil) {
//		[request setValue:referer forHTTPHeaderField:@"Referer"];
//	}
	
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
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
	
	//NSLog(@"RCHttp didReceiveResponse totalBytesExpected = %qi", totalBytesExpected);
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
	//NSLog(@"RCImageView didReceiveData with Percentage: %3.0f%%", pc);
	
	if ([delegate respondsToSelector:@selector(onPhotoProgress:index:)]) {
		[delegate performSelector:@selector(onPhotoProgress:index:) withObject:[NSNumber numberWithDouble:pc] withObject:[NSNumber numberWithInt:i]];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
    //NSLog(@"RCImageView connectionDidFinishLoading %i", i);
	//NSLog(@"%i", [imageData length]);
	UIImage *image = [[UIImage alloc] initWithData:imageData];
	
	if (image.size.width < self.frame.size.width && image.size.height < self.frame.size.height) {
		self.contentMode = UIViewContentModeCenter;
	}
	
	[self setImage:image];
	self.opaque = YES;// explicitly opaque for performance
	
	//NSLog(@"RCImageView fin %i", [UIImageJPEGRepresentation (self.image, 0.8f) length]);
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
