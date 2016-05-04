//
//  QSUtilities.h
//  hummiiapp
//
//  Created by Manuela Rink on 05/04/16.
//  Copyright © 2016 MobileServices. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QSUtilities : NSObject

+ (void) playPushSound: (NSString *) soundName;
+ (UIAlertController *) createAlertControllerWithTitle: (NSString *) title message: (NSString*) msg;

@end
