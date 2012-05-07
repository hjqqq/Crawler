//
//  MapEditCamera.h
//  Crawler
//
//  Created by Adam Eberbach on 7/05/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import "Mobile.h"
#import "MapEditCameraDelegate.h"
#import "MapStuff.h"
#import "Map+helper.h"

@interface MapEditCamera : Mobile {

    CellDirection facing;
}

@property int tag;
@property __weak id<MapEditCameraDelegate> viewDelegate;

- (void)turnLeft;
- (void)turnRight;
- (void)strafeLeft;
- (void)strafeRight;
- (void)moveForward;
- (void)moveBack;

@end
