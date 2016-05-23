//
//  APIClient.h
//  Petsy
//
//  Created by Julian Jans on 20/11/2014.
//  Copyright (c) 2014 Julian Jans. All rights reserved.
//

#import <UIKit/UIKit.h>


// TODO: Need to fix the NSMutableRequest return type on the


/// Block structure to return an image with its corresponding URL
typedef void (^JJImageViewerDownloadResponse)(NSURL *url, UIImage *image);


@interface JJImageDownloader : NSObject <NSURLSessionTaskDelegate>

/// A single container for the NSURL Session
+ (instancetype)sharedClient;

/// Get an image with: @param url image URL \returns The NSMutableRequest object so that the owner can cancel it in flight
- (NSMutableURLRequest *)getImageURL:(NSURL *)url withCompletionHandler:(JJImageViewerDownloadResponse)block;

/// Cancels all the outstanding data downloads for the session
- (void)cancelPendingTasks;

/// Cancels a specific request
- (void)cancelRequest:(NSMutableURLRequest *)request;

@end