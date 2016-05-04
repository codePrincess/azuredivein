//
//  samplesPolicyData.h
//  Microsoft Tasks
//
//  Created by Brandon Werner on 4/2/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface SamplesPolicyData : NSObject

@property (strong) NSString* policyName;
@property (strong) NSString* policyID;

+(id) getInstance;

@end
