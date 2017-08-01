//
//  QYHChatViewController.m
//  FengChatHuai
//
//  Created by iMacQIU on 16/5/20.
//  Copyright © 2016年 iMacQIU. All rights reserved.
//

#import "QYHChatViewController.h"
#import "QYHAddTableViewController.h"
#import "MGSwipeTableCell.h"
#import "QYHContenViewController.h"
#import "QYHFMDBmanager.h"
#import "QYHContactModel.h"
#import "QYHChatMssegeModel.h"
#import "QYHNewFriendViewController.h"
#import "QYHChatViewCell.h"
#import "QYHContactsViewController.h"
#import "EaseConversationModel.h"
#import "UIImageView+WebCache.h"


@interface QYHChatViewController ()<UITableViewDelegate,UITableViewDataSource,NSFetchedResultsControllerDelegate,UIAlertViewDelegate>

{
    NSFetchedResultsController *_resultsContr;

    BOOL _isRes;
}

@property (weak, nonatomic) IBOutlet UITableView *myTableView;

@property(nonatomic,strong) QYHContenViewController *chatVC;

/**
 * 好友
 */
@property(strong,nonatomic) NSMutableArray *usersArray;
@property(nonatomic,strong) NSMutableArray *msgDataArray;
@property(nonatomic,strong) NSMutableArray *dataArray;
@property(nonatomic,strong) NSMutableArray *addFriendArray;

@property(nonatomic,strong) EaseConversationModel *model;

@end

@implementation QYHChatViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        NSLog(@"QYHChatViewController--initWithCoder");
        
        _msgDataArray   = [NSMutableArray array];
        
        _dataArray      = [NSMutableArray array];
        
        _addFriendArray = [NSMutableArray array];
        
        _usersArray     = [NSMutableArray array];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getAllChatMessage) name:KLoginSuccessNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getAllChatMessage) name:KReceiveChatMessageNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getAllChatMessage) name:KconversationListDidUpdateNotification object:nil];
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if ([QYHAccount shareAccount].isNeedRefresh) {
        [QYHAccount shareAccount].isNeedRefresh = NO;
        
        [self getAllChatMessage];
        
    }else{
        
        if (self.navigationController.tabBarItem.badgeValue) {
            [self.myTableView reloadData];
        }
    }
    
    if (self.isTrans) {
        
        UIBarButtonItem *navigationSpacer = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                             target:self action:nil];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
            navigationSpacer.width = - 10.5;  // ios 7
            
        }else{
            navigationSpacer.width = - 6;  // ios 6
        }
        
        UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissAction)];
        
        
        self.navigationItem.leftBarButtonItems = @[navigationSpacer,leftBarButtonItem];
    }
    
}

- (void)dismissAction{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"QYHChatViewController--viewDidLoad");
    
     self.myTableView.rowHeight = 60.0f;
    
    if (self.isTrans) {
        self.myTableView.tableHeaderView = [self loadHearView];
        self.title = @"最近联系人";
        self.navigationItem.rightBarButtonItem = nil;
    }
     self.myTableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 20)];
    
    //首先实例化聊天界面
    _chatVC = [QYHContenViewController shareInstance];
    
    
    [self getAllChatMessage];
    
}

/**
 *  tabbleviewHearView
 *
 *
 */
- (UIView *)loadHearView{
    
    UIView *hearView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 95)];
    hearView.backgroundColor = [UIColor whiteColor];
    
    UIView *spaceView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 35)];
    spaceView.backgroundColor = [UIColor colorWithHexString:@"EFEFF4"];
    
    UIView *lineView1 = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(spaceView.frame), SCREEN_WIDTH, 1)];
    lineView1.backgroundColor = [UIColor colorWithHexString:@"DADADA"];
    
    UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 55, 200, 21)];
    nameLabel.text = @"创建新的聊天";
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 36, SCREEN_WIDTH, 60);
    button.backgroundColor = [UIColor clearColor];
    button.alpha = 0.3;
    
    [button addTarget:self action:@selector(didSelectButton:) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIView *lineView2 = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(hearView.frame)-1, SCREEN_WIDTH, 1)];
    lineView2.backgroundColor = [UIColor colorWithHexString:@"DADADA"];
    
    [hearView addSubview:spaceView];
    [hearView addSubview:button];
    [hearView addSubview:lineView1];
    [hearView addSubview:nameLabel];
    [hearView addSubview:lineView2];
    
    return hearView;
}


