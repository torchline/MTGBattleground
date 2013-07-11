//
//  ViewController.m
//  FlickrTest
//
//  Created by Brad Walker on 5/29/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "ViewController.h"
#import "Flickr.h"
#import "UIImageView+AFNetworking.h"

@interface ViewController ()

@property (nonatomic, strong) void __block (^myBlock)(NSDictionary *response);

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	__weak typeof(self) weakSelf = self;
	
	self.myBlock = ^(NSDictionary *response) {
		NSLog(@"%d", [[response valueForKeyPath:@"items"] count]);
		
		double delayInSeconds = 2.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[weakSelf repeat];
		});
	};
	
	[self repeat];
	
	[self.imageView setImageWithURL:[NSURL URLWithString:@"http://farm9.staticflickr.com/8123/8881911121_bfa884ce43_m.jpg"] placeholderImage:[UIImage imageNamed:@"flickr.png"]];
}

- (void)repeat {
	__weak typeof(self) weakSelf = self;
	
	[Flickr requestPublicPhotosWithCompletion:^(NSDictionary *response) {
		NSLog(@"%d", [[response valueForKeyPath:@"items"] count]);
		
		double delayInSeconds = 2.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[weakSelf repeat];
		});
	} failure:^{
		double delayInSeconds = 2.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[weakSelf repeat];
		});
	}];
}

@end
