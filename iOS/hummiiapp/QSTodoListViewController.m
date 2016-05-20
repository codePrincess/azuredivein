// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <MicrosoftAzureMobile/MicrosoftAzureMobile.h>

#import "QSTodoListViewController.h"
#import "QSTodoService.h"
#import "QSAppDelegate.h"
#import "QSUtilities.h"


#pragma mark * Private Interface


@interface QSTodoListViewController ()

// Private properties
@property (strong, nonatomic) QSTodoService *todoService;
@property (weak, nonatomic) IBOutlet UIView *topView;

@end


#pragma mark * Implementation


@implementation QSTodoListViewController

#pragma mark * UIView methods


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create the todoService - this creates the Mobile Service client inside the wrapped service
    self.todoService = [QSTodoService defaultService];
    
    // have refresh control reload all data from server
    [self.refreshControl addTarget:self
                            action:@selector(onRefresh:)
                  forControlEvents:UIControlEventValueChanged];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"diver"]];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.frame = CGRectMake(110, 0, self.view.frame.size.width, 600);
    imageView.alpha = 0.5;
    [self.view insertSubview:imageView belowSubview:self.topView];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logout)];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"Login" style:UIBarButtonItemStylePlain target:self action:@selector(login)];
    
    self.navigationItem.leftBarButtonItem = leftItem;
    self.navigationItem.rightBarButtonItem = rightItem;
    
    // load the data
    [self refresh];
}

- (void) refresh
{
    [self.refreshControl beginRefreshing];
    
    [self.todoService syncData:^{
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
    }];
}


#pragma mark * UITableView methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSDictionary *item = self.todoService.data[indexPath.row];
    
    cell.textLabel.textColor = [item[@"completed"] boolValue] ? [UIColor grayColor] : [UIColor blackColor];
    cell.textLabel.text = [item valueForKey:@"text"];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.todoService.data.count;
}



- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Change the appearance to look greyed out until we remove the item
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.textColor = [UIColor grayColor];
    
    // Ask the todoService to set the item's completed value to YES
    NSDictionary *dict = self.todoService.data[indexPath.row];
    
    __weak typeof(self) weakSelf = self;
    [self.todoService completeItem:dict completion:^{
        [weakSelf refresh];
    }];
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = self.todoService.data[indexPath.row];
 
    // If the item is completed, then this is just pending upload. Editing is not allowed
    return [item[@"completed"] boolValue] ? UITableViewCellEditingStyleNone : UITableViewCellEditingStyleDelete;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Customize the Delete button to say "completed"
    return @"completed";
}



#pragma mark * UITextFieldDelegate methods


-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder]; // hide the on-screen keyboard
    return YES;
}


#pragma mark * UI Actions


- (IBAction)onAdd:(id)sender
{
    if (self.itemText.text.length  == 0) return;
    
    NSDictionary *item = @{ @"text" : self.itemText.text, @"completed" : @NO };
    
    [self.refreshControl beginRefreshing];
    
    __weak typeof(self) weakSelf = self;
    [self.todoService addItem:item completion:^{
        [weakSelf refresh];
        [weakSelf.refreshControl endRefreshing];
    }];
    self.itemText.text = @"";
    [self.itemText resignFirstResponder];
}

- (IBAction)apiGetPressed:(id)sender {
    [self.todoService callGetDateAPI:^(NSDictionary *result, NSError *error) {
        NSString *dateString = result[@"currentTime"];
        NSTimeInterval interval = dateString.doubleValue / 1000;
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
        NSString *message = [NSString stringWithFormat:@"Date from API: \n%@", date];
        
        UIViewController *ctrl = [QSUtilities createAlertControllerWithTitle: @"Resonse from API" message:message];
        [self presentViewController:ctrl animated:YES completion:nil];
    }];
}

- (IBAction)apiPostPressed:(id)sender {
    [self.todoService callResetCompleteAPI:^(NSDictionary *result, NSError *error) {
        NSString *message = [NSString stringWithFormat:@"SUCCESS!\n  %@", result[@"message"]];
        UIViewController *ctrl = [QSUtilities createAlertControllerWithTitle: @"Resonse from API" message:message];
        
        __weak typeof(self) weakSelf = self;
        [self presentViewController:ctrl animated:YES completion:^{
            [weakSelf refresh];
        }];
    }];
}

- (IBAction)forceAppCrash:(id)sender {
    @throw NSInvalidArchiveOperationException;
//    NSArray *array = @[@"hallo", @"das", @"ist", @"ein", @"test"];
//    for (int i=0; i<array.count+1; i++) {
//        NSLog(@"%@", array[i]);
//    }
}


- (void)onRefresh:(id) sender
{
    [self refresh];
}

#pragma mark * NavigationBar Item Actions

- (void) login
{
    [self.todoService signupOrLogin:^{
        [self.tableView reloadData];
    }];
}

- (void) logout
{
    [self.todoService logout];
}

@end
