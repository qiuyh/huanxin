//
//  QYHEMClientTool.m
//  FengChatHuai
//
//  Created by iMacQIU on 17/3/29.
//  Copyright © 2017年 iMacQIU. All rights reserved.
//

#import "QYHEMClientTool.h"
#import "UserProfileManager.h"

static QYHEMClientTool *emclientTool = nil;

@implementation QYHEMClientTool

+(instancetype)shareInstance{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        emclientTool = [[QYHEMClientTool alloc]init];
    });
    
    return emclientTool;
}


/**********************************基础功能（初始化，绑定token，注册，登陆，退出）*********************************************/

#pragma mark - 基础功能（初始化，绑定token，注册，登陆，退出）

-(void)initializeSDKWithOptions{
    //AppKey:注册的AppKey，详细见下面注释。
    //apnsCertName:推送证书名（不需要加后缀），详细见下面注释。
    EMOptions *options = [EMOptions optionsWithAppkey:@"1111170327115495#chat"];
    options.apnsCertName = @"fenghuaidev";
    [[EMClient sharedClient] initializeSDKWithOptions:options];
    
    //添加回调监听代理:
    [[EMClient sharedClient] addDelegate:self delegateQueue:nil];
    
    
    //注册消息回调
    //移除消息回调
    [[EMClient sharedClient].chatManager removeDelegate:self];
    //注册消息回调
    [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
    
    //好友添加代理回调
    [[EMClient sharedClient].contactManager removeDelegate:self];
    [[EMClient sharedClient].contactManager addDelegate:self delegateQueue:nil];
    
}

-(void)bindDeviceToken:(NSData *)deviceToken{
    [[EMClient sharedClient] bindDeviceToken:deviceToken];
}


-(void)applicationDidEnterBackground:(UIApplication *)application{
    [[EMClient sharedClient] applicationDidEnterBackground:application];
}

-(void)applicationWillEnterForeground:(UIApplication *)application{
    [[EMClient sharedClient] applicationWillEnterForeground:application];
}


-(EMError *)registerWithUsername:(NSString *)username password:(NSString *)password{
  return [[EMClient sharedClient] registerWithUsername:username password:password];
}

-(EMError *)loginWithUsername:(NSString *)username password:(NSString *)password{
    
    /*自动登录在以下几种情况下会被取消：
     
     用户调用了 SDK 的登出动作；
     用户在别的设备上更改了密码，导致此设备上自动登录失败；
     用户的账号被从服务器端删除；
     用户从另一个设备登录，把当前设备上登录的用户踢出。
     所以，在您调用登录方法前，应该先判断是否设置了自动登录，如果设置了，则不需要您再调用。
     */
    BOOL isAutoLogin = [EMClient sharedClient].options.isAutoLogin;
    if (!isAutoLogin) {
        EMError *error = [[EMClient sharedClient] loginWithUsername:username password:password];
        if (!error){
            //SDK 中自动登录属性默认是关闭的，需要您在登录成功后设置，以便您在下次 APP 启动时不需要再次调用环信登录，并且能在没有网的情况下得到会话列表。
            [[EMClient sharedClient].options setIsAutoLogin:YES];
        }
        return error;
    }
    return nil;
}


-(EMError *)logout{
    EMError *error = [[EMClient sharedClient] logout:YES];
    if (!error) {
        NSLog(@"退出成功");
    }
    return error;
}


-(NSString *)currentUsername{
   return [EMClient sharedClient].currentUsername;
}

-(BOOL)isAutoLogin{
    return [EMClient sharedClient].isAutoLogin;
}

-(BOOL)isLoggedIn{
    return [EMClient sharedClient].isLoggedIn;
}

-(BOOL)isConnected{
    return [EMClient sharedClient].isConnected;
}



#pragma mark - EMClientDelegate

/*!
 *  自动登录返回结果
 *
 *  @param error 错误信息
 */
- (void)autoLoginDidCompleteWithError:(EMError *)error{
    NSLog(@"自动登录:error==%@",error);
    
    if (!error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:KLoginSuccessNotification object:nil];
    }
}

