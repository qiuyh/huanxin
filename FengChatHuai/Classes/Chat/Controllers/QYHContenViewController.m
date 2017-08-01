//
//  QYHContenViewController.m
//  FengChatHuai
//
//  Created by iMacQIU on 16/5/26.
//  Copyright © 2016年 iMacQIU. All rights reserved.
//

#import "QYHContenViewController.h"
#import "QYHChatCell.h"
#import "QYHHttpTool.h"
#import "QYHToolView.h"
#import "QYHChatCell.h"
#import "QYHQiNiuRequestManarger.h"
#import "UIImageView+WebCache.h"
#import "MWPhotoBrowser.h"
#import "UIImage+Additions.h"
#import "MJRefresh.h"
#import "QYHRecordingView.h"
#import "NSString+Additions.h"
#import "QYHFMDBmanager.h"
#import "QYHChatMssegeModel.h"
#import "UIView+SDAutoLayout.h"
#import "QYHMessageTableView.h"
#import "QYHMainTabbarController.h"
#import "QYHDetailTableViewController.h"
//#import "XMPPvCardTemp.h"
#import "QYHWebViewController.h"
#import "QYHChatViewController.h"

//枚举Cell类型
typedef enum : NSUInteger {
    TextSend ,
    ImageSend,
    VoiceSend
    
} sendContentType;
//
//
//typedef enum : NSUInteger {
//    HImageType,
//    VImageType
//    
//} imageType;

@interface QYHContenViewController ()<UITableViewDelegate,UITableViewDataSource,NSFetchedResultsControllerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,MWPhotoBrowserDelegate,UIGestureRecognizerDelegate,QYHChatCellDelegate>

{
    NSFetchedResultsController *_resultContr;
    
    NSArray *_face;
    
    CGFloat _ratioHW;
    
    CGFloat _offSet;
    
    BOOL _isCaScroll;
    
    CGFloat _textViewHeight;
    
    
    BOOL _isRefresh;
    
    BOOL _isSendAgain;
    
    BOOL _isVisibleViewController;

}

//@property (nonatomic,assign) NSInteger scrollToTopRow;


@property (nonatomic,assign) BOOL isShowKeyBoard;//判断是否显示键盘

@property (nonatomic,strong) UIView* headView;

@property (nonatomic,strong) UIActivityIndicatorView *activity;

@property (weak, nonatomic) IBOutlet QYHMessageTableView *myTableView;

//工具栏
@property (weak, nonatomic) IBOutlet UIView *toolView;

@property (nonatomic,strong) QYHToolView *toolView1;


//音量图片
@property (strong, nonatomic) UIImageView *volumeImageView;

//工具栏的高约束，用于当输入文字过多时改变工具栏的约束
//@property (strong, nonatomic) NSLayoutConstraint *tooViewConstraintHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tooViewConstraintBottom;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tooViewConstraintHeight;

@property (nonatomic,assign) MySendContentType sentType;

@property (nonatomic,assign) imageType sendImageType;

@property (nonatomic,assign) CGFloat audioTime;

@property (strong, nonatomic) QYHRecordingView* recordingView;

@property (nonatomic, strong) NSMutableArray *dataArray;

@property (nonatomic, strong) NSMutableArray *imageArray;

@property (nonatomic, strong) NSMutableArray *photosArray;

@property (nonatomic,assign) NSInteger index;

@property (nonatomic,strong) UIScrollView *imageScrollView;

@property (nonatomic,strong) QYHChatCell * preCell;

@property (nonatomic,strong) QYHChatCell * menuCell;

@property (nonatomic,assign) BOOL islager;

@property (nonatomic,strong)  EMMessage *transMssegeModel;


@property (nonatomic,strong) EMConversation *conversation;

//@property (nonatomic,copy) NSString *contentStr;//复制的文字

@end

@implementation QYHContenViewController


static QYHContenViewController *contenVC = nil;
+(instancetype)shareInstance{
    @synchronized(self) {
        if(contenVC == nil) {
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            contenVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"QYHContenViewController"];
        }
    }
    return contenVC;
}

+ (void)attemptDealloc
{
    contenVC = nil;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        _friendJidDic = [NSMutableDictionary dictionary];
        _imageArray   = [NSMutableArray array];
        _photosArray  = [NSMutableArray array];
        _dataArray    = [NSMutableArray array];
        _allDataArray = [NSMutableArray array];
        _audioTime    = 0;
        
        _toolView1 = [[QYHToolView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 44)];
        //工具栏
        [_toolView1 initView:YES];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveChatMessage:) name:KReceiveChatMessageNotification object:nil];
        
        //注册为被通知者
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuShow:) name:UIMenuControllerWillShowMenuNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuHide:) name:UIMenuControllerWillHideMenuNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.view setBackgroundColor:[UIColor colorWithRed:235.0/255 green:235.0/255 blue:235.0/255 alpha:1.0]];

    [self.myTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.myTableView.backgroundColor = [UIColor colorWithRed:235.0/255 green:235.0/255 blue:235.0/255 alpha:1.0];

    _face = [QYHChatDataStorage shareInstance].faceDataArray;
    
    //加载数据库的聊天数据
//    [self setupResultContr];

    //添加基本的子视图
    [self addMySubView];

    //给子视图添加约束
//    [self addConstaint];

    //设置工具栏的回调
    [self setToolViewBlock];
    
    //添加键盘掉落事件(针对UIScrollView或者继承UIScrollView的界面)
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyboardwillHide:)];
    //设置成NO表示当前控件响应后会传播到其他控件上，默认为YES。
    tapGestureRecognizer.cancelsTouchesInView = YES;
    tapGestureRecognizer.delegate = self;
    //将触摸事件添加到当前view
    [self.myTableView addGestureRecognizer:tapGestureRecognizer];
    
    [self getData];
    
    
}


