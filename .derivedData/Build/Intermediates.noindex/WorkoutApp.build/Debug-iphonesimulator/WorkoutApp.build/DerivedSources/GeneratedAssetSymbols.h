#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.local.WorkoutApp";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "guide-squat" asset catalog image resource.
static NSString * const ACImageNameGuideSquat AC_SWIFT_PRIVATE = @"guide-squat";

/// The "guide-squat-pattern" asset catalog image resource.
static NSString * const ACImageNameGuideSquatPattern AC_SWIFT_PRIVATE = @"guide-squat-pattern";

#undef AC_SWIFT_PRIVATE
