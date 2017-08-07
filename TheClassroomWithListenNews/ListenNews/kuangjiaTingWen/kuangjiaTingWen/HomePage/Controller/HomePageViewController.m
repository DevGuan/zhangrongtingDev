//
//  HomePageViewController.m
//  kuangjiaTingWen
//
//  Created by Zhimi on 17/3/20.
//  Copyright © 2017年 zhimi. All rights reserved.
//

#import "HomePageViewController.h"
#import "HMSegmentedControl.h"
#import "TBCircleScrollView.h"
#import "NSDate+TimeFormat.h"
#import "ProjiectDownLoadManager.h"
#import "WHC_Download.h"
#import "AppDelegate.h"
#import "bofangVC.h"
#import "guanggaoVC.h"
#import "lunboxiangqingVC.h"
#import "NewReportViewController.h"
#import "ClassViewController.h"

@interface HomePageViewController ()<UIScrollViewDelegate,UITableViewDelegate,UITableViewDataSource>

@property (strong,nonatomic) UIScrollView *scrollView;
@property (strong,nonatomic) HMSegmentedControl *segmentedControl;
@property (strong,nonatomic) UITableView *columnTableView;
@property (strong,nonatomic) UITableView *newsTableView;
@property (strong,nonatomic) UITableView *classroomTableView;
@property (strong,nonatomic) NSMutableArray *columnInfoArr;
@property (strong,nonatomic) NSMutableArray *newsInfoArr;
@property (strong,nonatomic) NSMutableArray *classroomInfoArr;
@property (assign, nonatomic) NSInteger columnIndex;
@property (assign, nonatomic) NSInteger columnPageSize;
@property (assign, nonatomic) NSInteger newsIndex;
@property (assign, nonatomic) NSInteger newsPageSize;
@property (assign, nonatomic) NSInteger classIndex;
@property (assign, nonatomic) NSInteger classPageSize;
@property (strong, nonatomic) NSMutableArray *slideADResult;
@property (strong, nonatomic) NSMutableArray *ztADResult;
@property (strong, nonatomic) NSMutableDictionary *pushNewsInfo;
@property (strong, nonatomic) UIView *lineView;
@property (assign, nonatomic) NSInteger playListIndex;
@end

@implementation HomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.playListIndex = 1;
    //这里是启动app时广告
    [self getStartAD];
    [self setUpData];
    [self setUpView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController.navigationBar setTranslucent:YES];
    
    [self.newsTableView reloadData];
    [self.columnTableView reloadData];
}

- (void)setUpData{
    self.columnIndex = 1;
    self.columnPageSize = 15;
    self.newsIndex = 1;
    self.newsPageSize = 15;
    self.classIndex = 1;
    self.classPageSize = 15;
    _columnInfoArr = [NSMutableArray new];
    _newsInfoArr = [NSMutableArray new];
    _classroomInfoArr = [NSMutableArray new];
    _slideADResult = [NSMutableArray new];
    _ztADResult = [NSMutableArray new];
    _pushNewsInfo = [NSMutableDictionary new];
    [self loadColumnDataWithAutoLoading:NO];
    [self loadNewsDataWithAutoLoading:NO];
    [self loadClassData];
    //获取频道列表 - 下载时有用到
    [NetWorkTool getPaoGuoFenLeiLieBiaoWithWhateverSomething:@"q" sccess:^(NSDictionary *responseObject) {
        if ([responseObject[@"results"] isKindOfClass:[NSArray class]]){
            NSMutableArray *commonListArr = [NSMutableArray arrayWithArray:responseObject[@"results"]];
            [CommonCode writeToUserD:commonListArr andKey:@"commonListArr"];
        }
    } failure:^(NSError *error) {
        NSLog(@"error = %@",error);
    }];
    DefineWeakSelf;
    APPDELEGATE.shouyeSkipToPlayingVC = ^ (NSString *pushNewsID){
        
        if ([ZRT_PlayerManager manager].playType == ZRTPlayTypeClassroomTry && Exact_id != nil) {
                NSMutableDictionary *dict = [CommonCode readFromUserD:@"is_free_data"];
            ClassViewController *vc = [ClassViewController shareInstance];
            vc.jiemuDescription = dict[@"jiemuDescription"];
            vc.jiemuFan_num = dict[@"jiemuFan_num"];
            vc.jiemuID = dict[@"jiemuID"];
            vc.jiemuImages = dict[@"jiemuImages"];
            vc.jiemuIs_fan = dict[@"jiemuIs_fan"];
            vc.jiemuMessage_num = dict[@"jiemuMessage_num"];
            vc.jiemuName = dict[@"jiemuName"];
            vc.act_id = Exact_id;
            vc.listVC = self;
            [weakSelf.navigationController.navigationBar setHidden:YES];
            [weakSelf.navigationController pushViewController:vc animated:YES];
            return;
        }
        
        if ([pushNewsID isEqualToString:@"NO"]) {
            //上一次听过的新闻
            if ([ZRT_PlayerManager manager].currentSong) {
                [weakSelf.navigationController pushViewController:[NewPlayVC shareInstance] animated:YES];
            }
            else{
                //跳转上一次播放的新闻
                [weakSelf skipToLastNews];
            }
        }
        else{
            NSString *pushNewsID = [[NSUserDefaults standardUserDefaults]valueForKey:@"pushNews"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            if ([[CommonCode readFromUserD:@"dangqianbofangxinwenID"] isEqualToString:pushNewsID]){
                if (![self.navigationController.topViewController isKindOfClass:[NewPlayVC class]]) {
                    [self.navigationController pushViewController:[NewPlayVC shareInstance] animated:YES];
                    if (![ZRT_PlayerManager manager].isPlaying) {
                        [[ZRT_PlayerManager manager] startPlay];
                    }
                }
                if (![ZRT_PlayerManager manager].isPlaying) {
                    [[ZRT_PlayerManager manager] startPlay];
                }
            }
            else{
                [weakSelf getPushNewsDetail];
            }
            
        }
    };
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(zidongjiazai:) name:@"bofangRightyaojiazaishujv" object:nil];
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(gaibianyanse:) name:@"gaibianyanse" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadClassList) name:ReloadClassList object:nil];
    RegisterNotify(ReloadHomeSelectPageData, @selector(reloadSelectedList))
    RegisterNotify(@"loginSccess", @selector(reloadClassList))
    RegisterNotify(@"tuichuLoginSeccess", @selector(reloadClassList))
    RegisterNotify(@"setMyunreadMessageTips", @selector(reloadClassList))
}

