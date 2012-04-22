//
//  CrawlerMapView.m
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Tickbox. All rights reserved.
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

- (void)detailHighlightCellWithTag:(int)tag {
    highlightTag = tag;
    [self setNeedsDisplay];
}

// this view created from storyboard
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
    
        cellWidth = floorf(self.frame.size.width / kMapCellsHorizontal);
        cellHeight = floorf(self.frame.size.height / kMapCellsVertical);
        totalCells = kMapCellsHorizontal * kMapCellsVertical;
        highlightTagDirection = kCellDirectionNorth;
    }
    return self;
}

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
                if([cell.meta intValue] & kCellMetaIsOpen) {
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
        
        if(displayHighlightTag) {
            // detail highlight is a border for the cell currently being edited with an arrow indicating view direction
            CGRect highlightRect = [self rectForTag:highlightTag];
            [[UIColor redColor] setStroke];
            CGContextStrokeRectWithWidth(ctx, highlightRect, 2.f);
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
    int rows = (int)(point.y / (CGFloat)kMapCellsVertical);
    int columns = (int)(point.x / (CGFloat)kMapCellsHorizontal);
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
