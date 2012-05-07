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

@class Brain;

@interface Mobile : NSObject {
    
    Brain *brain;
}

@end
