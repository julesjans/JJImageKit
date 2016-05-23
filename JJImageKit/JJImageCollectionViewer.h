//
//  JJImageCollectionViewer.h
//  ImageViewerFramework
//
//  Created by Julian Jans on 29/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JJImageViewDelegate.h"
#import "JJImageViewer.h"


/// Abstract Class: provides a UICollectionView interface for a set of images
@interface JJImageCollectionViewer : JJImageViewer <JJImageViewDelegate>


/// Overide this method in a subclass to receive the current index that has been selected \warning Do not call super on this
- (void)didSelectIndex:(NSUInteger)index;

/// How many images there are per row in the collection view \todo Make this animatable
@property (nonatomic, assign) NSUInteger imagesPerRow;

@end