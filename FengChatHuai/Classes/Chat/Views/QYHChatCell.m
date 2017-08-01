//
//  QYHChatCell.m
//  FengChatHuai
//
//  Created by iMacQIU on 16/5/27.
//  Copyright © 2016年 iMacQIU. All rights reserved.
//

#import "QYHChatCell.h"
#import "UIButton+AFNetworking.h"
#import "UIImageView+WebCache.h"
//#import "XMPPvCardTemp.h"

@interface QYHChatCell()<AVAudioPlayerDelegate,UIGestureRecognizerDelegate,MLEmojiLabelDelegate,UIAlertViewDelegate>

@property (strong, nonatomic) NSMutableAttributedString *attrString;
@property (copy, nonatomic) ButtonImageBlock imageBlock;
@property (strong, nonatomic) NSString *imageUrl;


@end


@implementation QYHChatCell


-(void)layoutSubviews{
    
    
    self.chatBgImageView.userInteractionEnabled = YES;
    self.chatTextView.userInteractionEnabled = YES;
    self.mlEmojiLabel.userInteractionEnabled = YES;
    
    /**
     *  显示UIMenuController菜单
     */
    if (self.menuBlock) {
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(showMenu:)];
        longPress.delegate = self;
        //        longPress.cancelsTouchesInView = NO;
        //        longPress.minimumPressDuration = 1.0;//(2秒)
        
        if (self.type == SendText) {
            NSLog(@"mlEmojiLabel");
            [self.mlEmojiLabel addGestureRecognizer:longPress];
        }else{
            [self.contentView addGestureRecognizer:longPress];
        }
        
    }
    
    /**
     *  显示PushDetailVC
     */
    
    if (self.pushBlock) {
//        NSLog(@"pushBlock");
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(pushToDetailVC:)];
        tapGesture.cancelsTouchesInView = NO;
        self.headImageView.userInteractionEnabled = YES;
        [self.headImageView addGestureRecognizer:tapGesture];
        
    }
}


- (void)setCellModelMessage:(EMMessage *)message type:(ContentType)contentType{
    
    self.messageModel = message;
    self.type = contentType;
    
    if (contentType == HeTextContent || contentType ==HeImageContent || contentType ==HeVoiceContent) {
        
    }else{
        
        switch (self.messageModel.status) {
            case ChatMessageSending:
                [self.activityView setHidden:NO];
                [self.activityView startAnimating];
                [self.sendFailuredImageView setHidden:YES];
                self.voiceImageView.hidden = YES;
                self.voiceTimeLabel.hidden = YES;
                break;
                
            case ChatMessageSendFailure:
                [self.activityView setHidden:YES];
                [self.activityView stopAnimating];
                [self.sendFailuredImageView setHidden:NO];
                self.voiceImageView.hidden = YES;
                self.voiceTimeLabel.hidden = YES;
                break;
                
            case ChatMessageSendSuccess:
                [self.activityView setHidden:YES];
                [self.activityView stopAnimating];
                [self.sendFailuredImageView setHidden:YES];
                self.voiceImageView.hidden = NO;
                self.voiceTimeLabel.hidden = NO;
                break;
                
            default:
                break;
        }
        
    }
    
    
    //设置背景图片
    NSString *imageNamed = contentType == HeTextContent || contentType ==HeImageContent || contentType ==HeVoiceContent ? @"chatfrom_bg_normal.png" : @"chatto_bg_normal.png";
    UIImage *image = [UIImage imageNamed:imageNamed];
    
    
    image = [image resizableImageWithCapInsets:(UIEdgeInsetsMake(image.size.height * 0.6, image.size.width * 0.4, image.size.height * 0.3, image.size.width * 0.4))];
    
    self.chatBgImageView.image = image;
    
    
    /**
     *  头像
     */
    
    UIImage *headImage1 = [UIImage imageNamed:@"placeholder"];
    self.headImageView.image = headImage1;

    switch (contentType) {
        case HeTextContent:
        case MyTextContent:
        {
            EMTextMessageBody *textBody = (EMTextMessageBody *)message.body;
            [self setTextValue:textBody.text type:contentType];
        }
            break;
            
        case HeImageContent:
        case MyImageContent:
        {
            EMImageMessageBody *imageBody = (EMImageMessageBody *)message.body;
            [self setImageValue:imageBody.thumbnailLocalPath ? imageBody.thumbnailLocalPath : imageBody.thumbnailRemotePath  type:contentType imageWith:imageBody.thumbnailSize.width];
        }
            break;
            
        case HeVoiceContent:
        case MyVoiceContent:
        {
            EMVoiceMessageBody *voiceBody = (EMVoiceMessageBody *)message.body;
            [self setVoiceValue:voiceBody.localPath type:contentType audioTime:voiceBody.duration];
        }
            break;
            
        default:
            break;
    }
}



