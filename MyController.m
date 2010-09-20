#import "MyController.h"
#import <Carbon/Carbon.h>

#define redBlock 1
#define blueBlock 2
#define purpleBlock 3
#define greenBlock 4
#define yellowBlock 5
#define orangeBlock 6
#define whiteBlock 7

static char colors[8] = {'X','R','B','P','G','Y','O','W'};

int getBlock(float r, float g, float b) {
	//Standard blocks
	if(r > .85 && g > .85 && b > .85) return whiteBlock;
	if(r < .2 && b > .7) return blueBlock;
	if(r > .8 && g < .6 && b > .7) return purpleBlock;
	if(r < .4 && g > .7 && b > .3 && b < .7) return greenBlock;
	if(r > .8 && g > .7 && b < .4) return yellowBlock;
	if(r > .8 && g > .6 && b > .3 && b < .45) return orangeBlock;
	if(r > .8 && g < .25) return redBlock;
	//Multiplier blocks
	if (r > .7 && r < .8 && g > .7 && r < .8 && b < .55) return yellowBlock + 10;
	if (r < .5 && b > .7) return blueBlock + 10;
	if (r < .6 && g > .67 && b < .65) return greenBlock + 10;
	if (r > .65 && g < .5 && b > .65) return purpleBlock + 10;
	if (r > .7 && g > .4 && b < .44) return orangeBlock + 10;
	if (r > .67 && g > .67 && b > .67 && r < .86 && b < .86 && g < .86) return whiteBlock + 10;
	if (r > 0.7 && g < .6 && b < .6) return redBlock + 10;
	if (r < .6 && b > .7) return blueBlock + 10; //blue x4
	
	//Special blocks (from 4 block combo)
	if (r > .9 && g < .6 && b < .7) return redBlock + 20;
	if (r > .99 && g > .95 && b < .71) return yellowBlock + 20;
	
	return -1;
}

MyController *gController;

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
	[gController makeMove:NULL];
	return 0;
}


@implementation MyController

- (id)init
{
	if(self = [super init]) {
		captureX = 0;
		captureY = 0;
		mWindow = NULL;
		mOpenGLScreenReader = [[OpenGLScreenReader alloc] init];
		shift = NO;
		swaps = 5;
		delay = 25000;
		turbotime = 50;
		memset(board,0,sizeof(board));
		
		
	}
	gController = self;
	return self;
}

- (IBAction)configChange:(id)sender {
	if(sender == maxSwaps) {
		swaps = [maxSwaps intValue];
	} else if(sender == turnDelay) {
		delay = 1000 * [turnDelay intValue];
	} else if(sender == turboTime) {
		turbotime = [turboTime intValue];
	}
	
}


-(void)awakeFromNib

{
	EventHotKeyRef myHotKeyRef;
	
    EventHotKeyID myHotKeyID;
	
    EventTypeSpec eventType;
	eventType.eventClass=kEventClassKeyboard;
	
    eventType.eventKind=kEventHotKeyPressed;
	InstallApplicationEventHandler(&myHotKeyHandler,1,&eventType,NULL,NULL);
	myHotKeyID.signature='mhk1';
	
    myHotKeyID.id=1;
	//cmd-opt-a
	RegisterEventHotKey(0, cmdKey+optionKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);

}

- (void)flagsChanged:(NSEvent *)theEvent
{
	int flags = [theEvent modifierFlags];
	
	shift = ( flags & NSShiftKeyMask ) ? YES : NO;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}
- (BOOL)resignFirstResponder {
    return YES;
}

- (void)becomeFirstResponder{}
- (void)keyUp:(NSEvent *)theEvent{}


- (IBAction)left:(id)sender {
	if(shift) captureX -= 10;
	else captureX -=1;
	
	[mView setCaptureX: captureX y: captureY];
	[mView setNeedsDisplay: true];
}

