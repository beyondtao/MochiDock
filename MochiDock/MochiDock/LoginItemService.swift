import ServiceManagement

enum LoginItemStatus: Equatable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
}

@MainActor
protocol LoginItemServicing: AnyObject {
    var status: LoginItemStatus { get }
    func setEnabled(_ enabled: Bool) throws
}

@MainActor
final class LoginItemService: LoginItemServicing {
    private let statusProvider: () -> SMAppService.Status
    private let registerAction: () throws -> Void
    private let unregisterAction: () throws -> Void

    var status: LoginItemStatus {
        switch statusProvider() {
        case .notRegistered: .notRegistered
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notFound: .notFound
        @unknown default: .notFound
        }
    }

    init() {
        let service = SMAppService.mainApp
        self.statusProvider = { service.status }
        self.registerAction = { try service.register() }
        self.unregisterAction = { try service.unregister() }
    }

    init(
        status: @escaping () -> SMAppService.Status,
        register: @escaping () throws -> Void,
        unregister: @escaping () throws -> Void
    ) {
        self.statusProvider = status
        self.registerAction = register
        self.unregisterAction = unregister
    }

    func setEnabled(_ enabled: Bool) throws {
        switch (enabled, status) {
        case (true, .enabled), (true, .requiresApproval),
             (false, .notRegistered), (false, .notFound):
            return
        case (true, .notRegistered), (true, .notFound):
            try registerAction()
        case (false, .enabled), (false, .requiresApproval):
            try unregisterAction()
        }
    }
}
