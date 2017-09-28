//
//  NewsCell.m
//  kuangjiaTingWen
//
//  Created by 泡果 on 2017/8/21.
//  Copyright © 2017年 zhimi. All rights reserved.
//

#import "NewsCell.h"

@interface NewsCell ()
{
    UIImageView *imgLeft;
    UILabel *titleLab;
    UILabel *detailNews;
    UILabel *riqiLab;
    UILabel *dataLab;
    UIButton *download;
    UIView *line;
}
@end
@implementation NewsCell

+ (NSString *)ID
{
    return @"NewsCell";
}
+(NewsCell *)cellWithTableView:(UITableView *)tableView
{
    NewsCell *cell = [tableView dequeueReusableCellWithIdentifier:[NewsCell ID]];
    if (cell == nil) {
        cell = [[NewsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[NewsCell ID]];
    }
    return cell;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CGFloat offsetY = 0;
        //图片
        imgLeft = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 120.0 / 375 * IPHONE_W, 19 + offsetY, 105.0 / 375 * IPHONE_W,   84.72 / 375 *IPHONE_W)];
        if (IS_IPAD) {
            [imgLeft setFrame:CGRectMake(SCREEN_WIDTH - 125.0 / 375 * IPHONE_W, 19 + offsetY, 105.0 / 375 * IPHONE_W, 70.0 / 375 *IPHONE_W)];
        }
        imgLeft.contentMode = UIViewContentModeScaleAspectFill;
        imgLeft.clipsToBounds = YES;
        [self.contentView addSubview:imgLeft];
        
        //标题
        titleLab = [[UILabel alloc]initWithFrame:CGRectMake(15.0 / 375 * IPHONE_W, 16.0 / 667 * IPHONE_H + offsetY,  SCREEN_WIDTH - 155.0 / 375 * IPHONE_W, 21.0 / 667 *IPHONE_H)];
        titleLab.textAlignment = NSTextAlignmentLeft;
        titleLab.font = [UIFont boldSystemFontOfSize:17.0f];
        titleLab.lineBreakMode = NSLineBreakByWordWrapping;
        [titleLab setNumberOfLines:3];
        [self.contentView addSubview:titleLab];
        
        if (IS_IPAD) {
            //正文
            detailNews = [[UILabel alloc]initWithFrame:CGRectMake(15.0 / 375 * IPHONE_W, titleLab.frame.origin.y + titleLab.frame.size.height + 20.0 / 667 * SCREEN_HEIGHT, titleLab.frame.size.width, 21.0 / 667 *IPHONE_H)];
            detailNews.textColor = gTextColorSub;
            detailNews.font = [UIFont systemFontOfSize:15.0f];
            [self.contentView addSubview:detailNews];
        }
        
        //日期
        riqiLab = [[UILabel alloc]initWithFrame:CGRectMake(15.0 / 375 * IPHONE_W, 86.0 / 667 *IPHONE_H + offsetY, 135.0 / 375 * IPHONE_W, 21.0 / 667 *IPHONE_H)];
        riqiLab.textColor = nSubColor;
        riqiLab.font = [UIFont systemFontOfSize:13.0f];
        [self.contentView addSubview:riqiLab];
        //大小
        dataLab = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 213.0 / 375 * IPHONE_W, 86.0 / 667 *IPHONE_H + offsetY, 45.0 / 375 * IPHONE_W, 21.0 / 667 *IPHONE_H)];
        dataLab.textColor = nSubColor;
        dataLab.font = [UIFont systemFontOfSize:13.0f];
        dataLab.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:dataLab];
        //下载
        download = [UIButton buttonWithType:UIButtonTypeCustom];
        [download setFrame:CGRectMake(CGRectGetMaxX(dataLab.frame), 86.0 / 667 *IPHONE_H + offsetY, 30.0 / 667 *IPHONE_H, 30.0 / 667 *IPHONE_H)];
        [download setImage:[UIImage imageNamed:@"download_grey"] forState:UIControlStateNormal];
        [download setImage:[UIImage imageNamed:@"download_finish"] forState:UIControlStateDisabled];
        [download setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 10, 10)];
        [download addTarget:self action:@selector(downloadColumnNewsAction:) forControlEvents:UIControlEventTouchUpInside];
        download.accessibilityLabel = @"下载";
        [self.contentView addSubview:download];
        
        line = [[UIView alloc]initWithFrame:CGRectMake(15.0 / 375 * SCREEN_WIDTH, CGRectGetMaxY(dataLab.frame) + 12.0 / 667 * SCREEN_HEIGHT, SCREEN_WIDTH - 30.0 / 375 * SCREEN_WIDTH, 0.5)];
        [line setBackgroundColor:nMineNameColor];
        [self.contentView addSubview:line];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDownloadSuccess:) name:DownloadNewsSuccessNotification object:nil];
    }
    return self;
}
- (void)setDataDict:(NSDictionary *)dataDict
{
    _dataDict = dataDict;
    
    //图片
    if ([NEWSSEMTPHOTOURL(dataDict[@"smeta"])  rangeOfString:@"http"].location != NSNotFound){
        [imgLeft sd_setImageWithURL:[NSURL URLWithString:NEWSSEMTPHOTOURL(dataDict[@"smeta"])]];
    }
    else{
        NSString *str = USERPHOTOHTTPSTRINGZhuBo(NEWSSEMTPHOTOURL(dataDict[@"smeta"]));
        [imgLeft sd_setImageWithURL:[NSURL URLWithString:str]];
    }
    //标题
    titleLab.text = dataDict[@"post_title"];
    titleLab.textColor = [[ZRT_PlayerManager manager] textColorFormID:dataDict[@"id"]];
    CGSize size = [titleLab sizeThatFits:CGSizeMake(titleLab.frame.size.width, MAXFLOAT)];
    titleLab.frame = CGRectMake(titleLab.frame.origin.x, titleLab.frame.origin.y, titleLab.frame.size.width, size.height);
    //正文
    if (IS_IPAD) {
        detailNews.text = dataDict[@"post_excerpt"];
    }
    //日期
    NSDate *date = [NSDate dateFromString:dataDict[@"post_modified"]];
    riqiLab.text = [date showTimeByTypeA];
    //大小
    dataLab.text = [NSString stringWithFormat:@"%.1lf%@",[dataDict[@"post_size"] intValue] / 1024.0 / 1024.0,@"M"];
    //是否已下载
    if ([[ZRT_PlayerManager manager] post_mpWithDownloadNewsID:dataDict[@"id"]] != nil) {
        download.enabled = NO;
    }else{
        download.enabled = YES;
    }
}
- (void)downloadColumnNewsAction:(UIButton *)button
{
    if ([[ZRT_PlayerManager manager] limitPlayStatusWithAdd:NO]) {
        [self alertMessageWithVipLimit];
        return;
    }
    if ([[ZRT_PlayerManager manager] post_mpWithDownloadNewsID:_dataDict[@"id"]] != nil) {
        XWAlerLoginView *alert = [XWAlerLoginView alertWithTitle:@"该新闻已下载过"];
        [alert show];
        return;
    }
    [SVProgressHUD showInfoWithStatus:@"开始下载"];
    [self performSelector:@selector(SVPDismiss) withObject:nil afterDelay:1.0];
    NSMutableDictionary *dic = (NSMutableDictionary *)_dataDict;
    dispatch_async(dispatch_get_main_queue(), ^{
        ProjiectDownLoadManager *manager = [ProjiectDownLoadManager defaultProjiectDownLoadManager];
        [manager insertSevaDownLoadArray:dic];
        WHC_Download *op = [[WHC_Download alloc]initStartDownloadWithURL:[NSURL URLWithString:dic[@"post_mp"]] savePath:manager.userDownLoadPath savefileName:[dic[@"post_mp"] stringByReplacingOccurrencesOfString:@"/" withString:@""] withObj:dic withCell:self isSingleDownload:YES delegate:nil];
        [manager.downLoadQueue addOperation:op];
    });
}
- (void)SVPDismiss
{
    [SVProgressHUD dismiss];
}
/**
 弹窗提示已听完每日限制，需要购买会员才能继续收听
 */
