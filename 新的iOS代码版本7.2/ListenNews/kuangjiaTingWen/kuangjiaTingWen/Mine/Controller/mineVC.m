//
//  mineVC.m
//  kuangjiaTingWen
//
//  Created by 贺楠 on 16/6/3.
//  Copyright © 2016年 贺楠. All rights reserved.
//

#import "mineVC.h"
#import "SheZhiVC.h"
#import "yingyongtuijianVC.h"
#import "wodeguanzhuVC.h"
#import "LoginNavC.h"
#import "LoginVC.h"
#import "gerenzhuyeVC.h"
#import "DownloadViewController.h"
#import "AppDelegate.h"
#import "BlogViewController.h"
#import "UIView+tap.h"
#import "SingleWebViewController.h"
#import "HelpAndFeedbackViewController.h"
#import "TTTAttributedLabel.h"
#import "PayViewController.h"
#import "MyCollectionViewController.h"

#define KunitTime 1.0

typedef void(^animateBlock)();

@interface mineVC ()<UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate>
{
    //animateBlock Arr
    NSMutableArray * _animateArr;
}
@property(strong,nonatomic)UITableView *tableView;

@property (strong, nonatomic) NSMutableDictionary *pushNewsInfo;

@property (strong, nonatomic) UIButton *newPersonMessageButton;

@property (strong, nonatomic) UIButton *newFriendMessageButton;

@property (strong, nonatomic) UIButton *newSettingMessageButton;

@property (strong, nonatomic) UIView *signInView;

@property (strong, nonatomic) UIImageView *signInImageView;

@property (strong, nonatomic) NSTimer * time;

@property (assign, nonatomic) BOOL isSigned;

@property (strong, nonatomic) UIView *experienceView;
@property (strong, nonatomic) UILabel *exp;


@end

@implementation mineVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.signInView];
    _animateArr=@[].mutableCopy;
    //+ 经验
    _experienceView = [[UIView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 63, SCREEN_HEIGHT - 160, 40, 40)];
    _experienceView.alpha=0;
    [self.view addSubview:_experienceView];
    UILabel *exptitle = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 35, 20)];
    [exptitle setText:@"经验"];
    [exptitle setFont:[UIFont systemFontOfSize:10.0]];
    [exptitle setTextColor:gTextDownload];
    [_experienceView addSubview:exptitle];
    _exp = [[UILabel alloc]initWithFrame:CGRectMake(5, 15, 35, 20)];
    //每日签到 +2经验
    [_exp setText:@"+2"];
    [_exp setFont:[UIFont systemFontOfSize:10.0]];
    [_exp setTextColor:UIColorFromHex(0xF67825)];
    [_experienceView addSubview:_exp];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginAlert:) name:@"loginAlert" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserInfo:) name:@"updateUserInfo" object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    if ([[CommonCode readFromUserD:@"isLogin"]boolValue] == YES){
        self.signInView.hidden = NO;
        NSDictionary *userInfo = [CommonCode readFromUserD:@"dangqianUserInfo"];
        if ([userInfo[results][@"sign"] isEqualToString:@"0"]) {
            self.isSigned = NO;
            [_signInImageView setImage:[UIImage imageNamed:@"sign_in"]];
            //TODO:未签到时添加动画
            CAKeyframeAnimation *anim = [CAKeyframeAnimation animation];
            anim.keyPath = @"position";
            anim.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(SCREEN_WIDTH - 23 - 18, SCREEN_HEIGHT - 85 - 60, 0, 10)].CGPath;
            anim.repeatCount = HUGE_VALF;
            anim.duration = 1.0;
            anim.calculationMode = kCAAnimationPaced;//动画连续效果
            [self.signInView.layer addAnimation:anim forKey:nil];
            
        }
        else{
            self.isSigned = YES;
            [_signInImageView setImage:[UIImage imageNamed:@"sign_ined"]];
        }
    }
    else{
        self.signInView.hidden = YES;
    }
    [self getUnreadMessage];
    
}

#pragma mark - Utilities

- (void)updateUserInfo:(NSNotification *)notification{
    //获取个人经验值，听币，金币,签到情况以及个人信息，粉丝数，关注数
    NSDictionary *userInfo = [CommonCode readFromUserD:@"dangqianUserInfo"];
    if ([[CommonCode readFromUserD:@"isWhatLogin"] isEqualToString:@"QQ"]){
        ExdangqianUser = [CommonCode readFromUserD:@"user_login"];
    }
    else if ([[CommonCode readFromUserD:@"isWhatLogin"] isEqualToString:@"ShouJi"]){
        ExdangqianUser = [CommonCode readFromUserD:@"dangqianUser"];
    }
    else if ([[CommonCode readFromUserD:@"isWhatLogin"] isEqualToString:@"WeiBo"]){
        ExdangqianUser = [CommonCode readFromUserD:@"user_login"];
    }
    else if ([[CommonCode readFromUserD:@"isWhatLogin"] isEqualToString:@"weixin"]){
        ExdangqianUser = [CommonCode readFromUserD:@"user_login"];
    }
    [NetWorkTool getMyuserinfoWithaccessToken:AvatarAccessToken user_id:userInfo[results][@"id"]  sccess:^(NSDictionary *responseObject) {
        RTLog(@"%@",responseObject);
        if ([responseObject[@"msg"] isEqualToString:@"获取成功!"]) {
            if ([[CommonCode readFromUserD:@"isWhatLogin"] isEqualToString:@"QQ"]){
                ExdangqianUser = responseObject[results][@"user_login"];
            }
            else if ([[CommonCode readFromUserD:@"isWhatLogin"] isEqualToString:@"ShouJi"]){
                ExdangqianUser = responseObject[results][@"user_phone"];
            }
            else if ([[CommonCode readFromUserD:@"isWhatLogin"] isEqualToString:@"WeiBo"]){
                ExdangqianUser = responseObject[results][@"user_login"];
            }
            else if ([[CommonCode readFromUserD:@"isWhatLogin"] isEqualToString:@"weixin"]){
                ExdangqianUser = responseObject[results][@"user_login"];
            }
            [CommonCode writeToUserD:ExdangqianUser andKey:@"dangqianUser"];
            [CommonCode writeToUserD:responseObject[results][@"id"] andKey:@"dangqianUserUid"];
            [CommonCode writeToUserD:@(YES) andKey:@"isLogin"];
            [CommonCode writeToUserD:responseObject andKey:@"dangqianUserInfo"];
            //拿到图片
            UIImage *userAvatar = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:USERPHOTOHTTPSTRING(responseObject[results][@"avatar"])]]];
            NSString *path_sandox = NSHomeDirectory();
            //设置一个图片的存储路径
            NSString *avatarPath = [path_sandox stringByAppendingString:@"/Documents/userAvatar.png"];
            //把图片直接保存到指定的路径（同时应该把图片的路径imagePath存起来，下次就可以直接用来取）
            [UIImagePNGRepresentation(userAvatar) writeToFile:avatarPath atomically:YES];
            [self.tableView reloadData];
        }
    } failure:^(NSError *error) {
        NSLog(@"%@",error);
    }];
}

- (void)dianjitouxiangshijian {
    if ([[CommonCode readFromUserD:@"isLogin"]boolValue] == YES){
        gerenzhuyeVC *gerenzhuye = [gerenzhuyeVC new];
        gerenzhuye.isMypersonalPage = YES;
        gerenzhuye.isNewsComment = NO;
        gerenzhuye.user_nicename = [CommonCode readFromUserD:@"dangqianUserInfo"][results][@"user_nicename"];
        gerenzhuye.sex = [CommonCode readFromUserD:@"dangqianUserInfo"][results][@"sex"];
        gerenzhuye.signature =  [CommonCode readFromUserD:@"dangqianUserInfo"][results][@"signature"];
        gerenzhuye.user_login = ExdangqianUser;
        gerenzhuye.fan_num = @"0";
        gerenzhuye.guan_num = @"0";
        self.hidesBottomBarWhenPushed=YES;
        [self.navigationController pushViewController:gerenzhuye animated:YES];
        self.hidesBottomBarWhenPushed=NO;
    }
    else{
        LoginVC *loginFriVC = [LoginVC new];
        LoginNavC *loginNavC = [[LoginNavC alloc]initWithRootViewController:loginFriVC];
        [loginNavC.navigationBar setBackgroundColor:[UIColor whiteColor]];
        loginNavC.navigationBar.tintColor = [UIColor blackColor];
        [self presentViewController:loginNavC animated:YES completion:nil];
    }
}

