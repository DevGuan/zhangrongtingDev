//
//  OJLCircleAnimationView.m
//  AnimationButton
//
//  Created by oujinlong on 16/6/15.
//  Copyright © 2016年 oujinlong. All rights reserved.
//

#import "OJLCircleAnimationView.h"

@interface OJLCircleAnimationView ()
@property (nonatomic, strong) UIColor* borderColor;
@property (nonatomic, assign) CGFloat timeFlag;
@property (nonatomic, strong) NSTimer* timer;
@end
@implementation OJLCircleAnimationView

+(instancetype)viewWithButton:(UIButton *)button{
    OJLCircleAnimationView* animationView = [[OJLCircleAnimationView alloc] init];
    
    animationView.frame = CGRectMake(0, 0, button.frame.size.width, button.frame.size.height);
    
    animationView.backgroundColor = [UIColor whiteColor];
    
    animationView.borderColor = gButtonRewardColor;
    
    animationView.timeFlag = 0;
    return animationView;
}
-(void)removeFromSuperview{
    [self.timer invalidate];
    [super removeFromSuperview];
}
-(void)startAnimation{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(continueAnimation) userInfo:nil repeats:YES];
    [self.timer fire];
    
}
-(void)continueAnimation{
    self.timeFlag += 0.01;
    
    [self setNeedsDisplay];

}
-(void)drawRect:(CGRect)rect{
    
    
    UIBezierPath* path = [UIBezierPath bezierPath];
    
    
    CGPoint center = CGPointMake(rect.size.width / 2, rect.size.height / 2);
    CGFloat radius = rect.size.width / 2 - 2;
    CGFloat start = - M_PI_2 + self.timeFlag * 2*M_PI;
    CGFloat end = -M_PI_2 + 0.45 * 2 * M_PI  + self.timeFlag * 2 *M_PI;
    
    [path addArcWithCenter:center radius:radius startAngle:start endAngle:end clockwise:YES];
    
    [self.borderColor setStroke];
    path.lineWidth = 1.5;
    
    [path stroke];
}
@end