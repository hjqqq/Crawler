//
//  CrawlerMapViewController.m
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Tickbox. All rights reserved.
//

#import "CrawlerMapViewController.h"
#import "DataModel.h"

@interface CrawlerMapViewController ()

@end

@implementation CrawlerMapViewController

@synthesize moc = _moc;

- (void)refreshWorldData {
    
    NSError *error;
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity:[NSEntityDescription entityForName:@"World" inManagedObjectContext:_moc]];
    worldArray = [_moc executeFetchRequest:fetch error:&error];
    if(currentWorld != nil)
        mapArray = [currentWorld.maps allObjects];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [mapView detailMode:detailModeSwitch.on];

}

- (void)viewDidUnload
{
    worldPicker = nil;
    worldButton = nil;
    mapPicker = nil;
    mapButton = nil;
    nameRequester = nil;
    nameTextField = nil;
    nameLabel = nil;
    currentWorldLabel = nil;
    currentMapLabel = nil;
    mapView = nil;
    detailModeSwitch = nil;
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
        
        // in detail mode, map view needs to highlight selected cell
        [mapView detailHighlightCellWithTag:tag];
        
        // edit windows need to be updated with current cell status
        NSLog(@"Selecting cell tagged %d for detail editing", tag);
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
        currentMapLabel.text = nil;
        [mapView mapForDisplay:nil];
    } else {
        currentMap = map;
        currentMapLabel.text = map.name;
        [mapView mapForDisplay:map];
    }
}

- (void)switchToWorld:(World *)world {
    currentWorld = world;
    currentWorldLabel.text = world.name;
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
        currentMapLabel.text = currentMap.name = nameTextField.text;
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

- (IBAction)detailModeSwitch:(UISwitch *)sender {
    [mapView detailMode:detailModeSwitch.on];
}
@end