- (void)popAction{
    
    NSLog(@"popToRootViewControllerAnimated");
    
    QYHMainTabbarController *tabbar = (QYHMainTabbarController *)self.tabBarController;
    tabbar.selectedIndex = 0;
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self scrollToBottom];
    [self keyboardwillHide:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
    
    
    _isCaScroll  = YES;

    
    if (_isRefresh) {
        
        _isRefresh = NO;

        /**
         *  通过保存的字典里获取对应好友是否有草稿
         */
        if ([_friendJidDic objectForKey:_userName]) {
            _toolView1.sendTextView.text = [_friendJidDic objectForKey:_userName];
        }else{
            _toolView1.sendTextView.text = @"";
        }
        
        if (_toolView1.sendTextView.text.length > 0) {
            
            [_toolView1.sendTextView becomeFirstResponder];
        }else{
            
            [_toolView1.sendTextView resignFirstResponder];
        }
        
        [self getData];

    }
    
    
    UIBarButtonItem *navigationSpacer = [[UIBarButtonItem alloc]
                                         initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                         target:self action:nil];
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        navigationSpacer.width = - 10.5;  // ios 7
        
    }else{
        navigationSpacer.width = - 6;  // ios 6
    }
    
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(popAction)];
    
    
    self.navigationItem.leftBarButtonItems = @[navigationSpacer,leftBarButtonItem];
    
    _isVisibleViewController = YES;
    
    /**
     *  转发信息
     */
    if (self.isTrans) {
        self.isTrans = NO;
        [self transSendMessage];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    if (_preCell) {
        [_preCell.audioPlayer stop];
        [_preCell.voiceImageView stopAnimating];
        
    }
    /**
     *  判断当前的好友是否有草稿，保存在字典里
     */

    if (_toolView1.sendTextView.text.length > 0) {
        
        [_friendJidDic setObject:_toolView1.sendTextView.text forKey:_userName];
    }else{
        [_friendJidDic removeObjectForKey:_userName];
    }
    
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [QYHAccount shareAccount].isNeedRefresh = YES;//传到历史记录聊天那刷新界面

    NSLog(@"QYHContenViewController--viewDidAppear");
    [self updatereadedStatus];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    _isVisibleViewController = NO;
    
    NSLog(@"QYHContenViewController--viewDidDisappear");
}


-(void) addMySubView
{
    
    _recordingView = [[QYHRecordingView alloc] initWithState:DDShowVolumnState];
    [_recordingView setHidden:YES];
    [_recordingView setCenter:CGPointMake(SCREEN_WIDTH/2.0, SCREEN_HEIGHT/2.0)];
    
    
    [_toolView addSubview:_toolView1];
    
    _toolView1.sd_layout.leftEqualToView(_toolView).rightEqualToView(_toolView).topEqualToView(_toolView).bottomEqualToView(_toolView);
    
}


- (UIView *)headView{
    
    if (!_headView) {
        _headView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 40)];
        _headView.backgroundColor = [UIColor clearColor];
        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//         _activity.transform = CGAffineTransformMakeScale(2, 2);//改变大小
        [_headView addSubview:_activity];
        _activity.frame = CGRectMake(_headView.frame.size.width/2.0, _headView.frame.size.height/3.0, 20, 20);
        _headView.hidden = YES;
    }
    return _headView;
}

#pragma mark - 实现工具栏的回调
-(void)setToolViewBlock
{
    __weak __block QYHContenViewController *copy_self = self;
    //通过block回调接收到toolView中的text
    [self.toolView1 setMyTextBlock:^(NSString *myText) {
        NSLog(@"%@",myText);
      
        [copy_self sendMessage:myText sendType:TextSend];
    }];
    
    
    //回调输入框的contentSize,改变工具栏的高度
    [self.toolView1 setContentSizeBlock:^(CGSize contentSize) {
        [copy_self updateHeight:contentSize];
    }];
    
    //录音开始
    [self.toolView1 setBeganRecordBlock:^(int flag) {
        
        if (flag == 1) {
            
            if (![[copy_self.view subviews] containsObject:copy_self.recordingView])
            {
                [copy_self.view addSubview:copy_self.recordingView];
            }
            [copy_self.recordingView setHidden:NO];
            [copy_self.recordingView setRecordingState:DDShowVolumnState];
            [copy_self.recordingView setVolume:(0.5)];

        }else{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [copy_self.recordingView setHidden:YES];
            });
            return;
        }
    }];
    
    //获取录音声量，用于声音音量的提示
    [self.toolView1 setAudioVolumeBlock:^(CGFloat volume) {
        
        [copy_self.recordingView setVolume:((volume*10)/6 + 0.5)];
        
    }];
    
    //获取录音的时间
    [self.toolView1 setAudioTimeBlock:^(CGFloat audioTime) {
        
        copy_self.audioTime = audioTime;
    }];
    
    //获取录音地址（用于录音播放方法）
    [self.toolView1 setAudioURLBlock:^(NSString *audioURL) {
//        copy_self.volumeImageView.hidden = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [copy_self.recordingView setHidden:YES];
        });
        
        NSLog(@"audioURL==%@",audioURL);
       
        [copy_self sendMessage:audioURL sendType:VoiceSend];
    }];
    
    //录音取消（录音取消后，把音量图片进行隐藏）
    [self.toolView1 setCancelRecordBlock:^(int flag) {
        if (flag == 1) {
//            copy_self.volumeImageView.hidden = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [copy_self.recordingView setHidden:NO];
                [copy_self.recordingView setRecordingState:DDShowCancelSendState];
            });
            return;

        }
        
        if (flag == 0) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [copy_self.recordingView setHidden:NO];
                [copy_self.recordingView setRecordingState:DDShowRecordTimeTooShort];
            });
            return;
        }
    }];
    
    
    //扩展功能回调
    [self.toolView1 setExtendFunctionBlock:^(int buttonTag) {
        
        switch (buttonTag) {
            case 1:
                //从相册获取
                [copy_self imgChooseBtnClick:UIImagePickerControllerSourceTypePhotoLibrary];
                break;
            case 2:
                //拍照
                [copy_self imgChooseBtnClick:UIImagePickerControllerSourceTypeCamera];
                break;
                
            default:
                break;
        }
    }];
}

#pragma mark - 刚进来的时候获取数据
- (void)getData{
    
    [_dataArray removeAllObjects];
    _dataArray = [NSMutableArray array];
//    [self.myTableView reloadData];
    
    _conversation = [[QYHEMClientTool shareInstance] getConversation:_userName type:EMConversationTypeChat];
    
    NSLog(@"_userName==%@,_conversation==%@",_userName,_conversation);
    
    __weak typeof(self) weakself = self;
    [_conversation loadMessagesStartFromId:nil count:30 searchDirection:EMMessageSearchDirectionUp completion:^(NSArray *aMessages, EMError *aError) {
        
        NSLog(@"loadMessagesStartFromId_aError==%@,aMessages==%@",aError.errorDescription,aMessages);
        
        weakself.myTableView.tableHeaderView = aMessages.count == 30 ? self.headView : nil;
        weakself.dataArray = [aMessages mutableCopy];
        
        [weakself.myTableView reloadData];
        
        //滑到表底部
        [weakself scrollToBottom];
        
        [weakself getImageData];
    }];
}


