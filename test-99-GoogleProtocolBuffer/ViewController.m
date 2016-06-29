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
        NSLog(@"%ld", (long)user.hasBalance);
        user.balance = 15.51;
        NSLog(@"%ld", (long)user.hasBalance);
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
        
        
        /*
         ----------------------
         下面通过自己写代码解析Protocol Buffer
         ----------------------
         */
        
        
        //打印出来看byte
        Byte *byte = (Byte *)dataUser.bytes;
        for (NSInteger i = 0; i < dataUser.length; i++) {
            NSLog(@"%d\n",byte[i]);
        }
        
        
//        unsigned char pMem[] = {0xf6,0x28,0x78,0x41};
//        float *p = (float*)pMem;
//        printf("%g\r\n",*p);
//        
//        Byte *a = (Byte *)dataUser.bytes;
//        Byte *b = {&a[20],&a[21],&a[22],&a[23]};
//        NSLog(@"%f", *(float*)b);
        
        NSInteger index = 0;
        NSInteger tag = ReadVarint32((Byte *)dataUser.bytes, index, (size_t *)&index);
        
        NSInteger userIdTag = ChangeToVarint32(1 << 3 | 2);  //userId的tag值
        if (userIdTag == tag) {
            NSInteger length = ReadVarint32((Byte *)dataUser.bytes, index, (size_t *)&index);
            NSData *dataUserId = [dataUser subdataWithRange:NSMakeRange(index, length)];
            NSString *userId = [[NSString alloc] initWithData:dataUserId encoding:NSUTF8StringEncoding];
            index += length;
            NSLog(@"用户ID：%@", userId);
        }
        
        tag = ReadVarint32((Byte *)dataUser.bytes, index, (size_t *)&index);
        
        NSInteger nickTag = ChangeToVarint32(2 << 3 | 2);   //nick的tag值
        if (nickTag == tag) {
            NSInteger length = ReadVarint32((Byte *)dataUser.bytes, index, (size_t *)&index);
            NSData *dataNick = [dataUser subdataWithRange:NSMakeRange(index, length)];
            NSString *nick = [[NSString alloc] initWithData:dataNick encoding:NSUTF8StringEncoding];
            index += length;
            NSLog(@"昵称：%@", nick);
        }
        
        tag = ReadVarint32((Byte *)dataUser.bytes, index, (size_t *)&index);
        
        NSInteger balanceTag = ChangeToVarint32(4 << 3 | 5);   //balance的tag值
        if (balanceTag == tag) {
            float balance;
            [dataUser getBytes:&balance range:NSMakeRange(index, 4)];
            index += 4;
            NSLog(@"余额：%lf", (double)balance);
        }
        
    }
    
    /*
     嵌套型model写入与读取
     */
    
    {
        //创建
        Person *person = [Person message];
        person.name = @"生命接触";
        Foot *foot = [Foot message];
        foot.width = 35;
        foot.height = 70;
        person.foot = foot;
        Eye *eyes1 = [Eye message];
        eyes1.color = @"#333333";
        [person.eyesArray addObject:eyes1];
        Eye *eyes2 = [Eye message];
        eyes2.color = @"#999999";
        [person.eyesArray addObject:eyes2];
        
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
        
        
        /*
         ----------------------
         下面通过自己写代码解析Protocol Buffer
         ----------------------
         */
        
        
        NSInteger index = 0;
        NSInteger tag = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);
        
        NSInteger nameTag = ChangeToVarint32(1 << 3 | 2);   //name的tag值
        if (nameTag == tag) {
            NSInteger length = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);
            NSData *dataName = [dataPerson subdataWithRange:NSMakeRange(index, length)];
            NSString *name = [[NSString alloc] initWithData:dataName encoding:NSUTF8StringEncoding];
            index += length;
            NSLog(@"名字：%@", name);
        }
        
        tag = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);
        
        NSInteger footTag = ChangeToVarint32(2 << 3 | 2);   //foot的tag值
        if (footTag == tag) {
            NSInteger length = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);  //Foot这个model的长度
            NSInteger footByteIndex = index;    //当前foot这个model所在字节的其实位置
            
            tag = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);
            
            NSInteger widthTag = ChangeToVarint32(1 << 3 | 0);   //宽度的tag值
            if (widthTag == tag) {
                NSInteger width = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);
                NSLog(@"宽度：%ld", (long)width);
            }
            
            tag = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);
            
            NSInteger heightTag = ChangeToVarint32(2 << 3 | 0);   //宽度的tag值
            if (heightTag == tag) {
                NSInteger height = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);
                NSLog(@"高度：%ld", (long)height);
            }
            
            //如果在foot中读取的字节总数等于foot的字节总数，则说明读取foot这个model完成（＊＊＊在实际开发中不能再这里才判断，应该没读取一个byte都判断一下是否超过length）
            if (index - footByteIndex == length) {
                NSLog(@"Foot这个model读取完成喽");
            }
        }
        
        tag = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);
        
        NSInteger eyesTag = ChangeToVarint32(3 << 3 | 2);   //eyes的start tag值
        
        if (eyesTag == tag) {
            NSInteger length = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);  //eyes这个model的长度
            NSInteger eyesByteIndex = index;    //当前foot这个model所在字节的其实位置
            
            tag = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);

            NSInteger colorTag = ChangeToVarint32(1 << 3 | 2);   //颜色的tag值
            if (colorTag == tag) {
                NSInteger colorLenght = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);
                NSData *dataColor = [dataPerson subdataWithRange:NSMakeRange(index, colorLenght)];
                NSString *color = [[NSString alloc] initWithData:dataColor encoding:NSUTF8StringEncoding];
                index += colorLenght;
                NSLog(@"颜色：%@", color);
            }
            
            //如果在eyes中读取的字节总数等于eyes的字节总数，则说明读取eyes这个model完成（＊＊＊在实际开发中不能再这里才判断，应该没读取一个byte都判断一下是否超过length）
            if (index - eyesByteIndex == length) {
                NSLog(@"Eyes这个model读取完成喽");
            }
        }
        
        tag = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);
        
        eyesTag = ChangeToVarint32(3 << 3 | 2);   //eyes的start tag值
        
        if (eyesTag == tag) {
            NSInteger length = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);  //eyes这个model的长度
            NSInteger eyesByteIndex = index;    //当前foot这个model所在字节的其实位置
            
            tag = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);
            
            NSInteger colorTag = ChangeToVarint32(1 << 3 | 2);   //颜色的tag值
            if (colorTag == tag) {
                NSInteger colorLenght = ReadVarint32((Byte *)dataPerson.bytes, index, (size_t *)&index);
                NSData *dataColor = [dataPerson subdataWithRange:NSMakeRange(index, colorLenght)];
                NSString *color = [[NSString alloc] initWithData:dataColor encoding:NSUTF8StringEncoding];
                index += colorLenght;
                NSLog(@"颜色：%@", color);
            }
            
            //如果在eyes中读取的字节总数等于eyes的字节总数，则说明读取eyes这个model完成（＊＊＊在实际开发中不能再这里才判断，应该没读取一个byte都判断一下是否超过length）
            if (index - eyesByteIndex == length) {
                NSLog(@"Eyes这个model读取完成喽");
            }
        }
        
        NSLog(@"读取完成");
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

