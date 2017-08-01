//
//  QYHEMClientTool.h
//  FengChatHuai
//
//  Created by iMacQIU on 17/3/29.
//  Copyright © 2017年 iMacQIU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMOptions.h"
#import "EMClient.h"

@interface QYHEMClientTool : NSObject<EMClientDelegate,EMChatManagerDelegate,EMContactManagerDelegate>

+ (instancetype)shareInstance;


#pragma mark - 基础功能（初始化，绑定token，注册，登陆，退出）

//初始化SDK
- (void)initializeSDKWithOptions;
//绑定token
- (void)bindDeviceToken:(NSData *)deviceToken;
//进入后台
- (void)applicationDidEnterBackground:(UIApplication *)application;
//进入前台
- (void)applicationWillEnterForeground:(UIApplication *)application;
//注册
- (EMError *)registerWithUsername:(NSString *)username
                         password:(NSString *)password;
//登陆
- (EMError *)loginWithUsername:(NSString *)username
                      password:(NSString *)password;
//退出登录
- (EMError *)logout;

/*!
 *  \~chinese
 *  当前登录账号
 */
- (NSString *)currentUsername;
/*!
 *  \~chinese
 *  SDK是否自动登录上次登录的账号
 */
- (BOOL)isAutoLogin;

/*!
 *  \~chinese
 *  用户是否已登录
 */
- (BOOL)isLoggedIn;

/*!
 *  \~chinese
 *  是否连上聊天服务器
 */
- (BOOL)isConnected;



#pragma mark - 发送消息

//发送文字
- (void)sendTextMessageWithText:(NSString *)text
                messageChatType:(EMChatType)chatType
                 conversationID:(NSString *)conversationID
                             to:(NSString *)toUser
                            ext:(NSDictionary *)messageExt
                       progress:(void (^)(int progress))aProgressBlock
                     completion:(void (^)(EMMessage *message, EMError *error))aCompletionBlock;

//发送图片
- (void)sendImageMessageWithData:(NSData *)data
                     displayName:(NSString *)displayName
                 messageChatType:(EMChatType)chatType
                  conversationID:(NSString *)conversationID
                              to:(NSString *)toUser
                             ext:(NSDictionary *)messageExt
                        progress:(void (^)(int progress))aProgressBlock
                      completion:(void (^)(EMMessage *message, EMError *error))aCompletionBlock;

//发送位置
- (void)sendLocationMessageWithLatitude:(double)latitude
                              longitude:(double)longitude
                                address:(NSString *)address
                        messageChatType:(EMChatType)chatType
                         conversationID:(NSString *)conversationID
                                     to:(NSString *)toUser
                                    ext:(NSDictionary *)messageExt
                               progress:(void (^)(int progress))aProgressBlock
                             completion:(void (^)(EMMessage *message, EMError *error))aCompletionBlock;

//发送语音
- (void)sendVoiceMessageWithLocalPath:(NSString *)localPath
                          displayName:(NSString *)displayName
                      messageChatType:(EMChatType)chatType
                       conversationID:(NSString *)conversationID
                                   to:(NSString *)toUser
                                  ext:(NSDictionary *)messageExt
                             progress:(void (^)(int progress))aProgressBlock
                           completion:(void (^)(EMMessage *message, EMError *error))aCompletionBlock;

//发送视频
- (void)sendVideoMessageWithLocalPath:(NSString *)localPath
                          displayName:(NSString *)displayName
                      messageChatType:(EMChatType)chatType
                       conversationID:(NSString *)conversationID
                                   to:(NSString *)toUser
                                  ext:(NSDictionary *)messageExt
                             progress:(void (^)(int progress))aProgressBlock
                           completion:(void (^)(EMMessage *message, EMError *error))aCompletionBlock;

//发送文件
- (void)sendFileMessageWithLocalPath:(NSString *)localPath
                         displayName:(NSString *)displayName
                     messageChatType:(EMChatType)chatType
                      conversationID:(NSString *)conversationID
                                  to:(NSString *)toUser
                                 ext:(NSDictionary *)messageExt
                            progress:(void (^)(int progress))aProgressBlock
                          completion:(void (^)(EMMessage *message, EMError *error))aCompletionBlock;


//插入消息  @[message]  EMMessage
- (void)importMessages:(NSArray *)aMessages
            completion:(void (^)(EMError *aError))aCompletionBlock;

//更新消息属性
- (void)updateMessage:(EMMessage *)aMessage
           completion:(void (^)(EMMessage *aMessage, EMError *aError))aCompletionBlock;




#pragma mark - 会话

//新建/获取一个会话
- (EMConversation *)getConversation:(NSString *)aConversationId
                               type:(EMConversationType)aType;
//删除单个会话
- (void)deleteConversation:(NSString *)aConversationId
                completion:(void (^)(NSString *aConversationId, EMError *aError))aCompletionBlock;

