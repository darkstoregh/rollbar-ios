//
//  RollbarNotifier.m
//  Rollbar
//
//  Created by Sergei Bezborodko on 3/18/14.
//  Copyright (c) 2014 Rollbar, Inc. All rights reserved.
//

#import "RollbarNotifier.h"
#import "RollbarThread.h"
#import "DDFileReader.h"
#import <UIKit/UIKit.h>
#include <sys/utsname.h>


static NSString *NOTIFIER_VERSION = @"0.0.3";
static NSString *QUEUED_ITEMS_FILE_NAME = @"rollbar.items";
static NSString *STATE_FILE_NAME = @"rollbar.state";

static NSUInteger MAX_RETRY_COUNT = 5;
static NSUInteger MAX_BATCH_SIZE = 10;

static NSString *queuedItemsFilePath = nil;
static NSString *stateFilePath = nil;
static NSMutableDictionary *queueState = nil;

static RollbarThread *rollbarThread;

@implementation RollbarNotifier

- (id)initWithAccessToken:(NSString*)accessToken configuration:(RollbarConfiguration*)configuration isRoot:(BOOL)isRoot {
    
    if ((self = [super init])) {
        if (configuration) {
            self.configuration = configuration;
        } else {
            self.configuration = [RollbarConfiguration configuration];
        }
        
        self.configuration.accessToken = accessToken;
        
        if (isRoot) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *cachesDirectory = [paths objectAtIndex:0];
            queuedItemsFilePath = [cachesDirectory stringByAppendingPathComponent:QUEUED_ITEMS_FILE_NAME];
            stateFilePath = [cachesDirectory stringByAppendingPathComponent:STATE_FILE_NAME];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:queuedItemsFilePath]) {
                [[NSFileManager defaultManager] createFileAtPath:queuedItemsFilePath contents:nil attributes:nil];
            }
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:stateFilePath]) {
                NSData *stateData = [NSData dataWithContentsOfFile:stateFilePath];
                NSDictionary *state = [NSJSONSerialization JSONObjectWithData:stateData options:0 error:nil];
                
                queueState = [state mutableCopy];
            } else {
                queueState = [@{@"offset": [NSNumber numberWithUnsignedInt:0],
                                @"retry_count": [NSNumber numberWithUnsignedInt:0]} mutableCopy];
            }
            
            [self.configuration _setRoot];
            rollbarThread = [[RollbarThread alloc] initWithNotifier:self];
            [rollbarThread start];
        }
    }
    
    return self;
}

- (void)logCrashReport:(NSString*)crashReport {
    NSDictionary *payload = [self buildPayloadWithLevel:self.configuration.crashLevel message:nil exception:nil extra:nil crashReport:crashReport];
    
    [self queuePayload:payload];
}

- (void)log:(NSString*)level message:(NSString*)message exception:(NSException*)exception data:(NSDictionary*)data {
    NSDictionary *payload = [self buildPayloadWithLevel:level message:message exception:exception extra:data crashReport:nil];
    
    [self queuePayload:payload];
}

- (void)saveQueueState {
    NSData *data = [NSJSONSerialization dataWithJSONObject:queueState options:0 error:nil];
    [data writeToFile:stateFilePath atomically:YES];
}

- (void)processSavedItems {
    __block NSString *lastAccessToken = nil;
    NSMutableArray *items = [NSMutableArray array];

    NSUInteger startOffset = [queueState[@"offset"] unsignedIntegerValue];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:queuedItemsFilePath];
    [fileHandle seekToEndOfFile];
    __block unsigned long long fileLength = [fileHandle offsetInFile];
    [fileHandle closeFile];
    
    if (!fileLength) {
        return;
    }
    
    // Empty out the queued item file if all items have been processed already
    if (startOffset == fileLength) {
        [@"" writeToFile:queuedItemsFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        queueState[@"offset"] = [NSNumber numberWithUnsignedInteger:0];
        queueState[@"retry_count"] = [NSNumber numberWithUnsignedInteger:0];
        [self saveQueueState];
        
        return;
    }
    
    // Iterate through the items file and send the items in batches.
    DDFileReader *reader = [[DDFileReader alloc] initWithFilePath:queuedItemsFilePath andOffset:startOffset];
    [reader enumerateLinesUsingBlock:^(NSString *line, NSUInteger nextOffset, BOOL *stop) {
        NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:[line dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        
        NSString *accessToken = payload[@"access_token"];
        
        // If the max batch size is reached as the file is being processed,
        // try sending the current batch before starting a new one
        if ([items count] >= MAX_BATCH_SIZE || (lastAccessToken != nil && [accessToken compare:lastAccessToken] != NSOrderedSame)) {
            BOOL shouldContinue = [self sendItems:items withAccessToken:lastAccessToken nextOffset:nextOffset];
            
            if (!shouldContinue) {
                // Return so that the current file offset will be retried next time the
                // file is processed
                return;
            }
            
            // The file has had items added since we started iterating through it,
            // update the known file length to equal the next offset
            if (nextOffset > fileLength) {
                fileLength = nextOffset;
            }
            
            [items removeAllObjects];
        }
        
        [items addObject:payload[@"data"]];
        
        lastAccessToken = accessToken;
    }];
    
    // The whole file has been read, send all of the pending items
    if ([items count]) {
        [self sendItems:items withAccessToken:lastAccessToken nextOffset:fileLength];
    }
}

- (NSDictionary*)buildPersonData {
    NSMutableDictionary *personData = [NSMutableDictionary dictionary];
    
    if (self.configuration.personId) {
        personData[@"id"] = self.configuration.personId;
    }
    if (self.configuration.personUsername) {
        personData[@"username"] = self.configuration.personUsername;
    }
    if (self.configuration.personEmail) {
        personData[@"email"] = self.configuration.personEmail;
    }
    
    if ([[personData allKeys] count]) {
        return personData;
    }
    
    return nil;
}

- (NSDictionary*)buildClientData {
    NSNumber *timestamp = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]]
    ;
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    
    NSString *version = infoDictionary[(NSString*)kCFBundleVersionKey];
    NSString *shortVersion = infoDictionary[@"CFBundleShortVersionString"];
    NSString *bundleName = infoDictionary[(NSString *)kCFBundleNameKey];
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceCode = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *iosData = [@{@"ios_version": [[UIDevice currentDevice] systemVersion],
                                      @"device_code": deviceCode,
                                      @"code_version": version,
                                      @"short_version": shortVersion,
                                      @"app_name": bundleName} mutableCopy];
    
    NSDictionary *data = @{@"timestamp": timestamp,
                           @"ios": iosData,
                           @"user_ip": @"$remote_ip"};
    
    return data;
}

