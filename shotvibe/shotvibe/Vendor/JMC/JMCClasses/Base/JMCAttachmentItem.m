/**
   Copyright 2011 Atlassian Software

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
**/
//
//  Created by nick on 22/05/11.
//
//


#import "JMCAttachmentItem.h"
#import "JMC.h"

#define kFilenameFormat @"filenameFormat"
#define kContentType @"contentType"
#define kData @"data"
#define kPath @"path"
#define kName @"name"
#define kType @"type"
#define kDataLength @"dataLength"
#define kDeleteFileWhenSent @"deleteFileWhenSent"

@implementation JMCAttachmentItem

@synthesize filenameFormat;
@synthesize contentType;
@synthesize name;
@synthesize data;
@synthesize path;
@synthesize dataLength;
@synthesize type;
@synthesize thumbnail;
@synthesize deleteFileWhenSent;


-(NSString*)attachmentDirPath
{
    NSString *uuid = nil;
    CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
    uuid = NSMakeCollectable(CFUUIDCreateString(kCFAllocatorDefault, theUUID));
    
    NSString* attachmentDir = [[[JMC sharedInstance] dataDirPath] stringByAppendingPathComponent:@"attachments"];
    
    NSString* file = [attachmentDir stringByAppendingPathComponent:[name stringByAppendingFormat:@"-%@", uuid]];
    CFRelease(theUUID);
    CFRelease(uuid);

    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:attachmentDir]) {
        [fileManager createDirectoryAtPath:attachmentDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return file;
}

-(void) saveDataToFile:(NSString*)file
{
    BOOL success = [data writeToFile:file atomically:NO];
    if (success) 
    {
        self.path = file;
        self.dataLength = [data length];
        [data release]; // release the data from memory
        data = nil; 
    }    
}

- (id)initWithName:(NSString *)aName
              data:(NSData *)aData
              type:(JMCAttachmentType)aType
       contentType:(NSString *)aContentType
    filenameFormat:(NSString *)aFilenameFormat {
    self = [super init];
    if (self) {
        contentType = [aContentType retain];
        data = [aData retain];
        filenameFormat = [aFilenameFormat retain];
        name = [aName retain];
        type = aType;
        thumbnail = nil;
        [self saveDataToFile:[self attachmentDirPath]];
        deleteFileWhenSent = YES; // if a client gives us NSData, then clean up the temp file when sent
    }
    return self;
}

- (id)initWithName:(NSString *)aName 
              path:(NSString *)aPath 
        dataLength:(NSUInteger)aDataLength
              type:(JMCAttachmentType)aType
       contentType:(NSString *)aContentType 
    filenameFormat:(NSString *)aFilenameFormat
{
    self = [super init];
    if (self) {
        contentType = [aContentType retain];
        path = [aPath retain];
        deleteFileWhenSent = NO; // if a client gives us a path, do not delete it
        dataLength = aDataLength;
        filenameFormat = [aFilenameFormat retain];
        name = [aName retain];
        type = aType;
        thumbnail = nil;
    }
    return self;
}

-(void) setData:(NSData *)aData
{
    data = [aData retain]; 
    [self saveDataToFile:self.path];
}

-(NSData*) data
{
    return [NSData dataWithContentsOfFile:self.path];
}

- (void)encodeWithCoder:(NSCoder*)coder {
    
    [coder encodeObject:self.path forKey:kPath];
    [coder encodeObject:self.contentType forKey:kContentType];
    [coder encodeObject:self.filenameFormat forKey:kFilenameFormat];
    [coder encodeObject:self.name forKey:kName];
    [coder encodeInt:self.type forKey:kType];
    [coder encodeInt:self.dataLength forKey:kDataLength];
    [coder encodeBool:self.deleteFileWhenSent forKey:kDeleteFileWhenSent];
}

- (id)initWithCoder:(NSCoder*)coder {
    self = [super init];
    if (!self) return nil;
    
    self.path = [coder decodeObjectForKey:kPath];
    self.contentType = [coder decodeObjectForKey:kContentType];
    self.filenameFormat = [coder decodeObjectForKey:kFilenameFormat];
    self.name = [coder decodeObjectForKey:kName];
    self.type = [coder decodeIntForKey:kType];
    self.dataLength = [coder decodeIntForKey:kDataLength];
    self.deleteFileWhenSent = [coder decodeBoolForKey:kDeleteFileWhenSent];

    return self;
}


- (void)dealloc {
    [thumbnail release], thumbnail = nil;
    [filenameFormat release], filenameFormat = nil;
    [contentType release], contentType = nil;
    [data release], data = nil;
    [path release], path = nil;
    [name release], name = nil;
    [super dealloc];
}
@end