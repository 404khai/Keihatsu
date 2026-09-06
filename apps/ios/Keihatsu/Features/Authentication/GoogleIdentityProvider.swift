import Foundation
import GoogleSignIn
import UIKit

@MainActor
protocol GoogleIdentityProviding: Sendable {
    func idToken() async throws -> String
    func signOut()
    func handle(_ url: URL) -> Bool
}

@MainActor
final class GoogleIdentityProvider: GoogleIdentityProviding {
    func idToken() async throws -> String {
        guard
            let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
            !clientID.isEmpty,
            !clientID.contains("$(")
        else { throw GoogleIdentityError.missingClientID }

        let serverClientID = (Bundle.main.object(forInfoDictionaryKey: "GIDServerClientID") as? String)
            .flatMap { $0.isEmpty || $0.contains("$(") ? nil : $0 }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID, serverClientID: serverClientID)

        guard let presenter = Self.presentingViewController else { throw GoogleIdentityError.missingPresenter }
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let token = result.user.idToken?.tokenString, !token.isEmpty else { throw GoogleIdentityError.missingIDToken }
            return token
        } catch let error as GIDSignInError where error.code == .canceled {
            throw GoogleIdentityError.cancelled
        }
    }

    func signOut() { GIDSignIn.sharedInstance.signOut() }
    func handle(_ url: URL) -> Bool { GIDSignIn.sharedInstance.handle(url) }

    private static var presentingViewController: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        var controller = scenes.flatMap(\.windows).first(where: \.isKeyWindow)?.rootViewController
        while let presented = controller?.presentedViewController { controller = presented }
        return controller
    }
}

nonisolated enum GoogleIdentityError: LocalizedError, Equatable, Sendable {
    case missingClientID, missingPresenter, missingIDToken, cancelled

    var errorDescription: String? {
        switch self {
        case .missingClientID: "Google Sign-In has not been configured for this build."
        case .missingPresenter: "Google Sign-In could not open from the current screen."
        case .missingIDToken: "Google did not return an identity token."
        case .cancelled: "Google Sign-In was cancelled."
        }
    }
}

@MainActor
struct UnavailableGoogleIdentityProvider: GoogleIdentityProviding {
    func idToken() async throws -> String { throw GoogleIdentityError.missingClientID }
    func signOut() {}
    func handle(_ url: URL) -> Bool { false }
}
