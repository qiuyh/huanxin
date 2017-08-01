//
//  QYHImageModelClass.m
//  FengChatHuai
//
//  Created by 邱永槐 on 16/5/26.
//  Copyright © 2016年 iMacQIU. All rights reserved.
//

#import "QYHImageModelClass.h"

@interface QYHImageModelClass ()

@property (nonatomic, strong) NSManagedObjectContext *manager;

@end

@implementation QYHImageModelClass


//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//        //通过上下文获取manager
//        self.manager = [QYHXMPPTool sharedQYHXMPPTool].rosterStorage.mainThreadManagedObjectContext;
//    }
//    return self;
//}
//
//-(void)save:(NSData *)image ImageText:(NSString *)imageText
//{
//    if (image != nil) {
//        NSArray *result = [self search:imageText];
//        
//        QYHHistoryImage *myImage;
//        
//        if (result.count == 0)
//        {
//            myImage = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([QYHHistoryImage class]) inManagedObjectContext:self.manager];
//            myImage.imageText = imageText;
//            myImage.headerImage = image;
//            myImage.time = [NSDate date];
//        }
//        else
//        {
//            myImage = result[0];
//            myImage.time = [NSDate date];
//        }
//        
//        //存储实体
//        NSError *error = nil;
//        if (![self.manager save:&error]) {
//            NSLog(@"保存出错%@", [error localizedDescription]);
//        }
//        
//    }
//    
//}
//
//
////查找
//-(NSArray *)search:(NSString *) image
//{
//    NSArray *result;
//    
//    //新建查询条件
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([QYHHistoryImage class])];
//    
//    //添加谓词
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"imageText=%@",image];
//    
//    //把谓词给request
//    [fetchRequest setPredicate:predicate];
//    
//    //执行查询
//    NSError *error = nil;
//    result = [self.manager executeFetchRequest:fetchRequest error:&error];
//    if (error) {
//        NSLog(@"查询错误：%@", [error localizedDescription]);
//    }
//    return result;
//}
//
//
//
////查询所有的
//-(NSArray *) queryAll
//{
//    //新建查询条件
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([QYHHistoryImage class])];
//    
//    //添加排序规则
//    //定义排序规则
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:NO];
//    
//    //添加排序规则
//    [fetchRequest setSortDescriptors:@[sortDescriptor]];
//    
//    
//    //执行查询
//    NSError *error = nil;
//    NSArray *result = [self.manager executeFetchRequest:fetchRequest error:&error];
//    if (error) {
//        NSLog(@"查询错误：%@", [error localizedDescription]);
//    }
//    
//    return result;
//}
//


@end
