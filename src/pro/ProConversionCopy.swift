import Foundation

/// View-layer presenter for the Pro-transition prompts. Reads raw data from `UsageStats`
/// and returns fully-formatted strings — one entry point per Day X body/subtitle so the
/// message composition lives in one place. `UsageStats` stays pure data; presentation
/// belongs here.
enum ProConversionCopy {
    /// [B] Day 12 subtitle — references what the user has been using.
    /// 0 used → generic line; 1–2 used → name them; 3+ → show the count. Both populated branches
    /// break to two lines via `\n` so they read as two short scannable thoughts.
    static func day12Subtitle() -> String {
        let used = UsageStats.usedProFeatureNames()
        if used.isEmpty {
            return NSLocalizedString("There is no trial period in this fork.", comment: "")
        }
        if used.count <= 2 {
            return String(format: NSLocalizedString(
                "You've been using %@.\nThese features remain available.",
                comment: ""), used.joined(separator: " and "))
        }
        return String(format: NSLocalizedString(
            "You've been using %d advanced features.\nThey remain available.",
            comment: ""), used.count)
    }

    static func day21Body() -> String {
        let triggers = UsageStats.triggerCount
        let proCount = UsageStats.usedProFeaturesSessionCount

        if triggers > 0 && proCount > 0 {
            return String(format: NSLocalizedString(
                "You've used AltTab %@ times; %@ of those used advanced features.",
                comment: ""),
                UsageStats.formatCount(triggers),
                UsageStats.formatCount(proCount))
        }
        if triggers > 0 {
            return String(format: NSLocalizedString(
                "You've used AltTab %@ times.",
                comment: ""),
                UsageStats.formatCount(triggers))
        }
        return NSLocalizedString("Every feature is available in this free fork.", comment: "")
    }
}
