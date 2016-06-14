//
//  ImageViewer.m
//  Image Viewer
//
//  Created by Julian Jans on 26/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import "JJImageScrollViewer.h"
#import "JJImageScrollCell.h"
#import "JJImageDownloader.h"
#import "NSURL+JJImageCache.h"

#define IMAGE_PADDING 20
#define ANIMATION_DURATION 0.0


@interface JJImageScrollViewer () <UIScrollViewDelegate>


/// Main scroll view, contains JJImageView subviews
@property (nonatomic, strong) UIScrollView *pagingScrollView;

/// Set to handle the recycling of JJImageView subviews
@property (nonatomic, strong) NSMutableSet *visiblePages, *recycledPages;

/// The current page number \warning needs to be CGFloat to handle change of scale during rotation
@property (nonatomic, readonly) CGFloat pageNumber;
@property (nonatomic, assign)   CGFloat pageNumberBeforeRotation;

/// Single tap gesture for hiding elements on the scrollview: UINavigation and UIPageControl
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;

/// Bools to handle view state
@property (nonatomic, assign) BOOL shoulStopScrollingDuringRotation, shouldHideStatusBar;

/// An optional UIPageControl to show page numbers \warning Will only work with limited pages
@property (nonatomic, strong) UIPageControl *pageControl;

@end


@implementation JJImageScrollViewer

@synthesize images = _images;


#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    self.visiblePages   = [[NSMutableSet alloc] init];
    self.recycledPages  = [[NSMutableSet alloc] init];
    
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.translucent = YES;
    
    self.pagingScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.pagingScrollView.scrollEnabled = YES;
    self.pagingScrollView.delegate = self;
    self.pagingScrollView.pagingEnabled = YES;
    self.pagingScrollView.showsHorizontalScrollIndicator = NO;
    self.pagingScrollView.showsVerticalScrollIndicator = NO;
    self.pagingScrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.pagingScrollView];
    
    self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleStatusBar:)];
    self.singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:self.singleTap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self layoutVisiblePages];
    [self loadVisiblePage];
    [self didScrollToPageIndex:self.pageNumber];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[JJImageDownloader sharedClient] cancelPendingTasks];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self layoutVisiblePages];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.view bringSubviewToFront:self.pageControl];
}

- (BOOL)prefersStatusBarHidden
{
    return self.shouldHideStatusBar;
}


#pragma mark - Image Storage & Delegate

- (void)setImages:(NSArray *)images
{
    NSAssert(!_images || _images.count == images.count, @"Cannot change the array size!");
    
    // If an element in the array has changed we need to update any visible & relevant views
    if (_images) {
        [images enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![obj isEqual:[_images objectAtIndex:idx]]) {
                for (JJImageScrollCell *page in self.visiblePages) {
                    if (page.index == idx) {
                        [page configureWith:obj atIndex:idx];
                    }
                }
            }
        }];
    }
    _images = images;
    
    // Only configure the page control if we are going to use it, it is slow to load with large numbers
    if (self.shouldShowPageControl) {
        self.pageControl.numberOfPages = _images.count;
        self.pageControl.hidden = !self.shouldShowPageControl;
    }
}


#pragma mark - Custom Layout Functions

- (void)layoutVisiblePages
{
    CGRect screen = self.view.bounds;
    
    CGFloat width = screen.size.width;
    CGFloat height = screen.size.height;
    
    CGRect pagingScrollFrame = CGRectMake(0, 0, width, height);
    pagingScrollFrame.origin.x -= IMAGE_PADDING;
    pagingScrollFrame.size.width += (IMAGE_PADDING * 2);
    
    [self.pagingScrollView setFrame:pagingScrollFrame];
    [self.pagingScrollView setContentSize:CGSizeMake(pagingScrollFrame.size.width * self.images.count, pagingScrollFrame.size.height)];
    
    for (JJImageScrollCell *page in self.visiblePages) {
        
        CGRect frame = page.frame;
        frame.size.height = height;
        frame.size.width = width;
        frame.origin = CGPointMake((width * page.index) + (IMAGE_PADDING + ((IMAGE_PADDING * 2) * page.index)), 0);
        
        [page setFrame:frame];
        [page resetImageSize];
    }
    self.pagingScrollView.contentOffset = CGPointMake((self.pagingScrollView.bounds.size.width * self.pageNumber), 0);
}

