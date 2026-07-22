import Foundation
import Testing
@testable import MochiDock

@MainActor
struct LocalizationTests {
    private let expectedTranslations: [(key: String, english: String, simplifiedChinese: String)] = [
        ("Show Pet", "Show Pet", "显示宠物"),
        ("Hide Pet", "Hide Pet", "隐藏宠物"),
        ("Settings…", "Settings…", "设置…"),
        ("MochiDock Settings", "MochiDock Settings", "MochiDock 设置"),
        ("Pet", "Pet", "宠物"),
        ("Application", "Application", "应用"),
        (
            "A quiet little friend on your desktop",
            "A quiet little friend on your desktop",
            "安静陪伴在桌面上的小伙伴"
        ),
        (
            "Adjust how your little friend looks and responds.",
            "Adjust how your little friend looks and responds.",
            "调整小伙伴的外观与互动方式。"
        ),
        (
            "Choose how MochiDock behaves on your Mac.",
            "Choose how MochiDock behaves on your Mac.",
            "选择 MochiDock 在 Mac 上的运行方式。"
        ),
        (
            "When the pointer comes close, your little friend will notice you.",
            "When the pointer comes close, your little friend will notice you.",
            "鼠标靠近时，小伙伴会注意到你。"
        ),
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
        ("Pointer Proximity Response", "Pointer Proximity Response", "鼠标接近回应"),
        ("Start at Login", "Start at Login", "登录时启动"),
        (
            "Allow MochiDock in System Settings > General > Login Items.",
            "Allow MochiDock in System Settings > General > Login Items.",
            "请在“系统设置 > 通用 > 登录项”中允许 MochiDock。"
        ),
        (
            "MochiDock’s login item is unavailable.",
            "MochiDock’s login item is unavailable.",
            "MochiDock 的登录项当前不可用。"
        ),
        (
            "Couldn’t update Start at Login.",
            "Couldn’t update Start at Login.",
            "无法更新“登录时启动”。"
        ),
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