#pragma mark - 上拉加载更多
- (void)getMOreData
{
    //等待0.5s
    _headView.hidden = NO;
    [_activity startAnimating];
    _isRefresh = YES;
    
    EMMessage *message = [self.dataArray firstObject];
    
    __weak typeof(self) weakself = self;
    [_conversation loadMessagesStartFromId:message.messageId count:30 searchDirection:EMMessageSearchDirectionUp completion:^(NSArray *aMessages, EMError *aError) {
        
//        weakself.scrollToTopRow = weakself.dataArray.count;
        
        weakself.myTableView.tableHeaderView = aMessages.count == 30 ? weakself.headView : nil;
        [weakself.dataArray insertObjects:[aMessages mutableCopy] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, aMessages.count)]];
        
        [weakself.myTableView reloadData];
        [weakself getImageData];
        
        [weakself.activity stopAnimating];
        weakself.headView.hidden = YES;
        weakself.isRefresh = NO;
    }];
}

#pragma mark - 接收聊天信息
- (void)receiveChatMessage:(NSNotification *)noti
{
    if (_isVisibleViewController) {
        
        [self updatereadedStatus];
        
        EMMessage *message = [self.dataArray lastObject];
        __weak typeof(self) weakself = self;
        [_conversation loadMessagesStartFromId:message.messageId count:20 searchDirection:EMMessageSearchDirectionUp completion:^(NSArray *aMessages, EMError *aError) {
            
//            weakself.scrollToTopRow = weakself.dataArray.count;
            
            [weakself.dataArray insertObjects:[aMessages mutableCopy] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, aMessages.count)]];
            
            [weakself.myTableView reloadData];
            
            [weakself scrollToBottom];
            [weakself getImageData];
        }];
        
    }
}


#pragma mark - 发消息
- (void)sendMessage:(id)meesage sendType:(sendContentType)sendType{
    
    __weak typeof(self) weakself = self;
   
    NSDictionary *messageExt = nil;
    NSString *from = [[QYHEMClientTool shareInstance] currentUsername];
    EMMessageBody *bodys = nil;
    
    switch (sendType) {
        case TextSend:{
            NSString *text = (NSString *)meesage;
            EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:text];
            bodys = body;
        }
            break;
            
        case ImageSend:{
            
            UIImage *newImage = (UIImage *)meesage;
            //将压缩过的图片 转化成二进制流
            NSData *data = UIImageJPEGRepresentation(newImage, 1.0);
            NSString *fileName = [NSString stringWithFormat:@"%ldImage", (long)[[NSDate date] timeIntervalSince1970]];
            NSString *path     =[NSString stringWithFormat:@"%@%@",[QYHChatDataStorage shareInstance].homePath,fileName];
            [data writeToFile:path atomically:YES];
            
            EMImageMessageBody *body = [[EMImageMessageBody alloc] initWithData:data displayName:fileName];
            bodys = body;
        }
            break;
        case VoiceSend:{
            NSString *voiceLocalPath = (NSString *)meesage;
            NSString *fileName = [NSString stringWithFormat:@"%ldAudio", (long)[[NSDate date] timeIntervalSince1970]];
            
            EMVoiceMessageBody *body = [[EMVoiceMessageBody alloc] initWithLocalPath:voiceLocalPath displayName:fileName];
            bodys = body;
            messageExt = @{@"isRead":@(NO)};
        }
            break;
        default:
            break;
    }
    
    
    //生成Message
    EMMessage *message = [[EMMessage alloc] initWithConversationID:_userName from:from to:_userName body:bodys ext:messageExt];
    message.chatType = EMChatTypeChat;
    //message.chatType = EMChatTypeChat;// 设置为单聊消息
    //message.chatType = EMChatTypeGroupChat;// 设置为群聊消息
    //message.chatType = EMChatTypeChatRoom;// 设置为聊天室消息
    //message.ext = @{@"key":@"value"}; // 扩展消息部分
    
    message.status = EMMessageStatusDelivering;
//    message.messageId = [NSString stringWithFormat:@"%ld%@%@", (long)[[NSDate date] timeIntervalSince1970],from,_userName];
    
    //发送前加入数据并刷新表格
    [self.dataArray insertObject:message atIndex:self.dataArray.count];
    
    [self.myTableView reloadData];
    