- (IBAction)right:(id)sender {
	if(shift) captureX += 10;
	else captureX +=1;
	
	[mView setCaptureX: captureX y: captureY];
	[mView setNeedsDisplay: true];
}
- (IBAction)up:(id)sender {
	if(shift) captureY += 10;
	else captureY +=1;

	[mView setCaptureX: captureX y: captureY];
	[mView setNeedsDisplay: true];
}
- (IBAction)down:(id)sender{
	if(shift) captureY -= 10;
	else captureY -=1;

	[mView setCaptureX: captureX y: captureY];
	[mView setNeedsDisplay: true];
}




// Take a "snapshot" of the screen and save the image
// to a TIFF file on disk
- (IBAction)screenSnapshot:(id)sender
{
    // Read the screen bits
    [mOpenGLScreenReader readFullScreenToBuffer];

	if(mWindow == NULL) [self initWindow];
	[self showWindow:self];
	
    // Write our image to a TIFF file on disk
//    [mOpenGLScreenReader createTIFFImageFileOnDesktop];
//    [mOpenGLScreenReader createTextFileOnDesktop];

    // Finished, so let's cleanup
}

- (IBAction)makeMove:(id)sender {
	if(mWindow == NULL) [self initWindow];
	[self hideWindow:self];
	time_t start = time(NULL);
	int waitCount;
	while(time(NULL) - start < 62) {
		// Read the screen bits
		[mOpenGLScreenReader readFullScreenToBuffer];
		
		[self captureBoard];
		
		int i,j;
/*		for (i = 0; i < 8; i++) {
			for (j = 0; j < 8; j++) {
//				printf("%d,",board[i][j]);
			}
//			printf("\n");
		}
*/		
		[self findMoves];
		[self collapseMoves];
		
//		printf("FINAL SWAPS:\n");
		for(i = 0; i < swaps; i++)
			if(mSwaps[i].x1 != -1) {

//				printf("%d,%d  :  %d,%d\n",mSwaps[i].x1,mSwaps[i].y1,mSwaps[i].x2,mSwaps[i].y2);
				[self executeSwap: mSwaps[i]];
				[self bringGameToFront];
				usleep(5000);
			}
		waitCount = 0;
		while(time(NULL) - start < turbotime && ![self isBoardStable] && waitCount < 5) {
			[mOpenGLScreenReader readFullScreenToBuffer];
			[self captureBoard];
			waitCount++;
			usleep(delay);
		}
		
//		usleep(25000);
	}
}

- (IBAction)oneShot:(id)sender {
	if(mWindow == NULL) [self initWindow];
	[self hideWindow:self];
	// Read the screen bits
	[mOpenGLScreenReader readFullScreenToBuffer];
	
	[self captureBoard];
	
	int i,j;
	for (i = 7; i >= 0; i--) {
		for (j = 0; j < 8; j++) {
			if(board[i][j].color > 0)
				printf("%c,",board[i][j].isMultiplier ? tolower(colors[board[i][j].color]) : colors[board[i][j].color]);
			else
				printf("X,");

		}
		printf("\n");
	}
}


- (BOOL) isBoardStable {
	int i,j;
	BOOL stable = true;
	
	for(i = 0; i < 8; i ++) {
		for(j = 0; j < 8; j++) {
			if(board[i][j].color != oldBoard[i][j].color) {
				stable = false;
				break;
			}
		}
		if(!stable) break;
	}
	
	for(i = 0; i < 8; i++) 
		for(j = 0; j < 8; j++)
			oldBoard[i][j].color = board[i][j].color;
	
	return stable;
}

