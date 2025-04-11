#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"local.VDC.VociDiCorridoio";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "GradientBottom" asset catalog color resource.
static NSString * const ACColorNameGradientBottom AC_SWIFT_PRIVATE = @"GradientBottom";

/// The "GradientTop" asset catalog color resource.
static NSString * const ACColorNameGradientTop AC_SWIFT_PRIVATE = @"GradientTop";

/// The "ProfImage" asset catalog image resource.
static NSString * const ACImageNameProfImage AC_SWIFT_PRIVATE = @"ProfImage";

/// The "SubjectImage" asset catalog image resource.
static NSString * const ACImageNameSubjectImage AC_SWIFT_PRIVATE = @"SubjectImage";

/// The "TimetableImage" asset catalog image resource.
static NSString * const ACImageNameTimetableImage AC_SWIFT_PRIVATE = @"TimetableImage";

/// The "using" asset catalog image resource.
static NSString * const ACImageNameUsing AC_SWIFT_PRIVATE = @"using";

#undef AC_SWIFT_PRIVATE