- (void)didSelectButton:(UIButton *)button{
    
    button.backgroundColor = [UIColor lightGrayColor];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        button.backgroundColor = [UIColor clearColor];
    });

    QYHContactsViewController *contactsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"QYHContactsViewController"];
    contactsVC.isTrans = YES;
    [self.navigationController pushViewController:contactsVC animated:YES];
}


//获取全部的聊天信息
- (void)getAllChatMessage
{
    
    [_dataArray removeAllObjects];
    
    __weak typeof(self) weakSelf = self;
    
    NSArray *conversationArray = [[QYHEMClientTool shareInstance] getAllConversations];
    
    [conversationArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        EMConversation *conversation = (EMConversation *)obj;
        EMMessage *lastMessage = [conversation latestMessage];
        
        NSLog(@"lastMessage == %@",lastMessage);
        
        NSString *from = lastMessage.direction == EMMessageDirectionReceive ? lastMessage.from:lastMessage.to;
        
        EaseConversationModel *model = [[EaseConversationModel alloc] initWithConversation:conversation];
        UserProfileEntity *profileEntity = [[UserProfileManager sharedInstance] getUserProfileByUsername:from];
//        if (profileEntity) {
            model.title = profileEntity.nickname == nil ? from : profileEntity.nickname;
            model.avatarURLPath = profileEntity.imageUrl;
            model.message = lastMessage;
            
            [weakSelf.dataArray addObject:model];
//        }
        
    }];
    
    
    [self.myTableView reloadData];
}


/**
 *  时间排序，按照时间先后顺序显示
 *
 *
 */

- (void)sortTimeByDes{
    
    [_dataArray removeAllObjects];
    
    for (NSArray *arr in _msgDataArray) {
        
         NSLog(@"lastObject==%@",[arr lastObject]);
        
        [_dataArray addObject:[arr lastObject]];

    }
    
    NSLog(@"_dataArray==%@",_dataArray);
    
    if (_dataArray.count >1) {
        NSArray *dateStringArray = [_dataArray mutableCopy];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        _dataArray = [NSMutableArray arrayWithArray:[dateStringArray sortedArrayUsingComparator:^NSComparisonResult(QYHChatMssegeModel *messegeModel1, QYHChatMssegeModel *messegeModel2) {
            
            NSDate *date1 = [dateFormatter dateFromString:messegeModel1.time];
            NSDate *date2 = [dateFormatter dateFromString:messegeModel2.time];
            
            return [date2 compare:date1];
        }]];
            }
    
    NSLog(@"myTableView reloadData");
    
    
    if (self.addFriendArray.count) {
        /**
         *  传到添加朋友信息界面刷新数据
         */
        [[NSNotificationCenter defaultCenter]postNotificationName:KReceiveNewAddFriendNotification object:self.addFriendArray];
    }
    
    [self.myTableView reloadData];
    
}

//获取全部未读信息
- (void)queryAllUnread{
    
    __weak __typeof(self) weakSelf = self;
    [[QYHFMDBmanager shareInstance] queryAllUnReadCompletion:^(NSInteger count, BOOL result) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (count) {
                
                if (count>99) {
                    weakSelf.navigationController.tabBarItem.badgeValue = @"99+";
                }else{
                    weakSelf.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu",count];
                }
                
            }else{
                weakSelf.navigationController.tabBarItem.badgeValue = nil;
            }
        });
        
    }];
}


