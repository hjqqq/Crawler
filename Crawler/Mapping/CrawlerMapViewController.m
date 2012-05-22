//
//  CrawlerMapViewController.m
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Adam Eberbach. All rights reserved.
//

#import "CrawlerMapViewController.h"
#import "DataModel.h"
#import <QuartzCore/QuartzCore.h>
#import "MapHighlightView.h"

typedef struct {
    float Position[3];
    float Color[4];
    float TexCoord[2];
    float Normal[3];
} Vertex;

const Vertex Vertices[] = {
    // Front
    {{-0.5, -0.5, -0.5}, {1, 0, 0, 1}, {1, 0}, {0, 0, 1}},
    {{0.5, -0.5, -0.5}, {1, 0, 0, 1}, {1, 1}, {0, 0, 1}},
    {{0.5, 0.5, -0.5}, {1, 0, 0, 1}, {0, 1}, {0, 0, 1}},
    {{-0.5, 0.5, -0.5}, {1, 0, 0, 1}, {0, 0}, {0, 0, 1}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0
};

@interface CrawlerMapViewController ()

@end

@implementation CrawlerMapViewController

@synthesize moc = _moc;

#pragma mark -
#pragma mark OpenGL

- (void)refreshWorldData {
    
    NSError *error;
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity:[NSEntityDescription entityForName:@"World" inManagedObjectContext:_moc]];
    worldArray = [_moc executeFetchRequest:fetch error:&error];
    if(currentWorld != nil)
        mapArray = [currentWorld.maps allObjects];
}

- (void)setupGL {
    
    // GLKView is created by storyboard and delegate is self. EAGLContext is ivar. 
    glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    previewCellView.context = glContext;
    [EAGLContext setCurrentContext:previewCellView.context];
    glEnable(GL_CULL_FACE);
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    effect = [[GLKBaseEffect alloc] init];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], 
                             GLKTextureLoaderOriginBottomLeft, nil];
    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"tile_floor" ofType:@"png"];
    GLKTextureInfo *info = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if(info == nil)
        NSLog(@"Error loading tile floor texture");
    effect.texture2d0.name = info.name;
    effect.texture2d0.enabled = true;
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, TexCoord));
    
    glGenVertexArraysOES(0, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    previewCellView.enableSetNeedsDisplay = NO;
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    float aspect = fabsf(previewCellView.bounds.size.width / previewCellView.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0f), aspect, 0.1f, 30.0f);    
    effect.transform.projectionMatrix = projectionMatrix;
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);        
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));
    
    glBindVertexArrayOES(0);
}

- (void)tearDownGL {
    
    if([EAGLContext currentContext] == previewCellView.context)
        [EAGLContext setCurrentContext:nil];
    previewCellView.context = nil;
    
    effect = nil;
}

#pragma mark -
#pragma mark OpenGL drawing

GLKMatrix4 viewMatrix;

static BOOL inline closeToZero(double testValue) {
    
    if(testValue < 0.001)
        return YES;
    return NO;
}


