//
//  Map+helper.h
//  Crawler
//
//  Created by Adam Eberbach on 21/04/12.
//  Copyright (c) 2012 Tickbox. All rights reserved.
//

#import "Map.h"

#define kMapCellsHorizontal   (25)
#define kMapCellsVertical     (25)

@interface Map (helper)

- (NSArray *)allCellsOrderedByTag;

@end