/**< 从byte中指定index位置读取varint32，返回读取的值，结束位置存储在endLocation中 */
static int32_t ReadVarint32(Byte *bytes, int8_t index, size_t *endLoaction) {
    *endLoaction = index;
    int8_t tmp = ((int8_t *)bytes)[(*endLoaction)++];
    if (tmp >= 0) {
        return tmp;
    }
    int32_t result = tmp & 0x7f;
    if ((tmp = ((int8_t *)bytes)[(*endLoaction)++]) >= 0) {
        result |= tmp << 7;
    } else {
        result |= (tmp & 0x7f) << 7;
        if ((tmp = ((int8_t *)bytes)[(*endLoaction)++]) >= 0) {
            result |= tmp << 14;
        } else {
            result |= (tmp & 0x7f) << 14;
            if ((tmp = ((int8_t *)bytes)[(*endLoaction)++]) >= 0) {
                result |= tmp << 21;
            } else {
                result |= (tmp & 0x7f) << 21;
                result |= (tmp = ((int8_t *)bytes)[(*endLoaction)++]) << 28;
                if (tmp < 0) {
                    // Discard upper 32 bits.
                    for (int i = 0; i < 5; i++) {
                        if (((int8_t *)bytes)[(*endLoaction)++] >= 0) {
                            return result;
                        }
                    }
                    
                    //Invalid VarInt32
                    abort();
                }
            }
        }
    }
    return result;
}


/**< 将正常的int类型转换成varint32 */
static int32_t ChangeToVarint32(int32_t value) {
    unsigned char charValue[] = {value};
    size_t index = 0;
    int32_t varintValue = ReadVarint32((Byte *)charValue, index, &index);
    
    return varintValue;
}

@end
