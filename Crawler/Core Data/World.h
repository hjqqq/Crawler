//
//  World.h
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface World : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *maps;
@end

@interface World (CoreDataGeneratedAccessors)

- (void)addMapsObject:(NSManagedObject *)value;
- (void)removeMapsObject:(NSManagedObject *)value;
- (void)addMaps:(NSSet *)values;
- (void)removeMaps:(NSSet *)values;

@end