- (void)loadVisiblePage
{
    CGRect visibleBounds = self.pagingScrollView.bounds;
    NSInteger firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    NSInteger lastNeededPageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, self.images.count - 1);
    
    for (JJImageScrollCell *page in self.visiblePages) {
        if (page.index < firstNeededPageIndex || page.index > lastNeededPageIndex) {
            [self.recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [self.visiblePages minusSet:self.recycledPages];
    
    CGRect screen = self.view.bounds;
    CGFloat width = screen.size.width;
    CGFloat height = screen.size.height;

    for (NSInteger index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        
        if (![self isDisplayingPageForIndex:index]) {
            
            JJImageScrollCell *page = [self dequeueRecycledPage];
            if (page == nil) {
                page = [[JJImageScrollCell alloc] initWithFrame:screen];
            }
            
            page.imageViewer = self;
            
            // Makes sure that the single tap only happens if the double tap on the image fails
            for (UIGestureRecognizer *gesture in page.gestureRecognizers) {
                [self.singleTap requireGestureRecognizerToFail:gesture];
            }
      
            [page configureWith:[self.cachedImages objectAtIndex:index] atIndex:index];
            
            CGRect frame = page.frame;
            frame.size.height = height;
            frame.size.width = width;
            frame.origin = CGPointMake((width * page.index) + (IMAGE_PADDING + ((IMAGE_PADDING * 2) * page.index)), 0);
            
            [page setFrame:frame];
            [page resetImageSize];
            
            [self.visiblePages addObject:page];
            [self.pagingScrollView addSubview:page];
        }
    }
}

- (JJImageScrollCell *)dequeueRecycledPage
{
    JJImageScrollCell *page = [self.recycledPages anyObject];
    if (page) {
        [self.recycledPages removeObject:page];
    }
    return page;
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index
{
    BOOL foundPage = NO;
    for (JJImageScrollCell *page in self.visiblePages) {
        if (page.index == index) {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}

- (CGFloat)pageNumber
{
    return self.pagingScrollView.contentOffset.x / self.pagingScrollView.bounds.size.width;
}

- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (index) {
        CGPoint newOffSet = CGPointMake((self.pagingScrollView.contentSize.width/self.images.count) * index, 0);
        [self.pagingScrollView setContentOffset:newOffSet animated:animated];
    }
}


#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.shoulStopScrollingDuringRotation) {
        [self loadVisiblePage];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self didScrollToPageIndex:self.pageNumber];
}

- (void)didScrollToPageIndex:(NSUInteger)index
{
    self.pageControl.currentPage = index;
}

- (void)toggleStatusBar:(id)sender
{
    BOOL status = !self.shouldHideStatusBar;
    
    //  Setting the background to a different colour is how Photos.app behaves:

    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        if (status) {
            self.view.backgroundColor = [UIColor blackColor];
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
    }];

    // Hide the page control, if it should be shown at all
    if (self.shouldShowPageControl) {
        self.pageControl.alpha = !status;
    }

    [self.navigationController setNavigationBarHidden:status animated:NO];
    self.shouldHideStatusBar = status;
    [self setNeedsStatusBarAppearanceUpdate];
}


#pragma mark - Page Control

- (UIPageControl *)pageControl
{
    if (!_pageControl && self.shouldShowPageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.translatesAutoresizingMaskIntoConstraints = NO;
        _pageControl.userInteractionEnabled = NO;
        [self.view addSubview:_pageControl];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_pageControl]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_pageControl)]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_pageControl]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_pageControl)]];
    }
    return _pageControl;
}


#pragma mark - Device orientation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    self.shoulStopScrollingDuringRotation = YES;
    self.pageNumberBeforeRotation = self.pageNumber;
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Update the content offset of the scroll view as the rotation is made
        CGPoint newOffSet = CGPointMake((self.pagingScrollView.contentSize.width/self.images.count) * self.pageNumberBeforeRotation, 0);
        [self.pagingScrollView setContentOffset:newOffSet animated:NO];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.shoulStopScrollingDuringRotation = NO;
    }];
}

@end
