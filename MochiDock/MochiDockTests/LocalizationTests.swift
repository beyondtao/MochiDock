import Foundation
import Testing
@testable import MochiDock

@MainActor
struct LocalizationTests {
    private let expectedTranslations: [(key: String, english: String, simplifiedChinese: String)] = [
        ("Show Pet", "Show Pet", "显示宠物"),
        ("Hide Pet", "Hide Pet", "隐藏宠物"),
        ("Pet Size", "Pet Size", "宠物尺寸"),
        ("Quit MochiDock", "Quit MochiDock", "退出 MochiDock"),
        ("Small — 80", "Small — 80", "小 — 80"),
        ("Medium — 120", "Medium — 120", "中 — 120"),
        ("Large — 160", "Large — 160", "大 — 160"),
        ("Extra Large — 240", "Extra Large — 240", "超大 — 240"),
        ("Jumbo — 320", "Jumbo — 320", "特大 — 320"),
        ("MochiDock pet", "MochiDock pet", "MochiDock 宠物"),
        ("Resting", "Resting", "休息中"),
        ("Happy", "Happy", "开心"),
    ]

    @Test func applicationBundleDeclaresEnglishAndSimplifiedChinese() {
        #expect(Bundle.main.localizations.contains("en"))
        #expect(Bundle.main.localizations.contains("zh-Hans"))
    }

    @Test func catalogProvidesEveryEnglishAndSimplifiedChineseTranslation() throws {
        let englishBundle = try localizedBundle(for: "en")
        let simplifiedChineseBundle = try localizedBundle(for: "zh-Hans")

        for translation in expectedTranslations {
            #expect(
                englishBundle.localizedString(
                    forKey: translation.key,
                    value: nil,
                    table: nil
                ) == translation.english
            )
            #expect(
                simplifiedChineseBundle.localizedString(
                    forKey: translation.key,
                    value: nil,
                    table: nil
                ) == translation.simplifiedChinese
            )
        }
    }

    @Test func missingTranslationFallsBackToTheEnglishKey() throws {
        let simplifiedChineseBundle = try localizedBundle(for: "zh-Hans")
        let englishFallback = "Future English Fallback"

        #expect(
            simplifiedChineseBundle.localizedString(
                forKey: englishFallback,
                value: nil,
                table: nil
            ) == englishFallback
        )
    }

    private func localizedBundle(for localization: String) throws -> Bundle {
        let path = try #require(
            Bundle.main.path(forResource: localization, ofType: "lproj")
        )
        return try #require(Bundle(path: path))
    }
}
