//
//  RNDDDropTargetView.m
//  gustash-react-native-drag-drop
//
//  Created by Gustavo Parreira on 26/04/2022.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "RNDDDropTargetView.h"
#import "NSData+MimeTypes.h"

@interface RNDDDropTargetView () <UIDropInteractionDelegate>
@end

@implementation RNDDDropTargetView {
    NSMutableArray *items;
}

- (instancetype)init
{
    if (self = [super init]) {
        UIDropInteraction *dropInteraction = [[UIDropInteraction alloc]
                                              initWithDelegate:self];
        [self addInteraction:dropInteraction];
    }
    return self;
}

#pragma mark UIDropInteractionDelegate

- (BOOL)dropInteraction:(UIDropInteraction *)interaction
       canHandleSession:(id<UIDropSession>)session
{
    return YES;
//    return [session canLoadObjectsOfClass:[UIImage class]];
}

- (UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction
                   sessionDidUpdate:(id<UIDropSession>)session
{
    return [[UIDropProposal alloc] initWithDropOperation:UIDropOperationCopy];
}

- (void)dropInteraction:(UIDropInteraction *)interaction
            performDrop:(id<UIDropSession>)session
{
    if (!self.onDrop) {
        return;
    }
    
    self->items = [NSMutableArray new];
    NSArray<NSString *> *imageUTIs = @[
        (NSString *)kUTTypeJPEG,
        (NSString *)kUTTypeTIFF,
        (NSString *)kUTTypeGIF,
        (NSString *)kUTTypePNG,
        (NSString *)kUTTypeAppleICNS,
        (NSString *)kUTTypeBMP,
        (NSString *)kUTTypeICO,
        (NSString *)kUTTypeRawImage,
        (NSString *)kUTTypeScalableVectorGraphics,
        (NSString *)kUTTypeLivePhoto,
    ];
    dispatch_group_t dispatchGroup = dispatch_group_create();
    
    for (UIDragItem *item in session.items) {
        NSItemProvider *provider = item.itemProvider;
        
        if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
            NSString *imageUTI = [provider.registeredTypeIdentifiers firstObjectCommonWithArray:imageUTIs];
            [self loadItemAsFile:provider withUTI:imageUTI inDispatchGroup:dispatchGroup];
            continue;
        }
        
        if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
            continue;
        }
        
        if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeText]) {
            continue;
        }
        
        [self loadItemAsFile:provider
                     withUTI:provider.registeredTypeIdentifiers.firstObject
             inDispatchGroup:dispatchGroup];
    }
    
    typeof(self) __weak weakSelf = self;
    dispatch_group_notify(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(weakSelf) __strong strongSelf = weakSelf;
        if (strongSelf) {
            if (strongSelf->items.count > 0) {
                strongSelf.onDrop(@{
                    @"items": self->items,
                });
            }
        }
    });
//
//    if ([session canLoadObjectsOfClass:[NSURL class]]) {
//        // Handling URL
//        [session loadObjectsOfClass:[NSURL class] completion:^(NSArray<NSURL *> * _Nonnull urlList) {
//            for (NSURL *url in urlList) {
//                self.onDrop([self dropDataForURL:url]);
//            }
//        }];
//    }
//
//    if ([session canLoadObjectsOfClass:[NSString class]]) {
//        // Handling text
//        [session loadObjectsOfClass:[NSString class] completion:^(NSArray<NSString *> * _Nonnull textList) {
//            for (NSString *text in textList) {
//                self.onDrop([self dropDataForText:text]);
//            }
//        }];
//    }
//
//    if ([session canLoadObjectsOfClass:[UIImage class]]) {
//        // Handling image
//        for (UIDragItem *item in session.items) {
//            NSItemProvider *provider = item.itemProvider;
//            NSString *typeIdentifier = [provider.registeredTypeIdentifiers firstObject];
//            NSLog(@"Type Identifiers: %@", provider.registeredTypeIdentifiers);
//            [provider loadDataRepresentationForTypeIdentifier:(NSString *)kUTTypeImage
//                                            completionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
//                self.onDrop([self dropDataForImageData:data withFilename:provider.suggestedName typeIndentifier:typeIdentifier]);
//            }];
//        }
//    }
}

#pragma mark Object Handlers

