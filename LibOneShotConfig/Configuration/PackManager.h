//
//  PackManager.h
//  ManualConfig
//
//  Created by codebat on 15/1/22.
//  Copyright (c) 2015年 Winnermicro. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PackManager : NSObject

+(NSMutableArray*)preparePacks:(NSArray*)bytesArry size:(int)size;
@end