- (void) executeSwap:(Swap)swap {
	
	// The data structure CGPoint represents a point in a two-dimensional
	// coordinate system.  Here, X and Y distance from upper left, in pixels.
	//
	CGPoint pt;
	CGEventRef mouseDownEv, mouseUpEv;
	//translate to screen coords:
	swap.x1 = captureX + 20 +(40 * swap.x1);
	swap.x2 = captureX + 20 +(40 * swap.x2);
	swap.y1 = captureY + 20 +(40 * swap.y1);
	swap.y2 = captureY + 20 +(40 * swap.y2);
	
	//translate y coord to screen coords:
	swap.y1 = [mOpenGLScreenReader height] - swap.y1;
	swap.y2 = [mOpenGLScreenReader height] - swap.y2;
	

	// click
	pt.x = swap.x1;
	pt.y = swap.y1;	
	mouseDownEv = CGEventCreateMouseEvent (NULL,kCGEventLeftMouseDown,pt,kCGMouseButtonLeft);
	CGEventPost (kCGHIDEventTap, mouseDownEv);
	mouseUpEv = CGEventCreateMouseEvent (NULL,kCGEventLeftMouseUp,pt,kCGMouseButtonLeft);
	CGEventPost (kCGHIDEventTap, mouseUpEv );
	usleep(30000);
	// click
	pt.x = swap.x2;
	pt.y = swap.y2;
	mouseDownEv = CGEventCreateMouseEvent (NULL,kCGEventLeftMouseDown,pt,kCGMouseButtonLeft);
	CGEventPost (kCGHIDEventTap, mouseDownEv);
	mouseUpEv = CGEventCreateMouseEvent (NULL,kCGEventLeftMouseUp,pt,kCGMouseButtonLeft);
	CGEventPost (kCGHIDEventTap, mouseUpEv );
}



- (void) bringGameToFront {
	
	// The data structure CGPoint represents a point in a two-dimensional
	// coordinate system.  Here, X and Y distance from upper left, in pixels.
	//
	CGPoint pt;
	pt.x = captureX - 10;
	pt.y = [mOpenGLScreenReader height] - captureY - 10;

	CGEventRef mouseDownEv = CGEventCreateMouseEvent (NULL,kCGEventLeftMouseDown,pt,kCGMouseButtonLeft);
	CGEventPost (kCGHIDEventTap, mouseDownEv);
	CGEventRef mouseUpEv = CGEventCreateMouseEvent (NULL,kCGEventLeftMouseUp,pt,kCGMouseButtonLeft);
	CGEventPost (kCGHIDEventTap, mouseUpEv );
	usleep(1000);
	
}
// remove any moves that refer to the same gems
- (void) collapseMoves {
	int currentMove, searchMove;
	BOOL isMultiplier;
	isMultiplier = FALSE;
	Swap tmp;
	
	//Move all multiplier swaps to front
	for(currentMove = 0; currentMove < MAXSWAPS; currentMove++) {
		if(mSwaps[currentMove].isMultiplier) {
			for(searchMove = 0; searchMove < MAXSWAPS; searchMove ++) {
				if(mSwaps[searchMove].isMultiplier == FALSE) {
					memcpy(&tmp,&(mSwaps[searchMove]),sizeof(Swap));
					memcpy(&(mSwaps[searchMove]),&(mSwaps[currentMove]),sizeof(Swap));
					memcpy(&(mSwaps[currentMove]),&tmp,sizeof(Swap));
				}
			}
				
		}
	}
	
/*	//if any swap is a multiplier swap, remove all non-multiplier swaps.
	if(isMultiplier) {
		for(currentMove = 0; currentMove < MAXSWAPS; currentMove++) {
			if(!mSwaps[currentMove].isMultiplier) {
				mSwaps[currentMove].x1 = mSwaps[currentMove].y1 = mSwaps[currentMove].x2 = mSwaps[currentMove].y2 = -1;
			}
		}
		return;
	}
*/	
	for(currentMove = 0; currentMove < MAXSWAPS; currentMove ++) 
		for(searchMove = currentMove; searchMove < MAXSWAPS; searchMove++) {
			if(currentMove != searchMove) {
				if((mSwaps[currentMove].x1 == mSwaps[searchMove].x1 && mSwaps[currentMove].y1 == mSwaps[searchMove].y1) ||
				   (mSwaps[currentMove].x1 == mSwaps[searchMove].x2 && mSwaps[currentMove].y1 == mSwaps[searchMove].y2) ||
				   (mSwaps[currentMove].x2 == mSwaps[searchMove].x1 && mSwaps[currentMove].y2 == mSwaps[searchMove].y1) ||
				   (mSwaps[currentMove].x2 == mSwaps[searchMove].x2 && mSwaps[currentMove].y2 == mSwaps[searchMove].y2))
				{
					mSwaps[searchMove].x1 = mSwaps[searchMove].y1 = mSwaps[searchMove].x2 = mSwaps[searchMove].y2 = -1;
				}
			}
			if(mSwaps[currentMove].x1 >= 8 || mSwaps[currentMove].x2 >= 8 || mSwaps[currentMove].y1 >= 8 || mSwaps[currentMove].y2 >= 8) 
				mSwaps[currentMove].x1 = mSwaps[currentMove].y1 = mSwaps[currentMove].x2 = mSwaps[currentMove].y2 = -1;
		}
		
}