- (void)loadItemAsFile:(NSItemProvider *)provider
               withUTI:(NSString *)identifier
       inDispatchGroup:(dispatch_group_t)dispatchGroup
{
    dispatch_group_enter(dispatchGroup);
    NSURL *tempDirectoryURL = [[[NSURL alloc] initFileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
                               URLByAppendingPathComponent:@"ReactNativeDragDrop"];

    typeof(self) __weak weakSelf = self;
    [provider loadFileRepresentationForTypeIdentifier:identifier completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error loading file %@ with identifier %@", provider.suggestedName, identifier);
            dispatch_group_leave(dispatchGroup);
            return;
        }
        
        if (!url) {
            NSLog(@"Did not get URL for file %@ with identifier %@", provider.suggestedName, identifier);
            dispatch_group_leave(dispatchGroup);
            return;
        }
        
        typeof(weakSelf) __strong strongSelf = weakSelf;
        if (strongSelf) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *_Nullable error;
            [fileManager createDirectoryAtURL:tempDirectoryURL
                  withIntermediateDirectories:YES
                                   attributes:nil
                                        error:&error];
            if (error) {
                NSLog(@"Error creating directory at %@: %@", tempDirectoryURL.absoluteString, error.localizedDescription);
                dispatch_group_leave(dispatchGroup);
                return;
            }
            
            
            NSString *fileName = [strongSelf duplicateFilenameFromURL:url inBasePathURL:tempDirectoryURL];
            NSURL *newPathURL = [tempDirectoryURL URLByAppendingPathComponent:fileName];
            
            // Move file from original URL to temp directory so React Native can access it
            [fileManager moveItemAtURL:url toURL:newPathURL error:&error];
            if (error) {
                NSLog(@"Error moving file from %@ to %@: %@",
                      url.absoluteString,
                      newPathURL.absoluteString,
                      error.localizedDescription);
                dispatch_group_leave(dispatchGroup);
                return;
            }
            
            CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)identifier, kUTTagClassMIMEType);
            [strongSelf->items addObject:@{
                @"data": newPathURL.absoluteString,
                @"filename": fileName,
                @"type": (__bridge_transfer NSString *)MIMEType,
            }];
            dispatch_group_leave(dispatchGroup);
        }
    }];
}

- (NSDictionary *)dropDataForURL:(NSURL *)url
{
    return @{
        @"data": url.absoluteString,
        @"type": @"text/plain",
    };
}

- (NSDictionary *)dropDataForText:(NSString *)text
{
    return @{
        @"data": text,
        @"type": @"text/plain",
    };
}

- (NSDictionary * _Nullable)dropDataForImageData:(NSData *)imageData
                                    withFilename:(NSString *)filename
                                 typeIndentifier:(NSString *)identifier
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString * _Nullable basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    if (!basePath) {
        return nil;
    }
    
    CFStringRef UTI = (__bridge CFStringRef)identifier;
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    NSString *MIMETypeString = (__bridge_transfer NSString *)MIMEType;
    NSString *imagePath = [basePath stringByAppendingPathComponent:filename];
    
    [imageData writeToFile:imagePath atomically:YES];
    return @{
        @"data": imagePath,
        @"type": MIMETypeString,
    };
}

#pragma mark FileManager Helpers

- (NSString *)duplicateFilenameFromURL:(NSURL *)fileURL inBasePathURL:(NSURL *)pathURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fileName = fileURL.lastPathComponent;
    
    if (![fileManager fileExistsAtPath:[pathURL URLByAppendingPathComponent:fileName].path]) {
        // File does not exist, use the original file name
        return fileName;
    }
    
    // If the file already exists, we want to make a copy with a different name
    NSString *fileExtension = fileURL.pathExtension;
    NSString *fileNameWithoutExtension = [fileURL.lastPathComponent stringByDeletingPathExtension];
    NSString *duplicateFileName;
    int duplicateIndex = 0;
    while (YES) {
        // This will result in a fileName like: myfilename_1
        duplicateFileName = [NSString stringWithFormat:@"%@_%d", fileNameWithoutExtension, duplicateIndex + 1];
        if (fileExtension) {
            // This will result in a fileName like: myfilename_1.jpg
            duplicateFileName = [NSString stringWithFormat:@"%@.%@", duplicateFileName, fileExtension];
        }
        
        // We had already made a duplicate with this name, increment index and stay in loop
        if ([fileManager fileExistsAtPath:[pathURL URLByAppendingPathComponent:duplicateFileName].path]) {
            duplicateIndex++;
            continue;
        }
        
        // This fileName is unique, use it
        break;
    }
    return duplicateFileName;
}

@end
