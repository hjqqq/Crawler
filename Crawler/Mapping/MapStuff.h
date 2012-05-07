//
//  MapStuff.h
//  Crawler
//
//  Created by Adam Eberbach on 7/05/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

// the order of this enum is important; multiplying value by M_PI_2 gives correct rotation
typedef enum _CellDirection {
    kCellDirectionNorth,
    kCellDirectionEast,
    kCellDirectionSouth,
    kCellDirectionWest
} CellDirection;
