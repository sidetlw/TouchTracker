//
//  BNRDrawView.m
//  TouchTracker
//
//  Created by test on 12/27/15.
//  Copyright © 2015 Mrtang. All rights reserved.
//

#import "BNRDrawView.h"
#import "BNRLine.h"
#import "BNRCircle.h"

@interface BNRDrawView ()
@property (nonatomic) NSMutableDictionary *prossingLines;
@property (nonatomic) BNRCircle *currentCircle;
@property (nonatomic) NSMutableArray *finishedCircles;
@property (nonatomic) BOOL drawCircle;
@property (nonatomic) NSMutableArray *circleTouches;
@property (nonatomic) UIButton *drawCircleButton;
@property (nonatomic) CGPoint location1;
@property (nonatomic) CGPoint location2;
@property (nonatomic,weak) BNRLine *selectedLine;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) BOOL tapSelectedLine;
@property (nonatomic) UIColor *lineColor;
@end

@implementation NSMutableArray(Plist)
-(BOOL)writeToPlistFile:(NSString*)filename{
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:filename];
    BOOL didWriteSuccessfull = [data writeToFile:path atomically:YES];
    return didWriteSuccessfull;
}

+(NSMutableArray*)readFromPlistFile:(NSString*)filename{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:filename];
    NSData * data = [NSData dataWithContentsOfFile:path];
    return  [NSKeyedUnarchiver unarchiveObjectWithData:data];
}
@end //needs to be set for implementation


@implementation BNRDrawView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _prossingLines = [[NSMutableDictionary alloc] init];
        self.backgroundColor = [UIColor grayColor];
        self.multipleTouchEnabled = YES;
        _drawCircle = NO;
        _circleTouches = [[NSMutableArray alloc] init];
        [_circleTouches insertObject:[NSNull null] atIndex:0];
        [_circleTouches insertObject:[NSNull null] atIndex:1];
        _finishedCircles = [[NSMutableArray alloc] init];
        _tapSelectedLine = NO;
        _lineColor = [UIColor blackColor];
        
//        NSMutableArray *temp = [NSMutableArray readFromPlistFile:@"finishedLines"];
//        if (temp != nil) {
//            self.finishedLines = temp;
//        }
       // self.finishedLines = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        _finishedLines = [NSKeyedUnarchiver unarchiveObjectWithFile:[self documentPath]];
        if (_finishedLines == nil) {
            _finishedLines = [[NSMutableArray alloc] init];
        }
        
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clearButtonTapped)];
        doubleTapGesture.numberOfTapsRequired = 2;
        [doubleTapGesture setDelaysTouchesBegan:YES];
        [self addGestureRecognizer:doubleTapGesture];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
        [self addGestureRecognizer:tapGesture];
        
        UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [self addGestureRecognizer:longGesture];
        
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
       self.panGesture.delegate = self;
        self.panGesture.cancelsTouchesInView = NO;
        [self addGestureRecognizer:self.panGesture];
        
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureAction:)];
        [swipeGesture setDelaysTouchesBegan:YES];
        swipeGesture.numberOfTouchesRequired = 3;
        swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
        [self addGestureRecognizer:swipeGesture];
        
