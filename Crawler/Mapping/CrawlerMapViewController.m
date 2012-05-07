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
    {{1, -1, 1}, {1, 0, 0, 1}, {1, 0}, {0, 0, 1}},
    {{1, 1, 1}, {0, 1, 0, 1}, {1, 1}, {0, 0, 1}},
    {{-1, 1, 1}, {0, 0, 1, 1}, {0, 1}, {0, 0, 1}},
    {{-1, -1, 1}, {0, 0, 0, 1}, {0, 0}, {0, 0, 1}},
    // Back
    {{1, 1, -1}, {1, 0, 0, 1}, {0, 1}, {0, 0, -1}},
    {{-1, -1, -1}, {0, 1, 0, 1}, {1, 0}, {0, 0, -1}},
    {{1, -1, -1}, {0, 0, 1, 1}, {0, 0}, {0, 0, -1}},
    {{-1, 1, -1}, {0, 0, 0, 1}, {1, 1}, {0, 0, -1}},
    // Left
    {{-1, -1, 1}, {1, 0, 0, 1}, {1, 0}, {-1, 0, 0}}, 
    {{-1, 1, 1}, {0, 1, 0, 1}, {1, 1}, {-1, 0, 0}},
    {{-1, 1, -1}, {0, 0, 1, 1}, {0, 1}, {-1, 0, 0}},
    {{-1, -1, -1}, {0, 0, 0, 1}, {0, 0}, {-1, 0, 0}},
    // Right
    {{1, -1, -1}, {1, 0, 0, 1}, {1, 0}, {1, 0, 0}},
    {{1, 1, -1}, {0, 1, 0, 1}, {1, 1}, {1, 0, 0}},
    {{1, 1, 1}, {0, 0, 1, 1}, {0, 1}, {1, 0, 0}},
    {{1, -1, 1}, {0, 0, 0, 1}, {0, 0}, {1, 0, 0}},
    // Top
    {{1, 1, 1}, {1, 0, 0, 1}, {1, 0}, {0, 1, 0}},
    {{1, 1, -1}, {0, 1, 0, 1}, {1, 1}, {0, 1, 0}},
    {{-1, 1, -1}, {0, 0, 1, 1}, {0, 1}, {0, 1, 0}},
    {{-1, 1, 1}, {0, 0, 0, 1}, {0, 0}, {0, 1, 0}},
    // Bottom
    {{1, -1, -1}, {1, 0, 0, 1}, {1, 0}, {0, -1, 0}},
    {{1, -1, 1}, {0, 1, 0, 1}, {1, 1}, {0, -1, 0}},
    {{-1, -1, 1}, {0, 0, 1, 1}, {0, 1}, {0, -1, 0}}, 
    {{-1, -1, -1}, {0, 0, 0, 1}, {0, 0}, {0, -1, 0}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 5, 7,
    // Left
    8, 9, 10,
    10, 11, 8,
    // Right
    12, 13, 14,
    14, 15, 12,
    // Top
    16, 17, 18,
    18, 19, 16,
    // Bottom
    20, 21, 22,
    22, 23, 20
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
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 4.0f, 10.0f);    
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

- (void)render:(CADisplayLink*)displayLink {
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -6.0f);   
//    _rotation += 2;
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(25), 1, 0, 0);
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), 0, 1, 0);
    effect.transform.modelviewMatrix = modelViewMatrix;
    
    // changes made to GLKBaseEffect are finalised
    [effect prepareToDraw];

    
    [previewCellView display];
}


#pragma mark -
#pragma mark GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
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
    mapEditCamera.viewDelegate = mapHighlightView;
    
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
        
        uint64_t meta = [cell.meta unsignedLongValue];
        
        if(meta & kCellMetaIsOpen) {
            meta &= ~kCellMetaIsOpen;
        } else {
            meta |= kCellMetaIsOpen;
        }
        cell.meta = [NSNumber numberWithUnsignedLong:meta];
        [_moc save:&error];
        [mapView updateCellWithTag:tag];
        
    } else {
        
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
        currentMap = map;
        [mapButton setTitle:map.name
                   forState:UIControlStateNormal];
        [mapView mapForDisplay:map];
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