//look for move patterns
- (void) findMoves {
	int y,x,i;
	Block c1,c2,c3,c4;
	Block d1,d2,d3,d4;
	
	int size = 8;

	int swapsFound = 0;
	for(i = 0; i < MAXSWAPS; i++) 
		mSwaps[i].x1 = mSwaps[i].x2 = mSwaps[i].y1 = mSwaps[i].y2 = -1;
	
	//4 gem moves
	for(y = 0; y < size - 1 ; y++)
		for(x = 0; x < size - 3; x++) {
			c1 = board[y][x];
			c2 = board[y][x+1];
			c3 = board[y][x+2];
			c4 = board[y][x+3];
			d1 = board[y+1][x];
			d2 = board[y+1][x+1];
			d3 = board[y+1][x+2];
			d4 = board[y+1][x+3];
			
			//XXOX
			//OOXO
			if(c1.color == c2.color  && c2.color == c4.color && d3.color == c1.color) {
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+2;
					mSwaps[swapsFound].y1 = y+1;
					mSwaps[swapsFound].x2 = x+2;
					mSwaps[swapsFound].y2 = y;
					mSwaps[swapsFound].isMultiplier = (c1.isMultiplier || c2.isMultiplier || c4.isMultiplier || d3.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+2,y+1,x+2,y);
					swapsFound++;
				} else return;
			}
			//XOXX
			//OXOO
			if(c1.color == c3.color && c3.color == c4.color && d2.color == c1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+1;
					mSwaps[swapsFound].y1 = y+1;
					mSwaps[swapsFound].x2 = x+1;
					mSwaps[swapsFound].y2 = y;
					mSwaps[swapsFound].isMultiplier = (c1.isMultiplier || c3.isMultiplier || c4.isMultiplier || d2.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+1,y+1,x+1,y);
					swapsFound++;
				} else return;

			//OXOO
			//XOXX
			if(d1.color == d3.color && d3.color == d4.color && c2.color == d1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+1;
					mSwaps[swapsFound].y1 = y;
					mSwaps[swapsFound].x2 = x+1;
					mSwaps[swapsFound].y2 = y+1;
					mSwaps[swapsFound].isMultiplier = (d1.isMultiplier || d3.isMultiplier || d4.isMultiplier || c2.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+1,y,x+1,y+1);
					swapsFound++;
				} else return;
			//XXOX
			//OOXO
			if(d1.color == d2.color  && d2.color == d4.color && c3.color == d1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+2;
					mSwaps[swapsFound].y1 = y;
					mSwaps[swapsFound].x2 = x+2;
					mSwaps[swapsFound].y2 = y+1;
					mSwaps[swapsFound].isMultiplier = (d1.isMultiplier || d2.isMultiplier || d4.isMultiplier || c3.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+2,y,x+2,y+1);
					swapsFound++;
				} else return;
			
		}

	//4 gem moves
	for(y = 0; y < size - 3 ; y++)
		for(x = 0; x < size - 1 ; x++) {
			c1 = board[y][x];
			c2 = board[y+1][x];
			c3 = board[y+2][x];
			c4 = board[y+3][x];
			d1 = board[y][x+1];
			d2 = board[y+1][x+1];
			d3 = board[y+2][x+1];
			d4 = board[y+3][x+1];
			
			//XO
			//XO
			//OX
			//XO
			if(c1.color == c2.color  && c2.color == c4.color && d3.color == c1.color) {
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+1;
					mSwaps[swapsFound].y1 = y+2;
					mSwaps[swapsFound].x2 = x;
					mSwaps[swapsFound].y2 = y+2;
					mSwaps[swapsFound].isMultiplier = (c1.isMultiplier || c2.isMultiplier || c4.isMultiplier || d3.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+1,y+2,x,y+2);
					swapsFound++;
				} else return;
			}
			
			//XO
			//OX
			//XO
			//XO
			if(c1.color == c3.color && c3.color == c4.color && d2.color == c1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+1;
					mSwaps[swapsFound].y1 = y+1;
					mSwaps[swapsFound].x2 = x;
					mSwaps[swapsFound].y2 = y+1;
					mSwaps[swapsFound].isMultiplier = (c1.isMultiplier || c3.isMultiplier || c4.isMultiplier || d2.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+1,y+1,x,y+1);
					swapsFound++;
				} else return;
			//OX
			//XO
			//OX
			//OX
			if(d1.color == d3.color && d3.color == d4.color && c2.color == d1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x;
					mSwaps[swapsFound].y1 = y+1;
					mSwaps[swapsFound].x2 = x+1;
					mSwaps[swapsFound].y2 = y+1;
					mSwaps[swapsFound].isMultiplier = (d1.isMultiplier || d3.isMultiplier || d4.isMultiplier || c2.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x,y+1,x+1,y+1);
					swapsFound++;
				} else return;
			//OX
			//OX
			//XO
			//OX
			if(d1.color == d2.color  && d2.color == d4.color && c3.color == d1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x;
					mSwaps[swapsFound].y1 = y+2;
					mSwaps[swapsFound].x2 = x+1;
					mSwaps[swapsFound].y2 = y+2;
					mSwaps[swapsFound].isMultiplier = (d1.isMultiplier || d2.isMultiplier || d4.isMultiplier || c3.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x,y+2,x+1,y+2);
					swapsFound++;
				} else return;
			
		}
	
	if(swapsFound > 0) return;
	//3 gem moves
	for(y = 0; y < size; y++)
		for(x = 0; x < size - 2; x++) {
			c1 = board[y][x];
			c2 = board[y][x+1];
			c3 = board[y][x+2];
			c4 = board[y][x+3];
			
			//XXOX
			if(c1.color == c2.color  && c2.color == c4.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+2;
					mSwaps[swapsFound].y1 = y;
					mSwaps[swapsFound].x2 = x+3;
					mSwaps[swapsFound].y2 = y;
					mSwaps[swapsFound].isMultiplier = (c1.isMultiplier || c2.isMultiplier || c4.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+2,y,x+3,y);
					swapsFound++;
				} else return;
			//XOXX
			if(c1.color == c3.color && c3.color == c4.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x;
					mSwaps[swapsFound].y1 = y;
					mSwaps[swapsFound].x2 = x+1;
					mSwaps[swapsFound].y2 = y;
					mSwaps[swapsFound].isMultiplier = (c1.isMultiplier || c3.isMultiplier || c4.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x,y,x+1,y);
					swapsFound++;
				} else return;
			
		}
	for(y = 0; y < size - 3; y++)
		for(x = 0; x < size; x++) {
			c1 = board[y][x];
			c2 = board[y+1][x];
			c3 = board[y+2][x];
			c4 = board[y+3][x];
			
			//X
			//X
			//O
			//X
			if(c1.color == c2.color  && c2.color == c4.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x;
					mSwaps[swapsFound].y1 = y+2;
					mSwaps[swapsFound].x2 = x;
					mSwaps[swapsFound].y2 = y+3;
					mSwaps[swapsFound].isMultiplier = (c1.isMultiplier || c2.isMultiplier || c4.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x,y+2,x,y+3);
					swapsFound++;
				} else return;
			//X
			//O
			//X
			//X
			if(c1.color == c3.color && c3.color == c4.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x;
					mSwaps[swapsFound].y1 = y;
					mSwaps[swapsFound].x2 = x;
					mSwaps[swapsFound].y2 = y+1;
					mSwaps[swapsFound].isMultiplier = (c1.isMultiplier || c3.isMultiplier || c4.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x,y,x,y+1);
					swapsFound++;
				} else return;
			
		}
	
	// 3 gem moves
	for(y = 0; y < size - 2; y++)
		for(x = 0; x < size - 1; x++) {
			c1 = board[y][x];
			c2 = board[y][x+1];
			c3 = board[y][x+2];
			d1 = board[y+1][x];
			d2 = board[y+1][x+1];
			d3 = board[y+1][x+2];
			
			//XOX
			//OXO
			if(c1.color == c3.color  && d2.color == c1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+1;
					mSwaps[swapsFound].y1 = y+1;
					mSwaps[swapsFound].x2 = x+1;
					mSwaps[swapsFound].y2 = y;
					mSwaps[swapsFound].isMultiplier = (c1.isMultiplier || c3.isMultiplier || d2.isMultiplier );

					//printf("SWAP: %d,%d:%d,%d\n", x+1,y+1,x+1,y);
					swapsFound++;
				} else return;
			//OXO
			//XOX
			if(d1.color == d3.color  && c2.color == d1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+1;
					mSwaps[swapsFound].y1 = y+1;
					mSwaps[swapsFound].x2 = x+1;
					mSwaps[swapsFound].y2 = y;
					mSwaps[swapsFound].isMultiplier = (d1.isMultiplier || d3.isMultiplier || c2.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+1,y+1,x+1,y);
					swapsFound++;
				} else return;
			//XXO
			//OOX
			if(c1.color == c2.color  && d3.color == c1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+2;
					mSwaps[swapsFound].y1 = y+1;
					mSwaps[swapsFound].x2 = x+2;
					mSwaps[swapsFound].y2 = y;
					mSwaps[swapsFound].isMultiplier = (c1.isMultiplier || d3.isMultiplier || c1.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+2,y+1,x+2,y);
					swapsFound++;
				} else return;
			//OOX
			//XXO
			if(d1.color == d2.color  && c3.color == d1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+2;
					mSwaps[swapsFound].y1 = y+1;
					mSwaps[swapsFound].x2 = x+2;
					mSwaps[swapsFound].y2 = y;
					mSwaps[swapsFound].isMultiplier = (d1.isMultiplier || d2.isMultiplier || c3.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+2,y+1,x+2,y);
					swapsFound++;
				} else return;
			//OXX
			//XOO
			if(c2.color == c3.color  && d1.color == c2.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x;
					mSwaps[swapsFound].y1 = y+1;
					mSwaps[swapsFound].x2 = x;
					mSwaps[swapsFound].y2 = y;
					mSwaps[swapsFound].isMultiplier = (c2.isMultiplier || c3.isMultiplier || d1.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x,y+1,x,y);
					swapsFound++;
				} else return;
			//XOO
			//OXX
			if(d2.color == d3.color  && c1.color == d2.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x;
					mSwaps[swapsFound].y1 = y+1;
					mSwaps[swapsFound].x2 = x;
					mSwaps[swapsFound].y2 = y;
					mSwaps[swapsFound].isMultiplier = (d2.isMultiplier || d3.isMultiplier || c1.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x,y+1,x,y);
					swapsFound++;
				} else return;
			
		}
	
	// 3 gem moves
	for(y = 0; y < size - 2; y++)
		for(x = 0; x < size - 1; x++) {
			c1 = board[y][x];
			c2 = board[y+1][x];
			c3 = board[y+2][x];
			d1 = board[y][x+1];
			d2 = board[y+1][x+1];
			d3 = board[y+2][x+1];
			
			
			//XO
			//OX
			//XO
			if(c1.color == c3.color  && d2.color == c1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+1;
					mSwaps[swapsFound].y1 = y+1;
					mSwaps[swapsFound].x2 = x;
					mSwaps[swapsFound].y2 = y+1;
					mSwaps[swapsFound].isMultiplier = (c1.isMultiplier || c3.isMultiplier || d2.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+1,y+1,x,y+1);
					swapsFound++;
				} else return;
			//OX
			//XO
			//OX
			if(d1.color == d3.color  && c2.color == d1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+1;
					mSwaps[swapsFound].y1 = y+1;
					mSwaps[swapsFound].x2 = x;
					mSwaps[swapsFound].y2 = y+1;
					mSwaps[swapsFound].isMultiplier = (d1.isMultiplier || d3.isMultiplier || c2.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+1,y+1,x,y+1);
					swapsFound++;
				} else return;
			//XO
			//XO
			//OX
			if(c1.color == c2.color  && d3.color == c1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+1;
					mSwaps[swapsFound].y1 = y+2;
					mSwaps[swapsFound].x2 = x;
					mSwaps[swapsFound].y2 = y+2;
					mSwaps[swapsFound].isMultiplier = (c1.isMultiplier || c2.isMultiplier || d3.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+1,y+2,x,y+2);
					swapsFound++;
				} else return;
			//OX
			//OX
			//XO
			if(d1.color == d2.color  && c3.color == d1.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+1;
					mSwaps[swapsFound].y1 = y+2;
					mSwaps[swapsFound].x2 = x;
					mSwaps[swapsFound].y2 = y+2;
					mSwaps[swapsFound].isMultiplier = (d1.isMultiplier || d2.isMultiplier || c3.isMultiplier );
					//printf("SWAP: %d,%d:%d,%d\n", x+1,y+2,x,y+2);
					swapsFound++;
				} else return;
			//OX
			//XO
			//XO
			if(c2.color == c3.color  && d1.color == c2.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+1;
					mSwaps[swapsFound].y1 = y;
					mSwaps[swapsFound].x2 = x;
					mSwaps[swapsFound].y2 = y;
					mSwaps[swapsFound].isMultiplier = (c2.isMultiplier || c3.isMultiplier || d1.isMultiplier );

					//printf("SWAP: %d,%d:%d,%d\n", x+1,y,x,y);
					swapsFound++;
				} else return;
			//XO
			//OX
			//OX
			if(d2.color == d3.color  && c1.color == d2.color)
				if(swapsFound < MAXSWAPS) {
					mSwaps[swapsFound].x1 = x+1;
					mSwaps[swapsFound].y1 = y;
					mSwaps[swapsFound].x2 = x;
					mSwaps[swapsFound].y2 = y;
					mSwaps[swapsFound].isMultiplier = (d2.isMultiplier || d3.isMultiplier || c1.isMultiplier );

					//printf("SWAP: %d,%d:%d,%d\n", x+1,y,x,y);
					swapsFound++;
				} else return;
			
		}
	
	
}


