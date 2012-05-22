//
//  Mobile.h
//  Crawler
//
// A mobile is something that can be on the map but can move, like the preview camera in the map view, 
// a NPC, monster or the player.
//
//  Created by Adam Eberbach on 7/05/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobileDelegate.h"
#import "MapStuff.h"

@class Brain;

@interface Mobile : NSObject {

    // cellID and position record where the mobile is and the way the it is facing
    int cellIdentifier;
    Direction facing;
    
    Brain *brain;
}

@property __weak id<MobileDelegate> controllerDelegate;

- (Direction)currentlyFacing;

- (void)setPosition:(int)cellId facing:(Direction)direction;

- (void)strafeLeft;
- (void)strafeRight;
- (void)moveForward;
- (void)moveBack;
- (void)turnLeft;
- (void)turnRight;

// the animation for a move has completed
- (void)moveComplete;

@end