- (void)showMenu:(UILongPressGestureRecognizer *)longPress{
    
    if (longPress.state == UIGestureRecognizerStateBegan) {
        NSLog(@"UILongPressGestureRecognizer");
        
        if (CGRectContainsPoint(self.chatBgImageView.frame,[longPress locationInView:self.contentView])) {
            self.menuBlock(self);
        }
    }
}

- (IBAction)pushToDetailVC:(id)sender
{
    NSLog(@"pushToDetailVC");
     self.pushBlock(self.messageModel.from);
}
- (void)setTime:(NSString *)msgObj
{
    NSString *timeString = [NSString getMessageDateStringFromdateString:msgObj andNeedTime:YES];
    CGSize rect = [NSString getContentSize:timeString fontOfSize:13 maxSizeMake:CGSizeMake(300, 30)];
    self.timeLabelWithConstraint.constant = rect.width + 10;
    self.timeLabel.text = timeString;

}

- (void)setTextValue:(NSString *)str type:(ContentType)contentType
{
    
    self.mlEmojiLabel.text = str;
    
    CGSize bound = [self.mlEmojiLabel preferredSizeWithMaxWidth:SCREEN_WIDTH*2.0/3];
    //根据text的宽高来重新设置新的约束
    //背景的宽

    self.chatBgImageWidthConstraint.constant = bound.width + 40;
    self.chatTextWidthConstaint.constant = bound.width + 20;
    
    self.mlEmojiLabel.frame = CGRectMake(5, 0, bound.width, bound.height + 20);
    

}


-(MLEmojiLabel *)mlEmojiLabel{
    if (!_mlEmojiLabel) {
        _mlEmojiLabel = [MLEmojiLabel new];
        _mlEmojiLabel.numberOfLines = 0;
//        _mlEmojiLabel.disableThreeCommon = YES;
        _mlEmojiLabel.font = [UIFont systemFontOfSize:15.0f];
        _mlEmojiLabel.backgroundColor = [UIColor clearColor];
        _mlEmojiLabel.userInteractionEnabled = YES;
        _mlEmojiLabel.delegate = self;
//        _mlEmojiLabel.textAlignment = NSTextAlignmentCenter;
        //下面是自定义表情正则和图像plist的例子
        _mlEmojiLabel.customEmojiRegex = @"\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]";
        _mlEmojiLabel.customEmojiPlistName = @"expressionImage_custom";
        
        [self.chatTextView addSubview:_mlEmojiLabel];
        
    }
    
    return _mlEmojiLabel;
}

- (void)setImageValue:(NSString *)imageUrl type:(ContentType)contentType imageWith:(CGFloat)imageWith
{
    
    self.chatBgImageWidthConstraint.constant  = imageWith;
    self.imgWidthConstraint.constant  = imageWith;
    self.buttonWidthConstraint.constant       = imageWith;
    
    self.imageUrl = imageUrl;
    [_chatBgImageView setContentMode:UIViewContentModeScaleAspectFill];
    [_chatBgImageView setClipsToBounds:YES];

    if (![imageUrl hasPrefix:@"http://"]) {
        
        self.chatBgImageView.image = [UIImage imageWithContentsOfFile:[[QYHChatDataStorage shareInstance].homePath stringByAppendingString:imageUrl]];
    }else{
        
        [self.chatBgImageView sd_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[UIImage imageNamed:@"x@2x"]];
    }
    
    if (contentType == MyImageContent) {
        self.imgbView.image = [[UIImage imageNamed:@"message_sender_background_reversed"] resizableImageWithCapInsets:UIEdgeInsetsMake(28, 20, 15, 20) resizingMode:UIImageResizingModeStretch];
    }else{
        self.imgbView.image = [[UIImage imageNamed:@"message_receiver_background_reversed"] resizableImageWithCapInsets:UIEdgeInsetsMake(28, 20, 15, 20) resizingMode:UIImageResizingModeStretch];
    }
    
}

- (void)setVoiceValue:(NSString *)playUrlString type:(ContentType)contentType audioTime:(NSInteger)audioTime
{
    
    CGFloat with = 90.0f + audioTime*2;
    
    with = with > SCREEN_WIDTH - 100 ? SCREEN_WIDTH - 100 : with;
    
    self.chatBgImageWidthConstraint.constant  = with;
    self.buttonWidthConstraint.constant       = with;
    
    self.voiceTimeLabel.text = [NSString stringWithFormat:@"%ld''",audioTime];
    
    if (contentType == HeVoiceContent) {
        EMVoiceMessageBody *voiceBody = (EMVoiceMessageBody *)self.messageModel.body;
//        self.redTipUIImageView.hidden = voiceBody;
    }
    
    self.playTime = audioTime;
    
    NSLog(@"playUrlString==%@",playUrlString);
    
    if (![playUrlString hasPrefix:@"http://"]) {
        
         self.playURL = playUrlString;
        
    }else{
        
        self.playURL = playUrlString;
    }

}

