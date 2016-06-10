//
//  APIClient.m
//  Petsy
//
//  Created by Julian Jans on 20/11/2014.
//  Copyright (c) 2014 Julian Jans. All rights reserved.
//

#import "JJImageDownloader.h"
#import "NSURL+JJImageCache.h"

typedef NS_ENUM(NSInteger, JJFileType) {
    JJFileTypeJPEG,
    JJFileTypePDF
};


@interface JJImageDownloader ()

@property (strong, nonatomic) NSURLSession *session;
@property (nonatomic, strong) NSMutableSet *requestQueue;

@end

// TODO: Make this generic for storyboards as well...?

@implementation JJImageDownloader


#pragma mark - Singleton Instance

+ (instancetype)sharedClient
{
    static JJImageDownloader *_sharedClient = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[JJImageDownloader alloc] init];
        
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _sharedClient.session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
        
    });
    
    return _sharedClient;
}


#pragma mark - Data Methods

- (NSMutableURLRequest *)getImageURL:(NSURL *)url withCompletionHandler:(JJImageViewerDownloadImageResponse)block
{
   return [self getFileURL:url fileType:JJFileTypeJPEG withCompletionHandler:block];
}


- (NSMutableURLRequest *)getPdfURL:(NSURL *)url withCompletionHandler:(JJImageViewerDownloadFileResponse)block
{
    return [self getFileURL:url fileType:JJFileTypePDF withCompletionHandler:block];
}


- (NSMutableURLRequest *)getFileURL:(NSURL *)url fileType:(JJFileType)fileType withCompletionHandler:(void(^)(NSURL *url, id result))block
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //    #if DEBUG
    //    NSLog(@"Requesting Image: %@: %@", request.HTTPMethod, request.URL);
    //    #endif
    
    // First we check if there is a local file
    if ([[NSFileManager defaultManager] fileExistsAtPath:url.temporaryLocalURL.path]) {
        
        id result;
        
        switch (fileType) {
            case JJFileTypeJPEG:
                result = [UIImage imageWithContentsOfFile:url.temporaryLocalURL.path];
                break;
            case JJFileTypePDF:
                result = url.temporaryLocalURL;
                break;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(url, result);
            }
        });
        
        // TODO: Cache handling if the local file is old
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.temporaryLocalURL.path error:nil];
        NSDate *date = [attributes fileModificationDate];

        // TODO: Need to improve the handling of stale images, and caching with URLs by key..?
        if ([date laterDate:[[NSDate date] dateByAddingTimeInterval:-60*60*24]] != date) {
            // Perform a new look up of this image..?
            
            #warning No handling of the cache at the moment
            
        }
        return request;
    }
    

    NSURLSessionTask *task = [self.session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            
            [self handleAuthentication:response];
            
            id result;
            
            switch (fileType) {
                case JJFileTypeJPEG: {
                    result = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
                    NSData * data = UIImageJPEGRepresentation(result, 0.5);
                    NSURL *temporaryURL = [url temporaryLocalURL];
                    [data writeToFile:temporaryURL.path atomically:YES];
                    break;
                }
                case JJFileTypePDF: {
                    [[NSFileManager defaultManager] copyItemAtURL:location toURL:[url temporaryLocalURL] error:NULL];
                    result = url.temporaryLocalURL;
                    break;
                }
            }
        
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(url, result);
                }
            });
            //    #if DEBUG
            //    NSLog(@"Image Request returned: %@", request.URL );
            //    #endif
        }
        [self removeRequestFromRequestQueue:request];
    }];
    [self addRequestToRequestQueue:request];
    [task resume];
    
    return request;
}

- (void)handleAuthentication:(NSURLResponse*)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    //    #if DEBUG
    //    NSLog(@"Image Request Returned Status: %d",(int)httpResponse.statusCode);
    //    NSLog(@"---");
    //    #endif
    
    if ([@[@401, @403] containsObject:@((int)httpResponse.statusCode)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // TODO: Handle any fails in here...
        });
    }
}

- (void)cancelPendingTasks
{
    [[self session] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for (NSURLSessionTask *task in downloadTasks) {
            [task cancel];
        }
    }];
}

- (void)cancelRequest:(NSMutableURLRequest *)request
{
    [[self session] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for (NSURLSessionTask *task in downloadTasks) {
            if ([task.currentRequest.URL isEqual:request.URL]) {
                [task cancel];
            }
        }
    }];
    [self removeRequestFromRequestQueue:request];
}

#pragma mark - Request Queue for Network Indicator
- (NSMutableSet *)requestQueue
{
    if (!_requestQueue) {
        _requestQueue = [[NSMutableSet alloc] init];
    }
    return _requestQueue;
}

- (void)addRequestToRequestQueue:(NSMutableURLRequest *)request
{
    if (request) {
        [self.requestQueue addObject:request];
        // [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
}

- (void)removeRequestFromRequestQueue:(NSMutableURLRequest *)request
{
    if (request) {
        [self.requestQueue removeObject:request];
        if (!self.requestQueue.count) {
            // [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
    }
}


@end