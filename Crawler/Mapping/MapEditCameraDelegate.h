//
//  MapEditCameraDelegate.h
//  Crawler
//
//  Created by Adam Eberbach on 7/05/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MapEditCameraDelegate <NSObject>

- (void)setRotation:(CGFloat)degrees;
- (void)updatePositionByTag:(int)tag;

@end
