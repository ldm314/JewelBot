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
	captureX = 480;
	captureY = 260;
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
		
		//static char colors[8] = {'X','R','B','P','G','Y','O','W'};
		NSArray* colorArray = [NSArray arrayWithObjects:
							   [NSColor grayColor], [NSColor redColor],
							   [NSColor blueColor], [NSColor purpleColor],
							   [NSColor greenColor], [NSColor yellowColor], [NSColor orangeColor],
							   [NSColor grayColor], nil];
							   
		
		int idx=0;
		//printf("*******************************************\n");
		for(i = captureY + 20; i < captureY + 320; i += 40) {
			for(j = captureX + 20; j < captureX + 320; j += 40, idx++) {

				rect1 = NSMakeRect(j-17,i-17,34,34);
				[[colorArray objectAtIndex:blocks[idx].color] set];
				NSFrameRectWithWidth ( rect1, 3 );

				rect1 = NSMakeRect(j-15,i-15,30,30);
				[[NSColor colorWithDeviceRed:blocks[idx].r
									   green:blocks[idx].g
										blue:blocks[idx].b
									   alpha:1.0] set];
				
				NSFrameRectWithWidth ( rect1, 3 );
				
				if (blocks[idx].isMultiplier) {
					[[NSColor whiteColor] set];
					NSFrameRectWithWidth ( rect1, 1 );
				}

				if (blocks[idx].isSpecial) {
					[[NSColor blackColor] set];
					NSFrameRectWithWidth ( rect1, 1 );
				}
				
			}
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
	//NSLog(@"Capturing at x=%d, y=%d",x,y);
	captureX = x;
	captureY = y;
}

- (void)setBoard:(Block[][9])board {
	
	int i,j;
	

	int idx=0;
	for (i = 0; i < 8; i++) {
		for (j = 0; j < 8; j++,idx++) {
			blocks[idx] = board[i][j];
		}
	}
	return;
	
}

@end
