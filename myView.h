//
//  myView.h
//  OpenGLScreenSnapshot
//
//  Created by Brian Moore on 9/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface MyView : NSView {
	id myReader;
	int captureX, captureY;
}

- (void)setReader:(NSObject *)reader;
- (void)setCaptureX:(int)x y:(int)y;
@end