- (IBAction)addFriendAction:(id)sender {
    
    QYHAddTableViewController *addVC  =[self.storyboard instantiateViewControllerWithIdentifier:@"QYHAddTableViewController"];
    [self.navigationController pushViewController:addVC animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return  _dataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return  1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"QYHChatViewCell";
    
    QYHChatViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[QYHChatViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    }
    
    
    [self configDateIndexPath:indexPath cell:cell];
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    EaseConversationModel *model = _dataArray[indexPath.row + indexPath.section];
    
    QYHChatViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (self.isTrans) {
        
        _model = model;
        UIAlertView *alerView = [[UIAlertView alloc]initWithTitle:@"确定发送给：" message:cell.titleLabel1.text delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alerView show];
        
        return;
    }
    
    
    if (!cell.redLabel.hidden) {
        [QYHAccount shareAccount].isNeedRefresh = YES;//传到历史记录聊天那刷新界面
    }
    
    EMMessage *message  = model.message;
    EMMessageBody *body = message.body;
    if (body.type != EMMessageBodyTypeText&&body.type != EMMessageBodyTypeImage&&body.type != EMMessageBodyTypeVoice) {
        /**
         *  申请添加好友界面
         */
        
        QYHNewFriendViewController *newFriendVC = [self.storyboard instantiateViewControllerWithIdentifier:@"QYHNewFriendViewController"];
        
        newFriendVC.friendDataArray = [_addFriendArray mutableCopy];
        
        [self.navigationController pushViewController:newFriendVC animated:YES];
        
        NSLog(@"跳到处理申请加为好友界面");
    }else{
        /**
         *  聊天界面
         */
        
        NSString *from = message.direction == EMMessageDirectionReceive ? message.from:message.to;
        _chatVC.userName = from;
        _chatVC.isRefresh = YES;
        _chatVC.title = cell.titleLabel1.text;
        
       [self.navigationController pushViewController:self.chatVC animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 35;
    }
    return 5.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0001;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if (section == 0)
    {
        if (self.isTrans) {
            UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 100, 21)];
            label.text = @"  最近聊天";
            label.textColor = [UIColor grayColor];
            label.font = [UIFont systemFontOfSize:15];
            
            return label;
        }
    }
    
    return nil;
}

