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
#import "QSTodoService.h"
#import "QSAppDelegate.h"
#import "ADAuthenticationContext.h"
#import "SamplesPolicyData.h"
#import "SamplesApplicationData.h"
#import "ADAuthenticationSettings.h"
#import "NSDictionary+UrlEncoding.h"

#pragma mark * Private interace


@interface QSTodoService()

@property (nonatomic, strong) MSTable *table;
@property (nonatomic, strong) ADAuthenticationContext* authContext;
@property (nonatomic, assign) BOOL completed;
@property (nonatomic, strong) MSSyncTable *syncTable;

@end


#pragma mark * Implementation


@implementation QSTodoService


+ (QSTodoService *)defaultService
{
    // Create a singleton instance of QSTodoService
    static QSTodoService* service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[QSTodoService alloc] init];
    });
    
    return service;
}

-(QSTodoService *)init
{
    self = [super init];
    
    if (self)
    {
        // Initialize the Mobile Service client with your URL and key   
        _client = [MSClient clientWithApplicationURLString:@"https://hummiiapp.azurewebsites.net"];
        
        QSAppDelegate *delegate = (QSAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = delegate.managedObjectContext;
        _store = [[MSCoreDataStore alloc] initWithManagedObjectContext:context];
        _client.syncContext = [[MSSyncContext alloc] initWithDelegate:nil dataSource:_store callback:nil];
        
        // Create an MSSyncTable instance to allow us to work with the TodoItem table
        _syncTable = [_client syncTableWithName:@"ManusSyncTable"];
        
        _table = [_client tableWithName:@"ManuItem"];
        _data = [NSArray array];
    }
    
    return self;
}

- (void) callGetDateAPI:(void (^) (NSDictionary *result, NSError*)) completionBlock {
    [self.client invokeAPI:@"currentDate"
                      body:nil
                HTTPMethod:@"GET"
                parameters:nil
                   headers:nil
                completion:^(id result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
                    if (error == nil) {
                        NSLog(@"Got answer from my own API: %@", result);
                        completionBlock(result, error);
                    }
                }
     ];
}

- (void) callResetCompleteAPI:(void (^) (NSDictionary *result, NSError*)) completionBlock {
    [self.client invokeAPI:@"resetManuItems"
                      body:nil
                HTTPMethod:@"GET"
                parameters:@{@"completed": @(self.completed)}
                   headers:nil
                completion:^(id result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
                    if (error == nil) {
                        NSLog(@"Got answer from my own API: %@", result);
                        self.completed = !self.completed;
                        completionBlock(result, error);
                    }
                    else {
                        NSLog(@"Something went wrong with POST api call: %@", error);
                    }
                }
     ];
}

-(void)addItem:(NSDictionary *)item completion:(QSCompletionBlock)completion
{
    [self.table insert:item
            completion:^(NSDictionary * _Nullable item, NSError * _Nullable error) {
                [self logErrorIfNotNil:error];
                completion();
            }
     ];
    
//    [self.syncTable insert:item
//                completion:^(NSDictionary * _Nullable item, NSError * _Nullable error) {
//                    [self logErrorIfNotNil:error];
//                    completion();
//                }
//     ];

}

-(void)completeItem:(NSDictionary *)item completion:(QSCompletionBlock)completion
{
    // Set the item to be completed (we need a mutable copy)
    NSMutableDictionary *mutable = [item mutableCopy];
    [mutable setObject:@YES forKey:@"completed"];
    
    // Update the item in the TodoItem table and remove from the items array on completion
    [self.table update:mutable completion:^(NSDictionary * _Nullable item, NSError * _Nullable error) {
        [self logErrorIfNotNil:error];
        completion();
    }];
}

-(void)syncData:(QSCompletionBlock)completion
{
    [self pullData:completion];
}

-(void)pullData:(QSCompletionBlock)completion
{
    // Pulls data from the remote server into the local table.
    // We're pulling all items and filtering in the view
    // query ID is used for incremental sync
    __weak typeof(self) weakSelf = self;
    [self.table readWithCompletion:^(MSQueryResult * _Nullable result, NSError * _Nullable error) {
        if(error) { // error is nil if no error occured
            NSHTTPURLResponse *response = error.userInfo.allValues[0];
            if (response && response.statusCode == 401) {
                [weakSelf signupOrLogin: completion];
            }
            else {
                NSLog(@"ERROR %@", error);
            }
        }
        else {
            self.data = result.items;
        }
        completion();
    }];
}

- (void)logErrorIfNotNil:(NSError *) error
{
    if (error) {
        NSLog(@"ERROR %@", error);
    }
}


- (void) signupOrLogin:(QSCompletionBlock)completion
{
//    SamplesApplicationData* appData = [SamplesApplicationData getInstance];
//    SamplesPolicyData *aPolicy = [[SamplesPolicyData alloc]init];
//    
//    aPolicy.policyID = appData.emailSignUpPolicyId;
//    aPolicy.policyName = @"Sign Up";
    
    UIViewController *parent = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    [self.client loginWithProvider:@"aad" controller:parent animated:YES completion:^(MSUser * _Nullable user, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"error on login: %@", error);
        }
        else {
            NSLog(@"login successfull with user: %@", user);
            [self tryRegisterForPushes];
            completion();
        }
    }];
}

- (void) logout
{
    [self.client logoutWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"logout failed: %@", error);
        }
        else {
            NSLog(@"User successfully logged out.");
        }
    }];
    
}

- (void) tryRegisterForPushes
{
    [self.client.push registerDeviceToken:self.pushToken completion:^(NSError * _Nullable error) {
        if (error == nil) {
            NSLog(@"device token registered: %@", self.pushToken);
        }
        else {
            NSLog(@"something went wrong with the device token registration: %@", error);
        }
    }];
}


@end
