import Combine
import Foundation

@MainActor
final class AccountSessionStore: ObservableObject {
    @Published private(set) var account: UserAccount?
    @Published private(set) var bearerToken: String?
    @Published private(set) var isRestoring = false
    @Published private(set) var isAuthenticating = false
    @Published private(set) var error: String?

    private let authentication: any AuthenticationServicing
    private let users: any UserServicing
    private let google: any GoogleIdentityProviding
    private let credentials: any CredentialStoring
    private let cache: AccountCache
    private let accountData: AccountDataCoordinator
    private var restoreTask: Task<Void, Never>?
    private var generation = UUID()

    init(
        authentication: any AuthenticationServicing,
        users: any UserServicing,
        google: any GoogleIdentityProviding,
        credentials: any CredentialStoring,
        cache: AccountCache,
        accountData: AccountDataCoordinator
    ) {
        self.authentication = authentication
        self.users = users
        self.google = google
        self.credentials = credentials
        self.cache = cache
        self.accountData = accountData
    }

    var isAuthenticated: Bool { account != nil && bearerToken != nil }

    func restore() async {
        if let restoreTask { return await restoreTask.value }
        let task = Task<Void, Never> { [weak self] in
            guard let self else { return }
            await self.performRestore()
        }
        restoreTask = task
        await task.value
        restoreTask = nil
    }

    func signIn() async -> Bool {
        guard !isAuthenticating else { return false }
        isAuthenticating = true
        error = nil
        defer { isAuthenticating = false }
        let requestGeneration = UUID()
        generation = requestGeneration
        do {
            let idToken = try await google.idToken()
            let response = try await authentication.exchangeGoogleToken(idToken)
            guard generation == requestGeneration else { return false }
            try await credentials.save(response.token)
            var user = response.account
            if let stats = try? await users.statistics(token: response.token) { user.statistics = stats }
            account = user
            bearerToken = response.token
            try? await cache.save(user)
            await accountData.attach(userID: user.id, token: response.token)
            return true
        } catch let identityError as GoogleIdentityError where identityError == .cancelled {
            return false
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func refreshProfile() async {
        guard let token = bearerToken else { return }
        do {
            async let current = authentication.currentAccount(token: token)
            async let statistics = users.statistics(token: token)
            var refreshed = try await current
            refreshed.statistics = (try? await statistics) ?? account?.statistics ?? .empty
            account = refreshed
            try? await cache.save(refreshed)
            error = nil
        } catch { handle(error) }
    }

    func updateProfile(_ update: ProfileUpdate) async throws {
        guard let token = bearerToken else { throw APIError.authenticationRequired }
        var updated = try await users.updateProfile(update, token: token)
        updated.statistics = account?.statistics ?? .empty
        account = updated
        try? await cache.save(updated)
    }

    func updateVisibility(_ value: Bool) async throws {
        guard let token = bearerToken else { throw APIError.authenticationRequired }
        let old = account
        account?.isProfilePublic = value
        do {
            var updated = try await users.updateVisibility(value, token: token)
            updated.statistics = old?.statistics ?? .empty
            account = updated
            try? await cache.save(updated)
        } catch {
            account = old
            throw error
        }
    }

    func publicProfile(userID: String) async throws -> PublicUserProfile {
        try await users.publicProfile(userID: userID)
    }

    func logout() async {
        generation = UUID()
        restoreTask?.cancel()
        restoreTask = nil
        let oldUserID = account?.id
        account = nil
        bearerToken = nil
        error = nil
        google.signOut()
        try? await credentials.remove()
        try? await cache.clear()
        await accountData.detach(userID: oldUserID)
    }

    func handleOpenURL(_ url: URL) -> Bool { google.handle(url) }

    private func performRestore() async {
        isRestoring = true
        defer { isRestoring = false }
        let requestGeneration = generation
        account = await cache.read()
        do {
            guard let token = try await credentials.read(), !token.isEmpty else {
                account = nil
                return
            }
            bearerToken = token
            guard let cached = account else {
                let current = try await authentication.currentAccount(token: token)
                guard generation == requestGeneration else { return }
                account = current
                try? await cache.save(current)
                await accountData.attach(userID: current.id, token: token)
                return
            }
            await accountData.attachCached(userID: cached.id)
            do {
                var current = try await authentication.currentAccount(token: token)
                if let stats = try? await users.statistics(token: token) { current.statistics = stats }
                guard generation == requestGeneration else { return }
                account = current
                try? await cache.save(current)
                await accountData.attach(userID: current.id, token: token)
            } catch {
                if case APIError.http(status: 401, _) = error {
                    try? await credentials.remove()
                    bearerToken = nil
                    account = nil
                    try? await cache.clear()
                    await accountData.detach(userID: cached.id)
                    self.error = "Your session expired. Sign in again to resume sync."
                } else {
                    self.error = "Offline — showing cached account data."
                }
            }
        } catch {
            account = nil
            bearerToken = nil
            self.error = error.localizedDescription
        }
    }

    private func handle(_ error: Error) {
        if case APIError.http(status: 401, _) = error {
            self.error = "Your session expired. Sign in again to resume sync."
        } else {
            self.error = error.localizedDescription
        }
    }
}
