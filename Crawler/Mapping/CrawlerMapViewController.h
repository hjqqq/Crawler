//
//  CrawlerMapViewController.h
//  Crawler
//
//  Created by Adam Eberbach on 20/04/12.
//  Copyright (c) 2012 Tickbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataModel.h"
#import "CrawlerMapView.h"
#import "CrawlerMapViewDelegate.h"

typedef enum _AnimateInFrom {
    kDirectionTop,
    kDirectionLeft,
    kDirectionRight,
    kDirectionBottom
} AnimateInFrom;

@interface CrawlerMapViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, CrawlerMapViewDelegate> {
    
    Map *currentMap;
    World *currentWorld;
    
    NSArray *worldArray;
    NSArray *mapArray;
    
    NSManagedObject *newObject;
    
    // coarse/fine edit mode, enable/disable cells or set their detail
    __weak IBOutlet UISwitch *detailModeSwitch;
    
    // the view that displays the current map
    __weak IBOutlet CrawlerMapView *mapView;
    
    // display titles above the map view
    __weak IBOutlet UILabel *currentWorldLabel;
    __weak IBOutlet UILabel *currentMapLabel;
    
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
