//
//  Map+helper.m
//  Crawler
//
//  Created by Adam Eberbach on 21/04/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import "Map+helper.h"
#import "Cell.h"

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
@end
