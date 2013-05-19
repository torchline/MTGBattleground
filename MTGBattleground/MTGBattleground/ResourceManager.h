//
//  ResourceManager.h
//  CropperFramework
//
//  Created by Brad Walker on 7/23/12.
//  Copyright 2012 Torchline Technology LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ResourceManager : NSObject {
	
}

+ (ResourceManager *)sharedInstance;

+ (NSString *)saveImage:(UIImage *)image withFilename:(NSString *)filename asPNG:(BOOL)asPNG;
+ (UIImage *)savedImageNamed:(NSString *)filename;
+ (UIImage *)imageWithPath:(NSString *)absolutePath;

+ (BOOL)writeData:(NSData *)data toPath:(NSString *)path overwrite:(BOOL)overwrite;

+ (NSString *)documentsDirectory;
+ (NSString *)tempDirectory;
+ (NSString *)bundleDirectory;
+ (NSString *)databaseDirectory;
+ (NSString *)downloadsDirectory;
+ (NSString *)themeDirectory;
+ (NSString *)recordingsDirectory;

+ (BOOL)copyFileAtPathIfNewer:(NSString *)source toPath:(NSString *)destination error:(NSError *__autoreleasing*)error;

+ (NSString *)getNewTempFilePath;

+ (NSComparisonResult)compareModificationDatesOfFilesAtPath:(NSString *)path1 andPath:(NSString *)path2;

@end
