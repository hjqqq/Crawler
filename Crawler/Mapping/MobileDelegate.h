//
//  MobileDelegate.h
//  Crawler
//
//  Created by Adam Eberbach on 7/05/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapStuff.h"

#define kMoveImpossible             (0x0000)
#define kMovePossible               (0x0001)
#define kMovePossibleFlying         (0x0004)
#define kMovePossibleWaterwalking   (0x0008)

typedef uint16_t MovePossible;

// the map edit camera delegate alters its view in response to actual movements recorded by the Mobile
@protocol MobileDelegate <NSObject>

// check under what conditions a move is possible and what its time cost is
- (MovePossible)checkMoveCost:(int *)ms;

// rotate the view over the arc required to face in a new direction
- (void)wasFacing:(Direction)wasFacing turnToFace:(Direction)facing;

// make the move to the indicated tag
- (void)moveDirection:(Direction)direction;


// move to the new tag position
//- (void)setRotation:(CGFloat)degrees;
//- (void)updatePositionByTag:(int)tag;

@end
