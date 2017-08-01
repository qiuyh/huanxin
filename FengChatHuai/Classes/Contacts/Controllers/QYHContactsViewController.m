//
//  QYHContactsViewController.m
//  FengChatHuai
//
//  Created by iMacQIU on 16/5/20.
//  Copyright © 2016年 iMacQIU. All rights reserved.
//

#import "QYHContactsViewController.h"
#import "QYHAddTableViewController.h"
#import "MGSwipeTableCell.h"
#import "QYHContenViewController.h"
#import "QYHFMDBmanager.h"
#import "QYHContactModel.h"
#import "QYHDetailTableViewController.h"
#import "QYHContactsCell.h"
#import "EaseUserModel.h"
#import "UIImageView+WebCache.h"

@interface QYHContactsViewController ()<UITableViewDelegate,UITableViewDataSource,NSFetchedResultsControllerDelegate,UIAlertViewDelegate>

{
    NSFetchedResultsController *_resultsContr;
    
    QYHContactModel *_nickNameUser;
    NSString *_deletUser;
    NSIndexPath     *_deletIndex;
    
    QYHContenViewController *_chatVC;
    
    BOOL _isVisibleViewController;
}

@property (weak, nonatomic) IBOutlet UITableView *myTableView;

/**
 * 好友
 */
@property(strong,nonatomic)NSMutableArray *usersArray;

//@property(strong,nonatomic)NSMutableArray *messageArray;

@property(nonatomic,strong) EaseUserModel *model;

@end

@implementation QYHContactsViewController



- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

//        _messageArray = [NSMutableArray array];
        
        _usersArray   = [NSMutableArray array];
    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getContentChange) name:KContentChangeNotification object:nil];
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.isTrans) {
        
        UIBarButtonItem *navigationSpacer = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                             target:self action:nil];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
            navigationSpacer.width = - 10.5;  // ios 7
            
        }else{
            navigationSpacer.width = - 6;  // ios 6
        }
        
        UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(popVCAction)];
        
        
        self.navigationItem.leftBarButtonItems = @[navigationSpacer,leftBarButtonItem];
    }
    
}

- (void)popVCAction{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)getContentChange{
    
    NSLog(@"内容数据发生改变——联系人界面打印");
    
    __weak typeof(self) weakSelf = self;
    
    [[QYHEMClientTool shareInstance] getContactsFromServerWithCompletion:^(NSArray *aList, EMError *aError) {
        if (!aError) {
            
            NSLog(@"getContactsFromServerWithCompletion==%@",aList);
            
            [aList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSString *username = obj;
                EaseUserModel *model = [[EaseUserModel alloc] initWithBuddy:username];
                UserProfileEntity *profileEntity = [[UserProfileManager sharedInstance] getUserProfileByUsername:username];
                
                NSLog(@"profileEntity==%@",profileEntity);
//                if (profileEntity) {
                    model.nickname = profileEntity.nickname == nil ? username : profileEntity.nickname;
                    model.avatarURLPath = profileEntity.imageUrl;
                    
                    [weakSelf.usersArray addObject:model];
//                }
            }];
            
               [weakSelf.myTableView reloadData];
            
        }else{
            NSLog(@"获取好友失败");
        }
        
    }];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    _isVisibleViewController = YES;
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    _isVisibleViewController = NO;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.myTableView.rowHeight = 60.0f;
    
    if (!self.isTrans) {
        self.myTableView.tableHeaderView = [self loadHearView];
        
    }else{
        self.navigationItem.rightBarButtonItem = nil;
        self.title = @"联系人";
    }
    
    self.myTableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 20)];
    
    _chatVC = [QYHContenViewController shareInstance];
    
    [self getContentChange];
}

/**
 *  tabbleviewHearView
 *
 *
 */
