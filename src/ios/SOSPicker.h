//
//  SOSPicker.h
//  SyncOnSet
//
//  Created by Christopher Sullivan on 10/25/13.
//
//

#import <Cordova/CDVPlugin.h>
#import "GMImagePickerController.h"


@interface SOSPicker : CDVPlugin < UINavigationControllerDelegate, UIScrollViewDelegate>

@property (copy)   NSString* callbackId;

- (void) getPictures:(CDVInvokedUrlCommand *)command;
- (void) hasReadPermission:(CDVInvokedUrlCommand *)command;
- (void) requestReadPermission:(CDVInvokedUrlCommand *)command;
- (void) closeImagePicker:(CDVInvokedUrlCommand *)command;

- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize;

@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger quality;
@property (nonatomic, assign) NSInteger outputType;
@property (nonatomic, assign) NSInteger maxVideoSize;
@property (nonatomic, assign) NSInteger maxPhotoSize;
@property (nonatomic, assign) BOOL mediaSizeLimitExceeded;
@property (nonatomic, assign) BOOL videoExportFailed;

@end
