//
//  ImageView.m
//  Image Viewer
//
//  Created by Julian Jans on 26/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import "JJImageScrollCell.h"
#import "JJImageDownloader.h"


@interface JJImageScrollCell ()

/// UiImageView containing the image, resized to fit the image, the containing scrollview is then zoomed to fit the UIImageView
@property (nonatomic, strong) UIImageView *imageView;

/// Property for the zoomscale which scales the UIImageView to mimic UIAspectFill scaling
@property (nonatomic, assign) CGFloat optimumZoomScale;

/// Loading view for downloading image
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;

@end


@implementation JJImageScrollCell


#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateNormal;
        self.delegate = self;
    
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        [doubleTap setNumberOfTapsRequired:2];
        [self addGestureRecognizer:doubleTap];
    }
    return self;
}


#pragma mark - View Configuration
/// Calculates the zoom factors that are necessary for the current image
- (void)setMaxMinZoomScalesForCurrentBounds
{
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = self.imageView.bounds.size;
    
    CGFloat xMinScale = boundsSize.width / imageSize.width;
    CGFloat yMinScale = boundsSize.height / imageSize.height;
   
    CGFloat minScale = (MIN(xMinScale, yMinScale)/1.0);
    CGFloat maxScale = MAX(xMinScale, yMinScale);
    
    if (minScale > maxScale) {
        minScale = maxScale;
    }
    
    self.optimumZoomScale = MAX(xMinScale, yMinScale);
    self.minimumZoomScale = minScale;

    CGFloat xMaxScale = imageSize.width / boundsSize.width;
    CGFloat yMaxScale = imageSize.height / boundsSize.height;
    
    self.maximumZoomScale = MAX(xMaxScale, yMaxScale);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize boundsSize = self.bounds.size;
    
    CGRect frameToCenter = self.imageView.frame;
    
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    } else {
        frameToCenter.origin.x = 0;
    }
    
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    } else {
        frameToCenter.origin.y = 0;
    }
    
    self.imageView.frame = frameToCenter;
}

- (void)resetImageSize
{
    [self setMaxMinZoomScalesForCurrentBounds];
    [self setZoomScale:self.minimumZoomScale animated:NO];
    self.contentSize = self.bounds.size;
}


#pragma mark - Scroll View Delegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGFloat offsetX = MAX((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0);
    CGFloat offsetY = MAX((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0);
    
    self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}


#pragma mark - Tap Gestures
/// Double tapping the view toggles between the minimum zoomscale and the optimum
- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    if(self.zoomScale > self.minimumZoomScale){
        [self setZoomScale:self.minimumZoomScale animated:YES];
    } else {
        [self setZoomScale:self.optimumZoomScale animated:YES];
    }
}


#pragma mark - Image presentation and Downloading

- (void)configureWith:(id)obj atIndex:(NSUInteger)index
{
    self.zoomScale = 1.0;
    self.index = index;

    self.imageView.image = nil;
    self.imageView = nil;
    
    // Add the loading view if it doesn't already exist
    if (!self.loadingView) {
        self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.loadingView.center = CGPointMake(self.bounds.size.width / 2.0f, self.bounds.size.height / 2.0f);
        self.loadingView.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
        [self.loadingView startAnimating];
        [self addSubview:self.loadingView];
    }
    
    // If the obj is a string it can either be a local path, or located in the bundle
    if ([[obj class] isSubclassOfClass:[NSString class]]) {
        
        NSString *string = (NSString *)obj;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:string]) {
            [self imageDidLoad:index withImage:[UIImage imageWithContentsOfFile:string]];
        }
        if ([UIImage imageNamed:string]) {
            [self imageDidLoad:index withImage:[UIImage imageNamed:(NSString *)obj]];
        }
        return;
    }
    
    // If the obj is an image, just load it and move on
    if ([[obj class] isSubclassOfClass:[UIImage class]]) {
        [self imageDidLoad:index withImage:(UIImage *)obj];
        return;
    }
    
    // If the obj is an NSURL it can either be a local URL or online and need downloading
    if ([[obj class] isSubclassOfClass:[NSURL class]]) {
        NSURL *url = (NSURL *)obj;
        if (url.isFileURL) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
                [self imageDidLoad:index withImage:[UIImage imageWithContentsOfFile:url.path]];
            }
        } else {
            [[JJImageDownloader sharedClient] getImageURL:url withCompletionHandler:^(NSURL *url, UIImage *image) {
                [self imageDidLoad:index withImage:image];
                [self.imageViewer didUpdateImage:image forURL:url atIndex:index];
            }];
        }
        return;
    }
}

/// Once the image has been located this is where it is set to the UIImageView
- (void)imageDidLoad:(NSUInteger)index withImage:(UIImage *)image
{
    // check that the page hasn't been recycled... Don't want to add the picture if we don't need to!
    if (self.index == index) {
        
        [self.loadingView stopAnimating];
        self.loadingView = nil;
        
        if (!self.imageView) {
            CGSize imageSize = image.size;
            
            CGRect proposedBounds = CGRectMake(0, 0, imageSize.width, imageSize.height);
            
            self.imageView = [[UIImageView alloc] initWithImage:image];
            self.imageView.frame = proposedBounds;
            
            [self setContentSize:image.size];
            [self addSubview:self.imageView];
            [self setMaxMinZoomScalesForCurrentBounds];
            [self setZoomScale:self.minimumZoomScale animated:NO];
            
        } else {
            self.imageView.image = image;
        }
    }
}

@end
