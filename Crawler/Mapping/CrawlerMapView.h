//
//  CrawlerMapView.h
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Tickbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CrawlerMapViewDelegate.h"
#import "DataModel.h"

#define kKeyCellTag           (@"kKeyCellTag")
#define kKeyCellState         (@"kKeyCellState")

typedef enum _CellDirection {
    kCellDirectionNorth,
    kCellDirectionSouth,
    kCellDirectionEast,
    kCellDirectionWest
} CellDirection;

typedef enum _CellState {
    kCellStateClosed,
    kCellStateOpen
} CellState;

@interface CrawlerMapView : UIView {

    IBOutlet id<CrawlerMapViewDelegate> delegate;
    
    BOOL displayHighlightTag;
    int highlightTag;
    CellDirection highlightTagDirection;
    
    NSArray *cellsArray;
    CGFloat cellWidth;
    CGFloat cellHeight;
    int totalCells;
}

- (IBAction)mapTap:(UITapGestureRecognizer *)recognizer;

#pragma -
#pragma public methods
- (void)mapForDisplay:(Map *)map;
- (void)updateCellWithTag:(int)tag;
- (void)detailHighlightCellWithTag:(int)tag;
- (void)detailMode:(BOOL)state;

@end
