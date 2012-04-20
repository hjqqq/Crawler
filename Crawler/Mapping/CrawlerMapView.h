//
//  CrawlerMapView.h
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Tickbox. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kMapCellsHorizontal   (25)
#define kMapCellsVertical     (25)

#define kKeyCellTag           (@"kKeyCellTag")
#define kKeyCellState         (@"kKeyCellState")


// cell state is a 64-bit value recording all the information about the cell
// byte 0: Wall state north
// byte 1: Wall state south
// byte 2: Wall state east
// byte 3: Wall state west
// bytes 4 & 5: What's on the floor?
// - what objects are here, an index into the objects array (accessing an array of object IDs)
// bytes 6 & 7: What creature(s) are here
// - what creatures are here, an index into the creatures array (accessing an array of creature IDs)

#define kCellStateNothing       (0x0000000000000000)

// shift values by these amounts to get them in the appropriate 
#define kCellWallNorthShift     (64)
#define kCellWallSouthShift     (56)
#define kCellWallEastShift      (48)
#define kCellWallWestShift      (40)
#define kFloorObjectsShift      (32)
#define kCellPopulationShift    (16)

// Wall type definitions
#define kCellWallStateEmpty     (0x00)                      // nothing here, no wall
#define kCellWallStateSolid     (0x01)                      // a plain wall
#define kCellWallTorchFilled    (0x02)                      // a wall with sconce and torch in it
#define kCellWallTorchEmpty     (0x02)                      // a wall with sconce and no torch


typedef enum _CellState {
    kCellStateClosed,
    kCellStateOpen
} CellState;

@interface CrawlerMapView : UIView {

    NSMutableArray *cellsArray;
    CGFloat cellWidth;
    CGFloat cellHeight;
    int totalCells;
}

- (IBAction)mapTap:(UITapGestureRecognizer *)recognizer;

@end
