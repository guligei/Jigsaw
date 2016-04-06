//
//  UIImage-Handling.m
//  WinAdDemo
//
//  Created by frank on 11-5-13.
//  Copyright 2011 wongf70@gmail.com All rights reserved.
//

#import "WUIImage.h"
#import "UIImage+resize.h"
#define screenW [UIScreen mainScreen].bounds.size.width
#define screenH [UIScreen mainScreen].bounds.size.height


@interface WUIImage()

@property(nonatomic,strong) NSMutableDictionary *basiDic;

@end

@implementation WUIImage



+(WUIImage *)shareImageUtil
{
    static WUIImage *imageUtilInstance = nil;
    if (!imageUtilInstance) {
        imageUtilInstance = [[WUIImage alloc]init];
    }
    return imageUtilInstance;
}



+ (UIImage *)image:(UIImage*)image byScalingToSize:(CGSize)targetSize {
    UIImage *sourceImage = image;
    UIImage *newImage = nil;
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = CGPointZero;
    thumbnailRect.size.width  = targetSize.width;
    thumbnailRect.size.height = targetSize.height;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage ;
}

-(NSDictionary*)SeparateByX:(int)x andY:(int)y
{
    CGSize originSize = CGSizeMake(screenW, screenW);

    float _xstep=originSize.width*1.0/(y);
    float _ystep=originSize.height*1.0/(x);
    [self.basiDic removeAllObjects];
    
    for (int i=0; i<x; i++)
    {
        for (int j=0; j<y; j++)
        {
            CGRect rect=CGRectMake(_xstep*j, _ystep*i, _xstep, _ystep);
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = rect;
            btn.layer.borderColor = [UIColor blackColor].CGColor;
            btn.layer.borderWidth = 1;
            [btn.titleLabel setFont:[UIFont systemFontOfSize:30.0]];
            NSString *name = [NSString stringWithFormat:@"%d",i+j*x+1];
            [btn setTitle:name forState:UIControlStateNormal];
            btn.tag = [name integerValue];
            btn.backgroundColor = [UIColor lightGrayColor];
            
            /**
             *  两种命名的方式，一个是 行列的乘积，一个是递增
             */
//            NSString*btnName=[NSString stringWithFormat:@"%d%d.jpg",i,j];
            NSString*bName=[NSString stringWithFormat:@"%@.jpg",name];
            [self.basiDic setObject:btn forKey:bName];
           
        }
    }
    return self.basiDic;
}


-(NSDictionary*)SeparateImage:(UIImage*)image ByX:(int)x andY:(int)y cacheQuality:(float)quality height:(CGFloat)height
{
   
    CGSize originSize = image.size;
    if (originSize.width > screenW)
        originSize = CGSizeMake(screenW, screenH);
    
//    image = [WUIImage image:image byScalingToSize:originSize];
    image =  [image imageByScalingToDefaultWidth:screenW];
    image = [image imageByScalingToDefaultSizeAccordingToHeight:height];
	if (x<1) {
		NSLog(@"illegal x!");
		return nil;
	}else if (y<1) {
		NSLog(@"illegal y!");
		return nil;
	}
	if (![image isKindOfClass:[UIImage class]]) {
		NSLog(@"illegal image format!");
		return nil;
	}
	float _xstep=image.size.width*1.0/(y);
	float _ystep=image.size.height*1.0/(x);
    [self.basiDic removeAllObjects];
	for (int i=0; i<x; i++) 
	{
		for (int j=0; j<y; j++) 
		{
			CGRect rect=CGRectMake(_xstep*j, _ystep*i, _xstep, _ystep);
			CGImageRef imageRef=CGImageCreateWithImageInRect([image CGImage],rect);
			UIImage* elementImage=[UIImage imageWithCGImage:imageRef];
			UIImageView*_imageView=[[UIImageView alloc] initWithImage:elementImage];
			_imageView.frame=rect;
			NSString*_imageString=[NSString stringWithFormat:@"%d%d.jpg",i,j];
			[self.basiDic setObject:_imageView forKey:_imageString];
			if (quality<=0)
			{
				continue;
			}
//			quality=(quality>1)?1:quality;
//			NSString*_imagePath=[NSHomeDirectory() stringByAppendingPathComponent:_imageString];
//			NSData* _imageData=UIImageJPEGRepresentation(elementImage, quality);
//			[_imageData writeToFile:_imagePath atomically:NO];
		}
	}
	return self.basiDic;
}


-(NSMutableDictionary *)basiDic
{
    if (!_basiDic) {
        _basiDic = [[NSMutableDictionary alloc]initWithCapacity:1];;
    }
    return _basiDic;
}
@end
