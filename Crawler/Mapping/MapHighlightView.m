//
//  MapHighlightView.m
//  Crawler
//
//  Created by Adam Eberbach on 7/05/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import "MapHighlightView.h"
#import "Map+helper.h"

@implementation MapHighlightView
@synthesize facing;

#pragma mark -
#pragma mark MapEditCameraDelegate

- (void)updatePositionByTag:(int)tag {

    CGSize cellSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
    CGFloat xOffset = (tag % kMapCellsHorizontal);
    CGFloat yOffset = (tag / kMapCellsHorizontal);
    
    self.frame = CGRectMake(tagZeroOrigin.x + (xOffset * cellSize.width), 
                            tagZeroOrigin.y + (yOffset * cellSize.height),
                            cellSize.width, cellSize.height);
    [self setNeedsDisplay];
}

- (void)setRotation:(CGFloat)degrees {
    
    rotation = degrees;
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark View Lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        tagZeroOrigin = frame.origin;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // detail highlight is a border for the cell currently being edited with an arrow indicating view direction
    [[UIColor redColor] setStroke];
    CGContextStrokeRectWithWidth(ctx, rect, 2.f);
    
    [[UIColor orangeColor] setFill];
    
    CGFloat border = 2.f;
    CGContextBeginPath(ctx);
    
    CGFloat midX = rect.origin.x + rect.size.width / 2;
    CGFloat midY = rect.origin.y + rect.size.height / 2;
    
    // apply arrow rotation
    CGContextTranslateCTM(ctx, midX, midY);
    CGContextRotateCTM(ctx, rotation);
    CGContextTranslateCTM(ctx, -midX, -midY);

    CGContextMoveToPoint(ctx, rect.origin.x + border, rect.origin.y + rect.size.height - border);
    CGContextAddLineToPoint(ctx, rect.origin.x + (rect.size.width / 2), rect.origin.y + border);
    CGContextAddLineToPoint(ctx, rect.origin.x + rect.size.width - border, rect.origin.y + rect.size.height - border);
    CGContextMoveToPoint(ctx, rect.origin.x + (rect.size.width / 2), rect.origin.y + border);
    CGContextAddLineToPoint(ctx, rect.origin.x + rect.size.width - border, rect.origin.y + rect.size.height - border);
    CGContextSetLineWidth(ctx, 1.f);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}

@end