/*!
 *  SDK连接服务器的状态变化时会接收到该回调
 *
 *  有以下几种情况，会引起该方法的调用：
 *  1. 登录成功后，手机无法上网时，会调用该回调
 *  2. 登录成功后，网络状态变化时，会调用该回调
 *
 *  @param aConnectionState 当前状态
 */
- (void)connectionStateDidChange:(EMConnectionState)aConnectionState{
    if (aConnectionState == EMConnectionConnected) {
        NSLog(@"已连接");
        [[NSNotificationCenter defaultCenter] postNotificationName:KLoginSuccessNotification object:nil];
    }else{
        NSLog(@"未连接");
    }
}


/*!
 *  当前登录账号在其它设备登录时会接收到该回调
 */
- (void)userAccountDidLoginFromOtherDevice{
    NSLog(@"当前登录账号在其它设备登录");
    [self showError:@"当前登录账号在其它设备登录"];
}

/*!
 *  当前登录账号已经被从服务器端删除时会收到该回调
 */
- (void)userAccountDidRemoveFromServer{
    NSLog(@"当前登录账号已经被从服务器端删除");
    [self showError:@"当前登录账号已经被从服务器端删除"];
}


- (void)showError:(NSString *)message{
    [[NSNotificationCenter defaultCenter]postNotificationName:KReceiveErrorConflictNotification object:nil];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"确认"
                                              otherButtonTitles:nil];
    [alertView show];

}


/****************************************** 消   息  ******************************************************/
//消息：IM 交互实体，在 SDK 中对应的类型是 EMMessage。EMMessage 由 EMMessageBody 组成。

#pragma mark - 消息

//发送文字
-(void)sendTextMessageWithText:(NSString *)text messageChatType:(EMChatType)chatType conversationID:(NSString *)conversationID to:(NSString *)toUser ext:(NSDictionary *)messageExt progress:(void (^)(int))aProgressBlock completion:(void (^)(EMMessage *, EMError *))aCompletionBlock{
    
    //消息：IM 交互实体，在 SDK 中对应的类型是 EMMessage。EMMessage 由 EMMessageBody 组成。
    
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:text];
    [self getEMMessageBymessageChatType:chatType conversationID:conversationID to:toUser body:body ext:messageExt progress:aProgressBlock completion:aCompletionBlock];
}

//发送图片
-(void)sendImageMessageWithData:(NSData *)data displayName:(NSString *)displayName messageChatType:(EMChatType)chatType conversationID:(NSString *)conversationID to:(NSString *)toUser ext:(NSDictionary *)messageExt progress:(void (^)(int))aProgressBlock completion:(void (^)(EMMessage *, EMError *))aCompletionBlock{
    
    EMImageMessageBody *body = [[EMImageMessageBody alloc] initWithData:data displayName:displayName];
    [self getEMMessageBymessageChatType:chatType conversationID:conversationID to:toUser body:body ext:messageExt progress:aProgressBlock completion:aCompletionBlock];
}

//发送位置
-(void)sendLocationMessageWithLatitude:(double)latitude longitude:(double)longitude address:(NSString *)address messageChatType:(EMChatType)chatType conversationID:(NSString *)conversationID to:(NSString *)toUser ext:(NSDictionary *)messageExt progress:(void (^)(int))aProgressBlock completion:(void (^)(EMMessage *, EMError *))aCompletionBlock{

    EMLocationMessageBody *body = [[EMLocationMessageBody alloc] initWithLatitude:latitude longitude:longitude address:address];
    [self getEMMessageBymessageChatType:chatType conversationID:conversationID to:toUser body:body ext:messageExt progress:aProgressBlock completion:aCompletionBlock];
}


//发送语音

