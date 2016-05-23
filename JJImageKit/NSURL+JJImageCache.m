//
//  NSURL+JJImageCache.m
//  Image Viewer
//
//  Created by Julian Jans on 29/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import "NSURL+JJImageCache.h"

@implementation NSURL (JJImageCache)

- (NSURL *)temporaryLocalURL
{
    NSURL *url = [NSURL fileURLWithPathComponents:@[NSTemporaryDirectory(), @"ImageViewerFramework"]];
    
    [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL];
    return [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%lu", (unsigned long)self.absoluteString.hash]];
}

@end