//    [self scrollToBottom];
    [self getImageData];

    if ([[QYHEMClientTool shareInstance] isLoggedIn] && [[QYHEMClientTool shareInstance] isConnected]) {
        //发送
        [[QYHEMClientTool shareInstance] sendMessage:message progress:^(int progress) {
            
        } completion:^(EMMessage *message, EMError *error) {
            
            if (!error) {
                NSLog(@"发送成功");
                message.status = EMMessageStatusSuccessed;
            }else{
                NSLog(@"发送失败==%@，message==%@",error.errorDescription,message);
                message.status = EMMessageStatusFailed;
            }
            //刷新发送状态
            [weakself.myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(weakself.dataArray.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [weakself updatereadedStatus];
        }];
    }else{
        message.status = EMMessageStatusFailed;
        //刷新发送状态
        [weakself.myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(weakself.dataArray.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [weakself updatereadedStatus];
//        [QYHProgressHUD showErrorHUD:nil message:@"网络连接失败！"];
    }
  
}


#pragma mark - 转发消息
-(void)transSendMessage
{
    __weak typeof(self) weakself = self;
    
    _transMssegeModel.status = EMMessageStatusDelivering;
    _transMssegeModel.messageId = [NSString stringWithFormat:@"%ld%@%@", (long)[[NSDate date] timeIntervalSince1970],_transMssegeModel.from,_transMssegeModel.conversationId];
    
    //发送前加入数据并刷新表格
    [self.dataArray insertObject:_transMssegeModel atIndex:(self.dataArray.count - 1)];
    
    [self.myTableView reloadData];
    
//    [self scrollToBottom];
    [self getImageData];
    
    if ([[QYHEMClientTool shareInstance] isLoggedIn] && [[QYHEMClientTool shareInstance] isConnected]) {
        
        [[QYHEMClientTool shareInstance] sendMessage:_transMssegeModel progress:^(int progress) {
            
        } completion:^(EMMessage *message, EMError *error) {
            if (!error) {
                NSLog(@"发送成功");
                message.status = EMMessageStatusSuccessed;
            }else{
                NSLog(@"发送失败");
                message.status = EMMessageStatusFailed;
            }
            //刷新发送状态
            [weakself.myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(weakself.dataArray.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [weakself updatereadedStatus];
        }];
        
    }else{
        _transMssegeModel.status = EMMessageStatusFailed;
        //刷新发送状态
        [weakself.myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(weakself.dataArray.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [weakself updatereadedStatus];
    }
}


#pragma mark - 发送失败，重发
- (void)reSendMessages:(EMMessage *)messegeModel
{
    __weak typeof(self) weakself = self;
    __block NSInteger index = -1;
    
    if ([[QYHEMClientTool shareInstance] isLoggedIn] && [[QYHEMClientTool shareInstance] isConnected]) {
        
        [[QYHEMClientTool shareInstance] sendMessage:messegeModel progress:^(int progress) {
            
        } completion:^(EMMessage *message, EMError *error) {
            if (!error) {
                NSLog(@"发送成功");
                message.status = EMMessageStatusSuccessed;
            }else{
                NSLog(@"发送失败");
                message.status = EMMessageStatusFailed;
            }
            
            [weakself.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                EMMessage *message = (EMMessage *)obj;
                
                index++;
                if ([messegeModel.messageId isEqualToString:message.messageId]) {
                    *stop = YES;
                }
            }];
            //刷新发送状态
            [weakself.myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [weakself updatereadedStatus];
        }];
    }else{
        messegeModel.status = EMMessageStatusFailed;
        //刷新发送状态
        [weakself.myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [weakself updatereadedStatus];
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)updatereadedStatus{
    
    EMError *error = nil;
    
    [_conversation markAllMessagesAsRead:&error];
    if (!error) {
        NSLog(@"更新已读状态成功");
    }else{
        NSLog(@"更新已读状态失败");
    }
}

- (BOOL)isCanScrollToBottom{
    //判断是否滑动到最后一行
    if (_myTableView.visibleCells.count) {
        QYHChatCell *tmpcell = _myTableView.visibleCells[_myTableView.visibleCells.count-1];
        
        NSIndexPath *index = [_myTableView indexPathForCell:tmpcell];
        
        if (index.row == _dataArray.count -1) {
            return YES;
        }else{
            return NO;
        }
    }
    
    return NO;
}

- (void)scrollToBottom{
    
    if (_dataArray.count >5) {
        
        NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:_dataArray.count - 1 inSection:0];
        [self.myTableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    
}


#pragma mark - 键盘出来的时候调整tooView的位置
-(void)keyChange:(NSNotification *) notify
{
    NSDictionary *dic = notify.userInfo;
    
    CGRect endKey = [dic[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    //坐标系的转换
    CGRect endKeySwap = [self.view convertRect:endKey fromView:self.view.window];
    //运动时间
    [UIView animateWithDuration:[dic[UIKeyboardAnimationDurationUserInfoKey] floatValue] animations:^{
        
        [UIView setAnimationCurve:[dic[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
        
        self.tooViewConstraintBottom.constant = SCREEN_HEIGHT - endKeySwap.origin.y;

        [self.view layoutIfNeeded];
    }];
    
    
     [self scrollToBottom];
}


#pragma mark - 更新toolView的高度约束
-(void)updateHeight:(CGSize)contentSize
{
    
    float height = contentSize.height + 8;
    
    //    NSLog(@"height==%f",height);
    if (height > 110) {
         height = 110;
    }
    
    self.tooViewConstraintHeight.constant = height;
    
    [UIView animateWithDuration:0.05 animations:^{
        [self.view layoutIfNeeded];
        
        if (_textViewHeight != height) {
            [self scrollToBottom];
            _textViewHeight = height;
        }
        
    }];

}

#pragma mark - 获取图片数据
- (void)getImageData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)  , ^{
        
        [_imageArray removeAllObjects];
        
        for (id msgObj in _dataArray) {
            
            if ([msgObj isKindOfClass:[EMMessage class]] ) {
                EMMessage *message = (EMMessage *)msgObj;
                EMMessageBody *body = message.body;
                
                if (body.type == EMMessageBodyTypeImage) {
                    
                    [_imageArray addObject:msgObj];
                }
            }
            
        }

    });
   
}

#pragma mark - 点击查看图片事件
- (void)setImageBlock:(QYHChatCell *)cell
{
    
    __weak __block QYHContenViewController *copy_self = self;
    
    //传出cell中的图片
    [cell setButtonImageBlock:^(NSString *imageURL) {
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            [copy_self countIndexByContent:imageURL];
            
        });
        
    }];
    
}

-(void)countIndexByContent:(NSString *)content{
    
    NSInteger count = 0;
    for (EMMessage *msgObj in self.imageArray) {
        
        EMImageMessageBody *imageBody = (EMImageMessageBody *)msgObj.body;
        NSString *imageUrl = imageBody.thumbnailLocalPath;
        
        if ([imageUrl isEqualToString:content] || [imageBody.thumbnailLocalPath isEqualToString:content]  ) {
            
            self.index = count;
            break;
        }
        
        count++;
    }
    
    [self displayImageIndex:self.index];

}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y<=0  && _isRefresh==NO &&self.myTableView.tableHeaderView)
    {
        [self getMOreData];
    }
}

#pragma mark -tableView DataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
 
    return _dataArray.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    EMMessage *message = _dataArray[indexPath.row];
    EMMessageBody *msgBody = message.body;
    
    switch (msgBody.type) {
        case EMMessageBodyTypeText:
        {
            // 收到的文字消息
            EMTextMessageBody *textBody = (EMTextMessageBody *)msgBody;
            NSString *txt = textBody.text;
            NSLog(@"收到的文字是 txt -- %@",txt);
            
            return [self getTextCellByIndexPath:indexPath message:message];
          
        }
            break;
        case EMMessageBodyTypeImage:
        {
            // 得到一个图片消息body
            EMImageMessageBody *body = ((EMImageMessageBody *)msgBody);
            
            NSLog(@"大图remote路径 -- %@"   ,body.remotePath);
            NSLog(@"大图local路径 -- %@"    ,body.localPath); // // 需要使用sdk提供的下载方法后才会存在
            NSLog(@"大图的secret -- %@"    ,body.secretKey);
            NSLog(@"大图的W -- %f ,大图的H -- %f",body.size.width,body.size.height);
            NSLog(@"大图的下载状态 -- %lu",body.downloadStatus);
            
            
            // 缩略图sdk会自动下载
            NSLog(@"小图remote路径 -- %@"   ,body.thumbnailRemotePath);
            NSLog(@"小图local路径 -- %@"    ,body.thumbnailLocalPath);
            NSLog(@"小图的secret -- %@"    ,body.thumbnailSecretKey);
            NSLog(@"小图的W -- %f ,大图的H -- %f",body.thumbnailSize.width,body.thumbnailSize.height);
            NSLog(@"小图的下载状态 -- %lu",body.thumbnailDownloadStatus);
            
            return [self getImageCellByIndexPath:indexPath message:message];
        }
            break;
        case EMMessageBodyTypeLocation:
        {
            EMLocationMessageBody *body = (EMLocationMessageBody *)msgBody;
            NSLog(@"纬度-- %f",body.latitude);
            NSLog(@"经度-- %f",body.longitude);
            NSLog(@"地址-- %@",body.address);
        }
            break;
        case EMMessageBodyTypeVoice:
        {
            // 音频sdk会自动下载
            EMVoiceMessageBody *body = (EMVoiceMessageBody *)msgBody;
            NSLog(@"音频remote路径 -- %@"      ,body.remotePath);
            NSLog(@"音频local路径 -- %@"       ,body.localPath); // 需要使用sdk提供的下载方法后才会存在（音频会自动调用）
            NSLog(@"音频的secret -- %@"        ,body.secretKey);
            NSLog(@"音频文件大小 -- %lld"       ,body.fileLength);
            NSLog(@"音频文件的下载状态 -- %lu"   ,body.downloadStatus);
            NSLog(@"音频的时间长度 -- %lu"      ,body.duration);
            
            return [self getVoiceCellByIndexPath:indexPath message:message];
        }
            break;
        case EMMessageBodyTypeVideo:
        {
            EMVideoMessageBody *body = (EMVideoMessageBody *)msgBody;
            
            NSLog(@"视频remote路径 -- %@"      ,body.remotePath);
            NSLog(@"视频local路径 -- %@"       ,body.localPath); // 需要使用sdk提供的下载方法后才会存在
            NSLog(@"视频的secret -- %@"        ,body.secretKey);
            NSLog(@"视频文件大小 -- %lld"       ,body.fileLength);
            NSLog(@"视频文件的下载状态 -- %lu"   ,body.downloadStatus);
            NSLog(@"视频的时间长度 -- %lu"      ,body.duration);
            NSLog(@"视频的W -- %f ,视频的H -- %f", body.thumbnailSize.width, body.thumbnailSize.height);
            
            // 缩略图sdk会自动下载
            NSLog(@"缩略图的remote路径 -- %@"     ,body.thumbnailRemotePath);
            NSLog(@"缩略图的local路径 -- %@"      ,body.thumbnailLocalPath);
            NSLog(@"缩略图的secret -- %@"        ,body.thumbnailSecretKey);
            NSLog(@"缩略图的下载状态 -- %lu"      ,body.thumbnailDownloadStatus);
        }
            break;
        case EMMessageBodyTypeFile:
        {
            EMFileMessageBody *body = (EMFileMessageBody *)msgBody;
            NSLog(@"文件remote路径 -- %@"      ,body.remotePath);
            NSLog(@"文件local路径 -- %@"       ,body.localPath); // 需要使用sdk提供的下载方法后才会存在
            NSLog(@"文件的secret -- %@"        ,body.secretKey);
            NSLog(@"文件文件大小 -- %lld"       ,body.fileLength);
            NSLog(@"文件文件的下载状态 -- %lu"   ,body.downloadStatus);
        }
            break;
            
        default:
            break;
    }

    
//    else{
//        
//        QYHChatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"timeCell" forIndexPath:indexPath];
//        
//        [cell setTime:msgObj];
//        
//        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
//        [cell setBackgroundColor:[UIColor clearColor]];
//        
//        return cell;
//    }
    
    return nil;
}

//调整cell的高度
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EMMessage *message = _dataArray[indexPath.row];
    EMMessageBody *msgBody = message.body;
    
    switch (msgBody.type) {
        case EMMessageBodyTypeText:
        {
            // 收到的文字消息
            EMTextMessageBody *textBody = (EMTextMessageBody *)msgBody;
            NSString *txt = textBody.text;
            
            MLEmojiLabel *emojiLabel2 = [MLEmojiLabel new];
            emojiLabel2.numberOfLines = 0;
            emojiLabel2.font = [UIFont systemFontOfSize:15.0f];
            
            //下面是自定义表情正则和图像plist的例子
            emojiLabel2.customEmojiRegex = @"\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]";
            emojiLabel2.customEmojiPlistName = @"expressionImage_custom";
            emojiLabel2.text = txt;
            
            CGSize bound = [emojiLabel2 preferredSizeWithMaxWidth:SCREEN_WIDTH*2.0/3];
            
            float height = bound.height + 35;
            return height;

        }
            break;
        case EMMessageBodyTypeImage:
        {
            // 得到一个图片消息body
            EMImageMessageBody *body = ((EMImageMessageBody *)msgBody);
            
            return body.thumbnailSize.height;
        }
            break;
       
        case EMMessageBodyTypeVoice:
        {
            // 音频sdk会自动下载
            EMVoiceMessageBody *body = (EMVoiceMessageBody *)msgBody;
            NSLog(@"音频文件大小 -- %lld"       ,body.fileLength);
            NSLog(@"音频的时间长度 -- %lu"      ,body.duration);
            
            return 60;
        }
            break;
       
        default:
            return 30;
            break;
    }
    
    return 100;
}


//返回text的Cell
- (QYHChatCell *)getTextCellByIndexPath:(NSIndexPath *)indexPath message:(EMMessage *)message{
    
    QYHChatCell *cell = nil;
    
    __weak typeof(self) weakSelf = self;
    
    if ([message.from isEqualToString:_userName]) {
        //ta
        cell = [self.myTableView dequeueReusableCellWithIdentifier:@"textCell" forIndexPath:indexPath];
        
        [cell setCellModelMessage:message type:HeTextContent];
        
    }else{
        cell = [self.myTableView dequeueReusableCellWithIdentifier:@"myselfTextCell" forIndexPath:indexPath];
        
        [cell setCellModelMessage:message type:MyTextContent];
        
        //重发
        [weakSelf reSendMessage:cell];
    }
    
    [weakSelf cellCallBckBlock:cell];
    
    cell.delagete = self;
    
    return cell;
}

//返回image的Cell
- (QYHChatCell *)getImageCellByIndexPath:(NSIndexPath *)indexPath message:(EMMessage *)message{
    
    QYHChatCell *cell = nil;
    //    [cell setMssegeModel:message];
    
    __weak typeof(self) weakSelf = self;
    
    if ([message.from isEqualToString:_userName]) {
        //ta
        cell = [self.myTableView dequeueReusableCellWithIdentifier:@"heImageCell" forIndexPath:indexPath];
        [cell setCellModelMessage:message type:HeImageContent];
    }else{
        cell = [self.myTableView dequeueReusableCellWithIdentifier:@"myImageCell" forIndexPath:indexPath];
        [cell setCellModelMessage:message type:MyImageContent];
        
        //重发
        [weakSelf reSendMessage:cell];
    }
    
    // [self setImageBlock:cell];
    
    [weakSelf cellCallBckBlock:cell];
    
    return cell;
    
}

//返回voice的Cell
- (QYHChatCell *)getVoiceCellByIndexPath:(NSIndexPath *)indexPath message:(EMMessage *)message{
    
    QYHChatCell *cell = nil;
    //    [cell setMssegeModel:message];
    
    __weak typeof(self) weakSelf = self;
    
    if ([message.from isEqualToString:_userName]) {
        //ta
        cell = [self.myTableView dequeueReusableCellWithIdentifier:@"heVoiceCell" forIndexPath:indexPath];
        [cell setCellModelMessage:message type:HeVoiceContent];
    }else{
        cell = [self.myTableView dequeueReusableCellWithIdentifier:@"myVoiceCell" forIndexPath:indexPath];
        [cell setCellModelMessage:message type:MyVoiceContent];
        
        //重发
        [weakSelf reSendMessage:cell];
    }
    
    [weakSelf cellCallBckBlock:cell];
    
    return cell;
}


//重发
- (void)reSendMessage:(QYHChatCell *)cell{
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(cell) weak_cell = cell;
    
    [cell setSendAgainBlock:^(EMMessage *messageModel) {
        [weak_cell.activityView setHidden:NO];
        [weak_cell.activityView startAnimating];
        [weak_cell.sendFailuredImageView setHidden:YES];
        [weakSelf reSendMessages:messageModel];
    }];
}

//cell的block回调
- (void)cellCallBckBlock:(QYHChatCell *)cell{
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setBackgroundColor:[UIColor clearColor]];
    
    __weak typeof(self) weakSelf = self;
    
    //展示Menu
    [cell setMenuBlock:^(QYHChatCell *cell){
        
        [weakSelf longGesture:cell];
    }];
    //点击头像进入详情
    [cell setPushBlock:^(NSString *user){
        [weakSelf pushToDetailVCByUser:user];
    }];
}

#pragma mark - 点击查看图片，展示图片
- (void)displayImageIndex:(NSInteger)index
{
    [_photosArray removeAllObjects];
    
     _isCaScroll = NO;
    
    for (int i=0; i<_imageArray.count; i++) {
        
        EMMessage *msgObj = _imageArray[i];
        EMImageMessageBody *imageBody = (EMImageMessageBody *)msgObj.body;
        
        NSString *imageUrl = imageBody.localPath ? imageBody.localPath : imageBody.remotePath;
        
//        NSLog(@"msgObj.fromUserID ==%@,,%@",msgObj.fromUserID ,imageUrl);

        if (![imageUrl hasPrefix:@"http://"]) {
            
            [_photosArray addObject:[MWPhoto photoWithImage:[UIImage imageWithContentsOfFile:[[QYHChatDataStorage shareInstance].homePath stringByAppendingString:imageUrl]]]];
            
            NSLog(@"lisi===%@",[UIImage imageWithContentsOfFile:imageUrl]);
        }else{
            
            [_photosArray addObject:[MWPhoto photoWithURL:[NSURL URLWithString:imageUrl]]];
        }
        
        
    }
    
    
    dispatch_async ( dispatch_get_main_queue (), ^{
        
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        
        // Set options
        browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
        browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
        browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
        browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
        browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
        browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
        browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
        [browser setCurrentPhotoIndex:index];
        
        browser.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        // Present
        //    [self.navigationController pushViewController:browser animated:NO];
        [self presentViewController:browser animated:YES completion:^{
            
        }];
        
        // Manipulate
        //    [browser showNextPhotoAnimated:YES];
        //    [browser showPreviousPhotoAnimated:YES];
        //    [browser setCurrentPhotoIndex:10];
        
    });
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photosArray.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photosArray.count) {
        return [_photosArray objectAtIndex:index];
    }
    return nil;
}

#pragma mark - 播放语音
- (IBAction)tapVoiceButton:(id)sender {
    
    if (_preCell) {
        [_preCell.audioPlayer stop];
        [_preCell.voiceImageView stopAnimating];
        
    }
    
    QYHChatCell * cell = nil;
    if (sender) {
        cell = (QYHChatCell *)[[sender superview] superview];
    }else{
        cell = _menuCell;
    }
    
    
    
    //播放语音
    [cell playAudioByPlayUrl:cell.playURL];
    
    
    
    NSArray *voiceArray = nil;
    
    if ([cell.reuseIdentifier isEqualToString:@"heVoiceCell"]) {
        
        if (!cell.redTipUIImageView.hidden) {
            cell.redTipUIImageView.hidden = YES;
            
            [cell.messageModel.ext setValue:@(YES) forKey:@"isRead"];
        }
        
        voiceArray = @[[UIImage imageNamed:@"dd_left_voice_one"],[UIImage imageNamed:@"dd_left_voice_two"],[UIImage imageNamed:@"dd_left_voice_three"]];
        
    }else{
        
        
        voiceArray = @[[UIImage imageNamed:@"dd_right_voice_one"],[UIImage imageNamed:@"dd_right_voice_two"],[UIImage imageNamed:@"dd_right_voice_three"]];
        
    }
    
    [cell.voiceImageView setContentMode:UIViewContentModeLeft];
    
    [cell.voiceImageView setAnimationImages:voiceArray];
    [cell.voiceImageView setAnimationRepeatCount:cell.playTime];
    [cell.voiceImageView setAnimationDuration:1];
    
    [cell.voiceImageView startAnimating];
    
    
    _preCell = cell;
    
}


#pragma mark - gesture delegate

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    NSLog(@"touch==%@",touch.view);
    
    if ([touch.view isKindOfClass:[MLEmojiLabel class]]) {
        MLEmojiLabel *mlEmojiLabel = (MLEmojiLabel *)touch.view;
        return ![mlEmojiLabel containslinkAtPoint:[touch locationInView:mlEmojiLabel]];
    }
    return YES;
    
}


#pragma mark - QYHChatCellDelegate
- (void)pushToWebViewControllerByUrl:(NSString *)url{
    
    QYHWebViewController *webVC = [[QYHWebViewController alloc]init];
    webVC.url = url;
    [self.navigationController pushViewController:webVC animated:YES];
}


//#pragma mark 发送聊天数据
//-(BOOL)textFieldShouldReturn:(UITextField *)textField{
//    
//    NSString *txt = textField.text;
//    
//    // 清空输入框的文本
//    textField.text = nil;
//    
////    //怎么发聊天数据
////    XMPPMessage *msg = [XMPPMessage messageWithType:@"chat" to:self.friendJid];
////    [msg addBody:txt];
////    [[QYHXMPPTool sharedQYHXMPPTool].xmppStream sendElement:msg];
//    
//    return YES;
//    
//}



#pragma mark 表格滚动，隐藏键盘

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    [self keyboardwillHide:nil];
}
-(void)keyboardwillHide:(UITapGestureRecognizer*)tap{
    
    if ([_toolView1.sendTextView.inputView isEqual:_toolView1.faceMoreView])
    {
        if (!_toolView1.moreView.hidden) {
            [_toolView1 tapMoreButton:nil];
            
        }if (!_toolView1.functionView.hidden) {
            [_toolView1 tapChangeKeyBoardButton:nil];
        }
    }
    
    [self.view  endEditing:YES];
}


#pragma mark 文件发送(以图片发送为例)
- (IBAction)imgChooseBtnClick:(UIImagePickerControllerSourceType)sourceType {
    //从图片库选取图片
    UIImagePickerController *imgPC = [[UIImagePickerController alloc] init];
    imgPC.sourceType = sourceType;
    //imgPC.allowsEditing = YES;
    imgPC.delegate = self;
    
    [self presentViewController:imgPC animated:YES completion:nil];
    
}

#pragma mark 用户选择的图片
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    NSLog(@"%@",info);
    
    UIImage *image = info[@"UIImagePickerControllerOriginalImage"];
    
    if (image) {
        
        self.sendImageType = image.size.height > image.size.width ? VImageType : HImageType;
        _ratioHW = image.size.height*1.0/image.size.width;
        
//        //压缩到指定的尺寸
//        CGSize size = CGSizeMake(SCREEN_WIDTH*2, (SCREEN_WIDTH/image.size.width) * image.size.height*2);
//        UIImage * newImage = [UIImage imageByScalingAndCroppingForSize:size withImage:image];
        //等比縮放image
        UIImage *newImage = [UIImage scaleImage:image toScale:0.8];
        
        //发送图片
        [self dismissViewControllerAnimated:YES completion:^{
            
            [self keyboardwillHide:nil];
            
            [self sendMessage:newImage sendType:ImageSend];
        }];
        
    }else{
        
        [QYHProgressHUD showErrorHUD:nil message:@"选取图片失败，请选取另外的图片或者重新选取！"];
    }
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        
        [self keyboardwillHide:nil];
    }];

}

