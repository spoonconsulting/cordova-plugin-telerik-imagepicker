//
//  SOSPicker.m
//  SyncOnSet
//
//  Created by Christopher Sullivan on 10/25/13.
//
//

#import "SOSPicker.h"
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import "GMImagePickerController.h"
#import "GMFetchItem.h"

#define CDV_PHOTO_PREFIX @"cdv_photo_"

typedef enum : NSUInteger {
    FILE_URI = 0,
    BASE64_STRING = 1
} SOSPickerOutputType;

@interface SOSPicker () <GMImagePickerControllerDelegate, UIAdaptivePresentationControllerDelegate>
@end

@implementation SOSPicker

@synthesize callbackId;

- (void) hasReadPermission:(CDVInvokedUrlCommand *)command {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) requestReadPermission:(CDVInvokedUrlCommand *)command {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authStatus) {
        NSString* status = [self getCameraRollAuthorizationStatusAsString:authStatus];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:status] callbackId:command.callbackId];
    }];
}

- (NSString*) getCameraRollAuthorizationStatusAsString: (PHAuthorizationStatus)authStatus
{
    NSString* status;
    if(authStatus == PHAuthorizationStatusDenied || authStatus == PHAuthorizationStatusRestricted){
        status = @"denied";
    }else if(authStatus == PHAuthorizationStatusNotDetermined ){
        status = @"not_determined";
    }else if(authStatus == PHAuthorizationStatusAuthorized){
        status = @"authorized";
    }
    return status;
}

- (void) getPictures:(CDVInvokedUrlCommand *)command {

    NSDictionary *options = [command.arguments objectAtIndex: 0];

    self.outputType = [[options objectForKey:@"outputType"] integerValue];
    BOOL allow_video = [[options objectForKey:@"allow_video" ] boolValue ];
    NSInteger maximumImagesCount = [[options objectForKey:@"maximumImagesCount"] integerValue];
    NSString * title = [options objectForKey:@"title"];
    NSString * message = [options objectForKey:@"message"];
    BOOL disable_popover = [[options objectForKey:@"disable_popover" ] boolValue];
    if (message == (id)[NSNull null]) {
      message = nil;
    }
    self.width = [[options objectForKey:@"width"] integerValue];
    self.height = [[options objectForKey:@"height"] integerValue];
    self.quality = [[options objectForKey:@"quality"] integerValue];
    self.maxMB = [[options objectForKey:@"maxFileSize"] integerValue];

    self.callbackId = command.callbackId;
    [self launchGMImagePicker:allow_video title:title message:message disable_popover:disable_popover maximumImagesCount:maximumImagesCount];
}

- (void)launchGMImagePicker:(bool)allow_video title:(NSString *)title message:(NSString *)message disable_popover:(BOOL)disable_popover maximumImagesCount:(NSInteger)maximumImagesCount
{
    GMImagePickerController *picker = [[GMImagePickerController alloc] init:allow_video];
    picker.delegate = self;
    picker.presentationController.delegate = self;
    picker.maximumImagesCount = maximumImagesCount;
    picker.title = title;
    picker.customNavigationBarPrompt = message;
    picker.colsInPortrait = 4;
    picker.colsInLandscape = 6;
    picker.minimumInteritemSpacing = 2.0;

    if(!disable_popover) {
        picker.modalPresentationStyle = UIModalPresentationPopover;

        UIPopoverPresentationController *popPC = picker.popoverPresentationController;
        popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
        popPC.sourceView = picker.view;
        //popPC.sourceRect = nil;
    }

    [self.viewController showViewController:picker sender:nil];
}


- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize
{
    UIImage* sourceImage = anImage;
    UIImage* newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = frameSize.width;
    CGFloat targetHeight = frameSize.height;
    CGFloat scaleFactor = 0.0;
    CGSize scaledSize = frameSize;

    if (CGSizeEqualToSize(imageSize, frameSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;

        // opposite comparison to imageByScalingAndCroppingForSize in order to contain the image within the given bounds
        if (widthFactor == 0.0) {
            scaleFactor = heightFactor;
        } else if (heightFactor == 0.0) {
            scaleFactor = widthFactor;
        } else if (widthFactor > heightFactor) {
            scaleFactor = heightFactor; // scale to fit height
        } else {
            scaleFactor = widthFactor; // scale to fit width
        }
        scaledSize = CGSizeMake(floor(width * scaleFactor), floor(height * scaleFactor));
    }

    UIGraphicsBeginImageContextWithOptions(scaledSize, YES, 1.0); // this will resize

    [sourceImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];

    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not scale image");
    }

    // pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}


#pragma mark - UIImagePickerControllerDelegate


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"UIImagePickerController: User finished picking assets");
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    CDVPluginResult* pluginResult = nil;
    NSArray* emptyArray = [NSArray array];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:emptyArray];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"UIImagePickerController: User pressed cancel button");
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (void)presentationControllerWillDismiss:(UIPresentationController *)presentationController {
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    CDVPluginResult* pluginResult = nil;
    NSArray* emptyArray = [NSArray array];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:emptyArray];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    [presentationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"GMImagePicker: User swiped down to cancel");
}

#pragma mark - GMImagePickerControllerDelegate

