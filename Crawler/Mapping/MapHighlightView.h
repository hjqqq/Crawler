//
//  MapHighlightView.h
//  Crawler
//
//  Created by Adam Eberbach on 7/05/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapStuff.h"
#import "MobileDelegate.h"

@interface MapHighlightView : UIView {

    CGPoint tagZeroOrigin;
    CGFloat rotation;
}

@property Direction facing;

- (void)updatePositionByTag:(int)tag;

@end