- (NSDictionary*)buildPayloadWithLevel:(NSString*)level message:(NSString*)message exception:(NSException*)exception extra:(NSDictionary*)extra crashReport:(NSString*)crashReport {
    
    NSDictionary *clientData = [self buildClientData];
    NSDictionary *notifierData = @{@"name": @"rollbar-ios",
                                   @"version": NOTIFIER_VERSION};
    
    NSDictionary *body = [self buildPayloadBodyWithMessage:message exception:exception extra:extra crashReport:crashReport];
    
    NSMutableDictionary *data = [@{@"environment": self.configuration.environment,
                                   @"level": level,
                                   @"language": @"objective-c",
                                   @"framework": @"ios",
                                   @"platform": @"ios",
                                   @"uuid": [self generateUUID],
                                   @"client": clientData,
                                   @"notifier": notifierData,
                                   @"body": body} mutableCopy];
    
    NSDictionary *personData = [self buildPersonData];
    
    if (personData) {
        data[@"person"] = personData;
    }
    
    return @{@"access_token": self.configuration.accessToken,
             @"data": data};
}

- (NSDictionary*)buildPayloadBodyWithCrashReport:(NSString*)crashReport {
    return @{@"crash_report": @{@"raw": crashReport}};
}

- (NSDictionary*)buildPayloadBodyWithMessage:(NSString*)message extra:(NSDictionary*)extra {
    NSMutableDictionary *result = [@{@"body": message} mutableCopy];
    
    if (extra) {
        result[@"extra"] = extra;
    }
    
    return @{@"message": result};
}

- (NSDictionary*)buildPayloadBodyWithMessage:(NSString*)message exception:(NSException*)exception extra:(NSDictionary*)extra crashReport:(NSString*)crashReport {
    if (crashReport) {
        return [self buildPayloadBodyWithCrashReport:crashReport];
    } else {
        return [self buildPayloadBodyWithMessage:message extra:extra];
    }
}

- (void)queuePayload:(NSDictionary*)payload {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:queuedItemsFilePath];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[NSJSONSerialization dataWithJSONObject:payload options:0 error:nil]];
    [fileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
}

- (BOOL)sendItems:(NSArray*)itemData withAccessToken:(NSString*)accessToken nextOffset:(NSUInteger)nextOffset {
    NSDictionary *newPayload = @{@"access_token": accessToken,
                                 @"data": itemData};
    
    NSData *jsonPayload = [NSJSONSerialization dataWithJSONObject:newPayload options:0 error:nil];
    
    [NSThread sleepForTimeInterval:2];
    BOOL success = [self sendPayload:jsonPayload];
    if (!success) {
        NSUInteger retryCount = [queueState[@"retry_count"] unsignedIntegerValue];
        
        if (retryCount < MAX_RETRY_COUNT) {
            queueState[@"retry_count"] = [NSNumber numberWithUnsignedInteger:retryCount + 1];
            [self saveQueueState];
            
            // Return NO so that the current batch will be retried next time
            return NO;
        }
    }
    
    queueState[@"offset"] = [NSNumber numberWithUnsignedInteger:nextOffset];
    queueState[@"retry_count"] = [NSNumber numberWithUnsignedInteger:0];
    [self saveQueueState];
    
    return YES;
}

- (BOOL)sendPayload:(NSData*)payload {
    NSURL *url = [NSURL URLWithString:self.configuration.endpoint];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:self.configuration.accessToken forHTTPHeaderField:@"X-Rollbar-Access-Token"];
    [request setHTTPBody:payload];
    
    NSError *error;
    NSHTTPURLResponse *response;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error) {
        NSLog(@"[Rollbar] Error %@; %@", error, [error localizedDescription]);
    } else {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        if ([httpResponse statusCode] == 200) {
            NSLog(@"[Rollbar] Success");
            return YES;
        } else {
            NSLog(@"[Rollbar] There was a problem reporting to Rollbar");
            NSLog(@"[Rollbar] Response: %@", [NSJSONSerialization JSONObjectWithData:data options:0 error:nil]);
        }
    }
    
    return NO;
}

- (NSString*)generateUUID {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *string = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return string;
}
        
@end