- (void)configDateIndexPath:(NSIndexPath *)indexPath cell:(QYHChatViewCell *)cell
{
    EaseConversationModel *model = _dataArray[indexPath.row + indexPath.section];
    EMMessage *message  = model.message;
    EMMessageBody *body = message.body;
    
    
    NSString *content = nil;
    
    switch (body.type) {
        case EMMessageBodyTypeText:{
            EMTextMessageBody *textBody = (EMTextMessageBody *)body;
            content = textBody.text;
        }
            break;
        case EMMessageBodyTypeImage:{
            //            EMImageMessageBody *imageBody = (EMImageMessageBody *)body;
            content = @"[图片]";
        }
            break;
        case EMMessageBodyTypeVoice:{
            //            EMVoiceMessageBody *voiceBody = (EMVoiceMessageBody *)body;
            content = @"[语音]";
        }
            break;
        default:
            break;
    }

    cell.detailLabel1.text = content;
    
    if (body.type == EMMessageBodyTypeVoice) {
        
        BOOL extIsRead = [[message.ext objectForKey:@"isRead"] boolValue];
        if (!extIsRead) {
            NSMutableAttributedString *AttributedStr = [[NSMutableAttributedString alloc]initWithString:content];
            
            [AttributedStr addAttribute:NSForegroundColorAttributeName
             
                                  value:[UIColor colorWithRed:185.0/255 green:10.0/255 blue:0.0/255 alpha:1.0]
             
                                  range:NSMakeRange(0, 4)];
            
            cell.detailLabel1.attributedText = AttributedStr;
        }
    }


    
    double timeInterval = message.timestamp;
    if(message.timestamp > 140000000000) {
        timeInterval = message.timestamp / 1000;
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    cell.timeLabel.text    = [NSString getMessageDateString:date andNeedTime:NO];
  
    
    if (body.type != EMMessageBodyTypeText&&body.type != EMMessageBodyTypeImage&&body.type != EMMessageBodyTypeVoice) {
//        
//        if (!self.isTrans) {
//            cell.rightButtons = [self createRightButtons:1 indexPath:indexPath];
//            cell.rightSwipeSettings.transition = MGSwipeStateSwippingRightToLeft;
//            
//            cell.imgView1.image    = [UIImage imageNamed:@"plugins_FriendNotify"];
//            cell.titleLabel1.text  = @"新朋友";
//            
//            
//            XMPPvCardTemp *vCard = [[QYHXMPPvCardTemp shareInstance] vCard:model.fromUserID];
//            
//            NSString *contentSting;
//            switch (model.addStatus) {
//                case AddAgreeded:
//                    contentSting = @"已同意您添加为好友";
//                    break;
//                case AddRejected:
//                    contentSting = @"已拒绝您添加为好友";
//                    break;
//                default:
//                    contentSting = @"请求添加为好友";
//                    break;
//            }
//            cell.detailLabel1.text = [NSString stringWithFormat:@"%@ %@",vCard.nickname?[vCard.nickname stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]:model.fromUserID,contentSting];
//            
//            //获取未读的信息条数
//            __weak __typeof(cell) weakCell = cell;
//            __weak __typeof(self) weakself = self;
//            [[QYHFMDBmanager shareInstance]queryAllUnReadAddFriendMessegeCompletion:^(NSInteger count, BOOL result) {
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (count) {
//                        
//                        weakCell.redLabel.hidden = NO;
//                        
//                        if (count>99) {
//                            weakCell.redLabel.text   = @"99+";
//                        }else{
//                            
//                            weakCell.redLabel.text   = [NSString stringWithFormat:@"%lu",count];
//                        }
//                        
//                        [weakself startShake:weakCell.redLabel];
//                        
//                    }else{
//                        weakCell.redLabel.hidden = YES;
//                        weakCell.redLabel.text   = [NSString stringWithFormat:@"%lu",count];
//                        [weakself stopShake:weakCell.redLabel];
//                    }
//                    
//                    
//                    weakCell.redLabelWithConstraint.constant = ([NSString getContentSize:weakCell.redLabel.text fontOfSize:13 maxSizeMake:CGSizeMake(35, 20)].width + 8 )> 18 ?[NSString getContentSize:weakCell.redLabel.text fontOfSize:13 maxSizeMake:CGSizeMake(35, 15)].width + 5:18;
//                    weakCell.redLabel.layer.cornerRadius = weakCell.redLabel.frame.size.height/2.0;
//                    weakCell.redLabel.clipsToBounds = YES;
//                });
//                
//            }];
//        }
        
    }else{
        
        if (!self.isTrans) {
            cell.rightButtons = [self createRightButtons:2 indexPath:indexPath];
//            cell.rightSwipeSettings.transition = MGSwipeStateSwippingRightToLeft;
        }
        
        /**
         *  通过保存的字典里获取对应好友是否有草稿
         */
        
        NSString *from = message.direction == EMMessageDirectionReceive ? message.from:message.to;
        
        if ([_chatVC.friendJidDic objectForKey:from]) {
            
            NSMutableAttributedString *AttributedStr = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"[草稿] %@",[_chatVC.friendJidDic objectForKey:from]]];
            
            [AttributedStr addAttribute:NSForegroundColorAttributeName
             
                                  value:[UIColor colorWithRed:185.0/255 green:10.0/255 blue:0.0/255 alpha:1.0]
             
                                  range:NSMakeRange(0, 4)];
            
            cell.detailLabel1.attributedText = AttributedStr;
        }
        
        //昵称
        cell.titleLabel1.text  = model.title;
        //显示好友的头像
        [cell.imgView1 sd_setImageWithURL:[NSURL URLWithString:model.avatarURLPath] placeholderImage:model.avatarImage];
        
        
        
        if (!self.isTrans) {
            //获取未读的信息条数
            __weak __typeof(cell) weakCell = cell;
            __weak __typeof(self) weakself = self;
            
            NSInteger count = [model.conversation unreadMessagesCount];
           
            if (count) {
                weakCell.redLabel.hidden = NO;
                
                if (count>99) {
                    weakCell.redLabel.text   = @"99+";
                }else{
                    
                    weakCell.redLabel.text   = [NSString stringWithFormat:@"%lu",count];
                }
                
                [weakself startShake:weakCell.redLabel];
                
            }else{
                weakCell.redLabel.hidden = YES;
                weakCell.redLabel.text   = [NSString stringWithFormat:@"%lu",count];
                [weakself stopShake:weakCell.redLabel];
            }
            
            
            weakCell.redLabelWithConstraint.constant = ([NSString getContentSize:weakCell.redLabel.text fontOfSize:13 maxSizeMake:CGSizeMake(35, 15)].width + 8) > 18 ?[NSString getContentSize:weakCell.redLabel.text fontOfSize:13 maxSizeMake:CGSizeMake(35, 15)].width + 5:18;
            weakCell.redLabel.layer.cornerRadius = weakCell.redLabel.frame.size.height/2.0;
            weakCell.redLabel.clipsToBounds = YES;
        }
        
    }
}


