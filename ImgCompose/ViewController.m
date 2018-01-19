//
//  ViewController.m
//  ImgCompose
//
//  Created by KayCM on 2017/11/20.
//  Copyright © 2017年 KayCM. All rights reserved.
//

#import "ViewController.h"
#import "CustomQRCode.h"
#import "ViewController2.h"
@interface ViewController ()
@property(nonatomic,strong)NSMutableArray *ImgStyle;
@property(nonatomic,strong)UIImageView *img;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _ImgStyle = [NSMutableArray new];
    
//
    [_ImgStyle addObject:@{@"Type":@"bg",@"content":@"http://static.yoro.com/res/26bc5014b392411b822f35956dbd6e82"}];
    [_ImgStyle addObject:@{@"Type":@"img",@"content":@"http://static.yoro.com/res/ecdc22faee354210835aba3333bb723f",@"position":@[@0,@0,@750,@442]}];
    [_ImgStyle addObject:@{@"Type":@"txt",@"content":@"测试123ABC",@"position":@[@100,@100,@200,@200],@"color":@"#123000",@"size":@"60"}];
    [_ImgStyle addObject:@{@"Type":@"qr",@"content":@"http://koubei.rosepie.com/diary/index?u=1217859&s=1043190&d=1511163113&t=1",@"position":@[@500,@1200,@100,@100],@"color":@"FF6464",@"size":@"100"}];
    
    _img = [[UIImageView alloc] initWithFrame:self.view.bounds];
    

    [self.view addSubview:_img];

    [self MakeCoverWithStyleArr:[_ImgStyle copy]];
    
    UIButton *A = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 30)];
    
    A.backgroundColor = [UIColor redColor];
    
    [self.view addSubview:A];
    
    [A addTarget:self action:@selector(goNext) forControlEvents:UIControlEventTouchUpInside];
    
}

-(void)goNext{
    
    ViewController2 *v2 = [ViewController2 new];
    
    [self.navigationController pushViewController:v2 animated:YES];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}


//图片下载,数据整理
-(void)MakeCoverWithStyleArr:(NSArray *)StylesArr{
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    __block NSMutableArray *SylArr = [NSMutableArray new];
    
    __block UIImage *backgroundImg = nil;
    
    for (NSDictionary *Style in StylesArr) {
        
        if ([[Style objectForKey:@"Type"] isEqualToString:@"img"]) {
            
            NSString *imgUrl = [Style objectForKey:@"content"];
            dispatch_group_async(group, queue, ^{
                NSURL *url = [NSURL URLWithString:imgUrl];
                NSData *data = [NSData dataWithContentsOfURL:url];
                UIImage *image = [UIImage imageWithData:data];
            
                NSValue *RectValue =  [NSValue valueWithCGRect:CGRectMake([[[Style objectForKey:@"position"] objectAtIndex:0] intValue],
                                                                          [[[Style objectForKey:@"position"] objectAtIndex:1] intValue],
                                                                          [[[Style objectForKey:@"position"] objectAtIndex:2] intValue],
                                                                          [[[Style objectForKey:@"position"] objectAtIndex:3] intValue])];
                
                [SylArr addObject:@{@"type":@"img",@"content":image,@"rect":RectValue}];
            });
            
        }else if ([[Style objectForKey:@"Type"] isEqualToString:@"txt"]) {
            
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
            
            UIColor *Color = [self colorWithHexString:[Style objectForKey:@"color"] alpha:1];
            
            NSDictionary *dic = @{NSFontAttributeName:[UIFont systemFontOfSize:[[Style objectForKey:@"size"] intValue]],
                                  NSParagraphStyleAttributeName:style,
                                  NSForegroundColorAttributeName:Color};
            
            NSValue *RectValue =  [NSValue valueWithCGRect:CGRectMake([[[Style objectForKey:@"position"] objectAtIndex:0] intValue],
                                                                      [[[Style objectForKey:@"position"] objectAtIndex:1] intValue],
                                                                      [[[Style objectForKey:@"position"] objectAtIndex:2] intValue],
                                                                      [[[Style objectForKey:@"position"] objectAtIndex:3] intValue])];
            [SylArr addObject:@{@"type":@"txt",@"content":[Style objectForKey:@"content"],@"rect":RectValue,@"style":dic}];
            
        }else if ([[Style objectForKey:@"Type"] isEqualToString:@"bg"]) {
            
            NSString *imgUrl = [Style objectForKey:@"content"];
            dispatch_group_async(group, queue, ^{
                NSURL *url = [NSURL URLWithString:imgUrl];
                NSData *data = [NSData dataWithContentsOfURL:url];
                backgroundImg = [UIImage imageWithData:data];
    
            });
            
        }else if ([[Style objectForKey:@"Type"] isEqualToString:@"qr"]){
            
            UIColor *Color = [self colorWithHexString:[Style objectForKey:@"color"] alpha:1];
            
            NSValue *RectValue =  [NSValue valueWithCGRect:CGRectMake([[[Style objectForKey:@"position"] objectAtIndex:0] intValue],
                                                                      [[[Style objectForKey:@"position"] objectAtIndex:1] intValue],
                                                                      [[[Style objectForKey:@"position"] objectAtIndex:2] intValue],
                                                                      [[[Style objectForKey:@"position"] objectAtIndex:3] intValue])];
            
            [SylArr addObject:@{@"type":@"qr",@"content":[Style objectForKey:@"content"],@"rect":RectValue,@"color":Color,@"size":[NSNumber numberWithInt:[[Style objectForKey:@"size"] intValue]]}];
            
        }
        
    }
    
    
    //队列完成notice
    dispatch_group_notify(group, queue, ^{
    
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"%@",SylArr);
            NSLog(@"bg:%@",backgroundImg);
            _img.image = [self ComposeInBgImage:backgroundImg WithStyleArr:SylArr];
            
           
        });
    });
    
    
}