- (void) captureBoard {
	int i,j,k,l;
	if(mOpenGLScreenReader != NULL) {
		CGImageRef imageRef = [mOpenGLScreenReader createRGBImageFromBufferData];
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
		
		//printf("*******************************************\n");
		for(i = captureY + 20; i < captureY + 320; i += 40) {
			for(j = captureX + 20; j < captureX + 320; j += 40) {
/*				
				CGFloat r1   = (rawData[i*bytesPerRow + (j * bytesPerPixel)]     * 1.0) / 255.0;
				CGFloat g1 = (rawData[i*bytesPerRow + (j * bytesPerPixel) + 1] * 1.0) / 255.0;
				CGFloat b1  = (rawData[i*bytesPerRow + (j * bytesPerPixel) + 2] * 1.0) / 255.0;
				
				CGFloat r2   = (rawData[(i-2)*bytesPerRow + ((j-2) * bytesPerPixel)]     * 1.0) / 255.0;
				CGFloat g2 = (rawData[(i-2)*bytesPerRow + ((j-2) * bytesPerPixel) + 1] * 1.0) / 255.0;
				CGFloat b2  = (rawData[(i-2)*bytesPerRow + ((j-2) * bytesPerPixel) + 2] * 1.0) / 255.0;
				
				CGFloat r3   = (rawData[(i+2)*bytesPerRow + ((j+2) * bytesPerPixel)]     * 1.0) / 255.0;
				CGFloat g3 = (rawData[(i+2)*bytesPerRow + ((j+2) * bytesPerPixel) + 1] * 1.0) / 255.0;
				CGFloat b3  = (rawData[(i+2)*bytesPerRow + ((j+2) * bytesPerPixel) + 2] * 1.0) / 255.0;
				
				CGFloat r = (r1 +r2 +r3) / 3;
				CGFloat g = (g1 +g2 +g3) / 3;
				CGFloat b = (b1 +b2 +b3) / 3;
*/
				CGFloat racc = 0.0;
				CGFloat gacc = 0.0;
				CGFloat bacc = 0.0;
				int count = 0;
				for(k = i - 4; k < i  + 4; k ++)
					for(l = j - 4; l < j + 4; l++) {
						racc += (rawData[k*bytesPerRow + (l * bytesPerPixel)]     * 1.0) / 255.0;
						gacc += (rawData[k*bytesPerRow + (l * bytesPerPixel) + 1] * 1.0) / 255.0;
						bacc += (rawData[k*bytesPerRow + (l * bytesPerPixel) + 2] * 1.0) / 255.0;
						count ++;
					}
				
				CGFloat r = racc / count;
				CGFloat g = gacc / count;
				CGFloat b = bacc / count;
				
				int y = i - captureY + 20;
				int x = j - captureX + 20;
				
				y /= 40;
				x /= 40;
				
				x -= 1;
				y -= 1;
				printf("%d,%d:%2.2f,%2.2f,%2.2f",x,y,r,g,b);
				
				board[y][x].color = getBlock(r, g, b);
				board[y][x].isMultiplier = NO;
				board[y][x].isSpecial = NO;
				
				if(board[y][x].color >= 20) {
					board[y][x].color -= 20;
					board[y][x].isSpecial = YES;
				}
				if(board[y][x].color >= 10) {
					board[y][x].color -= 10;
					board[y][x].isMultiplier = YES;
				}
				
				if(board[y][x].color == -1)
					printf("***");
				
				printf("\n");
					
				
			}
			//printf("\n");
		}
		free(rawData);
		CGImageRelease(imageRef);
	}
	
}


