//
//  CrawlerMapViewDelegate.h
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Tickbox. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CrawlerMapViewDelegate <NSObject>

- (void)selectedCellTagged:(int)tag;

@end
