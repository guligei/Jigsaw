//
//  JigSawViewController.m
//  guligei_AppFactory
//
//  Created by wangyanan on 4/10/14.
//  Copyright (c) 2014 wangyanan. All rights reserved.
//

#import "JigSawViewController.h"
#import "WUIImage.h"
#import "UIImage+resize.h"
#import "AppDelegate.h"
#import "UIView+Toast.h"

#define KUP 1
#define KDOWN 2
#define KLEFT 3
#define KRIGHT 4

@interface NodeInfo : NSObject

@property(nonatomic,strong) NodeInfo *parentNodeInfo;
@property(nonatomic,strong) NSMutableArray *nodeData;

@end

@implementation NodeInfo

-(NodeInfo *)initNodeInfoWithParentNode:(NodeInfo *)pNode nodeData:(NSMutableArray *)nodeData
{
    NodeInfo *info = [[NodeInfo alloc]init];
    info.parentNodeInfo = pNode;
    info.nodeData = nodeData;
    return info;
}

@end


@interface JigSawViewController ()

@property(nonatomic,strong) UIImageView *lastImageView;
@property(nonatomic,strong) NSString *imagePath;
@property(nonatomic,strong) UIButton *transparentBtn;
@property(nonatomic) int row;
@property(nonatomic) int column;
@property(nonatomic) int second;
@property(nonatomic,strong) NSTimer *myTimer;
@property(nonatomic,strong) NSMutableArray *nodeListArray;
@property(nonatomic,strong) NSMutableArray *allStatusArray;
@property(nonatomic,strong) NSMutableArray *rootNodeDataArray;
@property(nonatomic,strong) NSMutableArray *strHashArray;
@property(nonatomic) long long int destOrder;
@property(nonatomic) long long int currentOrder;

@end

@implementation JigSawViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = RGBCOLOR(164, 249, 192);
    self.row = 3;
    self.column = 3;
    self.rowSlider.value = 3;
    self.rowSlider.maximumValue = 6;
    self.rowSlider.minimumValue = 2;
    self.columnSlider.value = 3;
    self.columnSlider.maximumValue = 6;
    self.columnSlider.minimumValue = 2;
    
    [self.rowSlider addTarget:self action:@selector(updateValue:) forControlEvents:UIControlEventValueChanged];
    [self.columnSlider addTarget:self action:@selector(updateValue:) forControlEvents:UIControlEventValueChanged];
    
    CGFloat sliderWidth = (screenW-self.finishBtn.frame.size.width-60)/2;
    self.rowSlider.frame = CGRectMake(self.finishBtn.frame.size.width+15, self.rowSlider.frame.origin.y, sliderWidth, self.rowSlider.frame.size.height);
    self.columnSlider.frame = CGRectMake(self.finishBtn.frame.size.width+20+sliderWidth, self.rowSlider.frame.origin.y, sliderWidth, self.rowSlider.frame.size.height);
    self.originImageView.frame = CGRectMake(0, 64, screenW, screenH-self.showBtn.frame.size.height - 10-64);
    self.originImageView.hidden = YES;
    
   
    [self clearFrontViews];
    [self loadImageView:nil];
    
    
}



/**
 *  清除添加在view上的拼接模块
 *
 */
