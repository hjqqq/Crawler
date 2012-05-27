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
    {{0, 0, 0}, {1, 0, 0, 1}, {1, 0}, {0, 0, 1}},
    {{1, 0, 0}, {1, 0, 0, 1}, {1, 1}, {0, 0, 1}},
    {{1, 1, 0}, {1, 0, 0, 1}, {0, 1}, {0, 0, 1}},
    {{0, 1, 0}, {1, 0, 0, 1}, {0, 0}, {0, 0, 1}}
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

    //glEnable(GL_DEPTH_TEST);
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
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(95.0f), aspect, 0.1f, 30.0f);    
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
    
    float xIncomplete = 0.f;
    float zIncomplete = 0.f;

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
                case kAnimationLeft:    // fall through - same finishing position for both direction turns
                case kAnimationRight:
                    switch(newFacing) {
                        case kDirectionNorth:
                            lookAtX = 0.f;
                            lookAtZ = -1.f;
                            break;
                        case kDirectionWest:
                            lookAtX = -1.f;
                            lookAtZ = 0.f;
                            break;
                        case kDirectionSouth:
                            lookAtX = 0.f;
                            lookAtZ = 1.f;
                            break;
                        case kDirectionEast:
                            lookAtX = 1.f;
                            lookAtZ = 0.f;
                            break;
                    }
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
                // in the following cases for Left and Right animations, the first LookAt affected is the
                // direction turning toward, the second turning away.
                case kAnimationLeft:
                    switch(newFacing) {
                        case kDirectionNorth:
                            lookAtZ = -fractionalMove;
                            lookAtX = 1 - fractionalMove;
                            break;
                        case kDirectionEast:
                            lookAtX = fractionalMove;
                            lookAtZ = 1 - fractionalMove;
                            break;
                        case kDirectionSouth:
                            lookAtZ = fractionalMove;
                            lookAtX = -1 + fractionalMove;
                            break;
                        case kDirectionWest:
                            lookAtX = -fractionalMove;
                            lookAtZ = -1 + fractionalMove;
                            break;
                    }
                    break;
                    
                case kAnimationRight:
                    switch(newFacing) {
                        case kDirectionNorth:
                            lookAtZ = -fractionalMove;
                            lookAtX = -1 + fractionalMove;
                            break;
                        case kDirectionEast:
                            lookAtX = fractionalMove;
                            lookAtZ = -1 + fractionalMove;
                            break;
                        case kDirectionSouth:
                            lookAtZ = fractionalMove;
                            lookAtX = 1 - fractionalMove;
                            break;
                        case kDirectionWest:
                            lookAtX = -fractionalMove;
                            lookAtZ = 1 - fractionalMove;
                            break;
                    }
                    break;
            }
        }
    }
    
    NSLog(@"xPosition %f, zPosition %f", xPosition + xIncomplete, zPosition + zIncomplete);
    
    viewMatrix = GLKMatrix4MakeLookAt(xPosition + xIncomplete, yPosition, zPosition + zIncomplete,
                                      xPosition + xIncomplete + lookAtX, yPosition, zPosition + zIncomplete + lookAtZ,
                                      0, 1, 0);
    [previewCellView display];
}

- (void)processMove {
    // the Mobile is moving in the indicated direction, initiate move animation
    moveBegan = [[NSDate date] timeIntervalSince1970] * 1000.0; // record time began in milliseconds
    
    // the map determines what the final position and direction is (teleport, rotate, slides...)
    // [map 

    // set resulting position and direction for mobile
    // (position is ignored so far but will become important when actually checking moves)
    [mapEditCamera setPosition:0 facing:newFacing];
}

#pragma mark -
#pragma mark MobileDelegate methods

// check under what conditions a move is possible and what its time cost is
- (MovePossible)checkMoveCost:(int *)ms {
    
    // query the map object for conditions of movement to the indicated tag and the cost of movement
    return kMovePossible;
}

- (NSString *)directionStr:(Direction)direction {

    switch(direction) {
        case kDirectionNorth:
            return @"North";
            break;
        case kDirectionEast:
            return @"East";
            break;
        case kDirectionSouth:
            return @"South";
            break;
        case kDirectionWest:
            return @"West";
            break;
    }
}

- (void)wasFacing:(Direction)wasFacing turnToFace:(Direction)facing {
    
    switch(wasFacing) {
        case kDirectionNorth:
            if(facing == kDirectionWest) {
                animationDirection = kAnimationLeft;
            } else {
                animationDirection = kAnimationRight;
            }
            break;
        case kDirectionEast:
            if(facing == kDirectionNorth) {
                animationDirection = kAnimationLeft;
            } else {
                animationDirection = kAnimationRight;
            }
            break;
        case kDirectionSouth:
            if(facing == kDirectionEast) {
                animationDirection = kAnimationLeft;
            } else {
                animationDirection = kAnimationRight;
            }
            break;
        case kDirectionWest:
            if(facing == kDirectionSouth) {
                animationDirection = kAnimationLeft;
            } else {
                animationDirection = kAnimationRight;
            }
            break;
    }
    newFacing = facing;
    [self processMove];
}

