//
//  Cell+helper.m
//  Crawler
//
//  Created by Adam Eberbach on 21/04/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import "DataModel.h"

@implementation Cell (helper)

+ (void)newClosedCellInMap:(Map *)map tagged:(int)tag withMoc:(NSManagedObjectContext *)moc {
    Cell *cell = [NSEntityDescription insertNewObjectForEntityForName:@"Cell" inManagedObjectContext:moc];
    cell.map = map;
    cell.tag = [NSNumber numberWithInt:tag];
    cell.meta = [NSNumber numberWithInt:kCellMetaEmptyUnused];
}
@end
