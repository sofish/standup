import Foundation
import ServiceManagement

public protocol LaunchAtLoginService {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

public struct SystemLaunchAtLoginService: LaunchAtLoginService {
    public init() {}

    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

@MainActor
public final class LaunchAtLoginController: ObservableObject {
    @Published public private(set) var isEnabled: Bool
    @Published public private(set) var errorMessage: String?

    private let service: any LaunchAtLoginService

    public init(service: any LaunchAtLoginService = SystemLaunchAtLoginService()) {
        self.service = service
        self.isEnabled = service.isEnabled
    }

    public func refresh() {
        isEnabled = service.isEnabled
        errorMessage = nil
    }

    public func setEnabled(_ enabled: Bool) {
        guard enabled != service.isEnabled else {
            refresh()
            return
        }

        do {
            try service.setEnabled(enabled)
            isEnabled = service.isEnabled
            errorMessage = nil
        } catch {
            isEnabled = service.isEnabled
            errorMessage = error.localizedDescription
        }
    }
}