// set up the view matrix for a viewpoint animation
- (void)render:(CADisplayLink*)displayLink {
    
    float xIncomplete;
    float zIncomplete;
//    static TurningToward turningToward = kNoDirectionSet;
    
    // maybe there's no move on
    if(!closeToZero(moveBegan)) {
        
        NSTimeInterval moveNow = [[NSDate date] timeIntervalSince1970] * 1000;
        
        double moveElapsed = moveNow - moveBegan;
        if(moveElapsed > kMoveInterval) {   // the animation is complete, finalise it
            
            switch(animationDirection) {
                case kAnimationNorth:
                    zPosition -= 1;
                    break;
                case kAnimationSouth:
                    zPosition += 1;
                    break;
                case kAnimationEast:
                    xPosition += 1;
                    break;
                case kAnimationWest:
                    xPosition -= 1;
                    break;
                case kAnimationLeft:
                    break;
                case kAnimationRight:
                    break;
            }
            moveBegan = 0.f;
            xIncomplete = zIncomplete = 0.f;

        } else {    // continue the animation's progress
            float fractionalMove = moveElapsed * 1.f / kMoveInterval;
            switch(animationDirection) {
                case kAnimationNorth:
                    zIncomplete = -fractionalMove;
                    break;
                case kAnimationSouth:
                    zIncomplete = fractionalMove;
                    break;
                case kAnimationEast:
                    xIncomplete = fractionalMove;
                    break;
                case kAnimationWest:
                    xIncomplete = -fractionalMove;
                    break;
                case kAnimationLeft:
                    break;
                case kAnimationRight:
                    break;
            }
        }
    }
    viewMatrix = GLKMatrix4MakeLookAt(xPosition + xIncomplete, 0, zPosition + zIncomplete,
                                      xPosition + xIncomplete + lookAtX, 0, zPosition + zIncomplete + lookAtZ,
                                      0, 1, 0);
    [previewCellView display];
    
#if 0    
    if(!closeToZero(moveBegan)) {
        // viewMatrix is moving
        NSTimeInterval moveNow = [[NSDate date] timeIntervalSince1970] * 1000;
        
        double moveElapsed = moveNow - moveBegan;
        if(moveElapsed > kMoveInterval) {
            // the move is complete
            switch(moveDirection) {
                case kMovingZPositive:
                    zPosition += 1;
                    break;
                case kMovingZNegative:
                    zPosition -= 1;
                    break;
                case kMovingXPositive:
                    xPosition += 1;
                    break;
                case kMovingXNegative:
                    xPosition -= 1;
                    break;
                case kRotatingLeft:
                    if(turningToward == kTurningEast) {
                        facing = kFacingEast;
                        lookAtX = 1.f;
                        lookAtZ = 0.f;
                    } else if(turningToward == kTurningWest) {
                        facing = kFacingWest;
                        lookAtX = -1.f;
                        lookAtZ = 0.f;
                    } else if(turningToward == kTurningNorth) {
                        facing = kFacingNorth;
                        lookAtX = 0.f;
                        lookAtZ = -1.f;
                    } else {
                        facing = kFacingSouth;
                        lookAtX = 0.f;
                        lookAtZ = 1.f;
                    }
                    break;
                case kRotatingRight:
                    if(turningToward == kTurningWest){
                        facing = kFacingWest;
                        lookAtX = -1.f;
                        lookAtZ = 0.f;
                    } else if(turningToward == kTurningEast) {
                        facing = kFacingEast;
                        lookAtX = 1.f;
                        lookAtZ = 0.f;
                    } else if(turningToward == kTurningSouth) {
                        facing = kFacingSouth;
                        lookAtX = 0.f;
                        lookAtZ = 1.f;
                    } else {
                        facing = kFacingNorth;
                        lookAtX = 0.f;
                        lookAtZ = -1.f;
                    }
                    break;
            }
            moveBegan = 0.f;
            xIncomplete = zIncomplete = 0.f;
            turningToward = kNoDirectionSet;
            
        } else {
            float fractionalMove = moveElapsed * 1.f / kMoveInterval;
            switch(moveDirection) {
                case kMovingZPositive:
                    zIncomplete = fractionalMove;
                    break;
                case kMovingZNegative:
                    zIncomplete = -fractionalMove;
                    break;
                case kMovingXPositive:
                    xIncomplete = fractionalMove;
                    break;
                case kMovingXNegative:
                    xIncomplete = -fractionalMove;
                    break;
                case kRotatingLeft:
                    
                    if(turningToward == kNoDirectionSet) {
                        if(lookAtZ > 0.5f){
                            turningToward = kTurningEast;
                        } else if(lookAtZ < -0.5f) {
                            turningToward = kTurningWest;
                        } else if(lookAtX > 0.5f) {
                            turningToward = kTurningNorth;
                        } else {
                            turningToward = kTurningSouth;
                        }
                    }
                    
                    if(turningToward == kTurningEast){
                        
                        lookAtX = fractionalMove;
                        lookAtZ = 1.f - fractionalMove;
                    } else if(turningToward == kTurningWest) {
                        
                        lookAtX = -fractionalMove;
                        lookAtZ = -1 + fractionalMove;
                    } else if(turningToward == kTurningNorth) {
                        
                        lookAtX = 1 - fractionalMove;
                        lookAtZ = -fractionalMove;
                    } else {
                        
                        lookAtX = -1 + fractionalMove;
                        lookAtZ = fractionalMove;
                    }
                    break;
                    
                case kRotatingRight:
                    
                    if(turningToward == kNoDirectionSet) {
                        if(lookAtZ > 0.5f){
                            turningToward = kTurningWest;
                        } else if(lookAtZ < -0.5f) {
                            turningToward = kTurningEast;
                        } else if(lookAtX > 0.5f) {
                            turningToward = kTurningSouth;
                        } else {
                            turningToward = kTurningNorth;
                        }
                    }
                    
                    if(turningToward == kTurningWest) {
                        
                        lookAtX = - fractionalMove;
                        lookAtZ = 1 - fractionalMove;
                    } else if(turningToward == kTurningEast) {
                        
                        lookAtX = fractionalMove;
                        lookAtZ = -1 + fractionalMove;
                    } else if(turningToward == kTurningSouth) {
                        
                        lookAtX = 1 - fractionalMove;
                        lookAtZ = fractionalMove;
                    } else {
                        
                        lookAtX = -1 + fractionalMove;
                        lookAtZ = - fractionalMove;
                    }
                    break;
            }
        }
    }
#endif
}
#pragma mark -
#pragma mark MobileDelegate methods

