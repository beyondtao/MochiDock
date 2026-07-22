import ServiceManagement
import Testing
@testable import MochiDock

@MainActor
struct LoginItemServiceTests {
    @Test(arguments: [
        (SMAppService.Status.notRegistered, LoginItemStatus.notRegistered),
        (.enabled, .enabled),
        (.requiresApproval, .requiresApproval),
        (.notFound, .notFound),
    ])
    func mapsEveryNativeStatus(
        native: SMAppService.Status,
        expected: LoginItemStatus
    ) {
        let service = LoginItemService(status: { native }, register: {}, unregister: {})

        #expect(service.status == expected)
    }

    @Test func enableAndDisableCallTheNativeBoundaryOnce() throws {
        var status = SMAppService.Status.notRegistered
        var registerCount = 0
        var unregisterCount = 0
        let service = LoginItemService(
            status: { status },
            register: { registerCount += 1; status = .enabled },
            unregister: { unregisterCount += 1; status = .notRegistered }
        )

        try service.setEnabled(true)
        try service.setEnabled(false)

        #expect(registerCount == 1)
        #expect(unregisterCount == 1)
        #expect(service.status == .notRegistered)
    }

    @Test func repeatedRequestsAreIdempotent() throws {
        var status = SMAppService.Status.enabled
        var registerCount = 0
        var unregisterCount = 0
        let service = LoginItemService(
            status: { status },
            register: { registerCount += 1 },
            unregister: { unregisterCount += 1; status = .notRegistered }
        )

        try service.setEnabled(true)
        try service.setEnabled(false)
        try service.setEnabled(false)

        #expect(registerCount == 0)
        #expect(unregisterCount == 1)
    }

    @Test func nativeErrorsPropagateAndStatusRemainsReadable() {
        var status = SMAppService.Status.notRegistered
        let service = LoginItemService(
            status: { status },
            register: {
                status = .requiresApproval
                throw TestLoginItemError.denied
            },
            unregister: {}
        )

        #expect(throws: TestLoginItemError.denied) {
            try service.setEnabled(true)
        }
        #expect(service.status == .requiresApproval)
    }
}

private enum TestLoginItemError: Error, Equatable {
    case denied
}
