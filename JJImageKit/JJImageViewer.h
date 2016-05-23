//
//  JJImageViewer.h
//  Image Viewer
//
//  Created by Julian Jans on 30/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JJImageViewDelegate.h"

@interface JJImageViewer : UIViewController <JJImageViewDelegate>


/// Set the images that we want to display, accepts: NSString (bundle), NSSURL (download), or UIImage
@property (nonatomic, copy) NSArray *images;

/// Scrolls the view to the selected index @param animated If you want standard UIKit animation \warning Do not override this method
- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated;

@end