- (void)setUpView{
    [self CustomNavigationBar];
    [self.scrollView addSubview:self.columnTableView];
    [self.scrollView addSubview:self.newsTableView];
    [self.scrollView addSubview:self.classroomTableView];
    [self.view addSubview:self.segmentedControl];
    [self.view addSubview:self.scrollView];
    DefineWeakSelf;
    [self.segmentedControl setIndexChangeBlock:^(NSInteger index) {
        [weakSelf.scrollView scrollRectToVisible:CGRectMake(SCREEN_WIDTH * index, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 104 - 49) animated:YES];
    }];
    [self.segmentedControl setSelectedSegmentIndex:1 animated:YES];
    self.columnTableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        weakSelf.columnIndex = 1;
        [self loadColumnDataWithAutoLoading:NO];
    }];
    self.columnTableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        weakSelf.columnIndex ++;
        [self loadColumnDataWithAutoLoading:NO];
    }];
    self.newsTableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        weakSelf.newsIndex = 1;
        [self loadNewsDataWithAutoLoading:NO];
    }];
    self.newsTableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        weakSelf.newsIndex ++;
        [self loadNewsDataWithAutoLoading:NO];
    }];
    self.classroomTableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        weakSelf.classIndex = 1;
        [weakSelf loadClassData];
    }];
    self.classroomTableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        weakSelf.classIndex ++;
        [weakSelf loadClassData];
    }];
}

#pragma mark - setter
- (UIScrollView *)scrollView{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 104, SCREEN_WIDTH, SCREEN_HEIGHT - 104 - 49)];
        _scrollView.backgroundColor = [UIColor whiteColor];
        _scrollView.pagingEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.contentSize = CGSizeMake(SCREEN_WIDTH * 3, SCREEN_HEIGHT - 104 - 49);
        _scrollView.delegate = self;
        [_scrollView scrollRectToVisible:CGRectMake(SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 104 - 49) animated:NO];
    }
    return _scrollView;
}

- (HMSegmentedControl *)segmentedControl{
    if (!_segmentedControl) {
        _segmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles: @[@"专栏", @"快讯",@"课堂"]];
        _segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        _segmentedControl.frame = CGRectMake(0, 64, SCREEN_WIDTH, 40);
        _segmentedControl.backgroundColor = [UIColor whiteColor];
        _segmentedControl.segmentEdgeInset = UIEdgeInsetsMake(0, 30, 0, 30);
        _segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleTextWidthStripe;
        _segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        _segmentedControl.selectedSegmentIndex = 1;
        _segmentedControl.verticalDividerEnabled = YES;
        _segmentedControl.verticalDividerColor = [UIColor whiteColor];
        _segmentedControl.selectionIndicatorColor = gTextColorSub;
        _segmentedControl.selectionIndicatorBoxColor = [UIColor whiteColor];
        _segmentedControl.selectionIndicatorHeight = 5.0;
        _segmentedControl.shouldAnimateUserSelection = YES;
        _segmentedControl.verticalDividerWidth = 1.0f;
        [_segmentedControl setTitleFormatter:^NSAttributedString *(HMSegmentedControl *segmentedControl, NSString *title, NSUInteger index, BOOL selected) {
            if (selected) {
                NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName :gTextDownload,NSFontAttributeName : [UIFont boldSystemFontOfSize:16]}];
                return attString;
            }
            else{
                NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName :gTextColorSub,NSFontAttributeName : [UIFont boldSystemFontOfSize:16]}];
                return attString;
            }
        }];
        [_segmentedControl addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
        
        //自定义菜单栏下方横线
//        CGFloat w = (SCREEN_WIDTH)/3;
//        self.lineView = [[UIView alloc]initWithFrame:CGRectMake(30, self.segmentedControl.frame.size.height - 5, w/2 , 5)];
//        [self.lineView setBackgroundColor:gTextColorSub];
//        [self.segmentedControl addSubview:self.lineView];
        
        UIView *downLine = [[UIView alloc]initWithFrame:CGRectMake(15.0 / 375 * IPHONE_W, _segmentedControl.frame.size.height - 1, SCREEN_WIDTH - 30.0 / 375 * IPHONE_W, 0.8)];
        [downLine setBackgroundColor:[UIColor colorWithHue:0.00 saturation:0.00 brightness:0.85 alpha:1.00]];
        [_segmentedControl addSubview:downLine];
    }
    return _segmentedControl;
}

- (UITableView *)columnTableView{
    if (!_columnTableView){
        _columnTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, self.scrollView.frame.size.height) style:UITableViewStylePlain];
        [_classroomTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        _columnTableView.delegate = self;
        _columnTableView.dataSource = self;
        _columnTableView.tableFooterView = [UIView new];
    }
    return _columnTableView;
}

