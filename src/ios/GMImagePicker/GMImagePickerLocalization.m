//
//  GMImagePickerLocalization.m
//
//

#import "GMImagePickerLocalization.h"

@implementation GMImagePickerLocalization

static NSBundle *GMImagePickerLocalizationBundle = nil;
static NSString *GMImagePickerPreferredLanguage = nil;

+ (void)setPreferredLanguage:(NSString *)language {
    if (language == (id)[NSNull null]) {
        language = nil;
    }
    if (language != nil && [language length] == 0) {
        language = nil;
    }
    if ((GMImagePickerPreferredLanguage == nil && language == nil) ||
        (GMImagePickerPreferredLanguage != nil && [GMImagePickerPreferredLanguage isEqualToString:language])) {
        return;
    }
    GMImagePickerPreferredLanguage = [language copy];
    GMImagePickerLocalizationBundle = [self bundleForLanguage:GMImagePickerPreferredLanguage];
}

+ (NSBundle *)bundle {
    return GMImagePickerLocalizationBundle ?: [NSBundle mainBundle];
}

+ (NSBundle *)bundleForLanguage:(NSString *)language {
    if (language == nil || [language length] == 0) {
        return nil;
    }

    NSString *tag = [language stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    NSMutableArray<NSString *> *candidates = [[NSMutableArray alloc] init];
    if ([tag length] > 0) {
        [candidates addObject:tag];
    }

    NSArray<NSString *> *parts = [tag componentsSeparatedByString:@"-"];
    if (parts.count > 0 && [parts[0] length] > 0) {
        [candidates addObject:parts[0]];
    }

    for (NSString *candidate in candidates) {
        NSString *path = [[NSBundle mainBundle] pathForResource:candidate ofType:@"lproj"];
        if (path != nil) {
            return [NSBundle bundleWithPath:path];
        }
    }

    return nil;
}

@end