//抖动动画
- (void)startShake:(UILabel *)redLabel
{
    // 设定为缩放
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    
    // 动画选项设定
    animation.duration = 2.0f; // 动画持续时间
    animation.repeatCount = MAXFLOAT; // 重复次数
    animation.autoreverses = YES; // 动画结束时执行逆动画
    
    // 缩放倍数
    animation.fromValue = [NSNumber numberWithFloat:1.0]; // 开始时的倍率
    animation.toValue   = [NSNumber numberWithFloat:1.5]; // 结束时的倍率
    
    // 添加动画
    [redLabel.layer addAnimation:animation forKey:@"scale-layer"];
    
//    CAKeyframeAnimation *rotationAni = [CAKeyframeAnimation animation];
//    
//    rotationAni.keyPath = @"transform.rotation.z";
//    
//    CGFloat angle = M_PI_4*2;
//    
//    rotationAni.values = @[@(-angle),@(angle),@(-angle)];
//    
//    rotationAni.repeatCount = MAXFLOAT;
//    
//    rotationAni.duration = 1.5;
//    
//    [redLabel.layer addAnimation:rotationAni forKey:@"shake"];
}

//移除抖动动画
- (void)stopShake:(UILabel *)redLabel
{
    
    [redLabel.layer removeAnimationForKey:@"scale-layer"];

    
//    [redLabel.layer removeAnimationForKey:@"shake"];
}


/**
 *  创建右滑按钮
 *
 *
 */
-(NSArray *) createRightButtons: (int) number indexPath:(NSIndexPath *)indexPath
{
    EaseConversationModel *model = _dataArray[indexPath.row + indexPath.section];
    NSString *title2 = [model.conversation unreadMessagesCount] == 0 ? @"标为未读":@"标为已读";
    
    NSMutableArray * result = [NSMutableArray array];
    NSString* titles[2] = {@"删除", title2};
    UIColor * colors[2] = {[UIColor redColor], [UIColor lightGrayColor]};
    
    __weak typeof(self) selfWeak = self;
    
    for (int i = 0; i < number; ++i)
    {
        MGSwipeButton * button = [MGSwipeButton buttonWithTitle:titles[i] backgroundColor:colors[i] callback:^BOOL(MGSwipeTableCell * sender){
            switch (i)
            {
                case 0:
                    [selfWeak deleteUserByIndexPath:indexPath];
                    break;
                    
                default:
                    [selfWeak updateIsReadOrNoReadByIndexPath:indexPath messageModel:model];
                    break;
            }
            
            //            BOOL autoHide = i != 0;
            return NO;
        }];
        [result addObject:button];
    }
    return result;
}
/**
 *  标为未读或者标为已读
 *
 *
 */
