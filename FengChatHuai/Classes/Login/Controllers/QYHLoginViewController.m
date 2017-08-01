//
//  QYHLoginViewController.m
//  FengChatHuai
//
//  Created by iMacQIU on 16/5/23.
//  Copyright © 2016年 iMacQIU. All rights reserved.
//

#import "QYHLoginViewController.h"
#import "QYHKeyBoardManagerViewController.h"
#import "QYHGetCodeViewController.h"
//#import "QYHXMPPTool.h"
#import "QYHFMDBmanager.h"
#import "QYHRegisterViewController.h"
//#import "XMPPvCardTemp.h"

@interface QYHLoginViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *headImageView;

@property (weak, nonatomic) IBOutlet UITextField *accountTextField;

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation QYHLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
   
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [QYHAccount shareAccount].isLogout = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    

    self.accountTextField.text  = [QYHAccount shareAccount].loginUser;
    self.passwordTextField.text = [QYHAccount shareAccount].loginPwd;
    
    if (self.accountTextField.text.length > 1) {
        
        NSString *path = [NSString stringWithFormat:@"%@%@headImage.jpeg",[QYHChatDataStorage shareInstance].homePath,[QYHAccount shareAccount].loginUser];
        
        NSLog(@"[UIImage imageWithContentsOfFile:path]==%@",[UIImage imageWithContentsOfFile:path]);
        self.headImageView.image = [UIImage imageWithContentsOfFile:path] ? [UIImage imageWithContentsOfFile:path] : [UIImage imageNamed:@"placeholder"];
    }
    
    [QYHKeyBoardManagerViewController shareInstance].selfView = self.view;
}

- (IBAction)loginAction:(id)sender {
    
    // 1.判断有没有输入用户名和密码
    if (self.accountTextField.text.length == 0) {
        NSLog(@"请求输入用户名和密码");
        [QYHProgressHUD showErrorHUD:nil message:@"请求输入用户名！"];
        return;
    }
    
    if (self.passwordTextField.text.length == 0) {
        [QYHProgressHUD showErrorHUD:nil message:@"请求输入密码！"];
        return;
    }
    
    
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    
    [self loginXMPP:self.passwordTextField.text];
    return;
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    __weak typeof(self) weakself = self;
    
    NSString *fileName1 = @"login.json";
    
    [[QYHQiNiuRequestManarger shareInstance]getFile:fileName1 withphotoNumber:self.accountTextField.text Success:^(id responseObject) {
        
        if (![[responseObject objectForKey:@"passWord"] isEqualToString:self.passwordTextField.text]) {
            [MBProgressHUD hideHUDForView:weakself.view animated:YES];
            [QYHProgressHUD showErrorHUD:nil message:@"密码错误！"];
            
            return ;
        }
        
        NSString *xmppPwd = [responseObject objectForKey:@"xmppPassWord"];
        
        //获取头像
        [weakself getHeadImage:xmppPwd];
        
        
    } failure:^(NSError *error) {
        
        [MBProgressHUD hideHUDForView:weakself.view animated:YES];
        
        NSDictionary *err = error.userInfo;
        
        if ([err[@"NSLocalizedDescription"] isEqualToString:@"The Internet connection appears to be offline."])
        {
            [QYHProgressHUD showErrorHUD:nil message:@"网络连接失败"];
            
        }else   if ([err[@"NSLocalizedDescription"] isEqualToString:@"Request failed: not found (404)"]){
            [QYHProgressHUD showErrorHUD:nil message:@"该手机未注册，请注册再登录"];
        }else{
            [QYHProgressHUD showErrorHUD:nil message:@"未知错误"];
        }
    }];
}


/**
 *  获取用户的信息保存起来
 */

