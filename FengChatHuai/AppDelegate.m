//
//  AppDelegate.m
//  FengChatHuai
//
//  Created by iMacQIU on 16/5/19.
//  Copyright © 2016年 iMacQIU. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>
#import "AppDelegate.h"
#import "QYHEMClientTool.h"
#import <SMS_SDK/SMSSDK.h>
#import "Reachability.h"
#import "UIImageView+WebCache.h"


static NSString *SMSappKey    = @"1475a62ad1e08";
static NSString *SMSappSecret = @"0a2871362cc6a003f44c3512a3394ee2";

@interface AppDelegate ()<UNUserNotificationCenterDelegate>

{
    BOOL _isOperationing;
}
@property (nonatomic, strong) Reachability *conn;
@property (nonatomic, strong) UIView *notReachableTipView;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //环信注册
    [[QYHEMClientTool shareInstance]initializeSDKWithOptions];
    
    
    /**
     *  检查是否有网
     */

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStateChange) name:kReachabilityChangedNotification object:nil];
    self.conn = [Reachability reachabilityForInternetConnection];
    [self.conn startNotifier];
    
    [self checkNetworkState];
    
    
    //初始化应用，appKey和appSecret从后台申请得
     [SMSSDK registerApp:SMSappKey withSecret:SMSappSecret];
    
    /*
     UIUserNotificationTypeNone    = 0,      没有,没有本地通知
     UIUserNotificationTypeBadge   = 1 << 0, 接受图标右上角提醒数字
     UIUserNotificationTypeSound   = 1 << 1, 接受通知时候,可以发出音效
     UIUserNotificationTypeAlert   = 1 << 2, 接受提醒(横幅/弹窗)
     */
    if (IOS10) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (!error) {
                NSLog(@"succeeded!");
            }
        }];
    } else if (IOS8_10){//iOS8-iOS10
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound) categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    } else {//iOS8以下
        [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    }
    
    [self setupNavBar];
    
    
    //配置XMPP的日志
//    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    
    // 判断用户是否登录
    //[QYHAccount shareAccount].isLogin
    
    if([[QYHEMClientTool shareInstance] isAutoLogin]){
        //来主界面
        id mainVc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateInitialViewController];
        self.window.rootViewController = mainVc;
        
        //自动登录
//        [[QYHXMPPTool sharedQYHXMPPTool] xmppLogin:^(XMPPResultType loginType) {
//            
//            if (loginType == XMPPResultTypeLoginSucess) {
//                
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    [[NSNotificationCenter defaultCenter] postNotificationName:KLoginSuccessNotification object:nil];
//                });
//                
//            }
//        }];
        
    }


    //加载表情
    [self loadFaceData];
    
    return YES;
}


- (void)checkNetworkState
{
    // 1.检测wifi状态
    Reachability *wifi = [Reachability reachabilityForLocalWiFi];
    
    // 2.检测手机是否能上网络(WIFI\3G\2.5G)
    Reachability *conn = [Reachability reachabilityForInternetConnection];
    
    // 3.判断网络状态
    if ([wifi currentReachabilityStatus] != NotReachable) { // 有wifi
        NSLog(@"有wifi");
        [[NSNotificationCenter defaultCenter]postNotificationName:KNetWorkingChangeNotification object:@(YES)];
        
        [QYHAccount shareAccount].isHasNetWorking = YES;
        
    } else if ([conn currentReachabilityStatus] != NotReachable) { // 没有使用wifi, 使用手机自带网络进行上网
        NSLog(@"使用手机自带网络进行上网");
        
        [[NSNotificationCenter defaultCenter]postNotificationName:KNetWorkingChangeNotification object:@(YES)];
        
        [QYHAccount shareAccount].isHasNetWorking = YES;
        
    } else { // 没有网络
        
        [QYHAccount shareAccount].isHasNetWorking = NO;
        
        if (!_isOperationing) {
             _isOperationing = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                _isOperationing = NO;
                
                [[NSNotificationCenter defaultCenter]postNotificationName:KNetWorkingChangeNotification object:@(NO)];
                
                NSLog(@"没有网络");
            });
            
        }
        
    }
}