- (void)payButtonAction:(UIButton *)sender
{
    [self.navigationController pushViewController:[PayViewController new] animated:YES];
}

- (void)loginFirst {
    
    UIAlertController *qingshuruyonghuming = [UIAlertController alertControllerWithTitle:@"温馨提示\n 您还没登录，请先登录后操作" message:nil preferredStyle:UIAlertControllerStyleAlert];
    qingshuruyonghuming.accessibilityLabel = @"温馨提示 您还没登录，请先登录后操作 取消、登录";
    [qingshuruyonghuming addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [qingshuruyonghuming addAction:[UIAlertAction actionWithTitle:@"登录" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        LoginVC *loginFriVC = [LoginVC new];
        LoginNavC *loginNavC = [[LoginNavC alloc]initWithRootViewController:loginFriVC];
        [loginNavC.navigationBar setBackgroundColor:[UIColor whiteColor]];
        loginNavC.navigationBar.tintColor = [UIColor blackColor];
        [self presentViewController:loginNavC animated:YES completion:nil];
    }]];
    
    [self presentViewController:qingshuruyonghuming animated:YES completion:nil];
}

- (void)loginAlert:(NSNotification *)notification{
    [self loginFirst];
}
/**
 根据推送ID获取新闻详情数据
 */
- (void)getPushNewsDetail{
    DefineWeakSelf;
    [NetWorkTool getpostinfoWithpost_id:[[NSUserDefaults standardUserDefaults]valueForKey:@"pushNews"] andpage:nil andlimit:nil sccess:^(NSDictionary *responseObject) {
        if ([responseObject[@"status"] integerValue] == 1) {
            weakSelf.pushNewsInfo = [responseObject[results] mutableCopy];
            [NetWorkTool getAllActInfoListWithAccessToken:nil ac_id:weakSelf.pushNewsInfo[@"post_news"] keyword:nil andPage:nil andLimit:nil sccess:^(NSDictionary *responseObject) {
                if ([responseObject[@"status"] integerValue] == 1){
                    [weakSelf.pushNewsInfo setObject:[responseObject[results] firstObject] forKey:@"post_act"];
                    [weakSelf presentPushNews];
                }
                else{
                    [SVProgressHUD showErrorWithStatus:responseObject[@"msg"]];
                }
            } failure:^(NSError *error) {
                //
                [SVProgressHUD showErrorWithStatus:@"网络请求失败"];
            }];
        }
        else{
            [SVProgressHUD showErrorWithStatus:responseObject[@"msg"]];
        }
        
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"网络请求失败"];
        NSLog(@"%@",error);
    }];
}
/**
 通知消息点击跳转新闻详情界面播放
 */
- (void)presentPushNews
{
    [ZRT_PlayerManager manager].songList = @[self.pushNewsInfo];
    [ZRT_PlayerManager manager].currentSong = self.pushNewsInfo;
    //设置播放器播放内容类型
    [ZRT_PlayerManager manager].playType = ZRTPlayTypeNews;
    [NewPlayVC shareInstance].rewardType = RewardViewTypeNone;
    [ZRT_PlayerManager manager].channelType = ChannelTypeChannelNone;
    [[NewPlayVC shareInstance] playFromIndex:0];
    [self.navigationController.navigationBar setHidden:YES];
    [self.navigationController pushViewController:[NewPlayVC shareInstance] animated:YES];
}
/**
 点击中心按钮跳转上一次记录新闻详情界面播放
 */
- (void)skipToLastNews
{
    [ZRT_PlayerManager manager].songList = [CommonCode readFromUserD:NewPlayVC_PLAYLIST];
    [ZRT_PlayerManager manager].currentSong = [CommonCode readFromUserD:NewPlayVC_THELASTNEWSDATA];
    //设置播放器播放内容类型
    [ZRT_PlayerManager manager].playType = ZRTPlayTypeNews;
    [NewPlayVC shareInstance].rewardType = RewardViewTypeNone;
    [ZRT_PlayerManager manager].channelType = [[CommonCode readFromUserD:NewPlayVC_PLAY_CHANNEL] intValue];
    [[NewPlayVC shareInstance] playFromIndex:[[CommonCode readFromUserD:NewPlayVC_PLAY_INDEX] integerValue]];
    [self.navigationController.navigationBar setHidden:YES];
    [self.navigationController pushViewController:[NewPlayVC shareInstance] animated:YES];
}

-(void)animat{
    
    self.signInImageView.alpha = 1;
    [UIView animateWithDuration:0.4 animations:^{
        CGRect fram = self.signInImageView.frame;
        fram.origin.y += 15;
        self.signInImageView.frame = fram;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 animations:^{
            CGRect fram = self.signInImageView.frame;
            fram.origin.y -= 15;
            self.signInImageView.frame = fram;
        }];
    }];
}

- (void)signInAction:(UITapGestureRecognizer *)tap
{
    if (self.isSigned) {
        [self.signInImageView setImage:[UIImage imageNamed:@"sign_ined"]];
        [self.signInView.layer removeAllAnimations];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUserInfo" object:nil];
    }
    else{
        tap.view.userInteractionEnabled = NO;
        //签到
        NSDictionary *userInfo = [CommonCode readFromUserD:@"dangqianUserInfo"];
        NSString *accesstoken = nil;
        if ([[CommonCode readFromUserD:@"isWhatLogin"] isEqualToString:@"ShouJi"]) {
            //
            accesstoken = [DSE encryptUseDES:userInfo[results][@"user_phone"]];
        }
        else{
            accesstoken = AvatarAccessToken;
        }
        [NetWorkTool signInWithaccessToken:AvatarAccessToken sccess:^(NSDictionary *responseObject) {
            tap.view.userInteractionEnabled = YES;
            if ([responseObject[@"msg"] isEqualToString:@"签到成功!"]) {
                self.isSigned = YES;
                [self.signInImageView setImage:[UIImage imageNamed:@"sign_ined"]];
                [self.signInView.layer removeAllAnimations];
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUserInfo" object:nil];
                [self showUpAnimations];
                [self getUnreadMessage];
            }
            else if([responseObject[@"msg"] isEqualToString:@"签到失败，今天已经签到过了!"]){
                self.isSigned = YES;
                [self.signInImageView setImage:[UIImage imageNamed:@"sign_ined"]];
                [self.signInView.layer removeAllAnimations];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUserInfo" object:nil];
                [self showUpAnimations];
                [self getUnreadMessage];
            }
            else {
                XWAlerLoginView *alert = [[XWAlerLoginView alloc] initWithTitle:responseObject[@"msg"]];
                [alert show];
            }
        } failure:^(NSError *error) {
            tap.view.userInteractionEnabled = YES;
        }];
    }
}

- (void)lvQAButtonAction{
    
    NSURL *url = [NSURL URLWithString:HelpCenterUrl];
    SingleWebViewController *singleWebVC = [[SingleWebViewController alloc] initWithTitle:@"帮助中心" url:url];
    [self.navigationController pushViewController:singleWebVC animated:YES];
}

- (void)showUpAnimations
{
    animateBlock up = ^(){
        _experienceView.frame = CGRectMake(SCREEN_WIDTH - 63, SCREEN_HEIGHT - 160, 40, 40);
        _experienceView.alpha=0;
        [UIView animateWithDuration:KunitTime delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _experienceView.alpha=1;
            _experienceView.frame = CGRectMake(SCREEN_WIDTH - 63, SCREEN_HEIGHT - 200, 40, 40);
        } completion:^(BOOL finished) {
            [self removeAni];
        }];
    };
    [_animateArr addObject:up];
    [self nextAnimate];
}

-(void)nextAnimate{
    
    if (_animateArr.count==0) {
        _experienceView.frame = CGRectMake(SCREEN_WIDTH - 63, SCREEN_HEIGHT - 160, 40, 40);
        _experienceView.alpha=0;
        return;
    }
    animateBlock ani= [_animateArr firstObject];
    ani();
}

-(void)removeAni{
    //数组越界删除崩溃bug
    if (_animateArr.count != 0) {
        [_animateArr removeObjectAtIndex:0];
    }
    [self nextAnimate];
}

