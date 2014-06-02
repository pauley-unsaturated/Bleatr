//
//  UNSDetailViewController.m
//  Bleatr
//
//  Created by Mark Pauley on 2/9/14.
//  Copyright (c) 2014 Unsaturated. All rights reserved.
//

#import "UNSBleatrRoomDetailViewController.h"
#import "UNSBleatrRoom.h"
#import "UNSBleatrRoomList.h"
#import <AudioToolbox/AudioToolbox.h>

@interface UNSBleatrRoomDetailViewController () <UITableViewDataSource,UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inputTextFieldBottomSpaceConstraint;
@property (readwrite, nonatomic) CGFloat originalBottomSpaceConstant;
- (void)configureView;

@property (strong,nonatomic) UNSBleatrRoom* room;
@end

@implementation UNSBleatrRoomDetailViewController

#pragma mark - Class methods
// Get that sweet, sweet sheep sound ready!
+(SystemSoundID)bleatSoundID {
  static SystemSoundID bleatSoundID = 0;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *soundPath =  [[NSBundle mainBundle] pathForResource:@"Bleat" ofType:@"aif"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &bleatSoundID);
  });
  return bleatSoundID;
}


#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
  if (_detailItem != newDetailItem) {
    _detailItem = newDetailItem;
    if(self.room) {
      [self.room removeObserver:self forKeyPath:@"bleats"];
    }
    NSAssert([_detailItem isKindOfClass:UNSBleatrRoom.class], @"The item must be a Bleatr Room!");
    self.room = (UNSBleatrRoom*)_detailItem;
    [self.room addObserver:self forKeyPath:@"bleats" options:NSKeyValueObservingOptionNew context:nil];
    
    // Update the view.
    [self configureView];
  }
  
  if (self.masterPopoverController != nil) {
    [self.masterPopoverController dismissPopoverAnimated:YES];
  }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if([keyPath isEqualToString:@"bleats"]) {
    AudioServicesPlaySystemSound([[self class] bleatSoundID]);
    [self.tableView reloadData];
  }
}

- (void)configureView
{
  // Update the user interface for the detail item.
  self.tableView.dataSource = self;
  [self.tableView reloadData];
  self.inputTextField.delegate = self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  [self configureView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self registerForKeyboardNotifications];
  if(!self.room) {
    // set ourselves to the hosted room if we don't have a room..
    self.detailItem = [UNSBleatrRoomList sharedInstance].rooms[0];
    [self configureView];
  }
  if (self.room) {
    self.detailDescriptionLabel.text = [self.room name];
    [self.navigationItem setTitle:self.room.name];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [self unregisterForKeyboardNotifications];
  if(self.room) {
    [self.room removeObserver:self forKeyPath:@"bleats"];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
  barButtonItem.title = NSLocalizedString(@"Home", @"Bleatr Room List");
  [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
  self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
  // Called when the view is shown again in the split view, invalidating the button and popover controller.
  [self.navigationItem setLeftBarButtonItem:nil animated:YES];
  self.masterPopoverController = nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  
}

- (IBAction)postBleat:(id)sender {
  if([sender respondsToSelector:@selector(text)]) {
    NSString* text = [sender text];
    if(text.length > 0) {
      [self.room postBleat:[sender text]];
    }
  }
  else {
    // Anonymous bleats
    [self.room postBleat:@"BAAAAH!"];
  }
  [self.inputTextField setText:nil];
}



#pragma mark - UITextField Delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
  return YES;
}

#pragma mark UITextField / Keyboard Shennanigans
// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWasShown:)
                                               name:UIKeyboardWillShowNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillBeHidden:)
                                               name:UIKeyboardWillHideNotification object:nil];
  
}

- (void)unregisterForKeyboardNotifications {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardWillHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification {
  NSDictionary* info = [aNotification userInfo];
  CGRect kbRect = [self.view convertRect:[[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]
                                fromView:nil];
                   
  CGSize kbSize = kbRect.size;
  
  self.originalBottomSpaceConstant = self.inputTextFieldBottomSpaceConstraint.constant;
  // Update the textField's bottom offset constraint to make space for the keyboard.
  self.inputTextFieldBottomSpaceConstraint.constant += kbSize.height;
  [UIView setAnimationCurve:[[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]];
  [UIView animateWithDuration:[[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                   animations:^{
    [self.view layoutIfNeeded];
  }];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
  NSDictionary* info = [aNotification userInfo];
  self.inputTextFieldBottomSpaceConstraint.constant = self.originalBottomSpaceConstant;
  [UIView setAnimationCurve:[[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]];
  [UIView animateWithDuration:[[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                   animations:^{
    [self.view layoutIfNeeded];
  }];
}


#pragma mark - UITableView Datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.room.bleats.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"BleatrCell";
  
  // Yeah, I know I'm doing this the old way. :p
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  cell.textLabel.text = self.room.bleats[indexPath.row];

  return cell;
}



@end
