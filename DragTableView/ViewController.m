//
//  ViewController.m
//  DragTableView
//
//  Created by Sean on 2018/3/8.
//  Copyright © 2018年 animation. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) UITableView *myTableView;

@property (strong, nonatomic) NSMutableArray *items;
@end

@implementation ViewController

static NSString *kIdentifier = @"cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"自定义";
    
    _myTableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kIdentifier];
        [self.view addSubview:tableView];
        tableView;
    });
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [_myTableView addGestureRecognizer:longPress];
    
    _items = [NSMutableArray new];
    for (int i = 0; i < 10; i++) {
        [_items addObject:@(i)];
    }
}

#pragma mark - TableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentifier forIndexPath:indexPath];
    cell.textLabel.font = [UIFont systemFontOfSize:14.f];
    cell.textLabel.text = [_items[indexPath.row] stringValue];
    return cell;
}

#pragma mark - Action
- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    static NSInteger beginIndex = NSNotFound;
    static UIView *snapshoot = nil;
    
    static CGFloat startY;  //记录手势的位置
    static CGFloat originY; //记录Snapshoot的起点
    
    CGPoint location = [recognizer locationInView:_myTableView];
    NSIndexPath *indexPath = [self.myTableView indexPathForRowAtPoint:location];
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            beginIndex = indexPath.row;
            UITableViewCell *cell = [_myTableView cellForRowAtIndexPath:indexPath];
            
            snapshoot = [self _snapshoot:cell];
            snapshoot.alpha = .5f;
            snapshoot.center = cell.center;
            [_myTableView addSubview:snapshoot];
            
            cell.hidden = true;
            
            startY = location.y;
            originY = CGRectGetMinY(snapshoot.frame);
        }
            break;
        case UIGestureRecognizerStateChanged: {
            if (beginIndex == NSNotFound) return;
            
            CGFloat movement = location.y - startY;
            CGRect rect = snapshoot.frame;
            rect.origin.y = originY + movement;
            snapshoot.frame = rect;
            
            BOOL needRecord;
            NSInteger curIndex;
            NSIndexPath *curIndexPath;
            UITableViewCell *curCell;
            if (movement > 0) { //用户往下滑动的时候
                curIndex = beginIndex + 1;
                if (curIndex >= _items.count) return;
                curIndexPath = [NSIndexPath indexPathForRow:curIndex inSection:0];
                curCell = [_myTableView cellForRowAtIndexPath:curIndexPath];
                if (CGRectGetMaxY(snapshoot.frame) < CGRectGetMidY(curCell.frame)) return;
                
                needRecord = true;
            } else {
                curIndex = beginIndex - 1;
                if (curIndex < 0) return;
                curIndexPath = [NSIndexPath indexPathForRow:curIndex inSection:0];
                curCell = [_myTableView cellForRowAtIndexPath:curIndexPath];
                if (CGRectGetMinY(snapshoot.frame) > CGRectGetMidY(curCell.frame)) return;
                
                needRecord = true;
            }
            
            if (needRecord) {
                [self.myTableView beginUpdates];
                [self.items exchangeObjectAtIndex:curIndex withObjectAtIndex:beginIndex];
                [self.myTableView moveRowAtIndexPath:curIndexPath toIndexPath:[NSIndexPath indexPathForRow:beginIndex inSection:0]];
                [self.myTableView endUpdates];
                
                beginIndex = curIndex;
                startY = location.y;
                originY = CGRectGetMinY(snapshoot.frame);
            }
        }
            break;
        default: {
            UITableViewCell *cell = [_myTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:beginIndex inSection:0]];
            cell.hidden = false;
            
            beginIndex = NSNotFound;
            [snapshoot removeFromSuperview];
            snapshoot = nil;
        }
            
            break;
    }
}

- (UIView *)_snapshoot:(UIView *)aView {
    // 用cell的图层生成UIImage，方便一会显示
    UIGraphicsBeginImageContextWithOptions(aView.bounds.size, NO, 0);
    [aView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //自定义这个快照的样子（下面的一些参数可以自己随意设置）
    UIView *aSnapshoot = [[UIImageView alloc] initWithImage:image];
    aSnapshoot.layer.masksToBounds = false;
    aSnapshoot.layer.shadowRadius = 5.f;
    aSnapshoot.layer.shadowOpacity = 0.5;
    aSnapshoot.layer.shadowOffset = CGSizeZero;
    return aSnapshoot;
}

@end
