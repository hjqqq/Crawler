//
//  CrawlerMapView.m
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import "CrawlerMapView.h"
#import "DataModel.h"

@interface CrawlerMapView (private)
- (CGRect)rectForTag:(int)tag;
- (void)mapForDisplay:(Map *)map;
@end

@implementation CrawlerMapView

#pragma -
#pragma Public methods, i.e. update display

- (void)mapForDisplay:(Map *)map {
    
    if(map == nil) {
        cellsArray = nil;
    } else {
        cellsArray = [map allCellsOrderedByTag];
    }
    [self setNeedsDisplay];
}

- (void)updateCellWithTag:(int)tag {
    // keep the highlight following the last tapped cell for when we go back to detail mode
    highlightTag = tag;
    [self setNeedsDisplayInRect:[self rectForTag:tag]];
}

- (void)detailMode:(BOOL)state {

    displayHighlightTag = state;
    [self setNeedsDisplay];
}

// this view created from storyboard
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
    
        cellWidth = floorf(self.frame.size.width / kMapCellsHorizontal);
        cellHeight = floorf(self.frame.size.height / kMapCellsVertical);
        totalCells = kMapCellsHorizontal * kMapCellsVertical;
    }
    return self;
}

static inline float radians(double degrees) { return degrees * M_PI / 180; }

- (void)drawRect:(CGRect)rect
{    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    if(cellsArray == nil) {
        [[UIColor grayColor] setFill];
        CGContextFillRect(ctx, self.bounds);
    } else {
        
        // the view is divided into Cells with each Cell having dimension of (frame.size.width / kMapCellsHorizontal)
        // and frame.size.height / kMapCellsVertical. There may be some view left over which doesn't matter.
        int tag = 0;
        
        for(int y = 0; y < kMapCellsVertical; y++) {
            for(int x = 0; x < kMapCellsHorizontal; x++) {
                
                Cell *cell = [cellsArray objectAtIndex:tag];
                if([cell isOpen]) {
                    [[UIColor blueColor] setFill];
                } else {
                    [[UIColor yellowColor] setFill];
                }
                CGFloat xOrigin = cellWidth * x;
                CGFloat yOrigin = cellHeight * y;
                
                CGContextFillRect(ctx, CGRectMake(xOrigin, yOrigin, cellWidth, cellHeight));
                
                tag++;
            }  
            CGContextFlush(ctx);
        }
    }
}

#pragma -
#pragma Touch handling

// given a tag, what rect does the cell identified occupy?
- (CGRect)rectForTag:(int)tag {
    
    int x = (tag % kMapCellsHorizontal) * cellWidth;
    int y = (tag / kMapCellsHorizontal) * cellHeight;
    return CGRectMake(x, y, cellWidth, cellHeight);
    
}

// given a touch at a certain coordinate, return the tag for the Cell this touch relates to
- (int)tagForCoordinate:(CGPoint)point {

    // indexed from zero this works out nicely
    int rows = (int)(point.y / cellHeight);
    int columns = (int)(point.x / cellWidth);
    int tag = (rows * kMapCellsHorizontal) + columns;
    return tag;
}

- (IBAction)mapTap:(UITapGestureRecognizer *)recognizer {
    
    if(cellsArray == nil)
        return;
    CGPoint tapCoordinate = [recognizer locationInView:self];
    
    // In a map that takes less space than the view a tap could occcur outside the cells. 
    if((tapCoordinate.y > (kMapCellsVertical * cellHeight)) || (tapCoordinate.x > (kMapCellsHorizontal * cellWidth)))
        return;
    
    [delegate selectedCellTagged:[self tagForCoordinate:tapCoordinate]];
}

@end
