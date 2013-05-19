//
//  ResourceManager.m
//  CropperFramework
//
//  Created by Brad Walker on 7/23/12.
//  Copyright 2012 Torchline Technology LLC. All rights reserved.
//

#import "ResourceManager.h"
#import <CommonCrypto/CommonDigest.h>

@implementation ResourceManager


#pragma mark -
#pragma mark Init

static ResourceManager *sharedHelper;
+ (ResourceManager *)sharedInstance {
	if (sharedHelper == nil)
		sharedHelper = [[ResourceManager alloc] init];
	return sharedHelper;
}


#pragma mark -
#pragma mark Public

+ (NSString *)saveImage:(UIImage *)image withFilename:(NSString *)filename asPNG:(BOOL)asPNG {
	NSString *formattedFilePath;
	NSRange dotRange = [filename rangeOfString:@"."];
	if (dotRange.location == NSNotFound)
		formattedFilePath = [NSString stringWithFormat:@"%@.%@", filename, asPNG ? @"png" : @"jpg"];
	else
		formattedFilePath = filename;
	
	//NSString *path = [[ResourceManager documentsDirectory] stringByAppendingPathComponent:formattedFilename];
	NSError *dirCreateError = nil;
	BOOL dirCreated = [[NSFileManager defaultManager] createDirectoryAtPath:[formattedFilePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&dirCreateError];
	if (!dirCreated && dirCreateError != nil) {
		NSLog(@"[ResourceManager saveImage]: Failed creating directory: %@", [dirCreateError localizedDescription]);
	}
	
	UIImage *flippedImage = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:UIImageOrientationDownMirrored];
	
	NSData *data;
	if (asPNG)
		data = UIImagePNGRepresentation(flippedImage);
	else
		data = UIImageJPEGRepresentation(flippedImage, 80.0f);
	
	NSError *writeError = nil;
	[data writeToFile:formattedFilePath options:NSDataWritingAtomic error:&writeError];
	
	if (writeError != nil)
		NSLog(@"[ResourceManager saveImage]: Failed saving image: %@", [writeError localizedDescription]);
	
	return writeError == nil ? formattedFilePath : nil;
}

+ (UIImage *)savedImageNamed:(NSString *)filePath {
    NSString *foundFilePath = nil;
	
	NSRange dotRange = [filePath rangeOfString:@"."];
	if (dotRange.location == NSNotFound) {
        
		NSString *filenamePNG = [[NSString alloc] initWithFormat:@"%@.png", filePath];
		NSString *filePathPNG = [[ResourceManager documentsDirectory] stringByAppendingPathComponent:filenamePNG];
        
		if ([[NSFileManager defaultManager] fileExistsAtPath:filePathPNG]) {
            foundFilePath = filePathPNG;
        }
        else {
			NSString *filenameJPG = [[NSString alloc] initWithFormat:@"%@.jpg", filePath];
			NSString *filePathJPG = [[ResourceManager documentsDirectory] stringByAppendingPathComponent:filenameJPG];

			if ([[NSFileManager defaultManager] fileExistsAtPath:filePathJPG])
				foundFilePath = filePathJPG;
		}
	}
    else {
        NSString *absFilePath = [[ResourceManager documentsDirectory] stringByAppendingPathComponent:filePath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:absFilePath])
            foundFilePath = absFilePath;
    }
    
    if (foundFilePath != nil) {
        return [ResourceManager imageWithPath:foundFilePath];
    }
	
	return nil;
}


+ (BOOL)writeData:(NSData *)data toPath:(NSString *)path overwrite:(BOOL)overwrite {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (overwrite) {
            // remove existing file
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        else
            return NO;
    }
    return [data writeToFile:path atomically:YES];
}

+ (NSData *)fileDataWithPath:(NSString *)absolutePath {
    return [[NSFileHandle fileHandleForReadingAtPath:absolutePath] readDataToEndOfFile];
}

+ (UIImage *)imageWithPath:(NSString *)absolutePath {
    return [UIImage imageWithData:[ResourceManager fileDataWithPath:absolutePath]];
}

