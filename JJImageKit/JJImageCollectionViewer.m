//
//  JJImageCollectionViewer.m
//  ImageViewerFramework
//
//  Created by Julian Jans on 29/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import "JJImageCollectionViewer.h"
#import "JJImageCollectionCell.h"
#import "JJImageDownloader.h"


#define INSET_SPACING 2.0f


@interface JJImageCollectionViewer () <UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate>

/// The vertical scrolling UICollectionView
@property (nonatomic, strong) UICollectionView *collectionView;

@end


@implementation JJImageCollectionViewer

static NSString * const reuseIdentifier = @"Cell";

@synthesize images = _images;

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the initial count of the rows horizontally to nice safe number
    self.imagesPerRow = 3;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    self.collectionView.scrollEnabled = YES;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.collectionView];
    
    // Register cell classes
    [self.collectionView registerClass:[JJImageCollectionCell class] forCellWithReuseIdentifier:reuseIdentifier];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[JJImageDownloader sharedClient] cancelPendingTasks];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.collectionView.frame = self.view.bounds;
    [self.collectionView.collectionViewLayout invalidateLayout];
}


#pragma mark - Handling the rotation

- (NSIndexPath *)visibleIndexPath
{
    CGRect visibleRect = (CGRect){.origin = self.collectionView.contentOffset, .size = self.collectionView.bounds.size};
    CGPoint visiblePoint = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect));
    return [self.collectionView indexPathForItemAtPoint:visiblePoint];
}

// Needed to scroll back to the correct view
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    NSIndexPath *desiredIndexPath = [[self visibleIndexPath] copy];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        [self.collectionView scrollToItemAtIndexPath:desiredIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.collectionView scrollToItemAtIndexPath:desiredIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.collectionView scrollToItemAtIndexPath:desiredIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }];
}


#pragma mark - Image Storage & Delegate

- (void)setImages:(NSArray *)images
{
    NSAssert(!_images || _images.count == images.count, @"Cannot change the array size!");
    
    BOOL shouldReloadEntireCollection = _images.count != images.count;
    
    // Get a list of all the index paths that have been updated
    NSMutableArray *indexesToUpdate = [NSMutableArray array];
    if (_images) {
        [images enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![obj isEqual:[self->_images objectAtIndex:idx]]) {
                [indexesToUpdate addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
            }
        }];
    }
    
    _images = images;
    
    if (shouldReloadEntireCollection) {
        [self.collectionView reloadData];
    } else if (indexesToUpdate.count) {
        // Update the changed index paths in batches
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadItemsAtIndexPaths:indexesToUpdate];
        } completion:^(BOOL finished) {}];
    }
}

- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (index) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animated];
    }
}


#pragma mark - UICollectionView Layout Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat size = ((self.view.bounds.size.width - (INSET_SPACING * self.imagesPerRow - 1)) / self.imagesPerRow);
    return CGSizeMake(size, size);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return INSET_SPACING;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return INSET_SPACING;
}


#pragma mark - UICollectionView DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.images.count;
}

- (JJImageCollectionCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JJImageCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [cell configureWith:[self.cachedImages objectAtIndex:indexPath.row] atIndex:indexPath.row];
    cell.imageViewer = self;
    
    return cell;
}


#pragma mark - UICollectionView Delegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self didSelectIndex:indexPath.row];
}

- (void)didSelectIndex:(NSUInteger)index
{
    // Overide this method in the subclass
}

@end
