import Foundation

/// Legacy helper retained for source compatibility with upstream files.
/// The free fork does not tailor Sparkle requests by license tier.
func syncLicenseCookie(state: LicenseState) {
    guard let host = URL(string: Endpoints.website)?.host else { return }
    let value: String
    switch state {
    case .pro: value = "pro"
    case .proExpired: value = "proExpired"
    default: value = ""
    }
    let cookie = HTTPCookie(properties: [
        .name: "license",
        .value: value,
        .domain: "." + host,
        .path: "/",
        .expires: Date.distantFuture,
        .secure: true,
    ])
    if let cookie { HTTPCookieStorage.shared.setCookie(cookie) }
}
