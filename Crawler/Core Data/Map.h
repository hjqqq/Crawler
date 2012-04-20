//
//  Map.h
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Tickbox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Cell, World;

@interface Map : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *cells;
@property (nonatomic, retain) World *world;
@end

@interface Map (CoreDataGeneratedAccessors)

- (void)addCellsObject:(Cell *)value;
- (void)removeCellsObject:(Cell *)value;
- (void)addCells:(NSSet *)values;
- (void)removeCells:(NSSet *)values;

@end