- (void)getUnreadMessage{
    //TODO:未读消息小红点
    if ([CommonCode readFromUserD:FEEDBACKYMESSAGEREAD] == nil) {
        [CommonCode writeToUserD:@"NO" andKey:FEEDBACKYMESSAGEREAD];
    }
    if ([CommonCode readFromUserD:TINGYOUQUANMESSAGEREAD] == nil) {
        [CommonCode writeToUserD:@"NO" andKey:TINGYOUQUANMESSAGEREAD];
    }
    if ([[CommonCode readFromUserD:@"isLogin"]boolValue] == YES){
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_group_t group = dispatch_group_create();
        
        dispatch_group_enter(group);
        dispatch_group_async(group, queue, ^{
            [NetWorkTool getFeedbackForMeWithaccessToken:AvatarAccessToken sccess:^(NSDictionary *responseObject) {
                dispatch_group_leave(group);
                if ([responseObject[status] integerValue] == 1) {
                    if ([responseObject[results] isKindOfClass:[NSArray class]]){
                        NSString *unreadID = [CommonCode readFromUserD:FEEDBACKFIRSTUNREADID];
                        NSMutableArray *resultArr = [responseObject[results] mutableCopy];
                        if (unreadID == nil) {
                            unreadID = [responseObject[results] firstObject][@"id"];
                            [CommonCode writeToUserD:[responseObject[results] firstObject][@"id"] andKey:FEEDBACKFIRSTUNREADID];
                            [CommonCode writeToUserD:responseObject[results] andKey:FEEDBACKFORMEDATAKEY];
                            [CommonCode writeToUserD:@"NO" andKey:FEEDBACKYMESSAGEREAD];
                            
                        }
                        else{
                            NSRange range;
                            for (int i = 0 ; i < [resultArr count]; i ++) {
                                if ([resultArr[i][@"id"] isEqualToString:unreadID ]) {
                                    range = NSMakeRange(i, [resultArr count] - i);
                                    break;
                                }
                            }
                            if (range.location < [resultArr count]) {
                                if (![[CommonCode readFromUserD:FEEDBACKYMESSAGEREAD] isEqualToString:@"NO"]) {
                                    [resultArr removeObjectsInRange:range];
                                }
                            }
                            [CommonCode writeToUserD:resultArr andKey:FEEDBACKFORMEDATAKEY];
                            if ([resultArr count]) {
                                [CommonCode writeToUserD:@"NO" andKey:FEEDBACKYMESSAGEREAD];
                            }
                        }
                        if ([resultArr count] && [[CommonCode readFromUserD:FEEDBACKYMESSAGEREAD] isEqualToString:@"NO"] ) {
                            [self.newSettingMessageButton setHidden:NO];
                            [self.newSettingMessageButton setTitle:[NSString stringWithFormat:@"%lu",[resultArr count]] forState:UIControlStateNormal];
                        }
                        else{
                            [self.newSettingMessageButton setHidden:YES];
                        }
                    }
                    else{
                        [CommonCode writeToUserD:nil andKey:FEEDBACKFORMEDATAKEY];
                        [self.newSettingMessageButton setHidden:YES];
                    }
                }
            } failure:^(NSError *error) {
                dispatch_group_leave(group);
            }];
        });
        dispatch_group_enter(group);
        dispatch_group_async(group, queue, ^{
            [NetWorkTool getNewPromptForMeWithaccessToken:AvatarAccessToken andpage:@"1" andlimit:@"100" sccess:^(NSDictionary *responseObject) {
                dispatch_group_leave(group);
                if ([responseObject[@"status"] integerValue] == 1) {
                    if ([responseObject[results] isKindOfClass:[NSArray class]]){
                        NSString *unreadID1 = [CommonCode readFromUserD:TINGYOUQUANFIRSTUNREADID];
                        NSMutableArray *resultArrr = [responseObject[results] mutableCopy];
                        if (unreadID1 == nil) {
                            unreadID1 = [responseObject[results] firstObject][@"id"];
                            [CommonCode writeToUserD:[responseObject[results] firstObject][@"id"] andKey:TINGYOUQUANFIRSTUNREADID];
                            [CommonCode writeToUserD:responseObject[results] andKey:NEWPROMPTFORMEDATAKEY];
                            [CommonCode writeToUserD:@"NO" andKey:TINGYOUQUANMESSAGEREAD];
                        }
                        else{
                            
                            NSRange range;
                            for (int i = 0 ; i < [resultArrr count]; i ++) {
                                if ([resultArrr[i][@"id"] isEqualToString:unreadID1 ]) {
                                    range = NSMakeRange(i, [resultArrr count] - i);
                                    break;
                                }
                            }
                            if (range.location < [resultArrr count]) {
                                if (![[CommonCode readFromUserD:TINGYOUQUANMESSAGEREAD] isEqualToString:@"NO"]) {
                                    [resultArrr removeObjectsInRange:range];
                                }
                                
                            }
                            [CommonCode writeToUserD:resultArrr andKey:NEWPROMPTFORMEDATAKEY];
                            if ([resultArrr count]) {
                                [CommonCode writeToUserD:@"NO" andKey:TINGYOUQUANMESSAGEREAD];
                            }
                        }
                        if ([resultArrr count] && [[CommonCode readFromUserD:TINGYOUQUANMESSAGEREAD] isEqualToString:@"NO"]) {
                            [self.newFriendMessageButton setHidden:NO];
                            [self.newFriendMessageButton setTitle:[NSString stringWithFormat:@"%lu",[resultArrr count]] forState:UIControlStateNormal];
                        }
                        else{
                            [self.newFriendMessageButton setHidden:YES];
                        }
                    }
                    else{
                        [CommonCode writeToUserD:nil andKey:NEWPROMPTFORMEDATAKEY];
                        [self.newFriendMessageButton setHidden:YES];
                    }
                }
            } failure:^(NSError *error) {
                dispatch_group_leave(group);
            }];
        });
        dispatch_group_enter(group);
        dispatch_group_async(group, queue, ^{
            
            NSString *lastReadTime = [CommonCode readFromUserD:PERSONALLASTREAD];
            [NetWorkTool getAddcriticismNumWithaccessToken:AvatarAccessToken andpage:@"1" andlimit:@"100" anddate:lastReadTime sccess:^(NSDictionary *responseObject) {
                dispatch_group_leave(group);
                if ([responseObject[@"status"] integerValue] == 1) {
                    if ([responseObject[results] isKindOfClass:[NSArray class]]){
                        [CommonCode writeToUserD:responseObject[results] andKey:ADDCRITICISMNUMDATAKEY];
                        [self.newPersonMessageButton setHidden:NO];
                        [self.newPersonMessageButton setTitle:[NSString stringWithFormat:@"%lu",[responseObject[results] count]] forState:UIControlStateNormal];
                        
                    }
                    else{
                        [CommonCode writeToUserD:nil andKey:ADDCRITICISMNUMDATAKEY];
                        [self.newPersonMessageButton setHidden:YES];
                    }
                }
                
            } failure:^(NSError *error) {
                dispatch_group_leave(group);
            }];
        });
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            //设置 我 的未读消息
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setMyunreadMessageTips" object:nil];
        });
    }
    else{
        [self.newPersonMessageButton setHidden:YES];
        [self.newFriendMessageButton setHidden: YES];
        [self.newSettingMessageButton setHidden:YES];
        //        [self loginFirst];
    }
    [self.tableView reloadData];
}