// check under what conditions a move is possible and what its time cost is
- (MovePossible)checkMoveCost:(int *)ms {
    
    // query the map object for conditions of movement to the indicated tag and the cost of movement
    return kMovePossible;
}

- (void)wasFacing:(Direction)wasFacing turnToFace:(Direction)facing {
    
}

#if 0
// rotate the view over the arc required to face in a new direction
- (void)setNewFacing:(Facing)facing {
    
    // the Mobile is rotating, initiate rotation animation
    moveBegan = [[NSDate date] timeIntervalSince1970] * 1000.0; // record time began in milliseconds
    if(facing == kDirectionNorth) {
        
    } else if(facing == kDirectionSouth) {
        
    } else if(facing == kDirectionEast) {
        
    } else if(facing == kDirectionWest) {
        
    }
    
    if(direction == kDirectionNorth)
        animationDirection = kAnimationNorth;
    else if(direction == kDirectionSouth)
        
        }
#endif
// move in the indicated direction
- (void)moveDirection:(Direction)direction {
    
    // the Mobile is moving in the indicated direction, initiate move animation
    moveBegan = [[NSDate date] timeIntervalSince1970] * 1000.0; // record time began in milliseconds
    if(direction == kDirectionNorth)
        animationDirection = kAnimationNorth;
    else if(direction == kDirectionSouth)
        animationDirection = kAnimationSouth;
    else if(direction == kDirectionEast)
        animationDirection = kAnimationEast;
    else if(direction == kDirectionWest)
        animationDirection = kAnimationWest;
}