- (void)getHeadImage:(NSString *)xmppPwd{
    
    __weak typeof(self) weakself = self;
    
    NSString *imageUrl  = [NSString stringWithFormat:@"http://7xt8p0.com2.z0.glb.qiniucdn.com/%@headImage.jpeg",self.accountTextField.text];
    
    [[QYHQiNiuRequestManarger shareInstance]getDataFromeQiNiuByfile:imageUrl Success:^(id responseObject) {
        
//        [MBProgressHUD hideHUDForView:weakself.view animated:YES];
        
        NSData *data   = responseObject;
        NSString *path = [NSString stringWithFormat:@"%@%@headImage.jpeg",[QYHChatDataStorage shareInstance].homePath,weakself.accountTextField.text];
        [data writeToFile:path atomically:YES];
        
        [weakself loginXMPP:xmppPwd];
        
    } failure:^(NSError *error) {
        
        NSLog(@"获取个人头像失败");
        
        NSDictionary *err = error.userInfo;
        
        if ([err[@"NSLocalizedDescription"] isEqualToString:@"The Internet connection appears to be offline."])
        {
            [MBProgressHUD hideHUDForView:weakself.view animated:YES];
            [QYHProgressHUD showErrorHUD:nil message:@"网络连接失败"];
            
        }else   if ([err[@"NSLocalizedDescription"] isEqualToString:@"Request failed: not found (404)"]){
            
            [weakself loginXMPP:xmppPwd];
            
        }else{
            [MBProgressHUD hideHUDForView:weakself.view animated:YES];
            [QYHProgressHUD showErrorHUD:nil message:@"未知错误"];
        }
        
    }];
}

///**
// *  不需要了
// *
// *
// */
//- (void)getInformation:(NSString *)xmppPwd{
//    
//    __weak typeof(self) weakself = self;
//    
//    NSString *fileName = @"information.json";
//    
//    [[QYHQiNiuRequestManarger shareInstance]getFile:fileName withphotoNumber:self.accountTextField.text Success:^(id responseObject) {
//        
//        NSDictionary *informationDic = responseObject;
//        NSUserDefaults *userinfo = [NSUserDefaults standardUserDefaults];
//        [userinfo setObject:informationDic forKey:[ NSString stringWithFormat:@"%@information",weakself.accountTextField.text]];
//        [weakself loginXMPP:xmppPwd];
//        //        [weakself getRemarkName:xmppPwd];
//        
//    } failure:^(NSError *error) {
//        NSLog(@"获取个人信息失败");
//        
//        NSDictionary *err = error.userInfo;
//        
//        if ([err[@"NSLocalizedDescription"] isEqualToString:@"The Internet connection appears to be offline."])
//        {
//            [MBProgressHUD hideHUDForView:weakself.view animated:YES];
//            [QYHProgressHUD showErrorHUD:nil message:@"网络连接失败"];
//            
//        }else   if ([err[@"NSLocalizedDescription"] isEqualToString:@"Request failed: not found (404)"]){
//
//            /**
//             *  一开始没有的话就保存为空字符串
//             */
//            NSDictionary *dic = @{@"nickName":@"",
//                                  @"myQRcode":@"",
//                                  @"sex":@"",
//                                  @"area":@"",
//                                  @"personalSignature":@""};
//            
//            NSUserDefaults *userinfo = [NSUserDefaults standardUserDefaults];
//            [userinfo setObject:dic forKey:[ NSString stringWithFormat:@"%@information",weakself.accountTextField.text]];
//            [weakself loginXMPP:xmppPwd];
//            //            [weakself getRemarkName:xmppPwd];
//            
//        }else{
//            [MBProgressHUD hideHUDForView:weakself.view animated:YES];
//            [QYHProgressHUD showErrorHUD:nil message:@"未知错误"];
//        }
//        
//    }];
//}
//
////获取备注，不需要了
//- (void)getRemarkName:(NSString *)xmppPwd{
//    
//    __weak typeof(self) weakself = self;
//    
//    NSString *fileName = @"remarkName.json";
//    
//    [[QYHQiNiuRequestManarger shareInstance]getFile:fileName withphotoNumber:self.accountTextField.text Success:^(id responseObject) {
//        
//        NSDictionary *remarkNameDic = responseObject;
//        
//        NSUserDefaults *userRemark     = [NSUserDefaults standardUserDefaults];
//        [userRemark setObject:remarkNameDic forKey:[ NSString stringWithFormat:@"%@remarkName",weakself.accountTextField.text]];
//        
//        [weakself loginXMPP:xmppPwd];
//        
//    } failure:^(NSError *error) {
//        NSLog(@"获取朋友备注失败");
//        
//        NSDictionary *err = error.userInfo;
//        
//        if ([err[@"NSLocalizedDescription"] isEqualToString:@"The Internet connection appears to be offline."])
//        {
//            [MBProgressHUD hideHUDForView:weakself.view animated:YES];
//            [QYHProgressHUD showErrorHUD:nil message:@"网络连接失败"];
//            
//        }else   if ([err[@"NSLocalizedDescription"] isEqualToString:@"Request failed: not found (404)"]){
//            
//            /**
//             *  一开始没有的话就保存为空字符串
//             */
//            NSDictionary *dic = @{@"888888":@"默认设置"};
//            
//            NSUserDefaults *userinfo = [NSUserDefaults standardUserDefaults];
//            [userinfo setObject:dic forKey:[ NSString stringWithFormat:@"%@remarkName",weakself.accountTextField.text]];
//            
//            [weakself loginXMPP:xmppPwd];
//            
//        }else{
//            [MBProgressHUD hideHUDForView:weakself.view animated:YES];
//            [QYHProgressHUD showErrorHUD:nil message:@"未知错误"];
//        }
//        
//    }];
//
//}


