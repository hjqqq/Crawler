//
//  Mobile.m
//  Crawler
//
// A mobile is something that can be on the map but can move, like the preview camera in the map view, 
// a NPC, monster or the player.
//
//  Created by Adam Eberbach on 7/05/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import "Mobile.h"

@implementation Mobile

@synthesize controllerDelegate;

- (id)init {
    
    if((self = [super init])) {
    }
    return self;
}

- (void)moveNorth {
    
    int cost;
    if([controllerDelegate checkMoveCost:&cost] == kMovePossible) {
        [controllerDelegate moveDirection:kDirectionNorth];
    }
}

- (void)moveSouth {
    
    int cost;
    if([controllerDelegate checkMoveCost:&cost] == kMovePossible) {
        [controllerDelegate moveDirection:kDirectionSouth];
    }
}

- (void)moveEast {
    int cost;
    if([controllerDelegate checkMoveCost:&cost] == kMovePossible) {
        [controllerDelegate moveDirection:kDirectionEast];
    }
}

- (void)moveWest {
    int cost;
    if([controllerDelegate checkMoveCost:&cost] == kMovePossible) {
        [controllerDelegate moveDirection:kDirectionWest];
    }
}

#pragma mark -
#pragma mark Public methods

- (Direction)currentlyFacing {
    return facing;
}

- (void)setPosition:(int)cellId facing:(Direction)direction {
    
    cellIdentifier = cellId;
    facing = direction;
}

- (void)strafeLeft {
    switch(facing) {
        case kDirectionNorth:
            [self moveWest];
            break;
        case kDirectionEast:
            [self moveNorth];
            break;
        case kDirectionSouth:
            [self moveEast];
            break;
        case kDirectionWest:
            [self moveSouth];
            break;
    }
}

- (void)strafeRight {
    switch(facing) {
        case kDirectionNorth:
            [self moveEast];
            break;
        case kDirectionEast:
            [self moveSouth];
            break;
        case kDirectionSouth:
            [self moveWest];
            break;
        case kDirectionWest:
            [self moveNorth];
            break;
    }
}


- (void)moveForward {
    switch(facing) {
        case kDirectionNorth:
            [self moveNorth];
            break;
        case kDirectionEast:
            [self moveEast];
            break;
        case kDirectionSouth:
            [self moveSouth];
            break;
        case kDirectionWest:
            [self moveWest];
            break;
    }
}

- (void)moveBack {
    switch(facing) {
        case kDirectionNorth:
            [self moveSouth];
            break;
        case kDirectionEast:
            [self moveWest];
            break;
        case kDirectionSouth:
            [self moveNorth];
            break;
        case kDirectionWest:
            [self moveEast];
            break;
    }
}

- (void)turnLeft {
    
    Direction wasFacing = facing;

    if(wasFacing == kDirectionNorth)
        facing = kDirectionWest;
    else if(wasFacing == kDirectionWest)
        facing = kDirectionSouth;
    else if(wasFacing == kDirectionSouth)
        facing = kDirectionEast;
    else if(wasFacing == kDirectionEast)
        facing = kDirectionNorth;

    [controllerDelegate wasFacing:wasFacing turnToFace:facing];
}

- (void)turnRight {
    
    Direction wasFacing = facing;
    
    if(wasFacing == kDirectionNorth)
        facing = kDirectionEast;
    else if(wasFacing == kDirectionEast)
        facing = kDirectionSouth;
    else if(wasFacing == kDirectionSouth)
        facing = kDirectionWest;
    else if(wasFacing == kDirectionWest)
        facing = kDirectionNorth;
    
    [controllerDelegate wasFacing:wasFacing turnToFace:facing];
}

- (void)moveComplete {
    
}

@end