-(void)sendVoiceMessageWithLocalPath:(NSString *)localPath displayName:(NSString *)displayName messageChatType:(EMChatType)chatType conversationID:(NSString *)conversationID to:(NSString *)toUser ext:(NSDictionary *)messageExt progress:(void (^)(int))aProgressBlock completion:(void (^)(EMMessage *, EMError *))aCompletionBlock{
    
    EMVoiceMessageBody *body = [[EMVoiceMessageBody alloc] initWithLocalPath:localPath displayName:displayName];
    [self getEMMessageBymessageChatType:chatType conversationID:conversationID to:toUser body:body ext:messageExt progress:aProgressBlock completion:aCompletionBlock];
}

//发送视频
-(void)sendVideoMessageWithLocalPath:(NSString *)localPath displayName:(NSString *)displayName messageChatType:(EMChatType)chatType conversationID:(NSString *)conversationID to:(NSString *)toUser ext:(NSDictionary *)messageExt progress:(void (^)(int))aProgressBlock completion:(void (^)(EMMessage *, EMError *))aCompletionBlock{
    EMVideoMessageBody *body = [[EMVideoMessageBody alloc] initWithLocalPath:localPath displayName:displayName];
    [self getEMMessageBymessageChatType:chatType conversationID:conversationID to:toUser body:body ext:messageExt progress:aProgressBlock completion:aCompletionBlock];
}

//发送文件
-(void)sendFileMessageWithLocalPath:(NSString *)localPath displayName:(NSString *)displayName messageChatType:(EMChatType)chatType conversationID:(NSString *)conversationID to:(NSString *)toUser ext:(NSDictionary *)messageExt progress:(void (^)(int))aProgressBlock completion:(void (^)(EMMessage *, EMError *))aCompletionBlock{
    
    EMFileMessageBody *body = [[EMFileMessageBody alloc] initWithLocalPath:localPath displayName:displayName];
    [self getEMMessageBymessageChatType:chatType conversationID:conversationID to:toUser body:body ext:messageExt progress:aProgressBlock completion:aCompletionBlock];
}




//获取EMMessage
- (void)getEMMessageBymessageChatType:(EMChatType)chatType conversationID:(NSString *)conversationID to:(NSString *)toUser body:(EMMessageBody *)body ext:(NSDictionary *)messageExt progress:(void (^)(int))aProgressBlock completion:(void (^)(EMMessage *, EMError *))aCompletionBlock{
    
    NSString *from = [[EMClient sharedClient] currentUsername];
    
    //生成Message
    EMMessage *message = [[EMMessage alloc] initWithConversationID:conversationID from:from to:toUser body:body ext:messageExt];
    
    message.chatType = chatType;
    
    //message.chatType = EMChatTypeChat;// 设置为单聊消息
    //message.chatType = EMChatTypeGroupChat;// 设置为群聊消息
    //message.chatType = EMChatTypeChatRoom;// 设置为聊天室消息

    //message.ext = @{@"key":@"value"}; // 扩展消息部分
    
    //发送
    
    [self sendMessage:message progress:aProgressBlock completion:aCompletionBlock];
}


//插入消息
- (void)importMessages:(NSArray *)aMessages completion:(void (^)(EMError *))aCompletionBlock{
    [[EMClient sharedClient].chatManager importMessages:aMessages completion:^(EMError *aError) {
        if (aCompletionBlock) {
            aCompletionBlock(aError);
        }
    }];
}

- (void)updateMessage:(EMMessage *)aMessage
           completion:(void (^)(EMMessage *aMessage, EMError *aError))aCompletionBlock{
    [[EMClient sharedClient].chatManager updateMessage:aMessage completion:^(EMMessage *aMessage, EMError *aError) {
        if (aCompletionBlock) {
            aCompletionBlock(aMessage,aError);
        }
    }];
}


/****************************************** 会    话 ******************************************************/
//会话：操作聊天消息 EMMessage 的容器，在 SDK 中对应的类型是 EMConversation。
#pragma mark - 会话

