//
//  QSUtilities.m
//  hummiiapp
//
//  Created by Manuela Rink on 05/04/16.
//  Copyright © 2016 MobileServices. All rights reserved.
//

#import "QSUtilities.h"
#import <AVFoundation/AVFoundation.h>

@implementation QSUtilities

+ (void) playPushSound: (NSString *) soundName
{
    if (soundName) {
        NSArray* soundComponents = [soundName componentsSeparatedByString:@"."];
        if (soundComponents != nil && soundComponents.count == 2) {
            
            @try {
                NSURL* musicFile = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                           pathForResource:soundComponents[0]
                                                           ofType:soundComponents[1]]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:musicFile.path]) {
                    SystemSoundID soundID;
                    AudioServicesCreateSystemSoundID((__bridge CFURLRef)musicFile, &soundID);
                    AudioServicesPlaySystemSound (soundID);
                }
            }
            @catch (NSException *exec) {
                NSLog(@"Error loading soundfile %@. File could not be found.",soundComponents[0]);
            }
        }
    }
}

+ (UIAlertController *) createAlertControllerWithTitle: (NSString *) title message: (NSString*) msg
{
    UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alertCtrl addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    return alertCtrl;
}


@end