#pragma mark --- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[CommonCode readFromUserD:@"isIAP"] boolValue] == YES?6:7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([[CommonCode readFromUserD:@"isIAP"] boolValue] == YES) {
        if (indexPath.row == 0){
            static NSString *wotouxiangcellIdentify = @"wotouxiangcellIdentify";
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:wotouxiangcellIdentify];
//            cell.backgroundColor = [UIColor redColor];
            if (!cell){
                
                cell = [tableView dequeueReusableCellWithIdentifier:wotouxiangcellIdentify];
            }
            
            UIImageView *cellBgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, -20, SCREEN_WIDTH,240.0 / 667 * IPHONE_H)];
            [cellBgView setUserInteractionEnabled:YES];
            [cell.contentView addSubview:cellBgView];
            
            UIImageView *ShadowImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, -20, SCREEN_WIDTH, 240.0 / 667 * IPHONE_H)];
            [cellBgView setUserInteractionEnabled:YES];
            [cell.contentView addSubview:ShadowImageView];
            
            UIImageView *coverView = [UIImageView new];
            [coverView setFrame:CGRectMake(0, -20, SCREEN_WIDTH, 240.0/ 667 * IPHONE_H)];
            [coverView setImage:[UIImage imageNamed:@"me_topbg1"]];
            [cell.contentView addSubview:coverView];
            
            //title
            UILabel *topLab = [[UILabel alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 44 )/2,IS_IPHONEX?20:0, 44, 44)];
            topLab.textColor = gTextColorMain;
            topLab.font = [UIFont fontWithName:@"Semibold" size:17.0f ];
            topLab.text = @"我";
            topLab.backgroundColor = [UIColor clearColor];
            topLab.textAlignment = NSTextAlignmentCenter;
            [cell.contentView addSubview:topLab];
            
            UIView *imgBorderView = [[UIView alloc]initWithFrame:CGRectMake(30.0 / 667 * IPHONE_H, 170.0 / 667 * IPHONE_H, 95.0 / 667 * IPHONE_H, 95.0 / 667 * IPHONE_H)];
            [imgBorderView setBackgroundColor:gImageBorderColor];
            [imgBorderView setUserInteractionEnabled:YES];
            [imgBorderView.layer setMasksToBounds:YES];
            [imgBorderView.layer setCornerRadius:95.0 / 667 * IPHONE_H / 2];
            [cell.contentView addSubview:imgBorderView];
            
            UIImageView *titleImage = [[UIImageView alloc]initWithFrame:CGRectMake(2.5/ 667 * IPHONE_H, 2.5 / 667 *IPHONE_H, 90.0 / 667 * IPHONE_H, 90.0 / 667 * IPHONE_H)];
            titleImage.image = [UIImage imageWithContentsOfFile:ExTouXiangPath];
            ShadowImageView.image = [UIImage imageWithContentsOfFile:ExTouXiangPath];
            ShadowImageView.contentMode = UIViewContentModeScaleAspectFill;
            ShadowImageView.clipsToBounds = YES;
            
            if (titleImage.image == nil){
                titleImage.image = [UIImage imageNamed:@"right-1"];
            }
            titleImage.layer.cornerRadius = titleImage.frame.size.width / 2;
            titleImage.clipsToBounds = YES;
            titleImage.userInteractionEnabled = YES;
            [titleImage addTapGesWithTarget:self action:@selector(dianjitouxiangshijian)];
            [imgBorderView addSubview:titleImage];
            //加边框
            CALayer *layer = [titleImage layer];
            layer.borderColor = [gImageBorderColor CGColor];
            layer.borderWidth = 0.0f;
            [self.newPersonMessageButton setHidden:YES];
            [cell.contentView addSubview:self.newPersonMessageButton];
            
            
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(imgBorderView.frame) + 12, imgBorderView.frame.origin.y + 10.0 / 667 * IPHONE_H, SCREEN_WIDTH - 150, 20.0 / 667 * IPHONE_H)];
            lab.font = [UIFont fontWithName:@"Semibold" size:18.0f ];
            lab.textColor = [UIColor blackColor];
            //        lab.backgroundColor = [UIColor greenColor];
            lab.textAlignment = NSTextAlignmentLeft;
            [lab addTapGesWithTarget:self action:@selector(dianjitouxiangshijian)];
            [cell.contentView addSubview:lab];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            //vip图标
            UIImageView *vipImgView = [[UIImageView alloc] init];
            vipImgView.hidden = YES;
            vipImgView.contentMode = UIViewContentModeScaleAspectFill;
            [cell.contentView addSubview:vipImgView];
            
            UIImageView *lvView = [[UIImageView alloc]initWithFrame:CGRectMake(vipImgView.hidden? CGRectGetMaxX(lab.frame) + 5:CGRectGetMaxX(vipImgView.frame) + 5, lab.frame.origin.y, 44.0, 16.0)];
            [lvView setImage:[UIImage imageNamed:@"LV1~9"]];
            lvView.hidden = YES;
            lvView.contentMode = UIViewContentModeScaleAspectFill;
            lvView.clipsToBounds = YES;
            [lvView addTapGesWithTarget:self action:@selector(lvQAButtonAction)];
            [cell.contentView addSubview:lvView];
            
            UILabel *lvLab = [[UILabel alloc]initWithFrame:CGRectMake(lvView.frame.size.width - 20, 0, 25, 16)];
            [lvLab setFont:gFontMain12];
            [lvLab setTextAlignment:NSTextAlignmentCenter];
            [lvLab setTextColor:[UIColor whiteColor]];
            if (TARGETED_DEVICE_IS_IPHONE_480) {
                [lvLab setFrame:CGRectMake(lvView.frame.size.width - 25, 0, 25, 16)];
            }
            else if (TARGETED_DEVICE_IS_IPHONE_568){
                [lvLab setFrame:CGRectMake(lvView.frame.size.width - 25, 0, 25, 16)];
            }
            else if (TARGETED_DEVICE_IS_IPHONE_667){
                [lvLab setFrame:CGRectMake(lvView.frame.size.width - 20, 0, 25, 16)];
            }
            else if (TARGETED_DEVICE_IS_IPHONE_736){
                [lvLab setFrame:CGRectMake(lvView.frame.size.width - 20, 0, 25, 16)];
            }else if(IS_IPAD){
                [lvLab setFrame:CGRectMake(lvView.frame.size.width, 5, 25, 16)];
                [lvLab setFont:gFontMajor17];
            }else if(IS_IPHONEX){
                [lvLab setFrame:CGRectMake(lvView.frame.size.width - 10, 0, 25, 16)];
            }
            [lvView addSubview:lvLab];
            
            TTTAttributedLabel *signtureLab = [[TTTAttributedLabel alloc]initWithFrame:CGRectMake(lab.frame.origin.x, 230.0 / 667 * IPHONE_H, SCREEN_WIDTH - 150,20.0 / 667 * IPHONE_H)];
            [cell.contentView addSubview:signtureLab];
            
            if ([[CommonCode readFromUserD:@"isLogin"]boolValue] == YES){
                NSDictionary *userInfo = [CommonCode readFromUserD:@"dangqianUserInfo"];
                NSString *isNameNil = userInfo[results][@"user_nicename"];
                if (isNameNil.length == 0){
                    lab.text = userInfo[results][@"user_login"];
                }
                else{
                    lab.text = userInfo[results][@"user_nicename"];
                }
                
                //账户信息
                NSString *df = [NSString stringWithFormat:@"金币：%@ | 听币：%@",userInfo[results][@"gold"],userInfo[results][@"listen_money"]];
                NSMutableAttributedString *attriString =[[NSMutableAttributedString alloc] initWithString:df attributes:@{NSForegroundColorAttributeName:gTextDownload,NSFontAttributeName:gFontMain12}];
                NSRange range1=[df rangeOfString:[NSString stringWithFormat:@"%@",userInfo[results][@"gold"]]];
                [attriString addAttributes:@{NSForegroundColorAttributeName:UIColorFromHex(0xf78540),NSFontAttributeName:gFontMain12} range:range1];
                [signtureLab addLinkToTransitInformation:nil withRange:range1];
                NSRange range2=[df rangeOfString:[NSString stringWithFormat:@"%@",userInfo[results][@"listen_money"]]];
                [attriString addAttributes:@{NSForegroundColorAttributeName:UIColorFromHex(0xf78540),NSFontAttributeName:gFontMain12} range:range2];
                [signtureLab addLinkToTransitInformation:nil withRange:range2];
                signtureLab.attributedText = attriString;
                //充值按钮
                UIButton *payButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [payButton setFrame:CGRectMake(lab.frame.origin.x, 255.0 / 667 * IPHONE_H, 80.0 / 375 * SCREEN_WIDTH, 20.0 / 667 * IPHONE_H)];
                [payButton setBackgroundColor:gButtonRewardColor];
                [payButton setTitle:@"充值" forState:UIControlStateNormal];
                [payButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [payButton.titleLabel setFont:gFontMain12];
                [payButton.layer setMasksToBounds:YES];
                [payButton.layer setCornerRadius:8.0];
                [payButton addTarget:self action:@selector(payButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                [cell.contentView addSubview:payButton];
                
                CGSize contentSize = [lab sizeThatFits:CGSizeMake(lab.frame.size.width, MAXFLOAT)];
                lab.frame = CGRectMake(lab.frame.origin.x, lab.frame.origin.y,contentSize.width, lab.frame.size.height);
                
                NSDictionary *userInfoDict = [CommonCode readFromUserD:@"dangqianUserInfo"];
                
                //判断是否在审核中
                if ([[CommonCode readFromUserD:@"isIAP"] boolValue] == YES) {
                    vipImgView.hidden = YES;
                }else{
                    if ([userInfoDict[results][member_type] intValue] == 1||[userInfoDict[results][member_type] intValue] == 2) {
                        
                        vipImgView.frame = CGRectMake(CGRectGetMaxX(lab.frame) + 10, lab.y + 2, 30, 37);
                        vipImgView.centerY = lab.centerY;
                        vipImgView.hidden = NO;
                        if ([userInfoDict[results][member_type] intValue] == 1) {
                            vipImgView.image = [UIImage imageNamed:@"vip"];
                        }else{
                            vipImgView.image = [UIImage imageNamed:@"svip"];
                        }
                    }else{
                        vipImgView.hidden = YES;
                    }
                }
                
                [lvView setFrame:CGRectMake(vipImgView.hidden? CGRectGetMaxX(lab.frame) + 5:CGRectGetMaxX(vipImgView.frame) + 10,IS_IPHONEX? lab.frame.origin.y + 4:lab.frame.origin.y + 2, 50.0 / 667 * IPHONE_H,IS_IPHONEX?16.0:16.0 / 667 * IPHONE_H)];
                lvView.hidden = NO;
                NSInteger lv = [userInfo[results][@"level"] integerValue];
                if (lv > 0 && lv < 10) {
                    [lvView setImage:[UIImage imageNamed:@"LV1~9"]];
                }
                else if (lv >= 10 && lv < 20){
                    [lvView setImage:[UIImage imageNamed:@"LV10~19"]];
                }
                else if (lv >= 20 && lv < 30){
                    [lvView setImage:[UIImage imageNamed:@"LV20~29"]];
                }
                else if (lv >= 30 && lv < 40){
                    [lvView setImage:[UIImage imageNamed:@"LV30~39"]];
                }
                else if (lv >= 40 && lv < 50){
                    [lvView setImage:[UIImage imageNamed:@"LV40~49"]];
                }
                else if (lv >= 50 && lv < 60){
                    [lvView setImage:[UIImage imageNamed:@"LV50~59"]];
                }
                else if (lv >= 60 && lv < 70){
                    [lvView setImage:[UIImage imageNamed:@"LV60~69"]];
                }
                else if (lv >= 70 && lv < 80){
                    [lvView setImage:[UIImage imageNamed:@"LV70~79"]];
                }
                else if (lv >= 80 && lv < 90){
                    [lvView setImage:[UIImage imageNamed:@"LV80~89"]];
                }
                else if (lv >= 90 && lv < 99){
                    [lvView setImage:[UIImage imageNamed:@"LV90~99"]];
                }
                else{
                    [lvView setImage:[UIImage imageNamed:@"LV100"]];
                }
                [lvLab setText:userInfo[results][@"level"]];
                
            }
            else{
                lab.text = nil;
                signtureLab.text = nil;
                lvView.hidden = YES;
                vipImgView.hidden = YES;
            }
            
            return cell;
        }
        else if (indexPath.row == 1){
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"wotwoIdentify"];
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(40.0 / 375 * IPHONE_W,IS_IPHONEX?14.0:14.0 / 667 * IPHONE_H, 100.0 / 375 * IPHONE_W, 30.0 / 667 * IPHONE_H)];
            lab.text = @"听友圈";
            //        lab.text = @"我的关注";
            lab.textAlignment = NSTextAlignmentLeft;
            lab.textColor = nTextColorMain;
            [cell.contentView addSubview:lab];
            lab.font =  [UIFont fontWithName:@"Regular" size:17.0f ];
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(20.0 / 375 * IPHONE_W,IS_IPHONEX?57.0: 57.0 / 667 * IPHONE_H, SCREEN_WIDTH - 20.0 / 375 * IPHONE_W, 1)];
            [line setBackgroundColor:gThinLineColor];
            [cell.contentView addSubview:line];
            [self.newFriendMessageButton setHidden:YES];
            [cell.contentView addSubview:self.newFriendMessageButton];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        else if (indexPath.row == 2){
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"wothreeIdentify"];
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(40.0 / 375 * IPHONE_W, IS_IPHONEX?14.0:14.0 / 667 * IPHONE_H, 100.0 / 375 * IPHONE_W, 30.0 / 667 * IPHONE_H)];
            lab.text = @"我的下载";
            lab.textAlignment = NSTextAlignmentLeft;
            lab.textColor = nTextColorMain;
            [cell.contentView addSubview:lab];
            lab.font = gFontMajor17;
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(20.0 / 375 * IPHONE_W,IS_IPHONEX?57.0: 57.0 / 667 * IPHONE_H, SCREEN_WIDTH - 20.0 / 375 * IPHONE_W, 1)];
            [line setBackgroundColor:gThinLineColor];
            [cell.contentView addSubview:line];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        else if (indexPath.row == 3){
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"wofourIdentify"];
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(40.0 / 375 * IPHONE_W, IS_IPHONEX?14.0:14.0 / 667 * IPHONE_H, 100.0 / 375 * IPHONE_W, 30.0 / 667 * IPHONE_H)];
            lab.text = @"我的收藏";
            lab.textAlignment = NSTextAlignmentLeft;
            lab.textColor = nTextColorMain;
            [cell.contentView addSubview:lab];
            lab.font = gFontMajor17;
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(20.0 / 375 * IPHONE_W, IS_IPHONEX?57.0:57.0 / 667 * IPHONE_H, SCREEN_WIDTH - 20.0 / 375 * IPHONE_W, 1)];
            [line setBackgroundColor:gThinLineColor];
            [cell.contentView addSubview:line];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        else if (indexPath.row == 4){
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"wofourIdentify"];
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(40.0 / 375 * IPHONE_W, IS_IPHONEX?14.0:14.0 / 667 * IPHONE_H, 100.0 / 375 * IPHONE_W, 30.0 / 667 * IPHONE_H)];
            lab.text = @"我的课堂";
            lab.textAlignment = NSTextAlignmentLeft;
            lab.textColor = nTextColorMain;
            [cell.contentView addSubview:lab];
            lab.font = gFontMajor17;
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(20.0 / 375 * IPHONE_W, IS_IPHONEX?57.0:57.0 / 667 * IPHONE_H, SCREEN_WIDTH - 20.0 / 375 * IPHONE_W, 1)];
            [line setBackgroundColor:gThinLineColor];
            [cell.contentView addSubview:line];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        else {
            static NSString *wosixIdentify = @"wosixIdentify";
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:wosixIdentify];
            if (!cell){
                cell = [tableView dequeueReusableCellWithIdentifier:wosixIdentify];
            }
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(40.0 / 375 * IPHONE_W, 14.0 / 667 * IPHONE_H, 100.0 / 375 * IPHONE_W, 30.0 / 667 * IPHONE_H)];
            lab.text = @"设置";
            lab.textAlignment = NSTextAlignmentLeft;
            lab.textColor = nTextColorMain;
            [cell.contentView addSubview:lab];
            lab.font = gFontMajor17;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [self.newSettingMessageButton setHidden:YES];
            [cell.contentView addSubview:self.newSettingMessageButton];
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(20.0 / 375 * IPHONE_W, IS_IPHONEX?57.0:57.0 / 667 * IPHONE_H, SCREEN_WIDTH - 20.0 / 375 * IPHONE_W, 1)];
            [line setBackgroundColor:gThinLineColor];
            [cell.contentView addSubview:line];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
    }else{
        if (indexPath.row == 0){
            static NSString *wotouxiangcellIdentify = @"wotouxiangcellIdentify";
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:wotouxiangcellIdentify];
            if (!cell){
                
                cell = [tableView dequeueReusableCellWithIdentifier:wotouxiangcellIdentify];
            }
            
            UIImageView *cellBgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, -20, SCREEN_WIDTH, 240.0 / 667 * IPHONE_H)];
            [cellBgView setUserInteractionEnabled:YES];
            [cell.contentView addSubview:cellBgView];
            
            UIImageView *ShadowImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, -20, SCREEN_WIDTH, 240.0 / 667 * IPHONE_H)];
            [cellBgView setUserInteractionEnabled:YES];
            [cell.contentView addSubview:ShadowImageView];
            
            UIImageView *coverView = [UIImageView new];
            [coverView setFrame:CGRectMake(0, -20, SCREEN_WIDTH, 240.0/ 667 * IPHONE_H)];
            [coverView setImage:[UIImage imageNamed:@"me_topbg1"]];
            [cell.contentView addSubview:coverView];
            
            //title
            UILabel *topLab = [[UILabel alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 44 )/2, IS_IPHONEX?20:0, 44, 44)];
            topLab.textColor = gTextColorMain;
            topLab.font = [UIFont fontWithName:@"Semibold" size:17.0f ];
            topLab.text = @"我";
            topLab.backgroundColor = [UIColor clearColor];
            topLab.textAlignment = NSTextAlignmentCenter;
            [cell.contentView addSubview:topLab];
            
            UIView *imgBorderView = [[UIView alloc]initWithFrame:CGRectMake(30.0 / 667 * IPHONE_H, 170.0 / 667 * IPHONE_H, 95.0 / 667 * IPHONE_H, 95.0 / 667 * IPHONE_H)];
            [imgBorderView setBackgroundColor:gImageBorderColor];
            [imgBorderView setUserInteractionEnabled:YES];
            [imgBorderView.layer setMasksToBounds:YES];
            [imgBorderView.layer setCornerRadius:95.0 / 667 * IPHONE_H / 2];
            [cell.contentView addSubview:imgBorderView];
            
            UIImageView *titleImage = [[UIImageView alloc]initWithFrame:CGRectMake(2.5/ 667 * IPHONE_H, 2.5 / 667 *IPHONE_H, 90.0 / 667 * IPHONE_H, 90.0 / 667 * IPHONE_H)];
            titleImage.image = [UIImage imageWithContentsOfFile:ExTouXiangPath];
            ShadowImageView.image = [UIImage imageWithContentsOfFile:ExTouXiangPath];
            ShadowImageView.contentMode = UIViewContentModeScaleAspectFill;
            ShadowImageView.clipsToBounds = YES;
            
            if (titleImage.image == nil){
                titleImage.image = [UIImage imageNamed:@"right-1"];
            }
            titleImage.layer.cornerRadius = titleImage.frame.size.width / 2;
            titleImage.clipsToBounds = YES;
            titleImage.userInteractionEnabled = YES;
            [titleImage addTapGesWithTarget:self action:@selector(dianjitouxiangshijian)];
            [imgBorderView addSubview:titleImage];
            //加边框
            CALayer *layer = [titleImage layer];
            layer.borderColor = [gImageBorderColor CGColor];
            layer.borderWidth = 0.0f;
            [self.newPersonMessageButton setHidden:YES];
            [cell.contentView addSubview:self.newPersonMessageButton];
            
            
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(imgBorderView.frame) + 12, imgBorderView.frame.origin.y + 10.0 / 667 * IPHONE_H, SCREEN_WIDTH - 150, 20.0 / 667 * IPHONE_H)];
            lab.font = [UIFont fontWithName:@"Semibold" size:18.0f ];
            lab.textColor = [UIColor blackColor];
            //        lab.backgroundColor = [UIColor greenColor];
            lab.textAlignment = NSTextAlignmentLeft;
            [lab addTapGesWithTarget:self action:@selector(dianjitouxiangshijian)];
            [cell.contentView addSubview:lab];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            //vip图标
            UIImageView *vipImgView = [[UIImageView alloc] init];
            vipImgView.hidden = YES;
            vipImgView.contentMode = UIViewContentModeScaleAspectFill;
            [cell.contentView addSubview:vipImgView];
            
            UIImageView *lvView = [[UIImageView alloc]initWithFrame:CGRectMake(vipImgView.hidden? CGRectGetMaxX(lab.frame) + 5:CGRectGetMaxX(vipImgView.frame) + 5, lab.frame.origin.y, 44.0, 16.0)];
            [lvView setImage:[UIImage imageNamed:@"LV1~9"]];
            lvView.hidden = YES;
            lvView.contentMode = UIViewContentModeScaleAspectFill;
            lvView.clipsToBounds = YES;
            [lvView addTapGesWithTarget:self action:@selector(lvQAButtonAction)];
            [cell.contentView addSubview:lvView];
            
            UILabel *lvLab = [[UILabel alloc]initWithFrame:CGRectMake(lvView.frame.size.width - 20, 0, 25, 16)];
            [lvLab setFont:gFontMain12];
            [lvLab setTextAlignment:NSTextAlignmentCenter];
            [lvLab setTextColor:[UIColor whiteColor]];
            if (TARGETED_DEVICE_IS_IPHONE_480) {
                [lvLab setFrame:CGRectMake(lvView.frame.size.width - 25, 0, 25, 16)];
            }
            else if (TARGETED_DEVICE_IS_IPHONE_568){
                [lvLab setFrame:CGRectMake(lvView.frame.size.width - 25, 0, 25, 16)];
            }
            else if (TARGETED_DEVICE_IS_IPHONE_667){
                [lvLab setFrame:CGRectMake(lvView.frame.size.width - 20, 0, 25, 16)];
            }
            else if (TARGETED_DEVICE_IS_IPHONE_736){
                [lvLab setFrame:CGRectMake(lvView.frame.size.width - 20, 0, 25, 16)];
            }else if(IS_IPAD){
                [lvLab setFrame:CGRectMake(lvView.frame.size.width, 5, 25, 16)];
                [lvLab setFont:gFontMajor17];
            }else if(IS_IPHONEX){
                [lvLab setFrame:CGRectMake(lvView.frame.size.width - 10, 0, 25, 16)];
            }
            [lvView addSubview:lvLab];
            
            TTTAttributedLabel *signtureLab = [[TTTAttributedLabel alloc]initWithFrame:CGRectMake(lab.frame.origin.x, 230.0 / 667 * IPHONE_H, SCREEN_WIDTH - 150, 20.0 / 667 * IPHONE_H)];
            [cell.contentView addSubview:signtureLab];
            
            if ([[CommonCode readFromUserD:@"isLogin"]boolValue] == YES){
                NSDictionary *userInfo = [CommonCode readFromUserD:@"dangqianUserInfo"];
                NSString *isNameNil = userInfo[results][@"user_nicename"];
                if (isNameNil.length == 0){
                    lab.text = userInfo[results][@"user_login"];
                }
                else{
                    lab.text = userInfo[results][@"user_nicename"];
                }
                
                //账户信息
                NSString *df = [NSString stringWithFormat:@"金币：%@ | 听币：%@",userInfo[results][@"gold"],userInfo[results][@"listen_money"]];
                NSMutableAttributedString *attriString =[[NSMutableAttributedString alloc] initWithString:df attributes:@{NSForegroundColorAttributeName:gTextDownload,NSFontAttributeName:gFontMain12}];
                NSRange range1=[df rangeOfString:[NSString stringWithFormat:@"%@",userInfo[results][@"gold"]]];
                [attriString addAttributes:@{NSForegroundColorAttributeName:UIColorFromHex(0xf78540),NSFontAttributeName:gFontMain12} range:range1];
                [signtureLab addLinkToTransitInformation:nil withRange:range1];
                NSRange range2=[df rangeOfString:[NSString stringWithFormat:@"%@",userInfo[results][@"listen_money"]]];
                [attriString addAttributes:@{NSForegroundColorAttributeName:UIColorFromHex(0xf78540),NSFontAttributeName:gFontMain12} range:range2];
                [signtureLab addLinkToTransitInformation:nil withRange:range2];
                signtureLab.attributedText = attriString;
                //充值按钮
                UIButton *payButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [payButton setFrame:CGRectMake(lab.frame.origin.x, 255.0 / 667 * IPHONE_H, 80.0 / 375 * SCREEN_WIDTH, 20.0 / 667 * IPHONE_H)];
                [payButton setBackgroundColor:gButtonRewardColor];
                [payButton setTitle:@"充值" forState:UIControlStateNormal];
                [payButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [payButton.titleLabel setFont:gFontMain12];
                [payButton.layer setMasksToBounds:YES];
                [payButton.layer setCornerRadius:8.0];
                [payButton addTarget:self action:@selector(payButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                [cell.contentView addSubview:payButton];
                
                CGSize contentSize = [lab sizeThatFits:CGSizeMake(lab.frame.size.width, MAXFLOAT)];
                lab.frame = CGRectMake(lab.frame.origin.x, lab.frame.origin.y,contentSize.width, lab.frame.size.height);
                
                NSDictionary *userInfoDict = [CommonCode readFromUserD:@"dangqianUserInfo"];
                
                //判断是否在审核中
                if ([[CommonCode readFromUserD:@"isIAP"] boolValue] == YES) {
                    vipImgView.hidden = YES;
                }else{
                    if ([userInfoDict[results][member_type] intValue] == 1||[userInfoDict[results][member_type] intValue] == 2) {
                        
                        vipImgView.frame = CGRectMake(CGRectGetMaxX(lab.frame) + 10, lab.y + 2, 30, 37);
                        vipImgView.centerY = lab.centerY;
                        vipImgView.hidden = NO;
                        if ([userInfoDict[results][member_type] intValue] == 1) {
                            vipImgView.image = [UIImage imageNamed:@"vip"];
                        }else{
                            vipImgView.image = [UIImage imageNamed:@"svip"];
                        }
                    }else{
                        vipImgView.hidden = YES;
                    }
                }
                
                [lvView setFrame:CGRectMake(vipImgView.hidden? CGRectGetMaxX(lab.frame) + 5:CGRectGetMaxX(vipImgView.frame) + 10, IS_IPHONEX? lab.frame.origin.y + 4:lab.frame.origin.y + 2, 50.0 / 667 * IPHONE_H, IS_IPHONEX?16.0:16.0 / 667 * IPHONE_H)];
                lvView.hidden = NO;
                NSInteger lv = [userInfo[results][@"level"] integerValue];
                if (lv > 0 && lv < 10) {
                    [lvView setImage:[UIImage imageNamed:@"LV1~9"]];
                }
                else if (lv >= 10 && lv < 20){
                    [lvView setImage:[UIImage imageNamed:@"LV10~19"]];
                }
                else if (lv >= 20 && lv < 30){
                    [lvView setImage:[UIImage imageNamed:@"LV20~29"]];
                }
                else if (lv >= 30 && lv < 40){
                    [lvView setImage:[UIImage imageNamed:@"LV30~39"]];
                }
                else if (lv >= 40 && lv < 50){
                    [lvView setImage:[UIImage imageNamed:@"LV40~49"]];
                }
                else if (lv >= 50 && lv < 60){
                    [lvView setImage:[UIImage imageNamed:@"LV50~59"]];
                }
                else if (lv >= 60 && lv < 70){
                    [lvView setImage:[UIImage imageNamed:@"LV60~69"]];
                }
                else if (lv >= 70 && lv < 80){
                    [lvView setImage:[UIImage imageNamed:@"LV70~79"]];
                }
                else if (lv >= 80 && lv < 90){
                    [lvView setImage:[UIImage imageNamed:@"LV80~89"]];
                }
                else if (lv >= 90 && lv < 99){
                    [lvView setImage:[UIImage imageNamed:@"LV90~99"]];
                }
                else{
                    [lvView setImage:[UIImage imageNamed:@"LV100"]];
                }
                [lvLab setText:userInfo[results][@"level"]];
                
            }
            else{
                lab.text = nil;
                signtureLab.text = nil;
                lvView.hidden = YES;
                vipImgView.hidden = YES;
            }
            
            return cell;
        }
        else if (indexPath.row == 1){
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"wotwoIdentify"];
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(40.0 / 375 * IPHONE_W, IS_IPHONEX?14.0:14.0 / 667 * IPHONE_H, 100.0 / 375 * IPHONE_W, 30.0 / 667 * IPHONE_H)];
            lab.text = @"听友圈";
            //        lab.text = @"我的关注";
            lab.textAlignment = NSTextAlignmentLeft;
            lab.textColor = nTextColorMain;
            [cell.contentView addSubview:lab];
            lab.font =  [UIFont fontWithName:@"Regular" size:17.0f ];
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(20.0 / 375 * IPHONE_W, IS_IPHONEX?57.0:57.0 / 667 * IPHONE_H, SCREEN_WIDTH - 20.0 / 375 * IPHONE_W, 1)];
            [line setBackgroundColor:gThinLineColor];
            [cell.contentView addSubview:line];
            [self.newFriendMessageButton setHidden:YES];
            [cell.contentView addSubview:self.newFriendMessageButton];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        else  if (indexPath.row == 2){
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"wofourIdentify"];
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(40.0 / 375 * IPHONE_W, IS_IPHONEX?14.0:14.0 / 667 * IPHONE_H, 100.0 / 375 * IPHONE_W, 30.0 / 667 * IPHONE_H)];
            lab.text = @"我的会员";
            lab.textAlignment = NSTextAlignmentLeft;
            lab.textColor = nTextColorMain;
            [cell.contentView addSubview:lab];
            lab.font = gFontMajor17;
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(20.0 / 375 * IPHONE_W, IS_IPHONEX?57.0:57.0 / 667 * IPHONE_H, SCREEN_WIDTH - 20.0 / 375 * IPHONE_W, 1)];
            [line setBackgroundColor:gThinLineColor];
            [cell.contentView addSubview:line];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        else if (indexPath.row == 3){
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"wothreeIdentify"];
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(40.0 / 375 * IPHONE_W, IS_IPHONEX?14.0:14.0 / 667 * IPHONE_H, 100.0 / 375 * IPHONE_W, 30.0 / 667 * IPHONE_H)];
            lab.text = @"我的下载";
            lab.textAlignment = NSTextAlignmentLeft;
            lab.textColor = nTextColorMain;
            [cell.contentView addSubview:lab];
            lab.font = gFontMajor17;
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(20.0 / 375 * IPHONE_W, IS_IPHONEX?57.0:57.0 / 667 * IPHONE_H, SCREEN_WIDTH - 20.0 / 375 * IPHONE_W, 1)];
            [line setBackgroundColor:gThinLineColor];
            [cell.contentView addSubview:line];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        else if (indexPath.row == 4){
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"wofourIdentify"];
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(40.0 / 375 * IPHONE_W, IS_IPHONEX?14.0:14.0 / 667 * IPHONE_H, 100.0 / 375 * IPHONE_W, 30.0 / 667 * IPHONE_H)];
            lab.text = @"我的收藏";
            lab.textAlignment = NSTextAlignmentLeft;
            lab.textColor = nTextColorMain;
            [cell.contentView addSubview:lab];
            lab.font = gFontMajor17;
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(20.0 / 375 * IPHONE_W, IS_IPHONEX?57.0:57.0 / 667 * IPHONE_H, SCREEN_WIDTH - 20.0 / 375 * IPHONE_W, 1)];
            [line setBackgroundColor:gThinLineColor];
            [cell.contentView addSubview:line];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        else if (indexPath.row == 5){
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"wofourIdentify"];
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(40.0 / 375 * IPHONE_W, IS_IPHONEX?14.0:14.0 / 667 * IPHONE_H, 100.0 / 375 * IPHONE_W, 30.0 / 667 * IPHONE_H)];
            lab.text = @"我的课堂";
            lab.textAlignment = NSTextAlignmentLeft;
            lab.textColor = nTextColorMain;
            [cell.contentView addSubview:lab];
            lab.font = gFontMajor17;
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(20.0 / 375 * IPHONE_W, IS_IPHONEX?57.0:57.0 / 667 * IPHONE_H, SCREEN_WIDTH - 20.0 / 375 * IPHONE_W, 1)];
            [line setBackgroundColor:gThinLineColor];
            [cell.contentView addSubview:line];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        else {
            static NSString *wosixIdentify = @"wosixIdentify";
            UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:wosixIdentify];
            if (!cell){
                cell = [tableView dequeueReusableCellWithIdentifier:wosixIdentify];
            }
            UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(40.0 / 375 * IPHONE_W, IS_IPHONEX?14.0:14.0 / 667 * IPHONE_H, 100.0 / 375 * IPHONE_W, 30.0 / 667 * IPHONE_H)];
            lab.text = @"设置";
            lab.textAlignment = NSTextAlignmentLeft;
            lab.textColor = nTextColorMain;
            [cell.contentView addSubview:lab];
            lab.font = gFontMajor17;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [self.newSettingMessageButton setHidden:YES];
            [cell.contentView addSubview:self.newSettingMessageButton];
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(20.0 / 375 * IPHONE_W, IS_IPHONEX?57.0:57.0 / 667 * IPHONE_H, SCREEN_WIDTH - 20.0 / 375 * IPHONE_W, 1)];
            [line setBackgroundColor:gThinLineColor];
            [cell.contentView addSubview:line];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0){
        return 265.0 / 667 * IPHONE_H;
    }
    else{
        return IS_IPHONEX?58.0:58.0f / 667 * IPHONE_H;
    }
    
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([[CommonCode readFromUserD:@"isIAP"] boolValue] == YES) {
        if (indexPath.row == 0) {
            //        [self dianjitouxiangshijian];
        }
        else if (indexPath.row == 1) {
            if ([[CommonCode readFromUserD:@"isLogin"]boolValue] == YES){
                
                BlogViewController *blogVC = [BlogViewController new];
                blogVC.view.backgroundColor = [UIColor whiteColor];
                blogVC.isFeedbackVC = NO;
                [self.navigationController pushViewController:blogVC animated:YES];
            }
            else {
                [self loginFirst];
            }
        }
        else if (indexPath.row == 2) {
            [self.navigationController pushViewController:[DownloadViewController new] animated:NO];
        }
        else if (indexPath.row == 3) {
            if ([[CommonCode readFromUserD:@"isLogin"]boolValue] == YES){
                [self.navigationController pushViewController:[MyCollectionViewController new] animated:YES];
            }
            else {
                [self loginFirst];
            }
        }
        else if (indexPath.row == 4) {
            if ([[CommonCode readFromUserD:@"isLogin"]boolValue] == YES){
                [self.navigationController pushViewController:[MyClassroomController new] animated:YES];
            }
            else {
                [self loginFirst];
            }
        }
        else if (indexPath.row == 5) {
            [self.navigationController pushViewController:[SheZhiVC new] animated:YES];
        }
    }else{
        if (indexPath.row == 0) {
        }
        else if (indexPath.row == 1) {
            if ([[CommonCode readFromUserD:@"isLogin"]boolValue] == YES){
                
                BlogViewController *blogVC = [BlogViewController new];
                blogVC.view.backgroundColor = [UIColor whiteColor];
                blogVC.isFeedbackVC = NO;
                [self.navigationController pushViewController:blogVC animated:YES];
            }
            else {
                [self loginFirst];
            }
        }
        else if (indexPath.row == 2) {
            if ([[CommonCode readFromUserD:@"isLogin"]boolValue] == YES){
                [self.navigationController pushViewController:[MyVipMenbersViewController new] animated:YES];
            }
            else {
                [self loginFirst];
            }
        }
        else  if (indexPath.row == 3) {
            [self.navigationController pushViewController:[DownloadViewController new] animated:NO];
        }
        else if (indexPath.row == 4) {
            if ([[CommonCode readFromUserD:@"isLogin"]boolValue] == YES){
                [self.navigationController pushViewController:[MyCollectionViewController new] animated:YES];
            }
            else {
                [self loginFirst];
            }
        }
        else if (indexPath.row == 5) {
            if ([[CommonCode readFromUserD:@"isLogin"]boolValue] == YES){
                [self.navigationController pushViewController:[MyClassroomController new] animated:YES];
            }
            else {
                [self loginFirst];
            }
        }
        else if (indexPath.row == 6) {
            [self.navigationController pushViewController:[SheZhiVC new] animated:YES];
        }
    }
}