//        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
//        clearButton.frame = CGRectMake(10, [[UIScreen mainScreen] bounds].size.height - 40, 50, 30);
//        [clearButton setTitle:@"清空" forState:UIControlStateNormal];
//        clearButton.backgroundColor = [UIColor whiteColor];
//        [self addSubview:clearButton];
//        [clearButton addTarget:self action:@selector(clearButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        
        _drawCircleButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _drawCircleButton.frame = CGRectMake(10, [[UIScreen mainScreen] bounds].size.height - 40, 50, 30);
        [_drawCircleButton setTitle:@"画圆" forState:UIControlStateNormal];
        _drawCircleButton.backgroundColor = [UIColor whiteColor];
        [self addSubview:_drawCircleButton];
        [_drawCircleButton addTarget:self action:@selector(drawCircleButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void)strokeLine:(BNRLine*)line
{
    UIBezierPath *path = [[UIBezierPath alloc] init];
    path.lineWidth = 10;
    path.lineCapStyle = kCGLineCapRound;
    
    [path moveToPoint:line.begin];
    [path addLineToPoint:line.end];
    [path stroke];
}

-(void)strokeCircle:(BNRCircle *)circle
{
    UIBezierPath *path = [[UIBezierPath alloc] init];
    
    if (circle.radius > 0) {
        [path moveToPoint:CGPointMake(circle.center.x + circle.radius, circle.center.y)];
        [path addArcWithCenter:circle.center radius:circle.radius startAngle:0 endAngle:(2.0 * M_PI) clockwise:YES];
    }
    
    [[UIColor greenColor] setStroke];
    path.lineWidth = 5.0;
    [path stroke];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.*/
- (void)drawRect:(CGRect)rect {
    
    for (BNRLine* line in self.finishedLines) {
        [self.lineColor set];
        [self strokeLine:line];
    }
    
    for (NSValue* key in self.prossingLines) {
        [[UIColor redColor] set];
        [self strokeLine:self.prossingLines[key]];
    }
    
    for (BNRCircle* circle in self.finishedCircles) {
        [self strokeCircle:circle];
    }
    
    if (self.currentCircle != nil) {
        [self strokeCircle:self.currentCircle];
    }
    
    if (self.selectedLine != nil) {
        [[UIColor greenColor] setStroke];
        [self strokeLine:self.selectedLine];
    }
    
}

-(NSString *)documentPath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:@"finishedLines"];
    return path;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesBegan:%@",NSStringFromSelector(_cmd));
    if (self.drawCircle == YES) {
        for (UITouch* t in touches) {
            NSValue *key = [NSValue valueWithNonretainedObject:t];
            if ([self.circleTouches objectAtIndex:0] == [NSNull null]) {
                self.circleTouches[0] = key;
                self.location1 = [t locationInView:self];
            }
            else if ([self.circleTouches objectAtIndex:1] == [NSNull null]){
                self.circleTouches[1] = key;
                self.location2 = [t locationInView:self];
            }
        }//for
        
        if (([self.circleTouches objectAtIndex:0] == [NSNull null]) || ([self.circleTouches objectAtIndex:1] == [NSNull null])) {
            return;
        }
        else {
            if (_currentCircle == nil) {
                _currentCircle = [[BNRCircle alloc] init];

            }
        }
        
    }
    else {
        for (UITouch* t in touches) {
            BNRLine *line = [[BNRLine alloc] init];
            CGPoint location = [t locationInView:self];
            line.begin = location;
            line.end = location;
            
            NSValue *key = [NSValue valueWithNonretainedObject:t];
            self.prossingLines[key] = line;
        }
    }
    
    [self setNeedsDisplay];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // NSLog(@"touchesMoved:%@",NSStringFromSelector(_cmd));
    if (self.drawCircle == YES) {
        if (([self.circleTouches objectAtIndex:0] == [NSNull null]) || ([self.circleTouches objectAtIndex:1] == [NSNull null])) {
            return;
        }
        CGPoint center;
        for (UITouch *t in touches) {
            NSValue* key = [NSValue valueWithNonretainedObject:t];
            if ([key isEqualToValue:self.circleTouches[0]] ) {
                self.location1 = [t locationInView:self];
            }
            else if ([key isEqualToValue:self.circleTouches[1]] ){
                self.location2 = [t locationInView:self];
            }
        }//for
        double xL = self.location1.x - self.location2.x;
        double yL = self.location1.y - self.location2.y;
        double duijiaoxian = sqrt(xL * xL + yL * yL);
        double radius = sqrt(duijiaoxian * duijiaoxian / 2.0) / 2.0;
        
        if (self.location1.x >= self.location2.x) {
            center.x = self.location1.x - radius;
        }
        else {
            center.x = self.location2.x - radius;
        }
        
        if (self.location1.y >= self.location2.y) {
            center.y = self.location1.y - radius;
        }
        else {
            center.y = self.location2.y - radius;
        }

        self.currentCircle.center = center;
        self.currentCircle.radius = radius;
    }
    else {
        for (UITouch *t in touches) {
            NSValue* key = [NSValue valueWithNonretainedObject:t];
            CGPoint location = [t locationInView:self];
            BNRLine *line = self.prossingLines[key];
            line.end = location;
        }
    }
    
    [self setNeedsDisplay];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesEnded:%@",NSStringFromSelector(_cmd));
     if (self.drawCircle == YES) {
         for (UITouch *t in touches) {
             NSValue* key = [NSValue valueWithNonretainedObject:t];
             if ([self.circleTouches containsObject:key]) {
                 NSInteger i = [self.circleTouches indexOfObject:key];
                 self.circleTouches[i] = [NSNull null];
             }
         }
         
         if (self.circleTouches[0] != [NSNull null] && self.circleTouches[1] != [NSNull null]) {
             return;
         }
         
         if (self.currentCircle != nil) {
             [self.finishedCircles addObject:self.currentCircle];
         }
         self.currentCircle = nil;
     }
     else {
         for (UITouch *t in touches) {
             NSValue* key = [NSValue valueWithNonretainedObject:t];
             BNRLine *line = self.prossingLines[key];
             [self.finishedLines addObject:line];
           //  [self.finishedLines writeToPlistFile:@"finishedLines"];
             [NSKeyedArchiver archiveRootObject:self.finishedLines toFile:[self documentPath]];
            // [self.finishedLines writeToFile:[self documentPath] atomically:YES];
             
             [self.prossingLines removeObjectForKey:key];
             
         }
     }
    
    [self setNeedsDisplay];
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesCancelled:%@",NSStringFromSelector(_cmd));
    if (self.drawCircle == YES) {
        for (UITouch *t in touches) {
            NSValue* key= [NSValue valueWithNonretainedObject:t];
            if ([self.circleTouches containsObject:key]) {
                [self.circleTouches removeObject:key];
            }
        }//for
    }
    else{
       for (UITouch* t in touches) {
           NSValue* key= [NSValue valueWithNonretainedObject:t];
           [self.prossingLines removeObjectForKey:key];
       }
    }
    
        
    [self setNeedsDisplay];
}

