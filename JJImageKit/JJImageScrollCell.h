//
//  ImageView.h
//  Image Viewer
//
//  Created by Julian Jans on 26/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JJImageScrollViewer.h"


@interface JJImageScrollCell : UIScrollView <UIScrollViewDelegate>


/// The index of the array of content that this view relates to
@property (nonatomic, assign) NSUInteger index;

/// The delegate/parent scroll view container
@property (nonatomic, weak) id<JJImageViewDelegate> imageViewer;

/// Setting of the view with an undetermined object @param obj (NSString/NSURL/UIImage)
- (void)configureWith:(id)obj atIndex:(NSUInteger)index;

/// Resets the view when it is recycled by its parent
- (void)resetImageSize;

@end