-(void)clearFrontViews
{
    for (int i = 0; i < _row; i++) {
        for (int j = 0 ; j<_column; j++) {
            NSInteger tag = i+j*_row+1;
            [[self.view viewWithTag:tag]removeFromSuperview];
        }
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



/**
 *  将图片进行切分
 *
 */
-(void)loadImageView:(UIImage *)image
{
    
    if (!image) {
        NSString *filePath = [[NSBundle mainBundle]pathForResource:@"psb" ofType:@"jpg"];;
        image = [[UIImage alloc]initWithContentsOfFile:filePath];
    }
    
    int width =screenW/_row;
    int height = (screenH-self.showBtn.frame.size.height - 10-64)/_column;
    NSMutableArray *randomArr = [self randomByRow:_row byColumn:_column];
    int randomIndex = 0;
    WUIImage *imageUtil = [WUIImage shareImageUtil];
    
//    NSDictionary*dict=[imageUtil SeparateImage:image ByX:_row andY:_column cacheQuality:.8 height:screenH-self.showBtn.frame.size.height - 10-64];

    NSDictionary *dict = [imageUtil SeparateByX:_row andY:_column];
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg",[randomArr objectAtIndex:randomIndex]];
    UIImageView *mImageView = [dict valueForKey:fileName];
    width = mImageView.frame.size.width;
    height = mImageView.frame.size.height;
    CGFloat imageOriginX = (screenW - width*_column)/2;
    _destOrder = [self createDestOrder];
    [self.rootNodeDataArray removeAllObjects];
    for (int i = 0; i < _row; i++) {
        for (int j = 0 ; j<_column; j++) {
            NSString *fileName = [NSString stringWithFormat:@"%@.jpg",[randomArr objectAtIndex:randomIndex]];
            UIImageView *mImageView = [dict valueForKey:fileName];
            CGRect mRect = CGRectMake(imageOriginX+j*(width+1), i*(height+1) + 44+20, width, height);
            mImageView.frame = mRect;
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(move:)];
            [mImageView addGestureRecognizer:tap];
            mImageView.userInteractionEnabled = YES;
            NSString *name = [NSString stringWithFormat:@"%d",_row*_column];
            if ([fileName isEqualToString:[NSString stringWithFormat:@"%@.jpg",name]]) {
                self.lastImageView = mImageView;
                self.lastImageView.hidden = YES;
                [self.finishBtn setImage:[UIImage imageNamed:@"icon_continue"] forState:UIControlStateNormal];
                self.finishBtn.tag = 4000;
                self.destinationFrame = mRect;
                [self.view addSubview:mImageView];
            }else{
                [self.view addSubview:mImageView];
            }
            randomIndex ++;
            NSString *tagName = [NSString stringWithFormat:@"%zd",mImageView.tag];
            [self.rootNodeDataArray addObject:tagName];
        }
    }
    
    NSMutableString *mutiStr = [NSMutableString string];
    for (NSString *str in self.rootNodeDataArray) {
        [mutiStr appendString:str];
    }
    NSLog(@"create order %@\n",mutiStr);
    [self validateOrder];
    
}


-(IBAction)validateOrder
{
    int totalNum = 0;
    for (int i = 0; i<self.rootNodeDataArray.count; i++) {
        NSInteger a = [[self.rootNodeDataArray objectAtIndex:i]integerValue];
        for (int j = i; j<self.rootNodeDataArray.count; j++) {
            NSInteger b = [[self.rootNodeDataArray objectAtIndex:j]integerValue];
            if (a>b) {
                totalNum ++;
            }
        }
    }
    

    if (totalNum%2!=0) {
        NSInteger count = self.rootNodeDataArray.count;
        NSString *tempOne = self.rootNodeDataArray[count-1];
        NSString *tempTwo = self.rootNodeDataArray[count-2];

        self.rootNodeDataArray[count-1] = self.rootNodeDataArray[count-2];
        self.rootNodeDataArray[count-2] = tempOne;
        
        
        UIView *viewOne = [self.view viewWithTag:[tempOne integerValue]];
        UIView *viewTwo = [self.view viewWithTag:[tempTwo integerValue]];
        CGRect viewOneFrame = viewOne.frame;
        viewOne.frame = viewTwo.frame;
        viewTwo.frame = viewOneFrame;
        
    }
    
    
    NSMutableString *mutiStr = [NSMutableString string];
    for (NSString *str in self.rootNodeDataArray) {
        [mutiStr appendString:str];
    }
    NSLog(@"validate  order %@\n",mutiStr);
}

/**
 *  自动拼图，哇哈哈
 */
-(IBAction)autoMove
{
    NodeInfo *nodeInfo = [[NodeInfo alloc]initNodeInfoWithParentNode:NULL nodeData:self.rootNodeDataArray];
    [self.nodeListArray addObject:nodeInfo];
    while (true)
    {
        /**
         *  返回第一个位置的值，并且把这个元素删除
         */
        if (self.nodeListArray.count > 0) {
             NodeInfo *currentNode  = [self.nodeListArray objectAtIndex:0];
            [self.nodeListArray removeObjectAtIndex:0];
            if (_currentOrder == _destOrder) {
//            if ([self checkValidate:currentNode.nodeData]) {
                NSLog(@"success！");
                break;
            }else{
                /**
                 *  1：上,2：下,3：左,4：右,代表四个方向
                 */
                for (int i = 1; i<5; i++)
                {
                    NSMutableArray *step = [self move:currentNode.nodeData direction:i];
                    if (step != NULL)
                    {
                        if (![self checkHaveStatus])
                        {
                            NodeInfo *nodeInfo = [[NodeInfo alloc]initNodeInfoWithParentNode:currentNode nodeData:step];
                            [self.nodeListArray addObject:nodeInfo];
                        }
                    }
                }
            }
        }else{
            NSLog(@"无解....");
            break;
        }
    }
}



/**
 *  是否包含对应状态
 *
 */
//-(BOOL)checkHaveStatus:(NSMutableArray *)nodeData
-(BOOL)checkHaveStatus
{
   
//    for (NSArray *array in self.allStatusArray) {
//        if ([array isEqualToArray:nodeData]) {
//            return true;
//        }
//    }
//    [self.allStatusArray addObject:nodeData];
//    return false;
    
    
    for (NSString *i in self.strHashArray) {
        long long j = [i longLongValue];
        if (j==_currentOrder) {
            return true;
        }
    }
    [self.strHashArray addObject:[NSString stringWithFormat:@"%lld",_currentOrder]];
    return false;
    
}


/**
 * 移动的空白模块
 *
 *  @param cNodeData
 *  @param direction
 *
 *  @return
 */

-(NSMutableArray *)move:(NSMutableArray *)cNodeData direction:(NSInteger)direction
{
    NSMutableArray *currentNodeData = [NSMutableArray arrayWithArray:cNodeData];
    NSInteger pIndex = [currentNodeData indexOfObject:@"9"];
    switch (direction) {
        case KUP:
        {
            if (pIndex < 3) {
                return NULL;
            }else{
                currentNodeData[pIndex] = currentNodeData[pIndex - 3];
                currentNodeData[pIndex - 3] = @"9";
            }
            break;
        }
        case KDOWN:
        {
            if (pIndex > 5)
            {
                return NULL;
            }else
            {
                currentNodeData[pIndex] = currentNodeData[pIndex + 3];
                currentNodeData[pIndex + 3] = @"9";
            }
            break;
        }
        case KLEFT:
        {
            if (pIndex == 0 || pIndex == 3 || pIndex == 6)
            {
                return NULL;
            }
            else
            {
                currentNodeData[pIndex] = currentNodeData[pIndex - 1];
                currentNodeData[pIndex - 1] = @"9";
            }
            break;
        }
            
        default:
        {
            if (pIndex == 2 || pIndex == 5 || pIndex == 8)
            {
                return NULL;
            }
            else
            {
                currentNodeData[pIndex] = currentNodeData[pIndex + 1];
                currentNodeData[pIndex + 1] = @"9";
                
            }
            break;
        }
            
            
            
    }
    
    
    NSString *mValue = currentNodeData[pIndex];

    /**
     *  移动具体模块
     */
//    [self movePlaceFrom:[mValue integerValue]];

    
//    [UIView animateWithDuration:0.5 animations:^{
//    }];
//    
//    
    NSMutableString *mutiStr = [NSMutableString string];
    for (NSString *str in currentNodeData) {
        [mutiStr appendString:str];
    }
    long long i = [mutiStr hash];
    _currentOrder = i;
    NSLog(@"当前hash值%lld",_currentOrder);
    return currentNodeData;
}




/**
 移动 字体模块
 *  根据数值来查找
 */
-(void)movePlaceFrom:(NSInteger)from
{
    
    UIButton *selectBtn = [self.view viewWithTag:from];
//    for (int i = 0; i < _row; i++) {
//        for (int j = 0 ; j<_column; j++) {
//            NSInteger tag = i+j*_row+1;
//            UIButton *btn = [self.view viewWithTag:tag];
//            if ([btn.titleLabel.text integerValue]==from) {
//                selectBtn = btn;
//                break;
//            }
//        }
//    }
    
    if (selectBtn) {
        CGRect frame = selectBtn.frame;
        selectBtn.frame = self.destinationFrame;
        self.destinationFrame= frame;
        
//        
//        [UIView animateWithDuration:0.3 animations:^{
//            CGRect frame = selectBtn.frame;
//            selectBtn.frame = self.destinationFrame;
//            self.destinationFrame= frame;
//        }];
    }
}


-(long long)createDestOrder
{
    NSMutableString *mutiStr = [NSMutableString string];
    for (int i = 1; i<_row*_column+1; i++) {
        [mutiStr appendString:[NSString stringWithFormat:@"%zd",i]];
    }
    long long mValue = [mutiStr hash];
    NSLog(@"create order hash %lld",mValue);
    return mValue;

}



-(BOOL)checkValidate:(NSMutableArray *)nodeDataArray
{
  
    for (int i = 1; i<_row*_column+1; i++) {
        NSLog(@"%zd",i);
        NSInteger tagValue = [[nodeDataArray objectAtIndex:i-1]integerValue];
        if (tagValue != i) {
            return false;
        }
    }
    return YES;
}

/**
 *  产生随机数
 *
 *  @param row
 *  @param column
 *
 *  @return
 */
-(NSMutableArray *)randomByRow:(int)row byColumn:(int)column
{
    NSMutableArray *arr = [NSMutableArray array];
    NSString *object;
    int x = 0;
    int y = 0;
    int z = 0;
    while (arr.count < row*column) {
        x = arc4random() % row;
        y = arc4random() % column;
        z = arc4random() % (row*column);
        z+=1;
        object = [NSString stringWithFormat:@"%d",z];
        if (![arr containsObject:object]) {
            [arr addObject:object];
        }
    }
    return arr;
    
}


/**
 *  四周相邻的判断
 *
 *  @param tap
 */
-(IBAction)move:(UITapGestureRecognizer *)tap
{
    if (self.finishBtn.tag == 5000) {
        [self.view makeToast:@"oops,请戳左下角图标！"];
        return;
    }
    CGFloat dOriginY = tap.view.frame.origin.y - self.destinationFrame.origin.y;
    CGFloat dOrginX = tap.view.frame.origin.x - self.destinationFrame.origin.x;
    
    NSInteger originYValue = fabs(dOriginY);
    NSInteger originXValue = fabs(dOrginX);
    
    BOOL con1 = originYValue == self.destinationFrame.size.height+1 ? YES:NO;
    BOOL con2 = originXValue == self.destinationFrame.size.width+1 ? YES:NO;
    
    if ((con1&&self.destinationFrame.origin.x==tap.view.frame.origin.x) || (con2&&self.destinationFrame.origin.y==tap.view.frame.origin.y)) {
        self.bottleFrame = tap.view.frame;
        tap.view.frame = self.destinationFrame;
        self.destinationFrame = self.bottleFrame;
    }
}


-(void)writeToLocal:(UIImage *)image
{
    [self.originImageView setImage:image];
}



/**
 *  点击完成出发操作
 *
 *  @param btn
 */

-(IBAction)finishAction:(UIButton *)btn
{
    
    if (self.originImageView.hidden == NO) {
        self.originImageView.hidden = YES;
        self.transparentBtn.hidden = YES;
    }
    
    
    self.lastImageView.frame = self.destinationFrame;
    if (btn.tag == 5000) {
        self.lastImageView.hidden = YES;
        [btn setImage:[UIImage imageNamed:@"icon_continue"] forState:UIControlStateNormal];
        btn.tag = 4000;
        [_myTimer setFireDate:[NSDate distantPast]];
    }else{
        self.lastImageView.hidden = NO;
        [btn setImage:[UIImage imageNamed:@"icon_end"] forState:UIControlStateNormal];
        btn.tag = 5000;
        [_myTimer setFireDate:[NSDate distantFuture]];
        
    }
    
}




/**
 *  显示隐藏原图
 */

-(IBAction)showOriginImageView
{
    self.originImageView.hidden = !self.originImageView.hidden;
    self.transparentBtn.hidden = self.originImageView.hidden ;
    if (self.originImageView.hidden == NO) {
        [self.view bringSubviewToFront:self.transparentBtn];
        [self.view bringSubviewToFront:self.originImageView];
    }
    //    UIImage *image = [UIImage imageWithContentsOfFile:self.imagePath];
    //    [self.originImageView setImage:image];
    
}




/**
 *  滑动slider 调用
 *
 *  @param slider
 */

-(IBAction)updateValue:(UISlider *)slider
{
    _second = 0;
    [_myTimer setFireDate:[NSDate distantPast]];
    if (self.originImageView.hidden == NO) {
        self.originImageView.hidden = YES;
        self.transparentBtn.hidden = YES;
    }
    
    
    static int beforeIndex = 0;
    int mValue = slider.value;
    if (beforeIndex == mValue) {
        return;
    }
    beforeIndex = mValue;
    
    [self clearFrontViews];
    
    if (slider.tag == 2000) {
        self.row = mValue;
    }else{
        self.column = mValue;
    }
    
    NSLog(@"%d",mValue);
    
    NSInteger r = arc4random() % 255;
    NSInteger g = arc4random() % 255;
    NSInteger b = arc4random() % 255;
    
    self.view.backgroundColor = RGBCOLOR(r, g, b);
    [self loadImageView:self.originImageView.image];
}





/**
 *  添加图片
 *
 *  @param sender
 */
- (IBAction)addPic:(id)sender
{
    UILongPressGestureRecognizer *gesture = (UILongPressGestureRecognizer *)sender;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照", @"相册", nil];
        [actionSheet showInView:self.view];
    }
    
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        UIImagePickerController* controller = [[UIImagePickerController alloc] init];
        controller.delegate = self;
        if (buttonIndex == 0) {
            if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                return;
            }
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
        }
        else {
            controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        controller.allowsEditing = NO;
        [self presentViewController:controller animated:YES completion:Nil];
    }
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:Nil];
    UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self writeToLocal:image];
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        picker.view.frame = CGRectMake(0, 20,SharedAppDelegate.window.frame.size.width, SharedAppDelegate.window.frame.size.height - 20);
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
    [self clearFrontViews];
    [self loadImageView:image];
    [self.myTimer fire];
}



- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [SharedAppDelegate.window.rootViewController dismissViewControllerAnimated:YES completion:Nil];
    
}


-(UIButton *)transparentBtn
{
    if (!_transparentBtn) {
        _transparentBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _transparentBtn.backgroundColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.8];
        _transparentBtn.frame = CGRectMake(0, 0, screenW, screenH-40);
        _transparentBtn.hidden = YES;
        [self.view addSubview:_transparentBtn];
    }
    return _transparentBtn;
    
}



-(IBAction)helpAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
}


-(IBAction)updateTime
{
    _second ++;
    NSInteger minute = _second/60;
    NSInteger ssecond = _second%60;
    self.timeLabel.text = [NSString stringWithFormat:@"%zd分%zd秒",minute,ssecond];
}


-(NSTimer *)myTimer
{
    if (!_myTimer) {
        _myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    }
    return _myTimer;
}


-(NSMutableArray *)allStatusArray
{
    if (!_allStatusArray) {
        _allStatusArray = [NSMutableArray array];
    }
    return _allStatusArray;
}


-(NSMutableArray *)nodeListArray
{
    if (!_nodeListArray) {
        _nodeListArray = [NSMutableArray array];
    }
    return _nodeListArray;
    
}


-(NSMutableArray *)rootNodeDataArray
{
    if (!_rootNodeDataArray) {
        _rootNodeDataArray = [NSMutableArray array];
    }
    return _rootNodeDataArray;
    
}


-(NSMutableArray *)strHashArray
{
    if (!_strHashArray) {
        _strHashArray = [NSMutableArray array];
    }
    return _strHashArray;
}

@end