// move in the indicated direction
- (void)moveDirection:(Direction)direction {
    
    if(direction == kDirectionNorth)
        animationDirection = kAnimationNorth;
    else if(direction == kDirectionSouth)
        animationDirection = kAnimationSouth;
    else if(direction == kDirectionEast)
        animationDirection = kAnimationEast;
    else if(direction == kDirectionWest)
        animationDirection = kAnimationWest;
    
    [self processMove];
}

#pragma mark -
#pragma mark GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    // changes made to GLKBaseEffect are finalised
    [effect prepareToDraw];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glBindVertexArrayOES(_vertexArray);

    GLKMatrixStackRef stack = GLKMatrixStackCreate(kCFAllocatorDefault);

    NSArray *cells = [currentMap allCellsOrderedByTag];
    
    for(int i = 0; i < 525; i++) {
        
        Cell *cell = [cells objectAtIndex:i];
        
        GLKMatrixStackPush(stack);

        int cellTag = [cell.tag intValue];
        float xPos = cellTag % kMapCellsHorizontal;
        float zPos = cellTag / kMapCellsHorizontal;

        GLKMatrix4 positionedMatrix = GLKMatrix4Translate(viewMatrix, xPos, 0, zPos);

        if([cell isOpen]) { // inside the cell walls must be visible
            
            // can walk in this cell so draw a floor
            GLKMatrix4 floorMatrix = GLKMatrix4Translate(positionedMatrix, 0, 0, 1);
            floorMatrix = GLKMatrix4RotateX(floorMatrix, -M_PI_2);
            effect.transform.modelviewMatrix = floorMatrix;
            [effect prepareToDraw];
            glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
            
            // and ceiling
            GLKMatrix4 ceilingMatrix = GLKMatrix4Translate(positionedMatrix, 0, 1, 0);
            ceilingMatrix = GLKMatrix4RotateX(ceilingMatrix, M_PI_2);
            effect.transform.modelviewMatrix = ceilingMatrix;
            [effect prepareToDraw];
            glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
            
        } else { // oustide the cell walls must be visible
            
            // can't walk in this cell so draw a closed cube - west wall
            GLKMatrix4 westWallMatrix = GLKMatrix4RotateY(positionedMatrix, -M_PI_2);
            effect.transform.modelviewMatrix = westWallMatrix;
            [effect prepareToDraw];
            glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
            
            // north wall - rotate around Y
            
            // east wall
            
            // south wall - translate Z+
            GLKMatrix4 southWallMatrix = GLKMatrix4Translate(positionedMatrix, 0, 0, 1);
            effect.transform.modelviewMatrix = southWallMatrix;
            [effect prepareToDraw];
            glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
            
        }

        
/*        
        // big arrays of cells draw fine but need to draw a cube appearing solid from the outside to
        // build the maze.
        GLKMatrix4 positionedMatrix = GLKMatrix4Translate(viewMatrix, xPos, 0, zPos);
        
        // wall in front
        effect.transform.modelviewMatrix = GLKMatrix4RotateY(positionedMatrix, M_PI);
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
        
        // wall to right
        GLKMatrix4 rightWall = GLKMatrix4RotateY(positionedMatrix, -M_PI_2);
        effect.transform.modelviewMatrix = rightWall;
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);

        // wall to left
        GLKMatrix4 leftWall = GLKMatrix4RotateY(positionedMatrix, M_PI_2);
        effect.transform.modelviewMatrix = leftWall;
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
        
        // floor
        GLKMatrix4 floor = GLKMatrix4RotateX(positionedMatrix, -M_PI_2);
        effect.transform.modelviewMatrix = floor;
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
        
        // ceiling
        GLKMatrix4 ceiling = GLKMatrix4RotateX(positionedMatrix, M_PI_2);
        effect.transform.modelviewMatrix = ceiling;
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
        
        // behind
        GLKMatrix4 behind = GLKMatrix4Translate(positionedMatrix, 0, 0, -1);
        behind = GLKMatrix4RotateX(behind, M_PI);
        effect.transform.modelviewMatrix = behind;
        [effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
*/
        GLKMatrixStackPop(stack);
    }
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
        
        // record the current 3D position and view direction, facing the centre of the inside of the cell
        xPosition = startTag % kMapCellsHorizontal + 0.5;
        yPosition = 0.5;
        zPosition = startTag / kMapCellsHorizontal + 0.5;
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