+ (NSString *)documentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+ (NSString *)tempDirectory {
    return NSTemporaryDirectory();
}

+ (NSString *)bundleDirectory {
    return [[NSBundle mainBundle] bundlePath];
}

+ (NSString *)databaseDirectory {
	NSString *dir = [[self documentsDirectory] stringByAppendingPathComponent:@"Databases"];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    return dir;
}

+ (NSString *)downloadsDirectory {
	NSString *dir = [[self documentsDirectory] stringByAppendingPathComponent:@"Downloads"];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    return dir;
}

+ (NSString *)themeDirectory {
	NSString *dir = [[self downloadsDirectory] stringByAppendingPathComponent:@"Themes"];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    return dir;
}

+ (NSString *)recordingsDirectory {
    NSString *dir = [[self documentsDirectory] stringByAppendingPathComponent:@"Recordings"];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    return dir;
}

+ (BOOL)copyFileAtPathIfNewer:(NSString *)source toPath:(NSString *)destination error:(NSError *__autoreleasing*)error {
	BOOL sourceFileExists = [[NSFileManager defaultManager] fileExistsAtPath:source];
	if (!sourceFileExists) {
		NSLog(@"source file does not exist");
		return NO;
	}
	
	BOOL createDestinationDirectorySuccess = [[NSFileManager defaultManager] createDirectoryAtPath:[destination stringByDeletingLastPathComponent]
																	   withIntermediateDirectories:YES
																						attributes:nil
																							 error:error];
	
	if (!createDestinationDirectorySuccess) {
		return NO;
	}
	
	BOOL destinationFileAlreadyExists = [[NSFileManager defaultManager] fileExistsAtPath:destination];
	
	BOOL shouldCopy = NO;
	if (destinationFileAlreadyExists) {
		NSComparisonResult fileComparisonResult = [ResourceManager compareModificationDatesOfFilesAtPath:source
																								 andPath:destination];
		
		if (fileComparisonResult == NSOrderedDescending) {
			BOOL removeDestinationSuccess = [[NSFileManager defaultManager] removeItemAtPath:destination error:error];

			if (!removeDestinationSuccess) {
				return NO;
			}
			
			shouldCopy = YES;
		}
	}
	else {
		shouldCopy = YES;
	}
	
	if (shouldCopy) {
		BOOL copySuccess = [[NSFileManager defaultManager] copyItemAtPath:source toPath:destination error:error];
		
		if (!copySuccess) {
			return NO;
		}
		else {
			NSLog(@"db replaced");
			return YES;
		}
	}
	else {
		error = nil;
		return NO;
	}	
}

+ (NSString *)getNewTempFilePath {
    BOOL exists;
    NSString *newTempFilePath = nil;
    do {
        NSString *timestampString = [[NSString alloc] initWithFormat:@"%d", (int)([NSDate timeIntervalSinceReferenceDate] * 100000)];
        const char *cStr = [timestampString UTF8String];

        unsigned char result[16];
        CC_MD5( cStr, strlen(cStr), result ); // This is the md5 call
        newTempFilePath =  [[NSString alloc] initWithFormat:@"%@/%d%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                [ResourceManager tempDirectory], (int)(arc4random() % 1000), result[0], result[1], result[2], result[3],
                result[4], result[5], result[6], result[7],
                result[8], result[9], result[10], result[11],
                result[12], result[13], result[14], result[15]
                ];
        exists = [[NSFileManager defaultManager] fileExistsAtPath:newTempFilePath];
    } while (exists);
    
    if (newTempFilePath == nil)
        return nil;
    
    return newTempFilePath;
}

+ (NSComparisonResult)compareModificationDatesOfFilesAtPath:(NSString *)path1 andPath:(NSString *)path2 {
	NSDictionary *path1Attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path1 error:nil];
	NSDictionary *path2Attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path2 error:nil];
	
	NSDate *path1ModificationDate = [path1Attributes valueForKey:NSFileModificationDate];
	NSDate *path2ModificationDate = [path2Attributes valueForKey:NSFileModificationDate];
	
	return [path1ModificationDate compare:path2ModificationDate];
}


@end