#pragma mark - pushToDetailVC

- (void)pushToDetailVCByUser:(NSString *)user{
//    
//    XMPPvCardTemp *vCard = [[QYHXMPPvCardTemp shareInstance] vCard:[user isEqualToString:[QYHAccount shareAccount].loginUser] ? nil :user];
//    
//    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    QYHDetailTableViewController *detailVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"QYHDetailTableViewController"];
//    
//    NSData   *imageUrl = vCard.photo ?vCard.photo:UIImageJPEGRepresentation([UIImage imageNamed:@"placeholder"], 1.0);
//    NSString *nickName = vCard.nickname ?[vCard.nickname stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]:@"";
//    NSString *sex = vCard.formattedName ?[vCard.formattedName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]:@"";
//    NSString *area = vCard.givenName ?[vCard.givenName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]:@"";
//    NSString *personalSignature = vCard.middleName ?[vCard.middleName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]:@"";
//    NSString *phone = user;
//    
//    detailVC.dic = @{@"imageUrl":imageUrl,
//                     @"nickName":nickName,
//                     @"sex":sex,
//                     @"area":area,
//                     @"personalSignature":personalSignature,
//                     @"phone":phone
//                     };
//        detailVC.isFromChatVC = YES;
//    
//    [self.navigationController pushViewController:detailVC animated:YES];

}

