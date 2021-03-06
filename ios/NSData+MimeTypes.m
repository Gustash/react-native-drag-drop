//
//  NSData+MimeTypes.m
//  gustash-react-native-drag-drop
//
//  Created by Gustavo Parreira on 26/04/2022.
//

#import "NSData+MimeTypes.h"

@implementation NSData (MimeTypes)

- (NSString *)mimeType {
    uint8_t c;
    [self getBytes:&c length:1];

    switch (c) {
        case 0xFF:
            return @"image/jpeg";
            break;
        case 0x89:
            return @"image/png";
            break;
        case 0x47:
            return @"image/gif";
            break;
        case 0x49:
        case 0x4D:
            return @"image/tiff";
            break;
        case 0x25:
            return @"application/pdf";
            break;
        case 0xD0:
            return @"application/vnd";
            break;
        case 0x46:
            return @"text/plain";
            break;
        default:
            return @"application/octet-stream";
    }
    return nil;
}

@end
