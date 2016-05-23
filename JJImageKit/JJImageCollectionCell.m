//
//  JJImageCollectionCell.m
//  ImageViewerFramework
//
//  Created by Julian Jans on 29/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import "JJImageCollectionCell.h"
#import "JJImageDownloader.h"


@interface JJImageCollectionCell ()

@property (nonatomic, strong) UIImageView *imageView;

/// Loading view for downloading image
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;

@property (nonatomic, strong) NSMutableURLRequest *request;

@end


@implementation JJImageCollectionCell


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        // TODO: Test if this is making a difference
        // Is there a better way of optimising the collection view cells. Maybe not having an image view
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
}


- (UIImageView *)imageView
{
    if (!_imageView){
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self addSubview:_imageView];
    }
    return _imageView;
}


#pragma mark - Configuring the UICollectionCell

- (void)configureWith:(id)obj atIndex:(NSUInteger)index
{
    self.index = index;
    
    [[JJImageDownloader sharedClient] cancelRequest:self.request];
    
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
            // [self.imageViewer didUpdateImage:[UIImage imageWithContentsOfFile:string] atIndex:index];
            return;
        }
        if ([UIImage imageNamed:string]) {
            [self imageDidLoad:index withImage:[UIImage imageNamed:(NSString *)obj]];
            // [self.imageViewer didUpdateImage:[UIImage imageNamed:(NSString *)obj] atIndex:index];
            return;
        }
        
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
                // [self.imageViewer didUpdateImage:[UIImage imageWithContentsOfFile:url.path] atIndex:index];
            }
        } else {
            self.request = [[JJImageDownloader sharedClient] getImageURL:url withCompletionHandler:^(NSURL *url, UIImage *image) {
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
        
        self.imageView.alpha = 0.0;
        self.imageView.image = image;
        
        [self bringSubviewToFront:self.imageView];
        
        [UIView animateWithDuration:0.1 animations:^{
            self.imageView.alpha = 1.0;
        } completion:^(BOOL finished) {
            [self.loadingView stopAnimating];
            self.loadingView = nil;
        }];
    }
}


#pragma mark - Recycling

- (NSString *)reuseIdentifier {
    return @"Cell";
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
    
    [[JJImageDownloader sharedClient] cancelRequest:self.request];
}

@end