- (IBAction)PushToFriendDetailVC:(id)sender {
//    [self pushToDetailVCByUser:self.friendJid.user];
}


#pragma mark - UIMenuController

-(IBAction)longGesture:(QYHChatCell *)cell
{
    _menuCell = cell;
    
    [self becomeFirstResponder];
    
    NSString *str = nil;
    switch (cell.type) {
        case SendText:
            str = @"复制";
            break;
        case SendImage:
            str = @"点击查看";
            break;
        case SendVoice:
            str = @"听筒播放";
            break;
        default:
            break;
    }
    
    UIMenuItem * itemPase = [[UIMenuItem alloc] initWithTitle:str action:@selector(copyString)];
    UIMenuItem * itemTrans = [[UIMenuItem alloc] initWithTitle:@"转发" action:@selector(trans)];
    UIMenuItem * itemCollect = [[UIMenuItem alloc] initWithTitle:@"收藏" action:@selector(collect)];
    UIMenuItem * itemCancel = [[UIMenuItem alloc] initWithTitle:@"删除" action:@selector(cancel)];
    
    UIMenuController * menuController = [UIMenuController sharedMenuController];
    [menuController setMenuItems: @[itemPase,itemTrans,itemCancel,itemCollect]];
    
    [menuController setTargetRect:cell.chatBgImageView.bounds inView:cell.chatBgImageView];
    
    [menuController setMenuVisible:YES animated:YES];
    
}