//根据 conversationId 批量删除会话
- (void)deleteConversations:(NSArray *)aConversations
                 completion:(void (^)(EMError *aError))aCompletionBlock;


#pragma mark - 获取会话列表

//获取所有会话(内存中有则从内存中取，没有则从db中取)

- (NSArray *)getAllConversations;

//获取会话未读消息数

- (NSInteger)unreadMessagesCount;



#pragma mark - 聊天

//发送消息
- (void)sendMessage:(EMMessage *)message progress:(void (^)(int))aProgressBlock completion:(void (^)(EMMessage *, EMError *))aCompletionBlock;
//
////接收消息
//- (void)messagesDidReceive:(NSArray *)aMessages;
//

//重发送消息
- (void)resendMessage:(EMMessage *)aMessage
             progress:(void (^)(int progress))aProgressBlock
           completion:(void (^)(EMMessage *message, EMError *error))aCompletionBlock;

//发送已读回执
- (void)sendMessageReadAck:(EMMessage *)aMessage
                completion:(void (^)(EMMessage *aMessage, EMError *aError))aCompletionBlock;

//下载缩略图（图片消息的缩略图或视频消息的第一帧图片），SDK会自动下载缩略图，所以除非自动下载失败，用户不需要自己下载缩略图
- (void)downloadMessageThumbnail:(EMMessage *)aMessage
                        progress:(void (^)(int progress))aProgressBlock
                      completion:(void (^)(EMMessage *message, EMError *error))aCompletionBlock;

//下载消息附件（语音，视频，图片原图，文件），SDK会自动下载语音消息，所以除非自动下载语音失败，用户不需要自动下载语音附件
- (void)downloadMessageAttachment:(EMMessage *)aMessage
                         progress:(void (^)(int progress))aProgressBlock
                       completion:(void (^)(EMMessage *message, EMError *error))aCompletionBlock;


#pragma mark - 好友

/*!
 *  \~chinese
 *  获取本地存储的所有好友
 *
 *  @result 好友列表<NSString>
 */
- (NSArray *)getLocalContacts;

/*!
 *  \~chinese
 *  从本地获取黑名单列表
 *
 *  @result 黑名单列表<NSString>
 */
- (NSArray *)getLocalBlackList;

/*!
 *  \~chinese
 *  从服务器获取所有的好友
 *
 *  @param aCompletionBlock 完成的回调
 *
 */
- (void)getContactsFromServerWithCompletion:(void (^)(NSArray *aList, EMError *aError))aCompletionBlock;

/*!
 *  \~chinese
 *  添加好友
 *
 *  @param aUsername        要添加的用户
 *  @param aMessage         邀请信息
 *  @param aCompletionBlock 完成的回调
 */
- (void)addContact:(NSString *)aUsername
           message:(NSString *)aMessage
        completion:(void (^)(NSString *aUsername, EMError *aError))aCompletionBlock;

/*!
 *  \~chinese
 *  删除好友
 *
 *  @param aUsername            要删除的好友
 *  @param aDeleteConversation  是否删除会话
 *  @param aCompletionBlock     完成的回调
 *
 */
- (void)deleteContact:(NSString *)aUsername
           completion:(void (^)(NSString *aUsername, EMError *aError))aCompletionBlock;

/*!
 *  \~chinese
 *  从服务器获取黑名单列表
 *
 *  @param aCompletionBlock 完成的回调
 *
 */
- (void)getBlackListFromServerWithCompletion:(void (^)(NSArray *aList, EMError *aError))aCompletionBlock;

/*!
 *  \~chinese
 *  将用户加入黑名单
 *
 *  @param aUsername        要加入黑命单的用户
 *  @param aCompletionBlock 完成的回调
 *
 */
- (void)addUserToBlackList:(NSString *)aUsername
                completion:(void (^)(NSString *aUsername, EMError *aError))aCompletionBlock;

/*!
 *  \~chinese
 *  将用户移出黑名单
 *
 *  @param aUsername        要移出黑命单的用户
 *  @param aCompletionBlock 完成的回调
 */
- (void)removeUserFromBlackList:(NSString *)aUsername
                     completion:(void (^)(NSString *aUsername, EMError *aError))aCompletionBlock;

/*!
 *  \~chinese
 *  同意加好友的申请
 *
 *  @param aUsername        申请者
 *  @param aCompletionBlock 完成的回调
 *
 */
- (void)approveFriendRequestFromUser:(NSString *)aUsername
                          completion:(void (^)(NSString *aUsername, EMError *aError))aCompletionBlock;

/*!
 *  \~chinese
 *  拒绝加好友的申请
 *
 *  @param aUsername        申请者
 *  @param aCompletionBlock 完成的回调
 *
 */
- (void)declineFriendRequestFromUser:(NSString *)aUsername
                          completion:(void (^)(NSString *aUsername, EMError *aError))aCompletionBlock;



#pragma mark - 好友个人信息



@end