#pragma mark UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (self.tableView.contentOffset.y <= 0) {
        self.tableView.bounces = NO;
    }
    else if (self.tableView.contentOffset.y >= 0){
            self.tableView.bounces = YES;
        }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    UITableViewCell *cell = [UITableViewCell new];
    if ([touch.view isKindOfClass:[cell.contentView class]]) {
        //放过对单元格点击事件的拦截
        return NO;
    }else{
        return YES;
    }
}

#pragma mark -- getter
- (UITableView *)tableView {
    if (!_tableView){
        _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0,IS_IPHONEX? -25:0, IPHONE_W, IPHONE_H- 49) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.tableFooterView = [UIView new];
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        //        _tableView.backgroundColor = ColorWithRGBA(0, 107, 153, 1);
    }
    return _tableView;
}

- (NSMutableDictionary *)pushNewsInfo {
    if (!_pushNewsInfo) {
        _pushNewsInfo = [NSMutableDictionary new];
    }
    return _pushNewsInfo;
}


- (UIButton *)newPersonMessageButton {
    if (!_newPersonMessageButton ) {
        _newPersonMessageButton  = [UIButton buttonWithType:UIButtonTypeCustom];
        [_newPersonMessageButton setFrame:CGRectMake(114.0 / 667 * IPHONE_H,240.0 / 667 * IPHONE_H, 20, 20)];
        [_newPersonMessageButton.layer setMasksToBounds:YES];
        [_newPersonMessageButton.layer setCornerRadius:10.0];
        [_newPersonMessageButton setBackgroundColor:UIColorFromHex(0xf23131)];
        [_newPersonMessageButton.titleLabel setFont:[UIFont systemFontOfSize:11.0]];
    }
    return _newPersonMessageButton;
}

