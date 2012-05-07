//
//  MapHighlightView.h
//  Crawler
//
//  Created by Adam Eberbach on 7/05/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapStuff.h"
#import "MapEditCameraDelegate.h"

@interface MapHighlightView : UIView <MapEditCameraDelegate> {

    CGPoint tagZeroOrigin;
    CGFloat rotation;
}

@property CellDirection facing;

- (void)updatePositionByTag:(int)tag;

@end
