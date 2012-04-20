//
//  Cell.h
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Tickbox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Cell : NSManagedObject

@property (nonatomic, retain) NSNumber * tag;
@property (nonatomic, retain) NSNumber * exitNorth;
@property (nonatomic, retain) NSNumber * population;
@property (nonatomic, retain) NSNumber * items;
@property (nonatomic, retain) NSNumber * exitWest;
@property (nonatomic, retain) NSNumber * exitEast;
@property (nonatomic, retain) NSNumber * exitSouth;
@property (nonatomic, retain) NSManagedObject *map;

@end