- (UITableView *)newsTableView{
    if (!_newsTableView){
        _newsTableView = [[UITableView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH, 0, SCREEN_WIDTH, self.scrollView.frame.size.height) style:UITableViewStylePlain];
        [_newsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        _newsTableView.delegate = self;
        _newsTableView.dataSource = self;
        _newsTableView.tableFooterView = [UIView new];
    }
    return _newsTableView;
}

- (UITableView *)classroomTableView{
    if (!_classroomTableView){
        _classroomTableView = [[UITableView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH * 2, 0, SCREEN_WIDTH, self.scrollView.frame.size.height) style:UITableViewStylePlain];
        [_classroomTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        _classroomTableView.delegate = self;
        _classroomTableView.dataSource = self;
        _classroomTableView.tableFooterView = [UIView new];
    }
    return _classroomTableView;
}

#pragma mark - Utiliteis
- (void)loadNewsDataWithAutoLoading:(BOOL)isAuto{
    if (self.newsIndex == 1) {
        [self getAD];
    }
    DefineWeakSelf;
    [NetWorkTool getInformationListWithaccessToken:AvatarAccessToken andPage:[NSString stringWithFormat:@"%ld",(long)self.newsIndex] andLimit:[NSString stringWithFormat:@"%ld",(long)self.newsPageSize] sccess:^(NSDictionary *responseObject) {
        if ([responseObject[@"results"] isKindOfClass:[NSArray class]]){
            if (weakSelf.newsIndex == 1) {
                [weakSelf.newsInfoArr removeAllObjects];
            }
            else{
                NSRange range = {NSNotFound, NSNotFound};
                for (int i = 0 ; i < [weakSelf.newsInfoArr count]; i ++) {
                    if ([weakSelf.newsInfoArr[i][@"id"] isEqualToString:[responseObject[@"results"] firstObject][@"id"] ]) {
                        range = NSMakeRange(i, [weakSelf.newsInfoArr count] - i);
                        break;
                    }
                }
                if (range.location < [weakSelf.newsInfoArr count]) {
                    [weakSelf.newsInfoArr removeObjectsInRange:range];
                }
            }
            [weakSelf.newsInfoArr addObjectsFromArray:responseObject[@"results"]];
            weakSelf.newsInfoArr = [[NSMutableArray alloc]initWithArray:weakSelf.newsInfoArr];
            if ([ZRT_PlayerManager manager].channelType == ChannelTypeHomeChannelOne) {
                [ZRT_PlayerManager manager].songList = weakSelf.newsInfoArr;
            }
            [weakSelf.newsTableView reloadData];
            [weakSelf endNewsRefreshing];
        }
        else{
            [weakSelf endNewsRefreshing];
        }
    } failure:^(NSError *error) {
        [weakSelf endNewsRefreshing];
    }];
}

- (void)loadColumnDataWithAutoLoading:(BOOL)isAuto
{
    DefineWeakSelf;
    [NetWorkTool getColumnListWithaccessToken:AvatarAccessToken andPage:[NSString stringWithFormat:@"%ld",(long)self.columnIndex] andLimit:[NSString stringWithFormat:@"%ld",(long)self.columnPageSize] sccess:^(NSDictionary *responseObject) {
        if ([responseObject[@"results"] isKindOfClass:[NSArray class]]){
            if (weakSelf.columnIndex == 1) {
                [weakSelf.columnInfoArr removeAllObjects];
            }
            else{
                NSRange range = {NSNotFound, NSNotFound};
                for (int i = 0 ; i < [weakSelf.columnInfoArr count]; i ++) {
                    if ([weakSelf.columnInfoArr[i][@"id"] isEqualToString:[responseObject[@"results"] firstObject][@"id"] ]) {
                        range = NSMakeRange(i, [weakSelf.columnInfoArr count] - i);
                        break;
                    }
                }
                if (range.location < [weakSelf.columnInfoArr count]) {
                    [weakSelf.columnInfoArr removeObjectsInRange:range];
                }
            }
            [weakSelf.columnInfoArr addObjectsFromArray:responseObject[@"results"]];
            weakSelf.columnInfoArr = [[NSMutableArray alloc]initWithArray:weakSelf.columnInfoArr];
            if ([ZRT_PlayerManager manager].channelType == ChannelTypeHomeChannelTwo) {
                [ZRT_PlayerManager manager].songList = weakSelf.newsInfoArr;
            }
            [weakSelf.columnTableView reloadData];
            [weakSelf endColumnRefreshing];
        }
        else{
            [weakSelf endColumnRefreshing];
        }
    } failure:^(NSError *error) {
        [weakSelf endColumnRefreshing];
    }];
}

- (void)loadClassData{
    NSString *accessToken;
    if (ExdangqianUser.length == 0 || ExdangqianUser == nil){
        accessToken = nil;
    }
    else{
        accessToken = [DSE encryptUseDES:ExdangqianUser];
    }
    DefineWeakSelf;
    [NetWorkTool getClassroomListWithaccessToken:AvatarAccessToken andPage:[NSString stringWithFormat:@"%ld",(long)self.classIndex] andLimit:[NSString stringWithFormat:@"%ld",(long)self.classPageSize] sccess:^(NSDictionary *responseObject) {
        if ([responseObject[@"results"] isKindOfClass:[NSArray class]]){
            if (weakSelf.classIndex == 1) {
                [weakSelf.classroomInfoArr removeAllObjects];
            }
            NSMutableArray *classArray = [self frameWithDataArray:[MyClassroomListModel mj_objectArrayWithKeyValuesArray:responseObject[@"results"]]];
            [weakSelf.classroomInfoArr addObjectsFromArray:classArray];
            weakSelf.classroomInfoArr = [[NSMutableArray alloc]initWithArray:weakSelf.classroomInfoArr];
            [weakSelf.classroomTableView reloadData];
            if (classArray.count < self.classPageSize) {
                [weakSelf.classroomTableView.mj_footer endRefreshingWithNoMoreData];
                [weakSelf.classroomTableView.mj_header endRefreshing];
            }else{
                [weakSelf endClassroomRefreshing];
            }
        }
        else{
            [weakSelf endClassroomRefreshing];
        }
    } failure:^(NSError *error) {
        [weakSelf endClassroomRefreshing];
    }];
    
}
/**
 返回frameArray
 
 @param modeArray 数据模型数组
 @return frame数据模型数组
 */
- (NSMutableArray *)frameWithDataArray:(NSMutableArray *)modeArray
{
    NSMutableArray *array = [NSMutableArray array];
    for (MyClassroomListModel *model in modeArray) {
        MyClassroomListFrameModel *frameModel = [[MyClassroomListFrameModel alloc] init];
        frameModel.model = model;
        [array addObject:frameModel];
    }
    return array;
}
- (void)CustomNavigationBar{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 54) / 2, 35, 54, 25)];
    view.backgroundColor = [UIColor whiteColor];
    view.userInteractionEnabled = YES;
    UIImageView *logo = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 54, 25)];
    [logo setImage:[UIImage imageNamed:@"home_logo"]];
    [view addSubview:logo];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.titleView = view;
    self.navigationController.navigationBarHidden=NO;
    //设置一张透明图片遮盖导航栏底下的黑色线条
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"shadow"]
                                                 forBarPosition:UIBarPositionAny
                                                     barMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
}

