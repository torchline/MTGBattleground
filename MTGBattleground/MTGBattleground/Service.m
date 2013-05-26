//
//  Service.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/23/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "Service.h"

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

#import "ResourceManager.h"


@implementation Service

static FMDatabaseQueue *_fmDatabaseQueue = nil;
+ (FMDatabaseQueue *)fmDatabaseQueue {
	if (!_fmDatabaseQueue) {
		NSString *bundleDBPath = [[ResourceManager bundleDirectory] stringByAppendingPathComponent:DB_FILE_NAME];
		NSString *docDBPath = [[ResourceManager databaseDirectory] stringByAppendingPathComponent:DB_FILE_NAME];
		
		NSError *error;
		[ResourceManager copyFileAtPathIfNewer:bundleDBPath toPath:docDBPath error:&error];
		if (error) {
			NSLog(@"%@", [error	localizedDescription]);
		}
		
		_fmDatabaseQueue = [[FMDatabaseQueue alloc] initWithPath:docDBPath];
	}
	
	return _fmDatabaseQueue;
}

static dispatch_queue_t _backgroundQueue = nil;
+ (dispatch_queue_t)backgroundQueue {
	if (!_backgroundQueue) {
		_backgroundQueue = dispatch_queue_create("com.torchlinetechnology.MTGBattleground.db", NULL);
	}
	
	return _backgroundQueue;
}


#pragma mark - Helper

+ (NSString *)newGUID {
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	return [(__bridge NSString *)string stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

+ (NSArray *)arrayByRemovingObject:(id)object fromArray:(NSArray *)array {
	NSMutableArray *newArray = [[NSMutableArray alloc] initWithArray:array];
	[newArray removeObject:object];
	return newArray;
}

+ (NSString *)updateAssignmentStringForFields:(NSArray *)fields {
	NSMutableString *string = [[NSMutableString alloc] initWithCapacity:40];
	
	NSUInteger i = 0;
	for (NSString *field in fields) {
		if (i == 0) {
			[string appendFormat:@"%@ = ?", field];
		}
		else {
			[string appendFormat:@", %@ = ?", field];
		}
		
		i++;
	}
	
	return string;
}

@end