-(void)clearButtonTapped
{
    NSLog(@"double tapped");
    [self.finishedLines removeAllObjects];
   // [self.finishedLines writeToPlistFile:@"finishedLines"];
    [NSKeyedArchiver archiveRootObject:self.finishedLines toFile:[self documentPath]];

   // [self.finishedCircles removeAllObjects];
    self.finishedLines = [[NSMutableArray alloc] init];
    
    [self setNeedsDisplay];
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void)deleteLine
{
    [self.finishedLines removeObject:self.selectedLine];
    [self setNeedsDisplay];
}

-(void)tap:(UIGestureRecognizer *)gesture
{
    NSLog(@"single tapped");
    CGPoint location = [gesture locationInView:self];
    self.selectedLine = [self lineAtPoint:location];
    
    if (self.selectedLine != nil) {
        [self becomeFirstResponder];
        
        UIMenuController *menu = [UIMenuController sharedMenuController];
        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"删除" action:@selector(deleteLine)];
        menu.menuItems = @[deleteItem];
        [menu setTargetRect:CGRectMake(location.x, location.y, 2, 2) inView:self];
        [menu setMenuVisible:YES animated:YES];
    }
    else {
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    
    [self setNeedsDisplay];
    self.tapSelectedLine = YES;
    
}

- (void)copy:(id)sender
{
    [super copy:sender];
}

-(void)pan:(UIPanGestureRecognizer *)gr
{
    NSLog(@"pan:");
    NSLog(@"x:%f y:%f",[gr velocityInView:self].x, [gr velocityInView:self].y);
    if (self.selectedLine == nil) {
        return;
    }
    
    if (self.tapSelectedLine == YES) {
        self.tapSelectedLine = NO;
        self.selectedLine = nil;
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
        return;
    }
    
    if (gr.state == UIGestureRecognizerStateChanged) {
        CGPoint changeDeltaTranslation = [gr translationInView:self];
        CGPoint begin = self.selectedLine.begin;
        CGPoint end = self.selectedLine.end;
        
        begin.x += changeDeltaTranslation.x;
        begin.y += changeDeltaTranslation.y;
        end.x += changeDeltaTranslation.x;
        end.y += changeDeltaTranslation.y;
        
        self.selectedLine.begin = begin;
        self.selectedLine.end = end;

    }
    [self setNeedsDisplay];
    [gr setTranslation:CGPointZero inView:self];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.panGesture) {
        return YES;
    }
    return NO;
}

-(void)swipeGestureAction:(UISwipeGestureRecognizer *)gr
{
    NSLog(@"swipeGestureAction");
    self.lineColor = [UIColor blueColor];
}

-(void)longPress:(UIGestureRecognizer*)gr
{
    if (gr.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [gr locationInView:self];
        self.selectedLine = [self lineAtPoint:location];
        
//        if (self.selectedLine) {
//            [[self prossingLines] removeAllObjects];
//        }
    }
    else if (gr.state == UIGestureRecognizerStateEnded)
    {
        self.selectedLine = nil;
    }
    
    [self setNeedsDisplay];
}

-(BNRLine *)lineAtPoint:(CGPoint)point
{
    for (BNRLine* line in self.finishedLines) {
        CGPoint start = line.begin;
        CGPoint end = line.end;
        
        for (float t = 0.0 ; t <= 1.0; t += 0.05) {
            float x = start.x + t * (end.x - start.x);
            float y = start.y + t * (end.y - start.y);
            
            if (hypot(x - point.x, y - point.y) < 20.0) {
                return line;
            }
        }
    }
    return nil;
}

-(void)drawCircleButtonTapped
{
    if (self.drawCircle == NO) {
        self.drawCircle = YES;
        [self.drawCircleButton setSelected:YES];
    }
    else{
        self.drawCircle = NO;
        [self.drawCircleButton setSelected:NO];
    }
}

@end