//新建/获取一个会话
-(EMConversation *)getConversation:(NSString *)aConversationId type:(EMConversationType)aType{
    return [[EMClient sharedClient].chatManager getConversation:aConversationId type:aType createIfNotExist:YES];
    //EMConversationTypeChat            单聊会话
    //EMConversationTypeGroupChat       群聊会话
    //EMConversationTypeChatRoom        聊天室会话
}

//删除单个会话
-(void)deleteConversation:(NSString *)aConversationId completion:(void (^)(NSString *, EMError *))aCompletionBlock{
    [[EMClient sharedClient].chatManager deleteConversation:aConversationId isDeleteMessages:YES completion:^(NSString *aConversationId, EMError *aError){
        if (aCompletionBlock) {
            aCompletionBlock(aConversationId,aError);
        }
    }];
}

//根据 conversationId 批量删除会话

-(void)deleteConversations:(NSArray *)aConversations completion:(void (^)(EMError *))aCompletionBlock{
    [[EMClient sharedClient].chatManager deleteConversations:aConversations isDeleteMessages:YES completion:^(EMError *aError){
        if (aCompletionBlock) {
            aCompletionBlock(aError);
        }
    }];
}


/****************************************** 获取会话列表 ******************************************************/
#pragma mark - 获取会话列表

//获取所有会话(内存中有则从内存中取，没有则从db中取)
-(NSArray *)getAllConversations{
    return [[EMClient sharedClient].chatManager getAllConversations];
}

//获取会话未读消息数
-(NSInteger)unreadMessagesCount{
    
    NSArray *conversations = [self getAllConversations];
    NSInteger unreadCount = 0;
    for (EMConversation *conversation in conversations) {
        unreadCount += conversation.unreadMessagesCount;
    }
    
    return unreadCount;
}


/****************************************** 聊    天 ******************************************************/
#pragma mark - 聊天

//发送消息
- (void)sendMessage:(EMMessage *)message progress:(void (^)(int))aProgressBlock completion:(void (^)(EMMessage *, EMError *))aCompletionBlock{
    
    [[EMClient sharedClient].chatManager sendMessage:message progress:^(int progress) {
        if (aProgressBlock) {
            aProgressBlock(progress);
        }
    } completion:^(EMMessage *message, EMError *error) {
        if (aCompletionBlock) {
            aCompletionBlock(message,error);
        }
    }];
    
}


//重发送消息
-(void)resendMessage:(EMMessage *)aMessage progress:(void (^)(int))aProgressBlock completion:(void (^)(EMMessage *, EMError *))aCompletionBlock{
    
    [[EMClient sharedClient].chatManager resendMessage:aMessage progress:^(int progress) {
        if (aProgressBlock) {
            aProgressBlock(progress);
        }
    } completion:^(EMMessage *message, EMError *error) {
        if (aCompletionBlock) {
            aCompletionBlock(message,error);
        }
    }];
}

#pragma mark - EMChatManagerDelegate

/*!
 *  \~chinese
 *  会话列表发生变化
 *
 *  @param aConversationList  会话列表<EMConversation>
 */
-(void)conversationListDidUpdate:(NSArray *)aConversationList{
    [[NSNotificationCenter defaultCenter] postNotificationName:KconversationListDidUpdateNotification object:aConversationList];
}


//接收消息
/*!
 @method
 @brief 接收到一条及以上非cmd消息
 */