- (UIView *)loadHearView{
    
    UIView *hearView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 218)];
    hearView.backgroundColor = [UIColor whiteColor];
    
    UIView *spaceView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 35)];
    spaceView.backgroundColor = [UIColor colorWithHexString:@"EFEFF4"];
    
    UIView *lineView1 = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(spaceView.frame), SCREEN_WIDTH, 1)];
    lineView1.backgroundColor = [UIColor colorWithHexString:@"DADADA"];

    
    UIView *lineView2 = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(hearView.frame)-1, SCREEN_WIDTH, 1)];
    lineView2.backgroundColor = [UIColor colorWithHexString:@"DADADA"];

    [hearView addSubview:spaceView];
    [hearView addSubview:lineView1];
    [hearView addSubview:lineView2];
    
    NSArray *imageArray = @[@"add_friend_icon_addgroup",@"Contact_icon_ContactTag",@"add_friend_icon_offical"];
    NSArray *nameArray  = @[@"群聊",@"标签",@"公众号"];
    
    for (int i = 0; i<3; i++) {
     
        UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(18, 45+61*i, 40, 40)];
        imgView.image = [UIImage imageNamed:imageArray[i]];
        
        UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(imgView.frame)+15, 10, 200, 21)];
        nameLabel.text = nameArray[i];
        nameLabel.centerY = imgView.centerY;
        
        UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(18, CGRectGetMaxY(imgView.frame)+10, SCREEN_WIDTH, 1)];
        lineView.backgroundColor = [UIColor colorWithHexString:@"DADADA"];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(0, 0, SCREEN_WIDTH, 60);
        button.backgroundColor = [UIColor clearColor];
        button.centerY = imgView.centerY;
        button.alpha = 0.3;
        button.tag = 100+i;
        
        [button addTarget:self action:@selector(didSelectButton:) forControlEvents:UIControlEventTouchUpInside];
        
        [hearView addSubview:button];
        [hearView addSubview:imgView];
        [hearView addSubview:nameLabel];
        [hearView addSubview:lineView];
        
    }
    
    return hearView;
}

- (void)didSelectButton:(UIButton *)button{
    
    button.backgroundColor = [UIColor lightGrayColor];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        button.backgroundColor = [UIColor clearColor];
    });
    
    [[[UIAlertView alloc]initWithTitle:@"未实现 ！" message:nil delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil, nil] show];
    
    switch (button.tag -100) {
        case 0:
            NSLog(@"群聊");
            break;
        case 1:
            NSLog(@"标签");
            break;
        case 2:
            NSLog(@"公众号");
            break;
        default:
            break;
    }
}


