//
//  GMImagePickerLocalization.h
//
//

#import <Foundation/Foundation.h>

@interface GMImagePickerLocalization : NSObject

+ (void)setPreferredLanguage:(NSString *)language;
+ (NSBundle *)bundle;

@end

static inline NSString *GMImagePickerLocalizedString(NSString *key, NSString *comment) {
    return NSLocalizedStringFromTableInBundle(key, @"GMImagePicker", [GMImagePickerLocalization bundle], comment);
}

static inline NSString *SOSPickerLocalizedString(NSString *key, NSString *comment) {
    return NSLocalizedStringFromTableInBundle(key, @"SOSPicker", [GMImagePickerLocalization bundle], comment);
}
