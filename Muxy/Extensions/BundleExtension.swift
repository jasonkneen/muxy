import Foundation

extension Bundle {
    static let appResources: Bundle = {
        let bundleName = "Muxy_Muxy"

        let candidates = [
            Bundle.main.resourceURL,
            Bundle.main.bundleURL,
        ]

        for candidate in candidates {
            guard let candidate else { continue }
            let path = candidate.appendingPathComponent(bundleName + ".bundle")
            if let bundle = Bundle(path: path.path) {
                return bundle
            }
        }

        return .module
    }()
}