- (void)updateIsReadOrNoReadByIndexPath:(NSIndexPath *)indexPath messageModel:(EaseConversationModel *)messageModel
{
    if ([messageModel.conversation unreadMessagesCount] == 0) {
        
        //标为未读
        EMError *error = nil;
        EMMessage *message  = messageModel.message;
        message.isRead = NO;

        [messageModel.conversation updateMessageChange:message error:&error];
        if (!error) {
            NSLog(@"标为未读状态成功");
        }else{
            NSLog(@"标为未读状态失败");
        }
        
        [self getAllChatMessage];
       
    }else{
        //标为已读
        EMError *error = nil;
        [messageModel.conversation markAllMessagesAsRead:&error];
        if (!error) {
            NSLog(@"标为未读状态成功");
        }else{
            NSLog(@"标为未读状态失败");
        }
        
        [self getAllChatMessage];
    }
}

/**
 *  删除聊天记录
 *
 *
 */
- (void)deleteUserByIndexPath:(NSIndexPath *)indexPath
{
    EaseConversationModel *model = _dataArray[indexPath.row + indexPath.section];
    EMMessage *message  = model.message;
    EMMessageBody *body = message.body;
    
    if (body.type != EMMessageBodyTypeText&&body.type != EMMessageBodyTypeImage&&body.type != EMMessageBodyTypeVoice) {
        
        __weak typeof(self) weakself = self;
        
        [[QYHFMDBmanager shareInstance]deleteAllAddFriendMessegeCompletion:^(BOOL result) {
            if (result) {

                [weakself.dataArray removeObjectAtIndex:indexPath.section];  //删除数组里的数据
                [weakself.myTableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];  //删除对应数据的cell
                
                /**
                 *  传到信息聊天界面刷新数据
                 */
                [[NSNotificationCenter defaultCenter] postNotificationName:KReceiveAddFriendNotification object:model];
                
            }else{
                NSLog(@"删除新朋友信息失败");
            }
        }];
        
    }else{
        
        __weak typeof(self) weakself = self;
        
        EMError *error = nil;
        
        [model.conversation deleteAllMessages:&error];
       
        if (!error) {
            
            [weakself.dataArray removeObjectAtIndex:indexPath.section];  //删除数组里的数据
            [weakself.myTableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];  //删除对应数据的cell
            
//            /**
//             *  传到信息聊天界面刷新数据
//             */
//            [[NSNotificationCenter defaultCenter] postNotificationName:KReceiveAddFriendNotification object:model];
//            
        }else{
            NSLog(@"删除好友信息失败");
        }

    }
    
}

#pragma mark - alerViewDelagete

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        
        self.isTrans = NO;
        
       __block QYHContenViewController *contentVC = _chatVC;
        /**
         *  聊天界面
         */
        EMMessage *message  = _model.message;
        NSString *from = message.direction == EMMessageDirectionReceive ? message.from:message.to;
        contentVC.userName = from;
        contentVC.isRefresh = YES;
        contentVC.title = alertView.message;
        contentVC.isTrans = YES;
        
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}


-(void)dealloc{
    
    NSLog(@"QYHChatViewController--dealloc");
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:KReceiveChatMessageNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:KconversationListDidUpdateNotification object:nil];
//    [[NSNotificationCenter defaultCenter]removeObserver:self name:KReceiveAddFriendNotification object:nil];
//    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:KLoginSuccessNotification object:nil];
    
}


@end
