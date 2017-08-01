//
//  QYHAddTableViewController.m
//  FengChatHuai
//
//  Created by iMacQIU on 16/5/25.
//  Copyright © 2016年 iMacQIU. All rights reserved.
//

#import "QYHAddTableViewController.h"
#import "QYHKeyBoardManagerViewController.h"
#import "QYHVerificationViewController.h"
#import "QYHDetailTableViewController.h"
//#import "XMPPvCardTemp.h"

@interface QYHAddTableViewController ()<UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *inPutextField;

@end

@implementation QYHAddTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
   [QYHKeyBoardManagerViewController shareInstance].selfView = self.view;

    self.navigationItem.rightBarButtonItem.tintColor = [UIColor greenColor];
    self.title = @"添加好友";
}


- (IBAction)addAction:(id)sender {
    
    
    if ([QYHChatDataStorage shareInstance].usersArray.count>49) {
        [self showMsg:@"外接服务器不支持超过49个好友，请删除一些好友再添加！"];
        return;
    }
    //添加好友
    // 获取用户输入好友名称
//    NSString *user = [self.inPutextField.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if (self.inPutextField.text.length < 1) {
        
        [self showMsg:@"该账号不存在！"];
        return;
    }
    
    
    if (![[QYHEMClientTool shareInstance] isConnected] || ![[QYHEMClientTool shareInstance] isConnected]) {
        
        [self showMsg:@"网络未连接！"];
        return;
    }
    
//    XMPPJID *myJid = [QYHXMPPTool sharedQYHXMPPTool].xmppStream.myJID;
//    XMPPJID *byJID = [XMPPJID jidWithUser:self.inPutextField.text  domain:myJid.domain resource:myJid.resource];
//    
//    XMPPvCardTemp *vCard =  [[QYHXMPPTool sharedQYHXMPPTool].vCard vCardTempForJID:byJID shouldFetch:YES];
//    
//    if (!vCard) {
//        vCard =  [[QYHXMPPTool sharedQYHXMPPTool].vCard vCardTempForJID:byJID shouldFetch:NO];
//    }
    
//
//    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    QYHDetailTableViewController *detailVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"QYHDetailTableViewController"];
//    
//    NSData   *imageUrl = vCard.photo ?vCard.photo:UIImageJPEGRepresentation([UIImage imageNamed:@"placeholder"], 1.0);
//    NSString *nickName = vCard.nickname ?[vCard.nickname stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]:@"";
//    NSString *sex = vCard.formattedName ?[vCard.formattedName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]:@"";
//    NSString *area = vCard.givenName ?[vCard.givenName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]:@"";
//    NSString *personalSignature = vCard.middleName ?[vCard.middleName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]:@"";
//    NSString *phone = self.inPutextField.text ;
//    
//    detailVC.dic = @{@"imageUrl":imageUrl,
//                     @"nickName":nickName,
//                     @"sex":sex,
//                     @"area":area,
//                     @"personalSignature":personalSignature,
//                     @"phone":phone
//                     };
////    detailVC.index      = 0;
//    
//    [self.navigationController pushViewController:detailVC animated:YES];
//
    

    QYHVerificationViewController *vc = [[QYHVerificationViewController alloc]initWithNibName:@"QYHVerificationViewController" bundle:nil];
    vc.friendName = self.inPutextField.text;
    [self.navigationController pushViewController:vc animated:YES];
}


-(void)showMsg:(NSString *)msg{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:msg delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
    
    [av show];
}


@end
