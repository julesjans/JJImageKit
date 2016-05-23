//
//  JJImageViewDelegate.h
//  ImageViewerFramework
//
//  Created by Julian Jans on 29/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Protocol to access methods on the parent scroll view: JJImageViewer
@protocol JJImageViewDelegate <NSObject>


/// Set the images that we want to display, accepts: NSString (bundle), NSSURL (download), or UIImage
@property (nonatomic, copy) NSArray *images;

/// Stores a mutable array of the images, if downloaded images need to be cached..?
@property (nonatomic, strong, readonly) NSMutableArray *cachedImages;

/// Scrolls the view to the selected index @param animated If you want standard UIKit animation \warning Do not override this method
- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated;

@optional

/// Delegate method called when an image has been downloaded/loaded from bundle/disk etc @param image The image @param url the original (remote) url @param index The index of the array
- (void)didUpdateImage:(UIImage *)image forURL:(NSURL *)url atIndex:(NSUInteger)index;

@end