- (void)dealloc
{
    [self.conn stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)networkStateChange
{
    [self checkNetworkState];
}

- (void)loadFaceData
{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        //加载plist文件中的数据
        NSBundle *bundle = [NSBundle mainBundle];
        //寻找资源的路径
        NSString *path = [bundle pathForResource:@"expression_custom" ofType:@"plist"];
        //获取plist中的数据
        [QYHChatDataStorage shareInstance].faceDataArray = [[NSArray alloc] initWithContentsOfFile:path];
        
        
        //寻找资源的路径
        NSString *imagePath = [bundle pathForResource:@"expressionImage_custom" ofType:@"plist"];
        //获取plist中的数据
        [QYHChatDataStorage shareInstance].faceDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:imagePath];
        
       
    });
    

    //之前
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        
//        //加载plist文件中的数据
//        NSBundle *bundle = [NSBundle mainBundle];
//        //寻找资源的路径
//        NSString *path = [bundle pathForResource:@"emoticons" ofType:@"plist"];
//        //获取plist中的数据
//        [QYHChatDataStorage shareInstance].faceDataArray = [[NSArray alloc] initWithContentsOfFile:path];
//        
//        
//        NSArray *faceArray = [QYHChatDataStorage shareInstance].faceDataArray;
//        
//        for (int i = 0; i < faceArray.count; i ++)
//        {
//            
//            if (![faceArray[i][@"png"] isEqualToString:@""]) {
//                
//                [[QYHChatDataStorage shareInstance].faceDictionary setObject:faceArray[i][@"png"] forKey:faceArray[i][@"chs"]];
//            }
//            
//            
//        }
//    });
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [[QYHEMClientTool shareInstance] applicationDidEnterBackground:application];
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    [[QYHEMClientTool shareInstance] applicationWillEnterForeground:application];
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    NSInteger count = [UIApplication sharedApplication].applicationIconBadgeNumber;
    [UIApplication sharedApplication].applicationIconBadgeNumber =count - 1;
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
//    [UIApplication sharedApplication].applicationIconBadgeNumber =count;
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - setup

- (void)setupNavBar
{
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0/255.0 green:130/255.0 blue:200/255.0 alpha:0.9]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    UINavigationBar *bar = [UINavigationBar appearance];
    
    bar.titleTextAttributes =[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIColor whiteColor],NSForegroundColorAttributeName,
                                                          [UIFont systemFontOfSize:18],NSFontAttributeName, nil];
}


#pragma mark - 收到内存警告
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application{
    NSLog(@"内存警告了⚠️⚠️⚠️⚠️⚠️⚠️⚠️");
    [[SDImageCache sharedImageCache] setValue:nil forKey:@"memCache"];
    SDWebImageManager *mgr = [SDWebImageManager sharedManager];
    [mgr cancelAll];
    [mgr.imageCache clearMemory];
}


// 将得到的deviceToken传给SDK
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    
    [[QYHEMClientTool shareInstance]bindDeviceToken:deviceToken];
    
    NSLog(@"注册deviceToken成功");
}

// 注册deviceToken失败
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    NSLog(@"注册deviceToken失败error -- %@",error);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"notification==%@",notification);
//    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"iOS6及以下系统，收到通知:%@", userInfo);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    NSLog(@"iOS7及以上系统，收到通知:%@", userInfo);
}


//iOS 10后台
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    　　//消息处理
    
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        NSLog(@"iOS10 收到远程通知:%@",userInfo);
        //此处省略一万行需求代码。。。。。。
        
    }else {
        // 判断为本地通知
        //此处省略一万行需求代码。。。。。。
//        NSLog(@"iOS10 收到本地通知:{\\\\nbody:%@，\\\\ntitle:%@,\\\\nsubtitle:%@,\\\\nbadge：%@，\\\\nsound：%@，\\\\nuserInfo：%@\\\\n}",body,title,subtitle,badge,sound,userInfo);
    }
}

//iOS 10前台
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler{
    NSDictionary *userInfo = notification.request.content.userInfo;
    　　//消息处理
    
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //此处省略一万行需求代码。。。。。。
        NSLog(@"iOS10 收到远程通知:%@",userInfo);
        
    }else {
        // 判断为本地通知
        //此处省略一万行需求代码。。。。。。
//        NSLog(@"iOS10 收到本地通知:{\\\\nbody:%@，\\\\ntitle:%@,\\\\nsubtitle:%@,\\\\nbadge：%@，\\\\nsound：%@，\\\\nuserInfo：%@\\\\n}",body,title,subtitle,badge,sound,userInfo);
    }
}



@end