- (void)messagesDidReceive:(NSArray *)aMessages{
    
    [self presentLocalNotice:@"您收到一条消息"];
    [[NSNotificationCenter defaultCenter] postNotificationName:KReceiveChatMessageNotification object:aMessages];
    
    for (EMMessage *message in aMessages) {
        
        // 消息中的扩展属性
        NSDictionary *ext = message.ext;
        NSLog(@"消息中的扩展属性是 -- %@",ext);
        
        
        EMMessageBody *msgBody = message.body;
        switch (msgBody.type) {
            case EMMessageBodyTypeText:
            {
                // 收到的文字消息
                EMTextMessageBody *textBody = (EMTextMessageBody *)msgBody;
                NSString *txt = textBody.text;
                NSLog(@"收到的文字是 txt -- %@",txt);
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
    }
}


- (void)presentLocalNotice:(NSString *)notice
{

    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.userInfo = @{@"alert": notice,
                                   @"badge": @"1"
                                   };

    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {

        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.alertBody = notice;

        [UIApplication sharedApplication].applicationIconBadgeNumber += 1;
        localNotification.fireDate = [NSDate date];

    }else{
        //防止多次震动
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(playShake) object:nil];
        [self performSelector:@selector(playShake) withObject:nil afterDelay:0.1f];

    }


    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];

}


- (void)playShake{

    //系统震动
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}


//下载缩略图（图片消息的缩略图或视频消息的第一帧图片），SDK会自动下载缩略图，所以除非自动下载失败，用户不需要自己下载缩略图
-(void)downloadMessageThumbnail:(EMMessage *)aMessage progress:(void (^)(int))aProgressBlock completion:(void (^)(EMMessage *, EMError *))aCompletionBlock{
    
    BOOL needDownload = NO;
    
    EMMessageBody *msgBody = aMessage.body;
    switch (msgBody.type) {
        case EMMessageBodyTypeImage:
        {
            EMImageMessageBody *body = ((EMImageMessageBody *)msgBody);
            if (body.thumbnailDownloadStatus > EMDownloadStatusSuccessed) {
                needDownload = YES;
            }
        }
            break;
        case EMMessageBodyTypeVoice:
        {
            // 音频sdk会自动下载
            EMVoiceMessageBody *body = (EMVoiceMessageBody *)msgBody;
            if (body.downloadStatus > EMDownloadStatusSuccessed) {
                needDownload = YES;
            }
        }
            break;
        case EMMessageBodyTypeVideo:
        {
            EMVideoMessageBody *body = (EMVideoMessageBody *)msgBody;
            
            if (body.thumbnailDownloadStatus > EMDownloadStatusSuccessed) {
                needDownload = YES;
            }
        }
            break;
       
        default:
            break;
    }
    

    if (needDownload) {
        [[EMClient sharedClient].chatManager downloadMessageThumbnail:aMessage progress:^(int progress) {
            if (aProgressBlock) {
                aProgressBlock(progress);
            }
            
        } completion:^(EMMessage *message, EMError *error) {
            if (aCompletionBlock) {
                aCompletionBlock(message,error);
            }
            
            if (!error) {
                NSLog(@"下载成功，下载后的message是 -- %@",aMessage);
            }
        }];
    }
    
}

//下载消息附件（语音，视频，图片原图，文件），SDK会自动下载语音消息，所以除非自动下载语音失败，用户不需要自动下载语音附件
-(void)downloadMessageAttachment:(EMMessage *)aMessage progress:(void (^)(int))aProgressBlock completion:(void (^)(EMMessage *, EMError *))aCompletionBlock{
    
    
    BOOL needDownload = NO;
    
    EMMessageBody *msgBody = aMessage.body;
    switch (msgBody.type) {
        case EMMessageBodyTypeImage:
        {
            EMImageMessageBody *body = ((EMImageMessageBody *)msgBody);
            if (body.downloadStatus > EMDownloadStatusSuccessed) {
                needDownload = YES;
            }
        }
            break;
        
        case EMMessageBodyTypeVideo:
        {
            EMVideoMessageBody *body = (EMVideoMessageBody *)msgBody;
            
            if (body.downloadStatus > EMDownloadStatusSuccessed) {
                needDownload = YES;
            }
        }
            break;
            
        case EMMessageBodyTypeFile:
        {
            EMFileMessageBody *body = (EMFileMessageBody *)msgBody;
            if (body.downloadStatus > EMDownloadStatusSuccessed) {
                needDownload = YES;
            }
        }
            break;
        default:
            break;
    }
    
    
    if (needDownload) {
        [[EMClient sharedClient].chatManager downloadMessageAttachment:aMessage progress:^(int progress) {
            if (aProgressBlock) {
                aProgressBlock(progress);
            }
            
        } completion:^(EMMessage *message, EMError *error) {
            if (aCompletionBlock) {
                aCompletionBlock(message,error);
            }
            
            
            if (!error) {
                NSLog(@"下载成功，下载后的message是 -- %@",aMessage);
            }
        }];
    }
}