- (void)segmentedControlChangedValue:(HMSegmentedControl *)segmentedControl {
    NSLog(@"Selected index %ld (via UIControlEventValueChanged)", (long)segmentedControl.selectedSegmentIndex);
    [self.lineView setFrame:CGRectMake(segmentedControl.selectedSegmentIndex * (SCREEN_WIDTH )/3 + 30, self.segmentedControl.frame.size.height - 5, (SCREEN_WIDTH)/6, 5)];
}

- (void)endColumnRefreshing{
    [self.columnTableView.mj_header endRefreshing];
    [self.columnTableView.mj_footer endRefreshing];
}

- (void)endNewsRefreshing{
    [self.newsTableView.mj_header endRefreshing];
    [self.newsTableView.mj_footer endRefreshing];
}

- (void)endClassroomRefreshing{
    [self.classroomTableView.mj_header endRefreshing];
    [self.classroomTableView.mj_footer endRefreshing];
}

- (void)downloadNewsAction:(UIButton *)sender{
    [SVProgressHUD showInfoWithStatus:@"开始下载"];
    [self performSelector:@selector(SVPDismiss) withObject:nil afterDelay:1.0];
    NSMutableDictionary *dic = self.newsInfoArr[sender.tag - 100];
    dispatch_async(dispatch_get_main_queue(), ^{
        ProjiectDownLoadManager *manager = [ProjiectDownLoadManager defaultProjiectDownLoadManager];
        [manager insertSevaDownLoadArray:dic];
        WHC_Download *op = [[WHC_Download alloc]initStartDownloadWithURL:[NSURL URLWithString:dic[@"post_mp"]] savePath:manager.userDownLoadPath savefileName:[dic[@"post_mp"] stringByReplacingOccurrencesOfString:@"/" withString:@""] withObj:dic delegate:nil];
        [manager.downLoadQueue addOperation:op];
    });
}

- (void)downloadColumnNewsAction:(UIButton *)sender{
    [SVProgressHUD showInfoWithStatus:@"开始下载"];
    [self performSelector:@selector(SVPDismiss) withObject:nil afterDelay:1.0];
    NSMutableDictionary *dic = self.columnInfoArr[sender.tag - 100];
    dispatch_async(dispatch_get_main_queue(), ^{
        ProjiectDownLoadManager *manager = [ProjiectDownLoadManager defaultProjiectDownLoadManager];
        [manager insertSevaDownLoadArray:dic];
        WHC_Download *op = [[WHC_Download alloc]initStartDownloadWithURL:[NSURL URLWithString:dic[@"post_mp"]] savePath:manager.userDownLoadPath savefileName:[dic[@"post_mp"] stringByReplacingOccurrencesOfString:@"/" withString:@""] withObj:dic delegate:nil];
        [manager.downLoadQueue addOperation:op];
    });
}

- (void)SVPDismiss {
    [SVProgressHUD dismiss];
}

- (void)getStartAD{
    [NetWorkTool getIntoAppGuangGaoPage:@"1" andLimit:@"15" sccess:^(NSDictionary *responseObject) {
        if ([responseObject[@"results"] isKindOfClass:[NSArray class]]){
            
            if (TARGETED_DEVICE_IS_IPHONE_480 && [[responseObject[@"results"] firstObject][@"status"] isEqualToString:@"1"]){
                [self openLaunchAD];
            }
            else if (TARGETED_DEVICE_IS_IPHONE_568 &&  [responseObject[@"results"][1] [@"status"] isEqualToString:@"1"]){
                [self openLaunchAD];
            }
            else if (TARGETED_DEVICE_IS_IPHONE_667 &&  [responseObject[@"results"][2] [@"status"] isEqualToString:@"1"]){
                [self openLaunchAD];
            }
            else if (TARGETED_DEVICE_IS_IPHONE_736 &&  [responseObject[@"results"][3] [@"status"] isEqualToString:@"1"]){
                [self openLaunchAD];
            }
            else if (TARGETED_DEVICE_IS_IPAD &&  [responseObject[@"results"][3] [@"status"] isEqualToString:@"1"]){
                [self openLaunchAD];
            }
            
        }
        
    }failure:^(NSError *error){
         
     }];
}

- (void)openLaunchAD{
    guanggaoVC *guangao = [guanggaoVC new];
    self.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:guangao animated:NO];
    self.hidesBottomBarWhenPushed = NO;
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

/**
 根据推送ID获取新闻详情数据
 */