- (IBAction)addFriendAction:(id)sender {
    
    QYHAddTableViewController *addVC  =[self.storyboard instantiateViewControllerWithIdentifier:@"QYHAddTableViewController"];
    [self.navigationController pushViewController:addVC animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return  _usersArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    return  1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"QYHContactsCell";
    
    QYHContactsCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];

    if (!cell) {
        cell = [[QYHContactsCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    }
    
    //获取对应的好友
    
    [self configDateIndexPath:indexPath tableCell:cell];
    
    
    if (!self.isTrans) {
        cell.rightButtons = [self createRightButtons:2 indexPath:indexPath];
//        cell.rightSwipeSettings.transition = MGSwipeStateSwippingRightToLeft;
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    EaseUserModel *model = _usersArray[indexPath.section + indexPath.row];
    
    if (self.isTrans) {
        
        QYHContactsCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        if (self.isTrans) {
            
            _model = model;
            UIAlertView *alerView = [[UIAlertView alloc]initWithTitle:@"确定发送给：" message:cell.titleLabel.text delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            alerView.tag = 102;
            [alerView show];
            
            return;
        }
        
    }else{
        
        /**
         *  聊天界面
         */
//        __block QYHContenViewController *contentVC = _chatVC;
        
        _chatVC.userName = model.buddy;
        _chatVC.isRefresh = YES;
        _chatVC.title = model.nickname;
        
        [self.navigationController pushViewController:_chatVC animated:YES];
        
//        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//        QYHDetailTableViewController *detailVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"QYHDetailTableViewController"];
//        
//        detailVC.dic = @{@"imageUrl":model.avatarURLPath ? model.avatarURLPath : model.avatarImage,
//                         @"nickName":model.nickname,
//                         @"sex":@"",
//                         @"area":@"",
//                         @"personalSignature":@"",
//                         @"phone":model.nickname
//                         };
//        
//        detailVC.isFriend   = YES;
//        detailVC.remarkName = model.nickname;
//        
//        [self.navigationController pushViewController:detailVC animated:YES];
        
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

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100){
//        if (buttonIndex == 1){
//            UITextField *nickNameTextField = [alertView textFieldAtIndex:0];
//            
//            if ([[QYHEMClientTool shareInstance] isLoggedIn] && [[QYHEMClientTool shareInstance] isConnected]) {
//                
//                if (nickNameTextField.text.length > 10) {
//                    [QYHProgressHUD showErrorHUD:nil message:@"备注不能超过10个字符"];
//                    return;
//                }
//                
//                  
////                [[QYHXMPPTool sharedQYHXMPPTool].roster setNickname:
////                 [nickNameTextField.text.length>0? nickNameTextField.text:nickNameTextField.placeholder stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forUser:_nickNameUser.jid];
////                
//            }else{
//                [QYHProgressHUD showErrorHUD:nil message:@"网络连接失败"];
//                [self.myTableView reloadData];
//            }
//        }else{
//            [self.myTableView reloadData];
//        }
        
    }else if(alertView.tag == 101){
        if (buttonIndex == 1){
            if ([[QYHEMClientTool shareInstance] isLoggedIn] && [[QYHEMClientTool shareInstance] isConnected]) {
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];

                __weak typeof(self) weakself = self;
                [[QYHEMClientTool shareInstance] deleteContact:_deletUser completion:^(NSString *aUsername, EMError *aError) {
                    
                    if (!aError) {
                         [MBProgressHUD hideHUDForView:weakself.view animated:YES];
                        [weakself.usersArray removeObjectAtIndex:_deletIndex.section];  //删除数组里的数据
                        [weakself.myTableView deleteSections:[NSIndexSet indexSetWithIndex:_deletIndex.section] withRowAnimation:UITableViewRowAnimationAutomatic];  //删除对应数据的cell
                    }else{
                        NSLog(@"删除对应的新朋友信息失败");
                    }
                    
                }];
              
            }else{
                [QYHProgressHUD showErrorHUD:nil message:@"网络连接失败"];
                [self.myTableView reloadData];
            }
            
        }else{
            [self.myTableView reloadData];
        }
        
    }else if (alertView.tag == 102){
        
        if (buttonIndex == 1) {
            
            self.isTrans = NO;
            
            __block QYHContenViewController *contentVC = _chatVC;
            /**
             *  聊天界面
             */
            
            contentVC.userName = _model.buddy;
            contentVC.isRefresh = YES;
            contentVC.title = alertView.message;
            contentVC.isTrans = YES;
            
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
        }
        
    }
    
}



/**
 *  创建右滑按钮
 *
 *
 */
-(NSArray *) createRightButtons: (int) number indexPath:(NSIndexPath *)indexPath
{
    NSMutableArray * result = [NSMutableArray array];
    NSString* titles[2] = {@"删除", @"备注"};
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
//                    [selfWeak updateNickNameByIndexPath:indexPath];
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
 *  修改备注
 *
 *
 */
- (void)updateNickNameByIndexPath:(NSIndexPath *)indexPath
{
     QYHContactModel *user =_usersArray[indexPath.row + indexPath.section];
    
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"修改备注" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.tag = 100;
    
    UITextField *nickNameTextField = [alertView textFieldAtIndex:0];
    nickNameTextField.placeholder  = user.nickname ? [user.nickname stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @"";
    _nickNameUser = user;
    
    
    [alertView show];
}

/**
 *  删除好友
 *
 *
 */
- (void)deleteUserByIndexPath:(NSIndexPath *)indexPath
{
    EaseUserModel *user = _usersArray[indexPath.row + indexPath.section];
    _deletUser  = user.buddy;
    _deletIndex = indexPath;
    
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"删除好友" message:@"您确定删除该好友，同时会将我从对方的列表中移除，且屏蔽对方的临时会话，不再接收此人的消息？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
 
    alertView.tag = 101;

    [alertView show];
}

/**
 *  展示好友
 *
 *
 */
- (void)configDateIndexPath:(NSIndexPath *)indexPath tableCell:(QYHContactsCell *)cell
{
    EaseUserModel *user = _usersArray[indexPath.row + indexPath.section];
    
    cell.titleLabel.text  = user.nickname;
    cell.detailLabel.text = @"";
    [cell.imgView sd_setImageWithURL:[NSURL URLWithString:user.avatarURLPath] placeholderImage:user.avatarImage];
}


-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:KContentChangeNotification object:nil];
}


@end
