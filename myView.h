//
//  myView.h
//  OpenGLScreenSnapshot
//
//  Created by Brian Moore on 9/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#define redBlock 1
#define blueBlock 2
#define purpleBlock 3
#define greenBlock 4
#define yellowBlock 5
#define orangeBlock 6
#define whiteBlock 7

typedef struct block {
	int color;
	float r,g,b;
	BOOL isMultiplier;
	BOOL isSpecial;
} Block;

@interface MyView : NSView {
	id myReader;
	int captureX, captureY;

	Block blocks[81];
}

- (void)setBoard:(Block[][9])board;
- (void)setReader:(NSObject *)reader;
- (void)setCaptureX:(int)x y:(int)y;
@end
