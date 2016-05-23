//
//  ScrollView.m
//  Image Viewer
//
//  Created by Julian Jans on 29/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import "GalleryScrollView.h"
#import "GalleryCollectionView.h"


@implementation GalleryScrollView


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self scrollToIndex:self.visibleIndex animated:NO];
}


- (void)didScrollToPageIndex:(NSUInteger)index
{
    [super didScrollToPageIndex:index];
    if (index) {
       self.visibleIndex = index;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Set the other view's index number here..?
    
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([[vc class] isSubclassOfClass:[GalleryCollectionView class]]) {
            GalleryCollectionView *cv = (GalleryCollectionView *)vc;
            cv.visibleIndex = self.visibleIndex;
        }
    }
}

@end