#pragma mark -
#pragma mark GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    // changes made to GLKBaseEffect are finalised
    [effect prepareToDraw];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glBindVertexArrayOES(_vertexArray);
    
    // rotation seems to pivot around the origin...
    // wall in front
    effect.transform.modelviewMatrix = viewMatrix;
    [effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    // wall to right
    GLKMatrix4 rightWall = GLKMatrix4RotateY(viewMatrix, -M_PI_2);
    effect.transform.modelviewMatrix = rightWall;
    [effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    // wall to left
    GLKMatrix4 leftWall = GLKMatrix4RotateY(viewMatrix, M_PI_2);
    effect.transform.modelviewMatrix = leftWall;
    [effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    // floor
    GLKMatrix4 floor = GLKMatrix4RotateX(viewMatrix, -M_PI_2);
    effect.transform.modelviewMatrix = floor;
    [effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    // ceiling
    GLKMatrix4 ceiling = GLKMatrix4RotateX(viewMatrix, M_PI_2);
    effect.transform.modelviewMatrix = ceiling;
    [effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    // behind
    GLKMatrix4 behind = GLKMatrix4RotateX(viewMatrix, M_PI);
    effect.transform.modelviewMatrix = behind;
    [effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
}

#pragma mark -
#pragma mark View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [mapView detailMode:detailModeSwitch.on];
    
    // the cursor for map editing appears in detail mode. 
    CGRect firstCell = [self.view convertRect:[mapView rectForTag:0] fromView:mapView];
    mapHighlightView = [[MapHighlightView alloc] initWithFrame:firstCell];
    [self.view addSubview:mapHighlightView];
    mapHighlightView.hidden = YES;
    
    mapEditCamera = [[MapEditCamera alloc] init];
    mapEditCamera.controllerDelegate = self;
    
    [self setupGL];
}

- (void)viewDidUnload
{
    [self tearDownGL];
    worldPicker = nil;
    worldButton = nil;
    mapPicker = nil;
    mapButton = nil;
    nameRequester = nil;
    nameTextField = nil;
    nameLabel = nil;
    mapView = nil;
    detailModeSwitch = nil;
    previewCellView = nil;
    worldButton = nil;
    mapButton = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma -
#pragma CrawlerMapViewDelegate

- (void)selectedCellTagged:(int)tag {
    
    NSError *error;
    NSArray *cellsArray = [currentMap allCellsOrderedByTag];
    Cell *cell = [cellsArray objectAtIndex:tag];
    
    if(detailModeSwitch.on == NO) {
        
        if([cell isOpen]) {
            [cell makeCellOpen:NO];
        } else {
            [cell makeCellOpen:YES];
        }
        
        [_moc save:&error];
        [mapView updateCellWithTag:tag];
        
    } else {
        // set mapEditCamera to selected position
//        mapEditCamera.tag = tag;
        [mapHighlightView updatePositionByTag:tag];
    }
}

#pragma - 
#pragma animations

// refactor, category on UIView

- (void)showView:(UIView *)view fromDirection:(AnimateInFrom)direction {
    
    CGRect visibleFrame = view.frame;
    
    switch(direction) {
        case kDirectionTop:
            visibleFrame.origin.y = 0;
            break;
        case kDirectionLeft:
        case kDirectionRight:
            visibleFrame.origin.x = 0;
            break;
        case kDirectionBottom: // move it up to that the whole view is visible
            visibleFrame.origin.y = [[UIScreen mainScreen] bounds].size.height - visibleFrame.size.height;
            break;
    }
    
    [UIView animateWithDuration:0.3f
                          delay:0.f 
                        options:UIViewAnimationOptionCurveEaseInOut 
                     animations:^{
                         view.frame = visibleFrame;
                     } 
                     completion:nil];
}

- (void)hideView:(UIView *)view toDirection:(AnimateInFrom)direction {
    
    CGRect offscreenFrame = view.frame;
    
    switch(direction) {
        case kDirectionTop:
            offscreenFrame.origin.y = 0.f - offscreenFrame.size.height;
            break;
        case kDirectionLeft:
            offscreenFrame.origin.x = 0.f - offscreenFrame.size.width;
            break;
        case kDirectionRight:
            offscreenFrame.origin.x = [[UIScreen mainScreen] bounds].size.width;
            break;
        case kDirectionBottom:
            offscreenFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
            break;
    }
    
    [UIView animateWithDuration:0.3f
                          delay:0.f 
                        options:UIViewAnimationOptionCurveEaseInOut 
                     animations:^{
                         view.frame = offscreenFrame;
                     } 
                     completion:nil];
}

#pragma -
#pragma UIPickerViewDataSource

- (void)refreshPickers {
    [worldPicker reloadAllComponents];
    [mapPicker reloadAllComponents];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    // all pickers use one component
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    [self refreshWorldData];
    
    if(pickerView == worldPicker) {
        return [worldArray count] + 1;
    } else if(pickerView == mapPicker) {
        return [mapArray count] + 1;
    }
    return 0;
}

#pragma -
#pragma UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    // performing save now ensures a rollback only undoes the addition of an object and that the object switched
    // away from is saved.
    NSError *error;
    [_moc save:&error];
    
    if(pickerView == worldPicker) {
        int worldCount = [worldArray count];
        
        if(row == worldCount)
            return NSLocalizedString(@"Define New World", nil);
        else {
            World *world = [worldArray objectAtIndex:row];
            return world.name;
        }
    } else if(pickerView == mapPicker) {
        int mapCount = [mapArray count];
        
        if(row == mapCount)
            return NSLocalizedString(@"Add a map", nil);
        else {
            Map *map = [mapArray objectAtIndex:row];
            return map.name;
        }
    } else {
        return NSLocalizedString(@"Huh?", nil);
    }
    
}

- (void)switchToMap:(Map *)map {
    
    if(map == nil) {
        [mapButton setTitle:NSLocalizedString(@"Choose Map", nil)
                   forState:UIControlStateNormal];
        [mapView mapForDisplay:nil];
    } else {
        // switching to a new map, lots of things happen - save map pointer to currentMap
        currentMap = map;
        
        // display titles etc.
        [mapButton setTitle:map.name
                   forState:UIControlStateNormal];
        
        // find the starting position for this map
        int startTag = [map startingCell];
        
        // initialise the mapView
        [mapView mapForDisplay:map];
        
        // position the preview camera "Mobile"
        [mapEditCamera setPosition:startTag facing:kDirectionNorth];
        
        // record the current 3D position and view direction
        xPosition = startTag % kMapCellsHorizontal;
        zPosition = startTag / kMapCellsHorizontal;
        lookAtX = 0;
        lookAtZ = -1;
        
        // initialise anything required for the draw loop
        
        // previewCellView appears
        previewCellView.hidden = NO;
    }
}

- (void)switchToWorld:(World *)world {
    currentWorld = world;
    [worldButton setTitle:world.name
                 forState:UIControlStateNormal];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    if(pickerView == worldPicker) {
        int worldCount = [worldArray count];
        if(row == worldCount) {
            // creating a new world
            newObject = [NSEntityDescription insertNewObjectForEntityForName:@"World" 
                                                      inManagedObjectContext:_moc];
            [self showView:nameRequester fromDirection:kDirectionLeft];
            [nameRequester becomeFirstResponder];
        } else {
            // switch to an existing world
            [self switchToWorld:[worldArray objectAtIndex:row]];
            [self refreshPickers];
        }
        [self hideView:worldPicker toDirection:kDirectionTop];
        worldButton.enabled = YES;
    } else if(pickerView == mapPicker) {
        int mapCount = [mapArray count];
        if(row == mapCount) {
            newObject = [NSEntityDescription insertNewObjectForEntityForName:@"Map" 
                                                      inManagedObjectContext:_moc];
            [self showView:nameRequester fromDirection:kDirectionLeft];
            [nameRequester becomeFirstResponder];
        } else {
            // switch to an existing map
            [self switchToMap:[mapArray objectAtIndex:row]];
            [self refreshPickers];
        }
        [self hideView:mapPicker toDirection:kDirectionTop];
        mapButton.enabled = YES;
    }
}

#pragma -
#pragma Respond to IBActions

// set name in object, save
- (IBAction)saveName:(UIButton *)sender {
    NSError *error;
    if(newObject != nil) {
        // handle creation of new Map or World object case
        if([newObject isKindOfClass:[Map class]]) {
            Map *map = (Map *)newObject;
            map.name = nameTextField.text;
            // attach map to current world
            map.world = currentWorld;
            // create cells in the map and add them
            int cellCount = kMapCellsHorizontal * kMapCellsVertical;
            for(int i = 0; i < cellCount; i++) {
                [Cell newClosedCellInMap:map tagged:i withMoc:_moc];
                
            }
            [_moc save:&error];
            [self switchToMap:map];
        } else if([newObject isKindOfClass:[World class]]){
            // new world is simple to create, no attaching maps or anything because it is the root object
            World *world = (World *)newObject;
            world.name = nameTextField.text;
            [_moc save:&error];
            [self switchToWorld:world];
        }
        newObject = nil;
    } else {
        // this is a rename of the existing map - check for duplicates before accepting TODO
        currentMap.name = nameTextField.text;
        [mapButton setTitle:currentMap.name
                   forState:UIControlStateNormal];
        [_moc save:&error];
    }
    [nameTextField resignFirstResponder];
    [self hideView:nameRequester toDirection:kDirectionLeft];
    [self refreshPickers];
}

- (IBAction)cancelName:(UIButton *)sender {
    // dump newObject if it is non-nil; abort name & commit
    if(newObject != nil) {
        [_moc rollback];
        newObject = nil;
    }
    [nameTextField resignFirstResponder];
    [self hideView:nameRequester toDirection:kDirectionLeft];
}

- (IBAction)saveMap:(UIButton *)sender {
    NSError *error;
    [_moc save:&error];
}

// choose a world from the picker, or define a new one
- (IBAction)loadWorld:(UIButton *)sender {
    [self showView:worldPicker fromDirection:kDirectionTop];
    worldButton.enabled = NO;
}

// choose a map from the picker, or define a new one
- (IBAction)loadMap:(UIButton *)sender {
    
    if(currentWorld == nil) {
        // must have an active world to select or create a map
        UIAlertView *noWorldAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"In the worlds before Monkey...", nil)
                                                               message:NSLocalizedString(@"There is no world yet, please choose or define", nil)
                                                              delegate:nil
                                                     cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     otherButtonTitles:nil];
        [noWorldAlert show];
    } else {
        [self showView:mapPicker fromDirection:kDirectionTop];
        mapButton.enabled = NO;
    }
}

// set a name for the map
// (cannot match any other name in this world)
- (IBAction)nameMap:(UIButton *)sender {
    nameTextField.text = currentMap.name;
    [self showView:nameRequester fromDirection:kDirectionLeft];
    [nameRequester becomeFirstResponder];
}

// confirm, then remove this map from storage. Clear display.
- (IBAction)trashMap:(UIButton *)sender {
    [self refreshPickers];
}

- (void)beginMove {
    moveBegan = [[NSDate date] timeIntervalSince1970] * 1000.0; // record time began in milliseconds
}

#pragma mark -
#pragma mark - Movement keys in map view controller are sent to the map edit camera

- (IBAction)turnLeft:(UIButton *)sender {
    [mapEditCamera turnLeft];
}

- (IBAction)turnRight:(UIButton *)sender {
    [mapEditCamera turnRight];
}

- (IBAction)strafeLeft:(UIButton *)sender {
    [mapEditCamera strafeLeft];
}

- (IBAction)strafeRight:(UIButton *)sender {
    [mapEditCamera strafeRight];
}

- (IBAction)moveForward:(UIButton *)sender {
    [mapEditCamera moveForward];
}

- (IBAction)moveBack:(UIButton *)sender {
    [mapEditCamera moveBack];
}

- (IBAction)detailModeSwitch:(UISwitch *)sender {
    [mapView detailMode:detailModeSwitch.on];
    mapHighlightView.hidden = !detailModeSwitch.on;
}
@end
