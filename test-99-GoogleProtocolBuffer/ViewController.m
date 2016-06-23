//
//  ViewController.m
//  test-99-GoogleProtocolBuffer
//
//  Created by Kyo on 21/6/16.
//  Copyright © 2016 hzins. All rights reserved.
//

#import "ViewController.h"

#import "User.pbobjc.h"
#import "Person.pbobjc.h"

#define kUserFilderName @"/User.data"
#define kPersonFilderName @"/Person.data"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];


    /*
     单个model写入与读取
     */
    
    {
        //创建
        User *user = [User message];
        NSLog(@"%ld", (long)user.hasUserId);
        user.userId = @"001";
        NSLog(@"%ld", (long)user.hasUserId);
        NSLog(@"%ld", (long)user.hasNick);
        user.nick = @"生命接触";
        NSLog(@"%ld", (long)user.hasNick);
        NSData *dataUser = [user data]; //转为data
        
        //存储到文件中
        NSString *docPath = [self applicationDocumentsDirectory];
        NSString *path = [docPath stringByAppendingFormat:kUserFilderName];
        if ([dataUser writeToFile:path atomically:YES]) {
            NSLog(@"存储成功");
        }
    }
    
    
    
    {
        //读取
        NSString *docPath = [self applicationDocumentsDirectory];
        NSString *path = [docPath stringByAppendingFormat:kUserFilderName];
        
        NSData *dataUser = [NSData dataWithContentsOfFile:path];
        User *user = [User parseFromData:dataUser error:NULL];
        NSLog(@"%@",user);
    }
    
    
    /*
     嵌套型model写入与读取
     */
    
    {
        //创建
        Person *person = [Person message];
        person.name = @"生命接触";
        Eye *eye = [Eye message];
        eye.color = @"#333333";
        [person.eyeArray addObject:eye];
        
        //存储到文件中
        NSData *dataPerson = [person data]; //转为data
        NSString *docPath = [self applicationDocumentsDirectory];
        NSString *path = [docPath stringByAppendingFormat:kPersonFilderName];
        if ([dataPerson writeToFile:path atomically:YES]) {
            NSLog(@"存储成功");
        }
    }
    
    
    {
        //读取
        NSString *docPath = [self applicationDocumentsDirectory];
        NSString *path = [docPath stringByAppendingFormat:kPersonFilderName];
        
        NSData *dataPerson = [NSData dataWithContentsOfFile:path];
        Person *person = [Person parseFromData:dataPerson error:NULL];
        NSLog(@"%@",person);
    }
    
    
}

#pragma mark ------------------------
#pragma mark - Methods

//得到路径
- (NSString *)applicationDocumentsDirectory {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

@end
