import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

    /// The "GradientBottom" asset catalog color resource.
    static let gradientBottom = DeveloperToolsSupport.ColorResource(name: "GradientBottom", bundle: resourceBundle)

    /// The "GradientTop" asset catalog color resource.
    static let gradientTop = DeveloperToolsSupport.ColorResource(name: "GradientTop", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "ProfImage" asset catalog image resource.
    static let prof = DeveloperToolsSupport.ImageResource(name: "ProfImage", bundle: resourceBundle)

    /// The "SubjectImage" asset catalog image resource.
    static let subject = DeveloperToolsSupport.ImageResource(name: "SubjectImage", bundle: resourceBundle)

    /// The "TimetableImage" asset catalog image resource.
    static let timetable = DeveloperToolsSupport.ImageResource(name: "TimetableImage", bundle: resourceBundle)

    /// The "using" asset catalog image resource.
    static let using = DeveloperToolsSupport.ImageResource(name: "using", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "GradientBottom" asset catalog color.
    static var gradientBottom: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gradientBottom)
#else
        .init()
#endif
    }

    /// The "GradientTop" asset catalog color.
    static var gradientTop: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gradientTop)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "GradientBottom" asset catalog color.
    static var gradientBottom: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .gradientBottom)
#else
        .init()
#endif
    }

    /// The "GradientTop" asset catalog color.
    static var gradientTop: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .gradientTop)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "GradientBottom" asset catalog color.
    static var gradientBottom: SwiftUI.Color { .init(.gradientBottom) }

    /// The "GradientTop" asset catalog color.
    static var gradientTop: SwiftUI.Color { .init(.gradientTop) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "GradientBottom" asset catalog color.
    static var gradientBottom: SwiftUI.Color { .init(.gradientBottom) }

    /// The "GradientTop" asset catalog color.
    static var gradientTop: SwiftUI.Color { .init(.gradientTop) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "ProfImage" asset catalog image.
    static var prof: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .prof)
#else
        .init()
#endif
    }

    /// The "SubjectImage" asset catalog image.
    static var subject: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .subject)
#else
        .init()
#endif
    }

    /// The "TimetableImage" asset catalog image.
    static var timetable: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .timetable)
#else
        .init()
#endif
    }

    /// The "using" asset catalog image.
    static var using: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .using)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "ProfImage" asset catalog image.
    static var prof: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .prof)
#else
        .init()
#endif
    }

    /// The "SubjectImage" asset catalog image.
    static var subject: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .subject)
#else
        .init()
#endif
    }

    /// The "TimetableImage" asset catalog image.
    static var timetable: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .timetable)
#else
        .init()
#endif
    }

    /// The "using" asset catalog image.
    static var using: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .using)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