- (void)loginXMPP:(NSString *)xmppPwd{
    
    // 2.1把用户和密码先放在Account单例
    [QYHAccount shareAccount].loginUser    = self.accountTextField.text;
    [QYHAccount shareAccount].loginPwd     = self.passwordTextField.text;
    [QYHAccount shareAccount].xmppLoginPwd = xmppPwd;
    
    // block会对self进行强引用
    __weak typeof(self) selfVc = self;
    //自己写的block ，有强引用的时候，使用弱引用,系统block,我基本可次理
    
    EMError *error = [[QYHEMClientTool shareInstance] loginWithUsername:self.accountTextField.text password:self.passwordTextField.text];
    //创建数据库，表
  //  [[QYHFMDBmanager shareInstance] createTale];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (!error) {
        [QYHAccount shareAccount].fromLogin = NO;
        //登录成功切换到主界面
        [UIStoryboard showInitialVCWithName:@"Main"];
        // 设置当前的登录状态
        [QYHAccount shareAccount].login = YES;
        
        // 保存登录帐户信息到沙盒
        [[QYHAccount shareAccount] saveToSandBox];
    }else{
        [QYHProgressHUD showErrorHUD:nil message:error.errorDescription];
//        [QYHProgressHUD showErrorHUD:nil message:@"用户名或者密码不正确"];
    }

}



- (IBAction)registerAction:(id)sender {
    
    
//    QYHRegisterViewController *getCodeVC = [self.storyboard instantiateViewControllerWithIdentifier:@"QYHRegisterViewController"];
//

    QYHGetCodeViewController *getCodeVC = [self.storyboard instantiateViewControllerWithIdentifier:@"QYHGetCodeViewController"];
    getCodeVC.isResetPassword = NO;
    [self.navigationController pushViewController:getCodeVC animated:YES];
    
}



- (IBAction)forgerPasswordAction:(id)sender {
    
    QYHGetCodeViewController *getCodeVC = [self.storyboard instantiateViewControllerWithIdentifier:@"QYHGetCodeViewController"];
    getCodeVC.isResetPassword = YES;
    [self.navigationController pushViewController:getCodeVC animated:YES];

}


- (void)pushGetCodeVC{
    
}

#pragma mark - textFiledDelage
- (void)textFieldDidEndEditing:(UITextField *)textField{
    
    NSString *path = [NSString stringWithFormat:@"%@%@headImage.jpeg",[QYHChatDataStorage shareInstance].homePath,textField.text];
    self.headImageView.image = [UIImage imageWithContentsOfFile:path] ? [UIImage imageWithContentsOfFile:path] : [UIImage imageNamed:@"placeholder"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