/*!
 @method
 @brief 接收到一条及以上cmd消息
 */
- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages {
    for (EMMessage *message in aCmdMessages) {
        EMCmdMessageBody *body = (EMCmdMessageBody *)message.body;
        NSLog(@"收到的action是 -- %@",body.action);
        
        NSDictionary *ext = message.ext;
        NSLog(@"cmd消息中的扩展属性是 -- %@",ext);
    }
}

// 发送已读回执。在这里写只是为了演示发送，在APP中具体在哪里发送需要开发者自己决定。
-(void)sendMessageReadAck:(EMMessage *)aMessage completion:(void (^)(EMMessage *, EMError *))aCompletionBlock{
    
    [[EMClient sharedClient].chatManager sendMessageReadAck:aMessage completion:^(EMMessage *message, EMError *error) {
        if (!error) {
            NSLog(@"发送成功");
        }
        
        if (aCompletionBlock) {
            aCompletionBlock(message,error);
        }
    }];

}



/*!
 @method
 @brief 接收到一条及以上已送达回执
 */
- (void)messagesDidDeliver:(NSArray *)aMessages{
    NSLog(@"已送达回执");
}


/*!
 *  接收到一条及以上已读回执
 *
 *  @param aMessages  消息列表<EMMessage>
 */
- (void)messagesDidRead:(NSArray *)aMessages{
    NSLog(@"已读回执");
}



/****************************************** 好   友 ******************************************************/

#pragma mark - 好友

//获取本地存储的所有好友
-(NSArray *)getLocalContacts{
    return [[EMClient sharedClient].contactManager getContacts];
}

//从本地获取黑名单列表
-(NSArray *)getLocalBlackList{
    return [[EMClient sharedClient].contactManager getBlackList];
}

//从服务器获取所有的好友
-(void)getContactsFromServerWithCompletion:(void (^)(NSArray *, EMError *))aCompletionBlock{
    [[EMClient sharedClient].contactManager getContactsFromServerWithCompletion:^(NSArray *aList, EMError *aError) {
        aCompletionBlock(aList,aError);
    }];
}

//添加好友

-(void)addContact:(NSString *)aUsername message:(NSString *)aMessage completion:(void (^)(NSString *, EMError *))aCompletionBlock{
    [[EMClient sharedClient].contactManager addContact:aUsername message:aMessage completion:^(NSString *aUsername, EMError *aError) {
         aCompletionBlock(aUsername,aError);
    }];
}

//删除好友
-(void)deleteContact:(NSString *)aUsername completion:(void (^)(NSString *, EMError *))aCompletionBlock{
    [[EMClient sharedClient].contactManager deleteContact:aUsername isDeleteConversation:YES completion:^(NSString *aUsername, EMError *aError) {
         aCompletionBlock(aUsername,aError);
    }];
}

//从服务器获取黑名单列表
-(void)getBlackListFromServerWithCompletion:(void (^)(NSArray *, EMError *))aCompletionBlock{
    [[EMClient sharedClient].contactManager getBlackListFromServerWithCompletion:^(NSArray *aList, EMError *aError) {
        aCompletionBlock(aList,aError);
    }];
}

