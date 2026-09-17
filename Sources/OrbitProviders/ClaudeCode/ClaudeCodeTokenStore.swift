import Foundation
import OrbitCore
import Security

/// Supplies the OAuth access token Claude Code's own CLI is already
/// maintaining, so the API client can call `/api/oauth/usage` directly
/// without the user doing any separate token setup.
public protocol ClaudeCodeTokenStoring: Sendable {
    func accessToken() throws -> String
}

/// Reads the same Keychain item the `claude` CLI reads and refreshes on
/// every invocation (service `"Claude Code-credentials"`), so token refresh
/// stays entirely the CLI's responsibility — this only ever reads.
public struct ClaudeCodeKeychainTokenStore: ClaudeCodeTokenStoring {
    private static let service = "Claude Code-credentials"

    /// The stored item's JSON shape. Only the field this client needs is
    /// modeled; unrecognized keys are ignored by `Codable` rather than
    /// causing a decode failure, so an unrelated field the CLI adds later
    /// cannot break token reads.
    private struct StoredCredentials: Decodable {
        struct OAuth: Decodable {
            let accessToken: String

            enum CodingKeys: String, CodingKey {
                case accessToken
            }
        }

        let claudeAiOauth: OAuth
    }

    public init() {}

    public func accessToken() throws -> String {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        query.removeAll()

        guard status == errSecSuccess, let data = item as? Data else {
            throw UsageRepositoryError.notAuthenticated
        }

        guard let credentials = try? JSONDecoder().decode(StoredCredentials.self, from: data) else {
            throw UsageRepositoryError.malformedResponse("Claude Code-credentials keychain item was not in the expected shape")
        }

        return credentials.claudeAiOauth.accessToken
    }
}
