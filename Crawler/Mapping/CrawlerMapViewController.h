//
//  CrawlerMapViewController.h
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataModel.h"
#import "CrawlerMapView.h"
#import "CrawlerMapViewDelegate.h"
#import "MapHighlightView.h"
#import "MapEditCamera.h"
#import "MobileDelegate.h"
#import <GLKit/GLKit.h>

typedef enum _AnimateInFrom {
    kDirectionTop,
    kDirectionLeft,
    kDirectionRight,
    kDirectionBottom
} AnimateInFrom;

typedef enum _MovingInDirection {
    kMovingZNegative,
    kMovingZPositive,
    kMovingXPositive,
    kMovingXNegative,
    kRotatingRight,
    kRotatingLeft
} MovingInDirection;

typedef enum _TurningToward {
    kNoDirectionSet,
    kTurningSouth,
    kTurningNorth,
    kTurningEast,
    kTurningWest
}TurningToward;

typedef enum _AnimationDirection {
    
    kAnimationNorth,
    kAnimationSouth,
    kAnimationEast,
    kAnimationWest,
    kAnimationLeft,
    kAnimationRight
    
} AnimationDirection;


#define kMoveInterval (750.f)

@interface CrawlerMapViewController : UIViewController <MobileDelegate, UIPickerViewDataSource, UIPickerViewDelegate, GLKViewDelegate> {
    
    AnimationDirection animationDirection;
    Direction   newFacing;
    float zPosition;
    float xPosition;
    float lookAtX;
    float lookAtZ;
    double moveBegan;

    EAGLContext *glContext;

    GLuint _vertexArray;
    
    float _curRed;
    float _rotation;
    BOOL _increasing;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLKBaseEffect *effect;

    
    Map *currentMap;
    World *currentWorld;
    
    NSArray *worldArray;
    NSArray *mapArray;
    
    NSManagedObject *newObject;

    MapEditCamera *mapEditCamera;
    MapHighlightView *mapHighlightView;
    
    // a thumbnail of the view from the current cell
    __weak IBOutlet GLKView *previewCellView;
    
    // coarse/fine edit mode, enable/disable cells or set their detail
    __weak IBOutlet UISwitch *detailModeSwitch;
    
    // the view that displays the current map
    __weak IBOutlet CrawlerMapView *mapView;
        
    // name the world or map
    __weak IBOutlet UIView *nameRequester;
    __weak IBOutlet UITextField *nameTextField;
    __weak IBOutlet UILabel *nameLabel;
    
    // make a new world
    __weak IBOutlet UIButton *worldButton;
    // make a new map
    __weak IBOutlet UIButton *mapButton;
    
    // choose world or map
    __weak IBOutlet UIPickerView *worldPicker;
    __weak IBOutlet UIPickerView *mapPicker;
}

// arrows
- (IBAction)turnLeft:(UIButton *)sender;
- (IBAction)turnRight:(UIButton *)sender;
- (IBAction)strafeLeft:(UIButton *)sender;
- (IBAction)strafeRight:(UIButton *)sender;
- (IBAction)moveForward:(UIButton *)sender;
- (IBAction)moveBack:(UIButton *)sender;

- (IBAction)detailModeSwitch:(UISwitch *)sender;

// accept a name change or create operation
- (IBAction)saveName:(UIButton *)sender;
// cancel it
- (IBAction)cancelName:(UIButton *)sender;

// choose a world from storage (or create)
- (IBAction)loadWorld:(UIButton *)sender;
// choose a map from storage (or create one)
- (IBAction)loadMap:(UIButton *)sender;
// save all edits
- (IBAction)saveMap:(UIButton *)sender;
// change the name of a map
- (IBAction)nameMap:(UIButton *)sender;
// discard this map and all its cells
- (IBAction)trashMap:(UIButton *)sender;

@property __weak NSManagedObjectContext *moc;

@end
