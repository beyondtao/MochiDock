import Foundation

struct ReminderLocalizedText {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func bubble(name: String) -> String { format("Time for %@!", name) }
    func currentlyRunning(name: String) -> String { format("Running: %@", name) }
    var pending: String { localized("Waiting for you") }
    func remaining(_ value: String) -> String { format("%@ remaining", value) }
    func interval(minutes: Int) -> String { format("Every %lld minutes", Int64(minutes)) }

    func switched(from previousName: String, to nextName: String) -> String {
        format("Paused “%@” and enabled “%@”.", previousName, nextName)
    }

    private func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    private func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: localized(key), arguments: arguments)
    }
}
