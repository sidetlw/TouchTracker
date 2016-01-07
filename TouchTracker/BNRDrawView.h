//
//  BNRDrawView.h
//  TouchTracker
//
//  Created by test on 12/27/15.
//  Copyright © 2015 Mrtang. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BNRLine;

@interface BNRDrawView : UIView <UIGestureRecognizerDelegate>
@property (nonatomic) NSMutableArray *finishedLines;

@end

@interface NSMutableArray (Plist)
-(BOOL)writeToPlistFile:(NSString*)filename;
+(NSMutableArray*)readFromPlistFile:(NSString*)filename;
@end



