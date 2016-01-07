//
//  BNRLine.h
//  TouchTracker
//
//  Created by test on 12/27/15.
//  Copyright © 2015 Mrtang. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreGraphics;

@interface BNRLine : NSObject <NSCoding>
@property (nonatomic) CGPoint begin;
@property (nonatomic) CGPoint end;
@end