- (void)getPushNewsDetail{
    DefineWeakSelf;
    [NetWorkTool getpostinfoWithpost_id:[[NSUserDefaults standardUserDefaults]valueForKey:@"pushNews"] andpage:nil andlimit:nil sccess:^(NSDictionary *responseObject) {
        if ([responseObject[@"status"] integerValue] == 1) {
            weakSelf.pushNewsInfo = [responseObject[@"results"] mutableCopy];
            [NetWorkTool getAllActInfoListWithAccessToken:nil ac_id:weakSelf.pushNewsInfo[@"post_news"] keyword:nil andPage:nil andLimit:nil sccess:^(NSDictionary *responseObject) {
                if ([responseObject[@"status"] integerValue] == 1){
                    [weakSelf.pushNewsInfo setObject:[responseObject[@"results"] firstObject] forKey:@"post_act"];
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

- (void)newsItemAction:(UIButton *)sender{
    NSString *term_id;
    NSString *newsType;
    if (sender.tag  == 500) {
        term_id = @"6";
        newsType = @"财经";
    }
    else if (sender.tag == 501){
        term_id = @"4";
        newsType = @"文娱";
    }
    else if (sender.tag == 502){
        term_id = @"8";
        newsType = @"国际";
    }
    else if (sender.tag == 503){
        term_id = @"7";
        newsType = @"科技";
    }
    else if (sender.tag == 504){
        term_id = @"14";
        newsType = @"时政";
    }
    NewReportViewController *newreportVC = [[NewReportViewController alloc]init];
    newreportVC.term_id = term_id;
    newreportVC.NewsTpye = newsType;
    self.hidesBottomBarWhenPushed=YES;
    [self.navigationController pushViewController:newreportVC animated:YES];
    self.hidesBottomBarWhenPushed=NO;
}

#pragma mark - NSNotificationAction
- (void)gaibianyanse:(NSNotification *)notification{
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        [self.columnTableView reloadData];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1){
        [self.newsTableView reloadData];
    }
}

- (void)zidongjiazai:(NSNotification *)notification{
    DefineWeakSelf;
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        weakSelf.columnIndex ++;
        [weakSelf loadColumnDataWithAutoLoading:YES];
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1){
        weakSelf.newsIndex ++;
        [weakSelf loadNewsDataWithAutoLoading:YES];
    }
}
//刷新课堂列表
- (void)reloadClassList
{
    self.classIndex = 1;
    [self loadClassData];
    [self getAD];
}

/**
 重复点击刷新首页对应列表
 */
- (void)reloadSelectedList
{
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        [self.columnTableView.mj_header beginRefreshing];
    }else if (self.segmentedControl.selectedSegmentIndex == 1){
        [self.newsTableView.mj_header beginRefreshing];
    }else{
        [self.classroomTableView.mj_header beginRefreshing];
    }
}

#pragma mark -UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = self.scrollView.contentOffset.x / pageWidth;
    [self.segmentedControl setSelectedSegmentIndex:page animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger numberOfRows = 0;
    if (tableView == self.columnTableView) {
        numberOfRows = [self.columnInfoArr count];
    }
    else if (tableView == self.newsTableView){
        numberOfRows = [self.newsInfoArr count];
    }
    else if (tableView == self.classroomTableView){
        numberOfRows = [self.classroomInfoArr count];
    }
    return numberOfRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.columnTableView){
        static NSString *columnCellIdentify = @"columnCellIdentify";
        UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:columnCellIdentify];
        if (!cell){
            cell = [tableView dequeueReusableCellWithIdentifier:columnCellIdentify];
        }
        if ([self.columnInfoArr count]) {
            CGFloat offsetY = 0;
            //图片
            UIImageView *imgLeft = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 120.0 / 375 * IPHONE_W, 19 + offsetY, 105.0 / 375 * IPHONE_W,   84.72 / 375 *IPHONE_W)];
            if (IS_IPAD) {
                [imgLeft setFrame:CGRectMake(SCREEN_WIDTH - 125.0 / 375 * IPHONE_W, 19 + offsetY, 105.0 / 375 * IPHONE_W, 70.0 / 375 *IPHONE_W)];
            }
            
            if ([NEWSSEMTPHOTOURL(self.columnInfoArr[indexPath.row][@"smeta"])  rangeOfString:@"http"].location != NSNotFound){
                [imgLeft sd_setImageWithURL:[NSURL URLWithString:NEWSSEMTPHOTOURL(self.columnInfoArr[indexPath.row][@"smeta"])]];
                //placeholderImage:[UIImage imageNamed:@"thumbnailsdefault"]
            }
            else{
                NSString *str = USERPHOTOHTTPSTRINGZhuBo(NEWSSEMTPHOTOURL(self.columnInfoArr[indexPath.row][@"smeta"]));
                [imgLeft sd_setImageWithURL:[NSURL URLWithString:str]];
                //placeholderImage:[UIImage imageNamed:@"thumbnailsdefault"]
            }
            [cell.contentView addSubview:imgLeft];
            imgLeft.contentMode = UIViewContentModeScaleAspectFill;
            imgLeft.clipsToBounds = YES;
            
            //标题
            UILabel *titleLab = [[UILabel alloc]initWithFrame:CGRectMake(15.0 / 375 * IPHONE_W, 16.0 / 667 * IPHONE_H + offsetY,  SCREEN_WIDTH - 155.0 / 375 * IPHONE_W, 21.0 / 667 *IPHONE_H)];
            titleLab.text = self.columnInfoArr[indexPath.row][@"post_title"];
            titleLab.textColor = [[ZRT_PlayerManager manager] textColorFormID:self.columnInfoArr[indexPath.row][@"id"]];
            titleLab.textAlignment = NSTextAlignmentLeft;
            titleLab.font = [UIFont boldSystemFontOfSize:17.0f ];
            [cell.contentView addSubview:titleLab];
            [titleLab setNumberOfLines:3];
            titleLab.lineBreakMode = NSLineBreakByWordWrapping;
            CGSize size = [titleLab sizeThatFits:CGSizeMake(titleLab.frame.size.width, MAXFLOAT)];
            titleLab.frame = CGRectMake(titleLab.frame.origin.x, titleLab.frame.origin.y, titleLab.frame.size.width, size.height);
            if (IS_IPAD) {
                //正文
                UILabel *detailNews = [[UILabel alloc]initWithFrame:CGRectMake(15.0 / 375 * IPHONE_W, titleLab.frame.origin.y + titleLab.frame.size.height + 20.0 / 667 * SCREEN_HEIGHT, titleLab.frame.size.width, 21.0 / 667 *IPHONE_H)];
                detailNews.text = self.columnInfoArr[indexPath.row][@"post_excerpt"];
                detailNews.textColor = gTextColorSub;
                detailNews.font = [UIFont systemFontOfSize:15.0f];
                [cell.contentView addSubview:detailNews];
            }
            
            //日期
            UILabel *riqiLab = [[UILabel alloc]initWithFrame:CGRectMake(15.0 / 375 * IPHONE_W, 86.0 / 667 *IPHONE_H + offsetY, 135.0 / 375 * IPHONE_W, 21.0 / 667 *IPHONE_H)];
            NSDate *date = [NSDate dateFromString:self.columnInfoArr[indexPath.row][@"post_modified"]];
            riqiLab.text = [date showTimeByTypeA];
            riqiLab.textColor = nSubColor;
            riqiLab.font = [UIFont systemFontOfSize:13.0f];
            [cell.contentView addSubview:riqiLab];
            //大小
            UILabel *dataLab = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 213.0 / 375 * IPHONE_W, 86.0 / 667 *IPHONE_H + offsetY, 45.0 / 375 * IPHONE_W, 21.0 / 667 *IPHONE_H)];
            dataLab.text = [NSString stringWithFormat:@"%.1lf%@",[self.columnInfoArr[indexPath.row][@"post_size"] intValue] / 1024.0 / 1024.0,@"M"];
            dataLab.textColor = nSubColor;
            dataLab.font = [UIFont systemFontOfSize:13.0f];
            dataLab.textAlignment = NSTextAlignmentCenter;
            [cell.contentView addSubview:dataLab];
            //下载
            UIButton *download = [UIButton buttonWithType:UIButtonTypeCustom];
            [download setFrame:CGRectMake(CGRectGetMaxX(dataLab.frame), 86.0 / 667 *IPHONE_H + offsetY, 30.0 / 667 *IPHONE_H, 30.0 / 667 *IPHONE_H)];
            [download setImage:[UIImage imageNamed:@"download_grey"] forState:UIControlStateNormal];
            [download setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 10, 10)];
            [download setTag:(indexPath.row + 100)];
            [download addTarget:self action:@selector(downloadColumnNewsAction:) forControlEvents:UIControlEventTouchUpInside];
            download.accessibilityLabel = @"下载";
            [cell.contentView addSubview:download];
            
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(15.0 / 375 * SCREEN_WIDTH, CGRectGetMaxY(dataLab.frame) + 12.0 / 667 * SCREEN_HEIGHT, SCREEN_WIDTH - 30.0 / 375 * SCREEN_WIDTH, 0.5)];
            [line setBackgroundColor:nMineNameColor];
            [cell.contentView addSubview:line];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    }
    else if (tableView == self.newsTableView){
        static NSString *NewsCellIdentify = @"NewsCellIdentify";
        UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NewsCellIdentify];
        if (!cell){
            cell = [tableView dequeueReusableCellWithIdentifier:NewsCellIdentify];
        }
        if ([self.newsInfoArr count]) {
            CGFloat offsetY = 0;
            if (indexPath.row == 0) {
                offsetY = 30;
                //新闻频道
                CGFloat newsItem_width = (SCREEN_WIDTH - 10.0 / 375 * IPHONE_W)/5;
                NSArray *newsItemTitle = @[@"财经",@"文娱",@"国际",@"科技",@"时政"];
                for (int i = 0 ; i < 5; i ++) {
                    UIButton *newsItem = [UIButton buttonWithType:UIButtonTypeCustom];
                    [newsItem setFrame:CGRectMake(newsItem_width * i + 5.0 / 375 * IPHONE_W + 5.0, 5, newsItem_width - 5, 25)];
                    [newsItem.layer setMasksToBounds:YES];
                    [newsItem.layer setCornerRadius:12.5];
                    [newsItem.layer setBorderWidth:0.5];
                    [newsItem.layer setBorderColor:gTextColorSub.CGColor];
                    [newsItem setTitle:newsItemTitle[i] forState:UIControlStateNormal];
                    [newsItem setTitleColor:gTextDownload forState:UIControlStateNormal];
                    [newsItem.titleLabel setFont:gFontMain14];
                    [newsItem setTag:(500+ i)];
                    [newsItem addTarget:self action:@selector(newsItemAction:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.contentView addSubview:newsItem];
                }
            }
            else{
                offsetY = 0;
            }
            //图片
            UIImageView *imgLeft = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 120.0 / 375 * IPHONE_W, 19 + offsetY, 105.0 / 375 * IPHONE_W,   84.72 / 375 *IPHONE_W)];
            if (IS_IPAD) {
                [imgLeft setFrame:CGRectMake(SCREEN_WIDTH - 125.0 / 375 * IPHONE_W, 19 + offsetY, 105.0 / 375 * IPHONE_W, 70.0 / 375 *IPHONE_W)];
            }
            if ([NEWSSEMTPHOTOURL(self.newsInfoArr[indexPath.row][@"smeta"])  rangeOfString:@"http"].location != NSNotFound){
                [imgLeft sd_setImageWithURL:[NSURL URLWithString:NEWSSEMTPHOTOURL(self.newsInfoArr[indexPath.row][@"smeta"])]];
                //placeholderImage:[UIImage imageNamed:@"thumbnailsdefault"]
            }
            else{
                NSString *str = USERPHOTOHTTPSTRINGZhuBo(NEWSSEMTPHOTOURL(self.newsInfoArr[indexPath.row][@"smeta"]));
                [imgLeft sd_setImageWithURL:[NSURL URLWithString:str]];
                //placeholderImage:[UIImage imageNamed:@"thumbnailsdefault"]
            }
            [cell.contentView addSubview:imgLeft];
            imgLeft.contentMode = UIViewContentModeScaleAspectFill;
            imgLeft.clipsToBounds = YES;
            
            //标题
            UILabel *titleLab = [[UILabel alloc]initWithFrame:CGRectMake(15.0 / 375 * IPHONE_W, 16.0 / 667 * IPHONE_H + offsetY,  SCREEN_WIDTH - 155.0 / 375 * IPHONE_W, 21.0 / 667 *IPHONE_H)];
            titleLab.text = self.newsInfoArr[indexPath.row][@"post_title"];
            titleLab.textColor = [[ZRT_PlayerManager manager] textColorFormID:self.newsInfoArr[indexPath.row][@"id"]];
            titleLab.textAlignment = NSTextAlignmentLeft;
            titleLab.font = [UIFont boldSystemFontOfSize:17.0f ];
            [cell.contentView addSubview:titleLab];
            [titleLab setNumberOfLines:3];
            titleLab.lineBreakMode = NSLineBreakByWordWrapping;
            CGSize size = [titleLab sizeThatFits:CGSizeMake(titleLab.frame.size.width, MAXFLOAT)];
            titleLab.frame = CGRectMake(titleLab.frame.origin.x, titleLab.frame.origin.y, titleLab.frame.size.width, size.height);
            if (IS_IPAD) {
                //正文
                UILabel *detailNews = [[UILabel alloc]initWithFrame:CGRectMake(15.0 / 375 * IPHONE_W, titleLab.frame.origin.y + titleLab.frame.size.height + 20.0 / 667 * SCREEN_HEIGHT, titleLab.frame.size.width, 21.0 / 667 *IPHONE_H)];
                detailNews.text = self.newsInfoArr[indexPath.row][@"post_excerpt"];
                detailNews.textColor = gTextColorSub;
                detailNews.font = [UIFont systemFontOfSize:15.0f];
                [cell.contentView addSubview:detailNews];
            }
            
            //日期
            UILabel *riqiLab = [[UILabel alloc]initWithFrame:CGRectMake(15.0 / 375 * IPHONE_W, 86.0 / 667 *IPHONE_H + offsetY, 135.0 / 375 * IPHONE_W, 21.0 / 667 *IPHONE_H)];
            NSDate *date = [NSDate dateFromString:self.newsInfoArr[indexPath.row][@"post_modified"]];
            riqiLab.text = [date showTimeByTypeA];
            riqiLab.textColor = nSubColor;
            riqiLab.font = [UIFont systemFontOfSize:13.0f];
            [cell.contentView addSubview:riqiLab];
            //大小
            UILabel *dataLab = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 213.0 / 375 * IPHONE_W, 86.0 / 667 *IPHONE_H + offsetY, 45.0 / 375 * IPHONE_W, 21.0 / 667 *IPHONE_H)];
            dataLab.text = [NSString stringWithFormat:@"%.1lf%@",[self.newsInfoArr[indexPath.row][@"post_size"] intValue] / 1024.0 / 1024.0,@"M"];
            dataLab.textColor = nSubColor;
            dataLab.font = [UIFont systemFontOfSize:13.0f];
            dataLab.textAlignment = NSTextAlignmentCenter;
            [cell.contentView addSubview:dataLab];
            //下载
            UIButton *download = [UIButton buttonWithType:UIButtonTypeCustom];
            [download setFrame:CGRectMake(CGRectGetMaxX(dataLab.frame), 86.0 / 667 *IPHONE_H + offsetY, 30.0 / 667 *IPHONE_H, 30.0 / 667 *IPHONE_H)];
            [download setImage:[UIImage imageNamed:@"download_grey"] forState:UIControlStateNormal];
            [download setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 10, 10)];
            [download setTag:(indexPath.row + 100)];
            [download addTarget:self action:@selector(downloadNewsAction:) forControlEvents:UIControlEventTouchUpInside];
            download.accessibilityLabel = @"下载";
            [cell.contentView addSubview:download];
            
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(15.0 / 375 * SCREEN_WIDTH, CGRectGetMaxY(dataLab.frame) + 12.0 / 667 * SCREEN_HEIGHT, SCREEN_WIDTH - 30.0 / 375 * SCREEN_WIDTH, 0.5)];
            [line setBackgroundColor:nMineNameColor];
            [cell.contentView addSubview:line];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    }
    else{
        MyClassroomTableViewCell *cell = [MyClassroomTableViewCell cellWithTableView:tableView];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        cell.hiddenDevider = YES;
        MyClassroomListFrameModel *frameModel = self.classroomInfoArr[indexPath.row];
        cell.frameModel = frameModel;
        return cell;
    }
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat heightForRow = 44.0;
    if (tableView == self.columnTableView) {
        heightForRow = 120.0 / 667 * IPHONE_H;
    }
    else if (tableView == self.newsTableView){
        if (indexPath.row == 0) {
            heightForRow = 150.0 / 667 * IPHONE_H;
        }
        else{
            heightForRow =  120.0 / 667 * IPHONE_H;
        }
    }
    else if (tableView == self.classroomTableView){
        MyClassroomListFrameModel *frameModel = self.classroomInfoArr[indexPath.row];
        heightForRow = frameModel.cellHeight;
    }
    return heightForRow;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.columnTableView || tableView == self.newsTableView) {
        
        self.playListIndex = self.segmentedControl.selectedSegmentIndex;
        
        NSArray *arr;
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            arr = self.columnInfoArr;
            [ZRT_PlayerManager manager].channelType = ChannelTypeHomeChannelTwo;
        }
        else if (self.segmentedControl.selectedSegmentIndex == 1){
            arr = self.newsInfoArr;
            [ZRT_PlayerManager manager].channelType = ChannelTypeHomeChannelOne;
        }
        //设置播放器播放内容类型
        [ZRT_PlayerManager manager].playType = ZRTPlayTypeNews;
        //设置播放器播放完成自动加载更多block
        DefineWeakSelf;
        [ZRT_PlayerManager manager].loadMoreList = ^(NSInteger currentSongIndex) {
            if (weakSelf.playListIndex == 0) {
                weakSelf.columnIndex ++;
                [weakSelf loadColumnDataWithAutoLoading:YES];
            }
            else if (weakSelf.playListIndex == 1){
                weakSelf.newsIndex ++;
                [weakSelf loadNewsDataWithAutoLoading:YES];
            }
        };
        //播放内容切换后刷新对应的播放列表
        [ZRT_PlayerManager manager].playReloadList = ^(NSInteger currentSongIndex) {
            if (weakSelf.playListIndex == 0) {
                [weakSelf.columnTableView reloadData];
            }
            else if (weakSelf.playListIndex == 1){
                [weakSelf.newsTableView reloadData];
            }
        };
        //设置播放界面打赏view的状态
        [NewPlayVC shareInstance].rewardType = RewardViewTypeNone;
        //判断是否是点击当前正在播放的新闻，如果是则直接跳转
        if ([[CommonCode readFromUserD:@"dangqianbofangxinwenID"] isEqualToString:arr[indexPath.row][@"id"]]){
            
            //设置播放器播放数组
            [ZRT_PlayerManager manager].songList = arr;
            [[NewPlayVC shareInstance] reloadInterface];
            [self.navigationController.navigationBar setHidden:YES];
            [self.navigationController pushViewController:[NewPlayVC shareInstance] animated:YES];
        }
        else{
            
            //设置播放器播放数组
            [ZRT_PlayerManager manager].songList = arr;
            //设置新闻ID
            [NewPlayVC shareInstance].post_id = arr[indexPath.row][@"id"];
            //保存当前播放新闻Index
            ExcurrentNumber = (int)indexPath.row;
            //调用播放对应Index方法
            [[NewPlayVC shareInstance] playFromIndex:ExcurrentNumber];
            //跳转播放界面
            [self.navigationController.navigationBar setHidden:YES];
            [self.navigationController pushViewController:[NewPlayVC shareInstance] animated:YES];
            [tableView reloadData];
        }

    }
    else if (tableView == self.classroomTableView){
        NSDictionary *userInfoDict = [CommonCode readFromUserD:@"dangqianUserInfo"];
        //跳转已购买课堂界面，超级会员可直接跳转课堂已购买界面
        MyClassroomListFrameModel *frameModel = self.classroomInfoArr[indexPath.row];
        if ([frameModel.model.is_free isEqualToString:@"1"]||[userInfoDict[results][member_type] intValue] == 2) {
            zhuboXiangQingVCNewController *faxianzhuboVC = [[zhuboXiangQingVCNewController alloc]init];
            faxianzhuboVC.jiemuDescription = frameModel.model.Description;
            faxianzhuboVC.jiemuFan_num = frameModel.model.fan_num;
            faxianzhuboVC.jiemuID = frameModel.model.ID;
            faxianzhuboVC.jiemuImages = frameModel.model.images;
            faxianzhuboVC.jiemuIs_fan = frameModel.model.is_fan;
            faxianzhuboVC.jiemuMessage_num = frameModel.model.message_num;
            faxianzhuboVC.jiemuName = frameModel.model.name;
            faxianzhuboVC.isfaxian = YES;
            faxianzhuboVC.isClass = YES;
            [self.navigationController pushViewController:faxianzhuboVC animated:YES];
        }
        //跳转未购买课堂界面
        else if ([frameModel.model.is_free isEqualToString:@"0"]){
            ClassViewController *vc = [ClassViewController shareInstance];
            vc.jiemuDescription = frameModel.model.Description;
            vc.jiemuFan_num = frameModel.model.fan_num;
            vc.jiemuID = frameModel.model.ID;
            vc.jiemuImages = frameModel.model.images;
            vc.jiemuIs_fan = frameModel.model.is_fan;
            vc.jiemuMessage_num = frameModel.model.message_num;
            vc.jiemuName = frameModel.model.name;
            vc.act_id = frameModel.model.ID;
            vc.listVC = self;
            [self.navigationController.navigationBar setHidden:YES];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}
- (void)getAD{
    //获取轮播图数据
//    [self.ztADResult removeAllObjects];
    [NetWorkTool getNewSlideListWithaccessToken:ExdangqianUser?[DSE encryptUseDES:ExdangqianUser]:@"" sccess:^(NSDictionary *responseObject) {
//        RTLog(@"%@",responseObject);
        if ([responseObject[@"results"] isKindOfClass:[NSArray class]]){
            
            self.slideADResult = responseObject[@"results"];
            [self setupTBCView];
        }
        else{
            self.slideADResult = [NSMutableArray array];
            [self setupTBCView];
        }
        [self.newsTableView reloadData];
    } failure:^(NSError *error) {
        NSLog(@"%@",error);
    }];
}
- (void)setupTBCView{
    /*
     {
     is_fan=0,
     images=2017-04-13/crop_58ef1953ef484.jpg,
     cate=3,
     name=10步成为巴菲特式投资天才,
     des=刘建位复旦大学国际金融硕士上海社会科学院经济学博士巴菲特价值投资研究与传播者,
     fan_num=110,
     picture={
     "thumb": "http:\/\/admin.tingwen.me\/Uploads\/2017-04-13\/crop_58ef1dc74e102.jpg"
     },
     description=10步成为巴菲特式投资天才,
     message_num=8,
     is_free=0,
     url=260
     }
     */
    if (self.slideADResult.count != 0) {
        TBCircleScrollView *tbScView = [[TBCircleScrollView alloc] initWithFrame:CGRectMake(15.0 / 375 * IPHONE_W, 0, IPHONE_W - 30.0 / 375 * IPHONE_W, 162.0 / 667 * SCREEN_HEIGHT) andArr:self.slideADResult];
        tbScView.scrollView.scrollsToTop = NO;
        tbScView.biaozhiStr = @"头条";
        NSMutableArray *imgArr = [[NSMutableArray alloc]init];
        for (int i = 0; i <self.slideADResult.count; i++ ){
            [imgArr addObject:NEWSSEMTPHOTOURL(self.slideADResult[i][@"picture"])];
        }
        tbScView.ztADCount = [imgArr count];
        tbScView.imageArray = [NSArray arrayWithArray:imgArr];
        self.newsTableView.tableHeaderView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 162.0 / 667 * SCREEN_HEIGHT)];
        [self.newsTableView.tableHeaderView addSubview:tbScView];
        [self.newsTableView reloadData];
    }else{
        self.newsTableView.tableHeaderView = [[UIView alloc] init];
        [self.newsTableView.tableHeaderView removeFromSuperview];
        [self.newsTableView reloadData];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
