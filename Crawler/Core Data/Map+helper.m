//
//  Map+helper.m
//  Crawler
//
//  Created by Adam Eberbach on 21/04/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import "Map+helper.h"
#import "Cell.h"
#import "Cell+helper.h"

@implementation Map (helper)

- (NSArray *)allCellsOrderedByTag {
    
    return [[self.cells allObjects] sortedArrayUsingComparator:^(Cell *obj1, Cell *obj2) {
        long tag1 = [obj1.tag intValue];
        long tag2 = [obj2.tag intValue];
        
        if(tag1 > tag2) {
            return (NSComparisonResult)NSOrderedDescending;
        } else if(tag1 < tag2) {
            return (NSComparisonResult)NSOrderedAscending;
        } else {
            return (NSComparisonResult)NSOrderedSame;
        }
    }];
}

// return the integer identifier of the map's starting cell (initial position for Mobile)
- (int)startingCell {
    NSArray *cells = [self allCellsOrderedByTag];
    for(Cell *cell in cells) {
        if([cell isOpen])
            return [cell.meta intValue];
    }
    return 0;
}
@end
