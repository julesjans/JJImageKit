//
//  CollectionView.m
//  Image Viewer
//
//  Created by Julian Jans on 29/05/2015.
//  Copyright (c) 2015 Julian Jans. All rights reserved.
//

#import "GalleryCollectionView.h"
#import "GalleryScrollView.h"


@interface GalleryCollectionView () <NSURLConnectionDelegate>

@property (nonatomic, copy) NSArray *largeImages;
@property (nonatomic, strong) NSMutableData *data;

@end


// TODO: Handle the deletion of the tmp cache
// TODO: Handle the code overlap, and put that into a category.

// Document the fact that subclasses need to be responsible for navigation between the two views...


@implementation GalleryCollectionView

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.bowmansculpture.com/webservices/ios.json"]];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [conn start];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self scrollToIndex:self.visibleIndex animated:YES];
}

// Handle the delegate
- (void)didSelectIndex:(NSUInteger)index
{
    self.visibleIndex = index;
    [self performSegueWithIdentifier:@"scroll" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scroll"]) {
        GalleryScrollView *scrollView = (GalleryScrollView *)segue.destinationViewController;
        scrollView.images = self.largeImages;
        scrollView.visibleIndex = self.visibleIndex;
    }
}


#pragma mark - NSURLConnection & HTTPS

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSMutableArray *smallImages = [NSMutableArray array];
    NSMutableArray *largeImages = [NSMutableArray array];
    
    NSDictionary *results = [NSJSONSerialization JSONObjectWithData:self.data options:NSJSONReadingMutableLeaves error:NULL];
    NSArray *sculptures = [results objectForKey:@"sculptures"];
    
    NSArray *sortedSculptures = [sculptures sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSInteger one = [[(NSDictionary *)obj1 objectForKey:@"id"] integerValue];
        NSInteger two = [[(NSDictionary *)obj2 objectForKey:@"id"] integerValue];
        if (one > two) {
            return (NSComparisonResult)NSOrderedAscending;
        } else {
            return (NSComparisonResult)NSOrderedDescending;
        }
    }];

    for (NSDictionary *sculpture in sortedSculptures) {
        NSString *sn = [sculpture objectForKey:@"id"];
        NSUInteger count = [[sculpture objectForKey:@"image_count"] integerValue];
        if (count > 1) {
            for (int i=1; i<=count; i++) {
                [smallImages addObject:[NSURL URLWithString:[NSString stringWithFormat:@"http://images.bowmansculpture.com/%@/small/%@-%d.jpg", sn, sn, i]]];
                [largeImages addObject:[NSURL URLWithString:[NSString stringWithFormat:@"http://images.bowmansculpture.com/%@/large/%@-%d@2x.jpg", sn, sn, i]]];
            }
        }
    }
    self.images = smallImages;
    self.largeImages = largeImages;
}

@end
