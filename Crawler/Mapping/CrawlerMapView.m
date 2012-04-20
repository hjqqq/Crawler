//
//  CrawlerMapView.m
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Tickbox. All rights reserved.
//

#import "CrawlerMapView.h"

@implementation CrawlerMapView

#pragma -
#pragma Public methods, i.e. update display

- (void)setCellState:(CellState)state forTag:(int)tag {
    
    NSMutableDictionary *cellDict = [cellsArray objectAtIndex:tag];
    [cellDict setObject:[NSNumber numberWithInt:state] forKey:kKeyCellState];
}

// this view created from storyboard
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
    
        cellWidth = self.frame.size.width / kMapCellsHorizontal;
        cellHeight = self.frame.size.height / kMapCellsVertical;
        totalCells = kMapCellsHorizontal * kMapCellsVertical;
        int tag = 0;
        
        cellsArray = [NSMutableArray arrayWithCapacity:totalCells];
        
        // create the Cells on the map
        for(int y = 0; y < kMapCellsVertical; y++) {
            for(int x = 0; x < kMapCellsHorizontal; x++) {
                NSMutableDictionary *cellDict = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:tag]
                                                                                   forKey:kKeyCellTag];
                [cellsArray addObject:cellDict];
                
                if((arc4random() % 8) > 3) {
                    [self setCellState:kCellStateOpen forTag:tag];
                }
                
                tag++;
            }
        }
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{    
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // the view is divided into Cells with each Cell having dimension of (frame.size.width / kMapCellsHorizontal)
    // and frame.size.height / kMapCellsVertical. There maye be some view left over which doesn't matter. Cells 
    // in state open are drawn in one color, Cells in state closed are in another.
    int tag = 0;
    int open, closed;
    open = closed = 0;
    for(int y = 0; y < kMapCellsVertical; y++) {
        for(int x = 0; x < kMapCellsHorizontal; x++) {
        
            NSMutableDictionary *cellDict = [cellsArray objectAtIndex:tag];
            CellState state = [[cellDict objectForKey:kKeyCellState] intValue];
            
            if(state == kCellStateClosed) {
                [[UIColor blueColor] setFill];
                closed++;
            } else if(state == kCellStateOpen) {
                [[UIColor yellowColor] setFill];
                open++;
            }
            CGFloat xOrigin = cellWidth * x;
            CGFloat yOrigin = cellHeight * y;
            
            CGContextFillRect(ctx, CGRectMake(xOrigin, yOrigin, cellWidth, cellHeight));
            
            tag++;
        }  
        CGContextFlush(ctx);
    }
}

#pragma -
#pragma Touch handling

// given a touch at a certain coordinate, return the tag for the Cell this touch relates to
- (int)tagForCoordinate:(CGPoint)point {

    // indexed from zero this works out nicely
    int rows = (int)(point.y / (CGFloat)kMapCellsVertical);
    int columns = (int)(point.x / (CGFloat)kMapCellsHorizontal);
    int tag = (rows * kMapCellsHorizontal) + columns;
    return tag;
}

- (IBAction)mapTap:(UITapGestureRecognizer *)recognizer {
    
    CGPoint tapCoordinate = [recognizer locationInView:self];
    NSLog(@"Tap on tag %d", [self tagForCoordinate:tapCoordinate]);
}

@end
