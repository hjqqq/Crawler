//
//  Cell+helper.h
//  Crawler
//
//  Created by Adam Eberbach on 21/04/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import "Cell.h"

// meaning of bits in meta

#define kCellMetaEmptyUnused                (0x0000000000000000) // not open means not active in the current map
#define kCellMetaIsOpen                     (0x0000000000000001) // not open means not active in the current map

@interface Cell (helper)

+ (void)newClosedCellInMap:(Map *)map tagged:(int)tag withMoc:(NSManagedObjectContext *)moc;

@end
