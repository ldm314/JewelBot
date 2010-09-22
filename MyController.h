#include <time.h>
#import <Cocoa/Cocoa.h>
#import "OpenGLScreenReader.h"
#import "myView.h"

#define MAXSWAPS 100

typedef struct swap {
	int x1;
	int y1;
	int x2;
	int y2;
	BOOL isMultiplier;
	BOOL isSpecial;
} Swap;

@interface MyController : NSObject
{
@public
    OpenGLScreenReader *mOpenGLScreenReader;
	NSWindow *mWindow;
	MyView *mView;
	int captureX, captureY;
	Block board[9][9];
	Block oldBoard[8][8];
	BOOL shift;
	Swap mSwaps[MAXSWAPS];
	id oldResponder;
	int swaps,delay,turbotime;
	
	IBOutlet id mainWindow;
	IBOutlet id maxSwaps;
	IBOutlet id turnDelay;
	IBOutlet id turboTime;


}

- (IBAction)screenSnapshot:(id)sender;
- (IBAction)makeMove:(id)sender;
- (IBAction)showWindow:(id)sender;
- (IBAction)hideWindow:(id)sender;
- (IBAction)oneShot:(id)sender;

	
- (IBAction)left:(id)sender;
- (IBAction)right:(id)sender;
- (IBAction)up:(id)sender;
- (IBAction)down:(id)sender;

- (IBAction)configChange:(id)sender;

- (void)flagsChanged:(NSEvent *)theEvent;

- (BOOL) isBoardStable;
- (void) initWindow;
- (void) captureBoard;
- (void) collapseMoves;
- (void) executeSwap:(Swap)swap;
- (void) bringGameToFront;
- (void) findMoves;

@end
