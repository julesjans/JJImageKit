//
//  ImageViewer.h
//  Image Viewer
//
//  Created by Julian Jans on 26/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JJImageViewDelegate.h"
#import "JJImageViewer.h"


/// Abstract Class: provides a Paging UIScrollView interface for a set of images
@interface JJImageScrollViewer : JJImageViewer <JJImageViewDelegate>


/// Set whether a paging control should be visible at the bottom of the paging view \warning Check the array count for size
@property (nonatomic, assign) BOOL shouldShowPageControl;

/// Overide this method in a subclass to receive the current page number after a scroll event @param index Page number -1 \warning Call super to get the paging control updated
- (void)didScrollToPageIndex:(NSUInteger)index;

@end