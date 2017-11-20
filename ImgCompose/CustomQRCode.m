//
//  CustomQRCode.m
//  ImgCompose
//
//  Created by KayCM on 2017/11/20.
//  Copyright © 2017年 KayCM. All rights reserved.
//

#import "CustomQRCode.h"

@implementation CustomQRCode

-(UIImage *)QRCodeForString:(NSString *)string withSize:(CGFloat)QRImgSize withQRColor:(UIColor*)QRColor withLogoImage:(UIImage*)LogoImg withLogoBgColor:(UIColor*)LogoBgColor withLogoSize:(CGFloat)logoImgSize{
    
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];//通过kvo方式给一个字符串，生成二维码
    [filter setValue:@"H" forKey:@"inputCorrectionLevel"];//设置二维码的纠错水平，越高纠错水平越高，可以污损的范围越大
    CIImage *outPutImage = [filter outputImage];//拿到二维码图片
    
    UIImage *QRImg = [self createNonInterpolatedUIImageFormCIImage:outPutImage withSize:QRImgSize waterImageSize:logoImgSize];
    
    //颜色处理
    if (QRColor) {
        
        NSMutableArray *QRArr = [self changeUIColorToRGB:QRColor];
        
        QRImg = [self imageBlackToTransparent:QRImg withRed:[[QRArr objectAtIndex:0] floatValue]  andGreen:[[QRArr objectAtIndex:1] floatValue] andBlue:[[QRArr objectAtIndex:2] floatValue]];
        
    }
    
    if (!LogoBgColor) {
        LogoBgColor = [UIColor whiteColor];
    }
    
    if (LogoImg) {
        QRImg = [self LogoAddInImg:QRImg withLogoImg:LogoImg WithLogoBgColor:LogoBgColor withLogoSize:logoImgSize];
    }

    
    return QRImg;
}


//图片生成
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size waterImageSize:(CGFloat)waterImagesize{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    //创建一个DeviceGray颜色空间
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    //CGBitmapContextCreate(void * _Nullable data, size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow, CGColorSpaceRef  _Nullable space, uint32_t bitmapInfo)
    //width：图片宽度像素
    //height：图片高度像素
    //bitsPerComponent：每个颜色的比特值，例如在rgba-32模式下为8
    //bitmapInfo：指定的位图应该包含一个alpha通道。
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    //创建CoreGraphics image
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef); CGImageRelease(bitmapImage);
    
    //原图
    UIImage *outputImage = [UIImage imageWithCGImage:scaledImage];
    
    return outputImage;
}

//颜色改变
- (UIImage*)imageBlackToTransparent:(UIImage*)image withRed:(CGFloat)red andGreen:(CGFloat)green andBlue:(CGFloat)blue{
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage); // 遍历像素
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++){
        if ((*pCurPtr & 0xFFFFFF00) < 0x99999900) // 将白色变成透明
        {
            // 改成下面的代码，会将图片转成想要的颜色
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[3] = red; //0~255
            ptr[2] = green;
            ptr[1] = blue;
        } else {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
        }
    }
    // 输出图片
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, nil);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace, kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef]; // 清理空间
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return resultUIImage;
}


//生成logo背景,添加logo
- (UIImage *)LogoAddInImg:(UIImage*)Img withLogoImg:(UIImage*)logoImg WithLogoBgColor:(UIColor *)color withLogoSize:(CGFloat)logoSize{
    
    UIGraphicsBeginImageContext(Img.size); //在这个范围内开启一段上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    [Img drawInRect:CGRectMake(0,0 , Img.size.width, Img.size.height)];
    
    //在这段上下文中获取到颜色UIColor
    CGContextSetFillColorWithColor(context, [color CGColor]);
    
    //用这个颜色填充这个上下文
    CGContextFillRect(context, CGRectMake((Img.size.width-logoSize)/2.0, (Img.size.width-logoSize)/2.0, logoSize, logoSize));
    
    //把logo图画到生成的二维码图片上，注意尺寸不要太大（最大不超过二维码图片的%30），太大会造成扫不出来
    [logoImg drawInRect:CGRectMake(((Img.size.width-logoSize)/2.0)+2, ((Img.size.width-logoSize)/2.0)+2, logoSize-4, logoSize-4)];
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    
    return newPic;
}

//UIColor 转RGB
- (NSMutableArray *) changeUIColorToRGB:(UIColor *)color
{
    NSMutableArray *RGBStrValueArr = [[NSMutableArray alloc] init];
    NSString *RGBStr = nil;
    //获得RGB值描述
    NSString *RGBValue = [NSString stringWithFormat:@"%@",color];
    //将RGB值描述分隔成字符串
    NSArray *RGBArr = [RGBValue componentsSeparatedByString:@" "];
    //获取红色值
    int r = [[RGBArr objectAtIndex:1] intValue] * 255;
    RGBStr = [NSString stringWithFormat:@"%d",r];
    [RGBStrValueArr addObject:RGBStr];
    //获取绿色值
    int g = [[RGBArr objectAtIndex:2] intValue] * 255;
    RGBStr = [NSString stringWithFormat:@"%d",g];
    [RGBStrValueArr addObject:RGBStr];
    //获取蓝色值
    int b = [[RGBArr objectAtIndex:3] intValue] * 255;
    RGBStr = [NSString stringWithFormat:@"%d",b];
    [RGBStrValueArr addObject:RGBStr];
    //返回保存RGB值的数组
    return RGBStrValueArr;
}


@end