#pragma mark - UIMenuControllerNoti
-(void)menuShow:(UIMenuController *)menu
{
    [self setCellBgImagePlaceByIsHide:NO];
}
-(void)menuHide:(UIMenuController *)menu
{
    [self setCellBgImagePlaceByIsHide:YES];

    UIMenuController * menuController = [UIMenuController sharedMenuController];
    [menuController setMenuItems:nil];
    
    [self resignFirstResponder];
}

/**
 *  长按切换图片和释放切换图片
 *
 *
 */
- (void)setCellBgImagePlaceByIsHide:(BOOL)isHide{
    
    /**
     *  right YES:为我的信息  NO：为他的信息
     */
    if ([_menuCell.reuseIdentifier isEqualToString:@"myImageCell"]||
        [_menuCell.reuseIdentifier isEqualToString:@"myVoiceCell"]||
        [_menuCell.reuseIdentifier isEqualToString:@"myselfTextCell"])
    {
       
        [self setCellBgImageByIsHide:isHide right:YES];
        
    }else{
        [self setCellBgImageByIsHide:isHide right:NO];
    }
    
}

- (void)setCellBgImageByIsHide:(BOOL)isHide right:(BOOL )isRight{
    
    UIImage *image = nil;
    
    if (isHide) {
        
        if (isRight) {
            if ([_menuCell.reuseIdentifier isEqualToString:@"myImageCell"])
            {
                image = [UIImage imageNamed:@"message_sender_background_reversed"];
            }else{
                image = [UIImage imageNamed:@"chatto_bg_normal.png"];
            }
            
        }else{
            if ([_menuCell.reuseIdentifier isEqualToString:@"heImageCell"])
            {
                image = [UIImage imageNamed:@"message_receiver_background_reversed"];
            }else{
                
                image = [UIImage imageNamed:@"chatfrom_bg_normal.png"];
            }
        }
        
    }else{
        
        if (isRight) {
            if ([_menuCell.reuseIdentifier isEqualToString:@"myImageCell"])
            {
                image = [UIImage imageNamed:@"message_sender_background_focused"];
            }else{
                image = [UIImage imageNamed:@"chatto_bg_focused.png"];
            }
        }else{
            if ([_menuCell.reuseIdentifier isEqualToString:@"heImageCell"])
            {
                image = [UIImage imageNamed:@"message_receiver_background_focused"];
            }else{
                image = [UIImage imageNamed:@"chatfrom_bg_focused.png"];
            }
        }
    }
    
    if ([_menuCell.reuseIdentifier isEqualToString:@"myImageCell"] || [_menuCell.reuseIdentifier isEqualToString:@"heImageCell"])
    {
        _menuCell.imgbView.image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(28, 20, 15, 20) resizingMode:UIImageResizingModeStretch];
    }else{
        
        image = [image resizableImageWithCapInsets:(UIEdgeInsetsMake(image.size.height * 0.6, image.size.width * 0.4, image.size.height * 0.3, image.size.width * 0.4))];
        
        _menuCell.chatBgImageView.image = image;
    }
    
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

