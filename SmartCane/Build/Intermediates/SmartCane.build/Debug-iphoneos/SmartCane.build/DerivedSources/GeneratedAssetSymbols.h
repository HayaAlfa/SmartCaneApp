#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"fau.edu.SmartCane";

/// The "Brand" asset catalog color resource.
static NSString * const ACColorNameBrand AC_SWIFT_PRIVATE = @"Brand";

/// The "BrandMuted" asset catalog color resource.
static NSString * const ACColorNameBrandMuted AC_SWIFT_PRIVATE = @"BrandMuted";

#undef AC_SWIFT_PRIVATE