- (void)assetsPickerController:(GMImagePickerController *)picker didFinishPickingAssets:(NSArray *)fetchArray
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];

    NSLog(@"GMImagePicker: User finished picking assets. Number of selected items is: %lu", (unsigned long)fetchArray.count);

    NSMutableArray * resultList = [[NSMutableArray alloc] init];
    CGSize targetSize = CGSizeMake(self.width, self.height);
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"NoCloud"];
  
    NSError* err = nil;
    NSString* filePath;
    CDVPluginResult* result = nil;

    NSArray *phAssets = picker.selectedAssets;

    for (NSInteger i = 0; i < fetchArray.count; i++) {
        GMFetchItem *item = fetchArray[i];
        PHAsset *phAsset = (i < phAssets.count) ? phAssets[i] : nil;

        if ( !item.image_fullsize ) {
            continue;
        }
     
        BOOL isVideo = NO;
        if (phAsset && phAsset.mediaType == PHAssetMediaTypeVideo) {
            isVideo = YES;
        }
    
        NSString *fileExtension = isVideo ? @"mp4" : @"jpg";
        do {
            filePath = [NSString stringWithFormat:@"%@/%@.%@", libPath, [[NSUUID UUID] UUIDString], fileExtension];
        } while ([fileMgr fileExistsAtPath:filePath]);
        
        if (isVideo && phAsset) {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            __block BOOL exportSuccess = NO;
            __block NSError *exportError = nil;
            
            [self exportVideoFromPHAsset:phAsset toPath:filePath completion:^(BOOL success, NSError *error) {
                exportSuccess = success;
                exportError = error;
                dispatch_semaphore_signal(semaphore);
            }];
            
            dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 5 * 60 * NSEC_PER_SEC);
            if (dispatch_semaphore_wait(semaphore, timeout) != 0) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:@"Video export timeout"];
                break;
            }
            
            if (exportSuccess) {
                CGSize videoSize = [self getVideoDimensionsAtPath:filePath];
                NSString *thumbnailPath = [self generateThumbnailForVideoAtURL:[NSURL fileURLWithPath:filePath]];
                NSMutableDictionary *videoInfo = [NSMutableDictionary dictionaryWithDictionary:@{@"path":[[NSURL fileURLWithPath:filePath] absoluteString],
                                            @"isVideo": @(YES),
                                            @"width": [NSNumber numberWithFloat:videoSize.width],
                                            @"height": [NSNumber numberWithFloat:videoSize.height]}];
                if (thumbnailPath) {
                    [videoInfo setObject:[[NSURL fileURLWithPath:thumbnailPath] absoluteString] forKey:@"thumbnail"];
                }
                [resultList addObject: videoInfo];
            } else {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:exportError ? exportError.localizedDescription : @"Video export failed"];
                break;
            }
            continue;
        }
        
        // Handle images
        NSData* data = nil;
        if (self.width == 0 && self.height == 0) {
            // no scaling required
            if (self.outputType == BASE64_STRING){
                UIImage* image = [UIImage imageNamed:item.image_fullsize];
                NSDictionary *imageInfo = @{@"path":[UIImageJPEGRepresentation(image, self.quality/100.0f) base64EncodedStringWithOptions:0], 
                                            @"width": [NSNumber numberWithFloat:image.size.width],
                                            @"height": [NSNumber numberWithFloat:image.size.height]};
                [resultList addObject: imageInfo];
            } else {
                if (self.quality == 100) {
                    // no scaling, no downsampling, this is the fastest option
                    UIImage* image = [UIImage imageNamed:item.image_fullsize];
                    NSDictionary *imageInfo = @{@"path":item.image_fullsize, 
                                                @"width": [NSNumber numberWithFloat:image.size.width], 
                                                @"height": [NSNumber numberWithFloat:image.size.height]};
                    [resultList addObject: imageInfo];
                   
                } else {
                    // resample first
                    UIImage* image = [UIImage imageNamed:item.image_fullsize];
                    data = UIImageJPEGRepresentation(image, self.quality/100.0f);
                    if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
                        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
                        break;
                    } else {
                        NSDictionary *imageInfo = @{@"path":[[NSURL fileURLWithPath:filePath] absoluteString], 
                                                    @"width": [NSNumber numberWithFloat:image.size.width], 
                                                    @"height": [NSNumber numberWithFloat:image.size.height]};
                        [resultList addObject: imageInfo];
                    }
                }
            }
        } else {
            // scale
            UIImage* image = [UIImage imageNamed:item.image_fullsize];
            UIImage* scaledImage = [self imageByScalingNotCroppingForSize:image toSize:targetSize];
            data = UIImageJPEGRepresentation(scaledImage, self.quality/100.0f);

            if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
                break;
            } else {
                if(self.outputType == BASE64_STRING){
                    NSDictionary *imageInfo = @{@"path":[data base64EncodedStringWithOptions:0], 
                                                @"width": [NSNumber numberWithFloat:scaledImage.size.width], 
                                                @"height": [NSNumber numberWithFloat:scaledImage.size.height]};
                    [resultList addObject: imageInfo];
                } else {
                    NSDictionary *imageInfo = @{@"path":[[NSURL fileURLWithPath:filePath] absoluteString], 
                                                @"width": [NSNumber numberWithFloat:scaledImage.size.width], 
                                                @"height": [NSNumber numberWithFloat:scaledImage.size.height]};
                    [resultList addObject: imageInfo];
                }
            }
        }
    }

    if (result == nil) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:resultList];
    }

    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];

}