- (void) initWindow {
	NSRect frame = NSMakeRect(0, 0 , [mOpenGLScreenReader width], [mOpenGLScreenReader height]);
	mWindow  = [[NSWindow alloc] initWithContentRect:frame
										   styleMask:NSBorderlessWindowMask
											 backing:NSBackingStoreBuffered
											   defer:NO];
	[mWindow setBackgroundColor:[NSColor clearColor]];
	[mWindow setOpaque:NO];
	[mWindow makeKeyAndOrderFront:NSApp];
	[mWindow setLevel:CGShieldingWindowLevel()];
	
	
	mView = [[MyView alloc] init];
	[mView setReader:mOpenGLScreenReader];
	[mWindow setContentView: mView];
	[mWindow setLevel:CGShieldingWindowLevel()];
	
}

- (IBAction)showWindow:(id)sender {
	if(mWindow == NULL) [self initWindow];
	oldResponder = [mainWindow firstResponder];
	[mainWindow makeFirstResponder:(struct NSResponder *)self];

	[mWindow makeKeyAndOrderFront:NSApp];
}

- (IBAction)hideWindow:(id)sender {
	if(mWindow == NULL) [self initWindow];
	[mainWindow makeFirstResponder:maxSwaps];

	[mWindow orderOut:NSApp];
	[mainWindow makeKeyAndOrderFront:NSApp];

}

@end