- (UIButton *)newFriendMessageButton {
    if (!_newFriendMessageButton ) {
        _newFriendMessageButton  = [UIButton buttonWithType:UIButtonTypeCustom];
        if (IS_IPHONEX) {
            [_newFriendMessageButton setFrame:CGRectMake(IS_IPAD?150:110,24.0, 20, 20)];
        }else{
            [_newFriendMessageButton setFrame:CGRectMake(IS_IPAD?150:110,IS_IPAD?23.0 / 667 * IPHONE_H:19.0 / 667 * IPHONE_H, 20, 20)];
        }
        [_newFriendMessageButton.layer setMasksToBounds:YES];
        [_newFriendMessageButton.layer setCornerRadius:10.0];
        [_newFriendMessageButton setBackgroundColor:UIColorFromHex(0xf23131)];
        [_newFriendMessageButton.titleLabel setFont:[UIFont systemFontOfSize:11.0]];
    }
    return _newFriendMessageButton;
}

- (UIButton *)newSettingMessageButton {
    if (!_newSettingMessageButton ) {
        _newSettingMessageButton  = [UIButton buttonWithType:UIButtonTypeCustom];
        if (IS_IPHONEX) {
            [_newSettingMessageButton setFrame:CGRectMake(IS_IPAD?140:110, 19.0, 20, 20)];
        }else{
            [_newSettingMessageButton setFrame:CGRectMake(IS_IPAD?140:110, IS_IPAD?23.0 / 667 * IPHONE_H:19.0 / 667 * IPHONE_H, 20, 20)];
        }
        [_newSettingMessageButton setFrame:CGRectMake(IS_IPAD?140:110, IS_IPAD?23.0 / 667 * IPHONE_H:IS_IPHONEX?24.0:19.0 / 667 * IPHONE_H, 20, 20)];
        [_newSettingMessageButton.layer setMasksToBounds:YES];
        [_newSettingMessageButton.layer setCornerRadius:10.0];
        [_newSettingMessageButton setBackgroundColor:UIColorFromHex(0xf23131)];
        [_newSettingMessageButton.titleLabel setFont:[UIFont systemFontOfSize:11.0]];
    }
    return _newSettingMessageButton;
}

- (UIView *)signInView{
    if (!_signInView) {
        _signInView = [[UIView alloc]init];
        [_signInView setFrame:CGRectMake(SCREEN_WIDTH - 83, SCREEN_HEIGHT - 85 - 83, 83, 83)];
        [_signInView setUserInteractionEnabled:YES];
        [_signInView addSubview:self.signInImageView];
        [_signInView addTapGesWithTarget:self action:@selector(signInAction:)];
    }
    return _signInView;
}

- (UIImageView *)signInImageView {
    if (!_signInImageView ) {
        _signInImageView  = [[UIImageView alloc]initWithFrame:CGRectMake(0,23, 60, 60)];
        [_signInImageView setUserInteractionEnabled:YES];
        [_signInImageView setImage:[UIImage imageNamed:@"sign_in"]];
    }
    return _signInImageView;
}

@end