//将用户加入黑名单
-(void)addUserToBlackList:(NSString *)aUsername completion:(void (^)(NSString *, EMError *))aCompletionBlock{
    [[EMClient sharedClient].contactManager addUserToBlackList:aUsername completion:^(NSString *aUsername, EMError *aError) {
         aCompletionBlock(aUsername,aError);
    }];
}

//将用户移出黑名单
-(void)removeUserFromBlackList:(NSString *)aUsername completion:(void (^)(NSString *, EMError *))aCompletionBlock{
    [[EMClient sharedClient].contactManager removeUserFromBlackList:aUsername completion:^(NSString *aUsername, EMError *aError) {
        aCompletionBlock(aUsername,aError);
    }];
}

//同意加好友的申请
-(void)approveFriendRequestFromUser:(NSString *)aUsername completion:(void (^)(NSString *, EMError *))aCompletionBlock{
    [[EMClient sharedClient].contactManager approveFriendRequestFromUser:aUsername completion:^(NSString *aUsername, EMError *aError) {
        aCompletionBlock(aUsername,aError);
    }];
}

//拒绝加好友的申请
-(void)declineFriendRequestFromUser:(NSString *)aUsername completion:(void (^)(NSString *, EMError *))aCompletionBlock{
    [[EMClient sharedClient].contactManager declineFriendRequestFromUser:aUsername completion:^(NSString *aUsername, EMError *aError) {
        aCompletionBlock(aUsername,aError);
    }];
}

#pragma mark - EMContactManagerDelegate

/*!
 *  \~chinese
 *  用户B同意用户A的加好友请求后，用户A会收到这个回调
 *
 *  @param aUsername   用户B
 */
- (void)friendRequestDidApproveByUser:(NSString *)aUsername{
    
}

/*!
 *  \~chinese
 *  用户B拒绝用户A的加好友请求后，用户A会收到这个回调
 *
 *  @param aUsername   用户B
 */
- (void)friendRequestDidDeclineByUser:(NSString *)aUsername{
    
}

/*!
 *  \~chinese
 *  用户B删除与用户A的好友关系后，用户A，B会收到这个回调
 *
 *  @param aUsername   用户B
 *
 */
- (void)friendshipDidRemoveByUser:(NSString *)aUsername{
    [[NSNotificationCenter defaultCenter] postNotificationName:KContentChangeNotification object:nil];
}

/*!
 *  \~chinese
 *  用户B同意用户A的好友申请后，用户A和用户B都会收到这个回调
 *
 *  @param aUsername   用户好友关系的另一方
 */
- (void)friendshipDidAddByUser:(NSString *)aUsername{
    [[UserProfileManager sharedInstance]loadUserProfileInBackgroundWithBuddy:@[aUsername] saveToLoacal:YES completion:^(BOOL success, NSError *error) {
        NSLog(@"friendshipDidAddByUser==%@",error);
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:KContentChangeNotification object:nil];
}

/*!
 *  \~chinese
 *  用户B申请加A为好友后，用户A会收到这个回调
 *
 *  @param aUsername   用户B
 *  @param aMessage    好友邀请信息
 */
- (void)friendRequestDidReceiveFromUser:(NSString *)aUsername
                                message:(NSString *)aMessage{
    
    __weak typeof(self) weakself = self;
    
    [[EMClient sharedClient].contactManager approveFriendRequestFromUser:aUsername completion:^(NSString *aUsername, EMError *aError) {

        if (!aError) {
            [weakself sendTextMessageWithText:@"我通过了你的朋友验证请求，现在我们可以开始聊天了" messageChatType:EMChatTypeChat conversationID:aUsername to:aUsername ext:nil progress:nil completion:^(EMMessage *message, EMError *error) {
                
                if (error) {
                    NSLog(@"error==%@",error);
                }
            }];
        }
        NSLog(@"friendRequestDidReceiveFromUser:::%@,%@",aUsername,aError);
    }];
}


@end
