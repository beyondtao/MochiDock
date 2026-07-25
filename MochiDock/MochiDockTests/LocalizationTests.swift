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
        ("Reminders", "Reminders", "提醒"),
        (
            "Let your little friend gently remind you.",
            "Let your little friend gently remind you.",
            "让小伙伴轻轻提醒你。"
        ),
        ("Complete", "Complete", "完成"),
        ("Remind me in 10 minutes", "Remind me in 10 minutes", "10 分钟后提醒"),
        ("Add Reminder", "Add Reminder", "添加提醒"),
        ("Edit Reminder", "Edit Reminder", "编辑提醒"),
        ("Reminder Name", "Reminder Name", "提醒名称"),
        ("Enable", "Enable", "启用"),
        ("Pause", "Pause", "暂停"),
        ("Edit", "Edit", "编辑"),
        ("Save", "Save", "保存"),
        ("Cancel", "Cancel", "取消"),
        ("Delete", "Delete", "删除"),
        ("Delete Reminder?", "Delete Reminder?", "删除提醒？"),
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

    @Test func reminderDynamicTextIsFullyLocalizedAndSafelyInterpolatesNames() throws {
        let name = "A very long tea & stretch <提醒>"
        let english = ReminderLocalizedText(bundle: try localizedBundle(for: "en"))
        let chinese = ReminderLocalizedText(bundle: try localizedBundle(for: "zh-Hans"))

        #expect(english.bubble(name: name) == "Time for A very long tea & stretch <提醒>!")
        #expect(chinese.bubble(name: name) == "该A very long tea & stretch <提醒>啦～")
        #expect(english.currentlyRunning(name: name) == "Running: A very long tea & stretch <提醒>")
        #expect(chinese.currentlyRunning(name: name) == "当前运行：A very long tea & stretch <提醒>")
        #expect(english.pending == "Waiting for you")
        #expect(chinese.pending == "等待处理")
        #expect(english.remaining("05:09") == "05:09 remaining")
        #expect(chinese.remaining("05:09") == "剩余 05:09")
        #expect(english.interval(minutes: 45) == "Every 45 minutes")
        #expect(chinese.interval(minutes: 45) == "每 45 分钟")
        #expect(
            english.switched(from: "Water 水", to: "Stretch & rest")
                == "Paused “Water 水” and enabled “Stretch & rest”."
        )
        #expect(
            chinese.switched(from: "Water 水", to: "Stretch & rest")
                == "已暂停“Water 水”，并启用“Stretch & rest”。"
        )
        for value in [
            english.bubble(name: name),
            english.currentlyRunning(name: name),
            english.pending,
            english.remaining("05:09"),
            english.interval(minutes: 45),
            english.switched(from: "Water 水", to: "Stretch & rest"),
        ] {
            #expect(!value.contains("该"))
            #expect(!value.contains("当前运行"))
            #expect(!value.contains("等待处理"))
            #expect(!value.contains("剩余"))
            #expect(!value.contains("分钟"))
            #expect(!value.contains("已暂停"))
        }
    }

    private func localizedBundle(for localization: String) throws -> Bundle {
        let path = try #require(
            Bundle.main.path(forResource: localization, ofType: "lproj")
        )
        return try #require(Bundle(path: path))
    }
}