-(void)setButtonImageBlock:(ButtonImageBlock)block
{
    self.imageBlock = block;
}

- (IBAction)tapImageButton:(id)sender {
    self.imageBlock(self.imageUrl);
}

- (void)playAudioByPlayUrl:(NSString *)urlString
{
    //初始化播放器的时候如下设置
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                            sizeof(sessionCategory),
                            &sessionCategory);
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (audioRouteOverride),
                             &audioRouteOverride);
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //默认情况下扬声器播放
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    //网络请求声音
    NSData *data = nil;
    
    NSLog(@"urlString==%@",urlString);
    if (![urlString hasPrefix:@"http://"]) {
        
        data = [NSData dataWithContentsOfFile:[[QYHChatDataStorage shareInstance].homePath stringByAppendingString:urlString]];
        
    }else{
        
        data  = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        
    }
    NSError *error = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc]initWithData:data error:&error];
    player.volume  = 1.0;
    if (error) {
        NSLog(@"播放错误：%@",[error description]);
    }
    self.audioPlayer = player;
    self.audioPlayer.meteringEnabled = YES;
    self.audioPlayer.delegate = self;
    
    [self handleNotification:YES];
    
    [self.audioPlayer play];
    NSLog(@"%@", urlString);
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"播放结束");
    
//    getDataFromeQiNiuByfile
    
    [self handleNotification:NO];
   
}

#pragma mark - 监听听筒or扬声器
- (void) handleNotification:(BOOL)state
{
    [[UIDevice currentDevice] setProximityMonitoringEnabled:state]; //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
    
    if(state)//添加监听
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sensorStateChange:) name:@"UIDeviceProximityStateDidChangeNotification"
                                                   object:nil];
    }
    else//移除监听
    { [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
    }
}

//处理监听触发事件
-(void)sensorStateChange:(NSNotificationCenter *)notification;
{
    //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗（省电啊）
    if ([[UIDevice currentDevice] proximityState] == YES)
    {
        NSLog(@"Device is close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }
    else
    {
        NSLog(@"Device is not close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.activityView setHidesWhenStopped:YES];
    [self.activityView setHidden:YES];

    [self.sendFailuredImageView setImage:[UIImage imageNamed:@"dd_send_failed"]];
    [self.sendFailuredImageView setHidden:YES];
    self.sendFailuredImageView.userInteractionEnabled=YES;
    
    UITapGestureRecognizer *pan = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickTheSendAgain)];
    [self.sendFailuredImageView addGestureRecognizer:pan];
    
    // Initialization code
}

-(void)setSendAgainBlock:(ClickTheSendAgainBlock)block
{
    self.sendAgain = block;
}


-(void)clickTheSendAgain
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"重发" message:@"是否重新发送此消息" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    alert.tag = 100;
    [alert show];
    
}

#pragma mark - alerViewDelegage
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100) {
        if (buttonIndex == 1) {
            
            self.sendAgain(self.messageModel);
        }
    }else{
        if (buttonIndex == 1) {
            
            if ([[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",alertView.message]]]) {
                [[UIApplication sharedApplication]openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",alertView.message]]];
                
            }
        }
    }
    
}


#pragma mark - MLEmojiLabelDelegate

- (void)mlEmojiLabel:(MLEmojiLabel*)emojiLabel didSelectLink:(NSString*)link withType:(MLEmojiLabelLinkType)type
{
    switch(type){
        case MLEmojiLabelLinkTypeURL:
            if ([self.delagete respondsToSelector:@selector(pushToWebViewControllerByUrl:)]) {
                [self.delagete pushToWebViewControllerByUrl:link];
            }
            NSLog(@"点击了链接%@",link);
            break;
        case MLEmojiLabelLinkTypePhoneNumber:
            
            //拨打电话
        {
            NSLog(@"点击了电话%@",link);
            
            UIAlertView *alerView = [[UIAlertView alloc]initWithTitle:nil message:link delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"呼叫", nil];
            alerView.tag = 101;
            [alerView show];
            
            break;
        }
        case MLEmojiLabelLinkTypeEmail:
            NSLog(@"点击了邮箱%@",link);
            break;
        case MLEmojiLabelLinkTypeAt:
            NSLog(@"点击了用户%@",link);
            break;
        case MLEmojiLabelLinkTypePoundSign:
            NSLog(@"点击了话题%@",link);
            break;
        default:
            NSLog(@"点击了不知道啥%@",link);
            break;
    }
    
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
