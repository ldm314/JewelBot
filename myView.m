//
//  myView.m
//  OpenGLScreenSnapshot
//
//  Created by Brian Moore on 9/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "myView.h"
#import <CommonCrypto/CommonDigest.h>

@implementation MyView

-(id) init
{
	self = [super init];
	myReader = NULL;
	captureX = 0;
	captureY = 0;
	return self;
}

- (void)drawRect:(NSRect)needsDisplayInRect {
	
	
	int fx, fy;
	int i,j;
	fx = fy = 0;

	if(myReader != NULL) {
		CGImageRef imageRef = [myReader createRGBImageFromBufferData];
		NSUInteger width = CGImageGetWidth(imageRef);
		NSUInteger height = CGImageGetHeight(imageRef);
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		unsigned char *rawData = malloc(height * width * 4);
		NSUInteger bytesPerPixel = 4;
		NSUInteger bytesPerRow = bytesPerPixel * width;
		NSUInteger bitsPerComponent = 8;
		CGContextRef context = CGBitmapContextCreate(rawData, width, height,
													 bitsPerComponent, bytesPerRow, colorSpace,
													 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
		CGColorSpaceRelease(colorSpace);
		
		CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
		CGContextRelease(context);
		NSColor * red = [NSColor redColor];
		NSColor * green = [NSColor greenColor];
		
		// fill target rect
		NSRect rect1 = NSMakeRect ( captureX,captureY,320,320 );
		[red set];
		NSFrameRectWithWidth ( rect1, 1 );
		
		[green set];
		//printf("*******************************************\n");
		for(i = captureY + 20; i < captureY + 320; i += 40)
			for(j = captureX + 20; j < captureX + 320; j += 40) {

				
				rect1 = NSMakeRect(j-2,i-2,4,4);
				NSRectFill(rect1);
			}
		
		CFRelease(imageRef);
		free(rawData);
	}
	
	[self setNeedsDisplay:YES];

	
	
}

- (void)setReader:(NSObject *)reader {
	myReader = reader;
}

- (void)setCaptureX:(int)x y:(int)y {
	captureX = x;
	captureY = y;
}
@end
