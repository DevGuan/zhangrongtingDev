//
//  MyClassroomController.m
//  kuangjiaTingWen
//
//  Created by 泡果 on 2017/6/14.
//  Copyright © 2017年 zhimi. All rights reserved.
//

#import "MyClassroomController.h"

@interface MyClassroomController ()<UITableViewDelegate,UITableViewDataSource>
{
    NSInteger currentPage;
}
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSourceArr;
@property (strong, nonatomic) UILabel *tipLabel;
@property (nonatomic, strong) UILabel *label;
@end

@implementation MyClassroomController
- (UILabel *)tipLabel
{
    if (_tipLabel == nil) {
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64)];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.text = @"您当前还没有购买的课程";
        _tipLabel.font = [UIFont systemFontOfSize:15.0];
        _tipLabel.textColor = [UIColor lightGrayColor];
    }
    return _tipLabel;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    currentPage = 1;
    [self setUpData];
    [self setUpView];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.hidesBottomBarWhenPushed = YES;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)setUpData{
    [NetWorkTool listBuyWithaccessToken:AvatarAccessToken andPage:[NSString stringWithFormat:@"%ld",currentPage] andLimit:@"10" sccess:^(NSDictionary *responseObject) {
        [self.tableView.mj_footer endRefreshing];
        if ([responseObject[@"results"] isKindOfClass:[NSArray class]]) {
            if (currentPage == 1) {
                [self.dataSourceArr removeAllObjects];
            }
            NSMutableArray *dataArray = [self frameWithDataArray:[MyClassroomListModel mj_objectArrayWithKeyValuesArray:responseObject[@"results"]]];
            [self.dataSourceArr addObjectsFromArray:dataArray];
            if (dataArray.count == 10) {
                currentPage ++;
            }
            if (self.dataSourceArr.count == 0) {
                [self.tableView addSubview:self.tipLabel];
            }else{
                [self.tipLabel removeFromSuperview];
            }
            [self.tableView reloadData];
        }
    } failure:^(NSError *error) {
        [self.tableView.mj_footer endRefreshing];
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
- (void)setUpView{
    
    [self setTitle:@"我的课堂"];
    //    [self enableAutoBack];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
    [self.view setBackgroundColor:[UIColor whiteColor]];
    UIView *topView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, IPHONE_W, 64)];
    [topView setUserInteractionEnabled:YES];
    topView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:topView];
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    leftBtn.frame = CGRectMake(10, 25, 35, 35);
    [leftBtn setImageEdgeInsets:UIEdgeInsetsMake(5, 0, 5, 10)];
    [leftBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    leftBtn.accessibilityLabel = @"返回";
    [leftBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:leftBtn];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(back)];
    [topView addGestureRecognizer:tap];
    
    UILabel *topLab = [[UILabel alloc]initWithFrame:CGRectMake(50, 30, IPHONE_W - 100, 30)];
    topLab.textColor = [UIColor blackColor];
    topLab.font = [UIFont boldSystemFontOfSize:17.0f];
    topLab.text = @"我的课堂";
    topLab.backgroundColor = [UIColor clearColor];
    topLab.textAlignment = NSTextAlignmentCenter;
    [topView addSubview:topLab];
    UIView *seperatorLine = [[UIView alloc]initWithFrame:CGRectMake(0, 63.5, SCREEN_WIDTH, 0.5)];
    [seperatorLine setBackgroundColor:[UIColor lightGrayColor]];
    [topView addSubview:seperatorLine];
    
    [self.view addSubview:self.tableView];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [self setUpData];
    }];
    
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(back)];
    [rightSwipe setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.tableView addGestureRecognizer:rightSwipe];
}

- (void)back
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyClassroomListFrameModel *frameModel = self.dataSourceArr[indexPath.row];
    zhuboxiangqingVCNew *faxianzhuboVC = [[zhuboxiangqingVCNew alloc]init];
    faxianzhuboVC.jiemuDescription = frameModel.model.Description;
    faxianzhuboVC.jiemuFan_num = frameModel.model.fan_num;
    faxianzhuboVC.jiemuID = frameModel.model.ID;
    faxianzhuboVC.jiemuImages = frameModel.model.images;
    faxianzhuboVC.jiemuIs_fan = frameModel.model.is_fan;
    faxianzhuboVC.jiemuMessage_num = frameModel.model.message_num;
    faxianzhuboVC.jiemuName = frameModel.model.name;
    faxianzhuboVC.isfaxian = YES;
    faxianzhuboVC.isClass = YES;
    self.hidesBottomBarWhenPushed=YES;
    [self.navigationController pushViewController:faxianzhuboVC animated:YES];
    self.hidesBottomBarWhenPushed=NO;

}
#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  [self.dataSourceArr count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    MyClassroomListFrameModel *frameModel = self.dataSourceArr[indexPath.row];
    return frameModel.cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    MyClassroomTableViewCell *cell = [MyClassroomTableViewCell cellWithTableView:tableView];
    cell.hiddenPrice = YES;
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    MyClassroomListFrameModel *frameModel = self.dataSourceArr[indexPath.row];
    cell.frameModel = frameModel;
    return cell;
}

- (UITableView *)tableView{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH, SCREEN_HEIGHT - 64) style:UITableViewStylePlain];
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    }
    return _tableView;
}

- (NSMutableArray *)dataSourceArr{
    if (!_dataSourceArr) {
        _dataSourceArr = [NSMutableArray array];
    }
    return _dataSourceArr;
}
@end