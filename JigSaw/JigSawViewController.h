//
//  JigSawViewController.h
//  guligei_AppFactory
//
//  Created by wangyanan on 4/10/14.
//  Copyright (c) 2014 wangyanan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constant.h"

@interface JigSawViewController : UIViewController<UIImagePickerControllerDelegate,UIActionSheetDelegate,UINavigationControllerDelegate>


/**
 *  拼图的逻辑
 http://oddest.nc.hcc.edu.tw/math162.htm
 http://blog.csdn.net/realmagician/article/details/17395035
 http://cnn237111.blog.51cto.com/2359144/1589636
 *
 生成算法：
 1，是否生成有解序列
 
 移动算法：
 可以把空格认为是0，每一次移动就是数字0和周围的数字做一次交换。
 1.比如对状态A，数字0在4个方向上尝试（有的位置不能再移动，忽略该状态）后，得到4个不同的状态A1，A2，A3，A4。那么可以有一棵树以A为根，A1，A2，A3，A4都为叶子节点。检测这4个节点是否已经满足结果，如果是，则已经找到解了。然后顺着这个叶子结点，一路向上逆序到它的父节点，所经过的所有叶子节点，即为每一步的状态。如果否，则下一步。
 2.创建一个集合，记录所有的状态，当新出现的状态是之前未曾有过的，则将该状态，即该叶子节点都放入一个队列。
 3.从该队列中取出一个状态，再进行4个方向上的尝试，即回到第一步。
 4.一直重试，直到队列为空，则说明无解。
 

 */


@property(nonatomic) CGRect destinationFrame;
@property(nonatomic) CGRect bottleFrame;
@property(nonatomic,strong) IBOutlet UIImageView *originImageView;
@property(nonatomic,strong) IBOutlet UIButton *showBtn;
@property(nonatomic,strong) IBOutlet UIButton *finishBtn;

@property(nonatomic,strong) IBOutlet UISlider *rowSlider;
@property(nonatomic,strong) IBOutlet UISlider *columnSlider;


@property(nonatomic,strong) IBOutlet UIButton *helpBtn;
@property(nonatomic,strong) IBOutlet UILabel *timeLabel;



@end
