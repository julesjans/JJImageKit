//
//  JJImageViewer.m
//  Image Viewer
//
//  Created by Julian Jans on 30/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import "JJImageViewer.h"
#import "NSURL+JJImageCache.h"


@interface JJImageViewer ()

/// Stores a mutable array of the images, if downloaded images need to be cached..?
@property (nonatomic, strong, readwrite) NSMutableArray *cachedImages;

@end


@implementation JJImageViewer


- (NSMutableArray *)cachedImages
{
    if (!_cachedImages) {
        _cachedImages = [self.images mutableCopy];
    }
    return _cachedImages;
}

- (void)didUpdateImage:(UIImage *)image forURL:(NSURL *)url atIndex:(NSUInteger)index
{
    //    if (image && !url) {
    //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //            
    //            NSData * data = UIImageJPEGRepresentation(image, 0.5);
    //            NSURL *temporaryURL = [url temporaryLocalURL];
    //            
    //            [data writeToFile:temporaryURL.path atomically:YES];
    //            
    //            dispatch_async(dispatch_get_main_queue(), ^{
    //                // If we are handling many images locally, it might be best to cache them..?
    //                [self.cachedImages replaceObjectAtIndex:index withObject:temporaryURL];
    //            });
    //        });
    //    }
    
    //    NSAssert(index, @"Delegate method must return an index");
    //    NSAssert(image, @"Delegate method must return an image");
}

- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated
{
    [NSException raise:@"Unimplemented" format:@"Implement this method!"];
}

@end
