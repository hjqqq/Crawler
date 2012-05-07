//
//  MapViewCamera.m
//  Crawler
//
//  Created by Adam Eberbach on 7/05/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import "MapEditCamera.h"

@implementation MapEditCamera

@synthesize viewDelegate;
@synthesize tag;

- (void)moveNorth {
    if(tag >= kMapCellsHorizontal)
        tag -= kMapCellsHorizontal;
    [viewDelegate updatePositionByTag:tag];
}

- (void)moveSouth {
    if(tag < (kMapCellsHorizontal * (kMapCellsVertical - 1)))
        tag += kMapCellsHorizontal;
    [viewDelegate updatePositionByTag:tag];
}

- (void)moveEast {
    if((tag % kMapCellsHorizontal) < (kMapCellsHorizontal - 1))
        tag++;
    [viewDelegate updatePositionByTag:tag];
}

- (void)moveWest {
    if((tag % kMapCellsHorizontal) > 0)
        tag--;
    [viewDelegate updatePositionByTag:tag];
}

#pragma mark -
#pragma mark Public methods

- (void)turnLeft {
    
    if(facing == kCellDirectionNorth)
        facing = kCellDirectionWest;
    else {
        facing--;
    }
    [viewDelegate setRotation:facing * M_PI_2];
}

- (void)turnRight {

    if(facing == kCellDirectionWest)
        facing = kCellDirectionNorth;
    else {
        facing++;
    }
    [viewDelegate setRotation:facing * M_PI_2];
}

- (void)strafeLeft {
    switch(facing) {
        case kCellDirectionNorth:
            [self moveWest];
            break;
        case kCellDirectionEast:
            [self moveNorth];
            break;
        case kCellDirectionSouth:
            [self moveEast];
            break;
        case kCellDirectionWest:
            [self moveSouth];
            break;
    }
}

- (void)strafeRight {
    switch(facing) {
        case kCellDirectionNorth:
            [self moveEast];
            break;
        case kCellDirectionEast:
            [self moveSouth];
            break;
        case kCellDirectionSouth:
            [self moveWest];
            break;
        case kCellDirectionWest:
            [self moveNorth];
            break;
    }
}


- (void)moveForward {
    switch(facing) {
        case kCellDirectionNorth:
            [self moveNorth];
            break;
        case kCellDirectionEast:
            [self moveEast];
            break;
        case kCellDirectionSouth:
            [self moveSouth];
            break;
        case kCellDirectionWest:
            [self moveWest];
            break;
    }
}

- (void)moveBack {
    switch(facing) {
        case kCellDirectionNorth:
            [self moveSouth];
            break;
        case kCellDirectionEast:
            [self moveWest];
            break;
        case kCellDirectionSouth:
            [self moveNorth];
            break;
        case kCellDirectionWest:
            [self moveEast];
            break;
    }
}

@end