-(UIImage *)ComposeInBgImage:(UIImage*)BgImage WithStyleArr:(NSArray*)StylesArr{
    
    UIGraphicsBeginImageContext(BgImage.size);
    //背景图渲染
    [BgImage drawInRect:CGRectMake(0, 0, BgImage.size.width, BgImage.size.height)];
    
    //先渲染图片,图片渲染完成后,再次渲染文字.混在一个循环内,文字容易被图片给覆盖
    for (NSDictionary *Style in StylesArr) {
        
        if ([[Style objectForKey:@"type"] isEqualToString:@"img"]) {
            //图片渲染
            UIImage *img = [Style objectForKey:@"content"];
            
            CGRect Rect = [[Style objectForKey:@"rect"] CGRectValue];
            
            [img drawInRect:Rect];
            
        }else {
            NSLog(@"Wtf..................?");
        }
        
    }
    
    for (NSDictionary *Style in StylesArr) {
        
        if ([[Style objectForKey:@"type"] isEqualToString:@"txt"]) {
            //文字渲染
            NSString *text = [Style objectForKey:@"content"];
            
            CGRect Rect = [[Style objectForKey:@"rect"] CGRectValue];
            
            NSDictionary *dic = [Style objectForKey:@"style"];
            
            [text drawInRect:Rect withAttributes:dic];
            
        }
        
    }
        
    for (NSDictionary *Style in StylesArr) {
        
        if ([[Style objectForKey:@"type"] isEqualToString:@"qr"]) {
            
            CustomQRCode *QR = [CustomQRCode new];
            
            UIImage *QRIMG = [QR QRCodeForString:[Style objectForKey:@"content"] withSize:[[Style objectForKey:@"size"] floatValue] withQRColor:[Style objectForKey:@"color"] withLogoImage:[UIImage imageNamed:@"logo"] withLogoBgColor:nil withLogoSize:20];
            
            CGRect Rect = [[Style objectForKey:@"rect"] CGRectValue];
            
            [QRIMG drawInRect:Rect];
        }
        
    }
    
    
    
    
    UIImage *restultImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return restultImage;
}


- (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha
{
    //  删除字符串中的空格
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    //  String should be 6 or 8 characters
    if ([cString length] < 6)
    {
        return [UIColor clearColor];
    }
    //  strip 0X if it appears
    //  如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"0X"])
    {
        cString = [cString substringFromIndex:2];
    }
    //  如果是#开头的，那么截取字符串，字符串从索引为1的位置开始，一直到末尾
    if ([cString hasPrefix:@"#"])
    {
        cString = [cString substringFromIndex:1];
    }
    if ([cString length] != 6)
    {
        return [UIColor clearColor];
    }
    
    //  Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    //  r
    NSString *rString = [cString substringWithRange:range];
    //  g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    //  b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    //  Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float)r / 255.0f) green:((float)g / 255.0f) blue:((float)b / 255.0f) alpha:alpha];
}


@end
