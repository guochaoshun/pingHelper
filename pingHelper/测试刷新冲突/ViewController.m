//
//  ViewController.m
//  测试刷新冲突
//
//  Created by 郭朝顺 on 2021/9/24.
//

#import "ViewController.h"
#import "ULPingHelper.h"

@interface ViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>


@property (strong, nonatomic) UICollectionView *collectionView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self collectionView];

    ULPingHelper *pingHelper = [[ULPingHelper alloc] init];
    pingHelper.host = @"api.kilamanbo.com";

    [NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        NSLog(@"开始");
        [pingHelper pingWithBlock:^(BOOL isSuccess, NSString * _Nonnull ipString, NSTimeInterval latency) {
            if (isSuccess) {
                NSLog(@"成功 %@ %@  %d ms",pingHelper.host,ipString,(int)latency);
            } else {
                NSLog(@"失败 %@ %@  %d ms",pingHelper.host,ipString,(int)latency);
            }
        }];
    }];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {



}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 100;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"UICollectionViewCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor orangeColor];
    NSLog(@"刷新cell -- %@",@(indexPath.item));
    return cell;
}



- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(120, 120);
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 100, 300, 300) collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor grayColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"UICollectionViewCell"];
        [self.view addSubview:_collectionView];
    }
    return _collectionView;
}



@end
