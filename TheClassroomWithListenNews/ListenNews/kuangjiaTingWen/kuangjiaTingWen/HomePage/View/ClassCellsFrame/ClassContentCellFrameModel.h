//
//  ClassContentCellFrameModel.h
//  kuangjiaTingWen
//
//  Created by 泡果 on 2017/6/2.
//  Copyright © 2017年 zhimi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClassContentCellFrameModel : NSObject
@property (strong, nonatomic) NSString *excerpt;/**< */
@property (assign, nonatomic) CGRect contentLabelF;
@property (assign, nonatomic) CGFloat cellHeight;
@end