- (void)alertMessageWithVipLimit
{
    id object = [self nextResponder];
    
    while (![object isKindOfClass:[UIViewController class]] &&
           object != nil) {
        object = [object nextResponder];
    }
    UIViewController *alertVC = (UIViewController *)object;

    UIAlertController *qingshuruyonghuming = [UIAlertController alertControllerWithTitle:@"温馨提示" message:[NSString stringWithFormat:@"您还不是会员，每日可收听(或下载)%@条已听完，是否前往开通会员，收听更多资讯",[CommonCode readFromUserD:[NSString stringWithFormat:@"%@",limit_num]]] preferredStyle:UIAlertControllerStyleAlert];
    [qingshuruyonghuming addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [qingshuruyonghuming addAction:[UIAlertAction actionWithTitle:@"前往开通会员" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([[CommonCode readFromUserD:@"isLogin"] boolValue] == YES) {
            MyVipMenbersViewController *MyVip = [MyVipMenbersViewController new];
            [alertVC.navigationController pushViewController:MyVip animated:YES];
        }else{
            LoginVC *loginFriVC = [LoginVC new];
            loginFriVC.isFormDownload = YES;
            LoginNavC *loginNavC = [[LoginNavC alloc]initWithRootViewController:loginFriVC];
            [loginNavC.navigationBar setBackgroundColor:[UIColor whiteColor]];
            loginNavC.navigationBar.tintColor = [UIColor blackColor];
            [alertVC presentViewController:loginNavC animated:YES completion:nil];
        }
    }]];
    
    [alertVC presentViewController:qingshuruyonghuming animated:YES completion:nil];
}
- (void)addDownloadSuccess:(NSNotification *)note
{
    if ([note.userInfo[@"id"] isEqualToString:_dataDict[@"id"]]) {
        download.enabled = NO;
    }
}
@end