- (CGSize)getVideoDimensionsAtPath:(NSString *)path {
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if ([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGSize size = videoTrack.naturalSize;
        return size;
    }
    return CGSizeMake(0, 0);
}

- (void)exportVideoFromPHAsset:(PHAsset *)asset toPath:(NSString *)outputPath completion:(void (^)(BOOL success, NSError *error))completion {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionCurrent;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeFastFormat;
    options.networkAccessAllowed = YES;
    
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
        if (avAsset == nil) {
            if (completion) {
                completion(NO, [NSError errorWithDomain:@"VideoExport" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to load video asset"}]);
            }
            return;
        }
        
        NSError *error;

        if ([avAsset isKindOfClass:[AVURLAsset class]]) {
            AVURLAsset *urlAsset = (AVURLAsset *)avAsset;
            NSURL *sourceURL = urlAsset.URL;
            
            if (sourceURL && [[NSFileManager defaultManager] isReadableFileAtPath:sourceURL.path]) {
                NSError *copyError = nil;
                if ([[NSFileManager defaultManager] copyItemAtPath:sourceURL.path toPath:outputPath error:&copyError]) {
                    if (completion) {
                        completion(YES, nil);
                    }
                    return;
                } else {
                    error = [NSError errorWithDomain:@"VideoExport" code:-1 userInfo:@{NSLocalizedDescriptionKey: copyError.localizedDescription}];
                    if (completion) {
                        completion(NO, error);
                    }
                }
            } else {
                error = [NSError errorWithDomain:@"VideoExport" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Source file not readable or doesn't exist"}];
                if (completion) {
                    completion(NO, error);
                }
            }
        } else {
            error = [NSError errorWithDomain:@"VideoExport" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"AVAsset is not AVURLAsset"}];
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

- (NSString*)generateThumbnailForVideoAtURL:(NSURL *)videoURL {
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(1.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];

    if (error) {
        NSLog(@"Error generating thumbnail: %@", error.localizedDescription);
        return nil;
    }

    UIImage *thumbnail = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"NoCloud"];
    NSError *directoryError = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:libraryDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:libraryDirectory withIntermediateDirectories:YES attributes:nil error:&directoryError];
        if (directoryError) {
            NSLog(@"Error creating NoCloud directory: %@", directoryError.localizedDescription);
            return nil;
        }
    }
    
    NSString *uniqueFileName = [NSString stringWithFormat:@"video_thumb_%@.jpg", [[NSUUID UUID] UUIDString]];
    NSString *filePath = [libraryDirectory stringByAppendingPathComponent:uniqueFileName];
    NSData *jpegData = UIImageJPEGRepresentation(thumbnail, 1.0);
    
    if ([jpegData writeToFile:filePath atomically:YES]) {
        NSLog(@"Thumbnail saved successfully at path: %@", filePath);
    } else {
        NSLog(@"Failed to save thumbnail.");
        return nil;
    }
    
    return filePath;
}
 
//Optional implementation:
-(void)assetsPickerControllerDidCancel:(GMImagePickerController *)picker
{
   CDVPluginResult* pluginResult = nil;
   NSArray* emptyArray = [NSArray array];
   pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:emptyArray];
   [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
   [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
   NSLog(@"GMImagePicker: User pressed cancel button");
}

- (void) closeImagePicker:(CDVInvokedUrlCommand *)command {
    bool boolMessage = FALSE;
    if (self.viewController != nil) {
      [self.viewController dismissViewControllerAnimated:YES completion:nil];
      boolMessage = TRUE;
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:boolMessage];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - GMImagePickerControllerDelegate - Asset Filtering

- (BOOL)assetsPickerController:(GMImagePickerController *)picker shouldShowAsset:(PHAsset *)asset {
    if (asset.mediaType != PHAssetMediaTypeVideo) {
        return YES;
    }

    NSArray *resources = [PHAssetResource assetResourcesForAsset:asset];
    long long fileSize = 0;
    
    for (PHAssetResource *resource in resources) {
        if (resource.type == PHAssetResourceTypeVideo ||
            resource.type == PHAssetResourceTypeFullSizeVideo ||
            resource.type == PHAssetResourceTypePairedVideo) {
            
            @try {
                id fileSizeValue = [resource valueForKey:@"fileSize"];
                if ([fileSizeValue isKindOfClass:[NSNumber class]]) {
                    fileSize = [fileSizeValue longLongValue];
                    break;
                }
            } @catch (NSException *exception) {
                // Continue to next resource if fileSize is not available
            }
        }
    }
    
    if (fileSize > 0) {
        CGFloat mb = fileSize / (1024.0 * 1024.0);
        
        if (mb > self.maxMB) {
            return NO;
        }
        return YES;
    }
    return YES;
}

@end