/**
 *  复制、查看图片、播放语音
 */
-(void)copyString
{
    if (!_menuCell.messageModel) {
        return;
    }
    
    switch (_menuCell.type) {
        case SendText:
        {
            EMTextMessageBody *textBody = (EMTextMessageBody *)_menuCell.messageModel.body;
            [[UIPasteboard generalPasteboard]setString:textBody.text];
        }
            break;
        case SendImage:
        {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                EMImageMessageBody *imageBody = (EMImageMessageBody *)_menuCell.messageModel.body;
                if (imageBody.localPath) {
                    [self countIndexByContent:imageBody.localPath];
                }else{
                    [self countIndexByContent:imageBody.remotePath];
                    [[QYHEMClientTool shareInstance] downloadMessageAttachment:_menuCell.messageModel progress:nil completion:nil];
                }
            });
            break;
        }
        case SendVoice:
            [self tapVoiceButton:nil];
            break;
        default:
            break;
    }
}
/**
 *  转发
 */
- (void)trans{
    QYHChatViewController *chatVC = [self.storyboard instantiateViewControllerWithIdentifier:@"QYHChatViewController"];
    chatVC.isTrans = YES;
    _transMssegeModel = _menuCell.messageModel;
    
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:chatVC];
    
//    [self.navigationController pushViewController:chatVC animated:YES];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}
/**
 *  收藏
 */
- (void)collect{
    
    [[[UIAlertView alloc]initWithTitle:@"未实现 ！" message:nil delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil, nil] show];
}
/**
 *  删除
 */
- (void)cancel{
    
    __weak typeof(self)weakself = self;
    
    EMError *error = nil;
    [_conversation deleteMessageWithId:_menuCell.messageModel.messageId error:&error];
    
    if (!error) {
        NSLog(@"删除单条信息成功");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableArray *indexPaths = [NSMutableArray array];
            
            NSInteger indexCount = [weakself.dataArray indexOfObject:weakself.menuCell.messageModel];
            
            id obj1 = nil;
            id obj2 = @"";
            
            if (indexCount - 1 >= 0) {
                obj1 = [weakself.dataArray objectAtIndex:indexCount -1];
            }
            
            if (indexCount + 1 < weakself.dataArray.count) {
                obj2 = [weakself.dataArray objectAtIndex:indexCount +1];
            }
            
            if ([obj1 isKindOfClass:[NSString class]]&&[obj2 isKindOfClass:[NSString class]])
            {
                [weakself.dataArray removeObjectAtIndex:indexCount -1];
                [indexPaths addObject:[NSIndexPath indexPathForRow:indexCount -1 inSection:0]];
            }
            
            [weakself.dataArray removeObject:weakself.menuCell.messageModel];
            
            [indexPaths addObject:[_myTableView indexPathForCell:_menuCell]];
            
            [weakself.myTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        });

    }else{
        NSLog(@"删除单条信息失败");
    }
}


- (void)dealloc
{
   
    NSLog(@"QYHContenViewController -- dealloc");
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:KReceiveChatMessageNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIMenuControllerWillShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIMenuControllerWillHideMenuNotification object:nil];
    
}


@end
