//
//  BNRLine.m
//  TouchTracker
//
//  Created by test on 12/27/15.
//  Copyright © 2015 Mrtang. All rights reserved.
//

#import "BNRLine.h"

@implementation BNRLine

- (id)initWithCoder:(NSCoder *)decoder  {
    self = [super init];
    
    _begin.x = [decoder decodeFloatForKey:@"beginX"];
    _begin.y = [decoder decodeFloatForKey:@"beginY"];
    _end.x = [decoder decodeFloatForKey:@"endX"];
    _end.y = [decoder decodeFloatForKey:@"endY"];
    
    return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder  {
    [encoder encodeFloat:self.begin.x forKey:@"beginX"];
    [encoder encodeFloat:self.begin.y forKey:@"beginY"];
    [encoder encodeFloat:self.end.x forKey:@"endX"];
    [encoder encodeFloat:self.end.y forKey:@"endY"];
}

@end
