import Foundation

enum OAuthService {
    static func authorizationURL(for connection: ProviderConnection) -> URL? {
        guard !connection.clientID.isEmpty else { return connection.provider.developerConsoleURL }

        let redirect = connection.oauthRedirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? connection.oauthRedirectURI
        let scopes = connection.provider.recommendedScopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? connection.provider.recommendedScopes

        switch connection.provider {
        case .googleDrive:
            return URL(string: "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(connection.clientID)&redirect_uri=\(redirect)&response_type=token&scope=\(scopes)&include_granted_scopes=true")
        case .oneDrive:
            return URL(string: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=\(connection.clientID)&response_type=token&redirect_uri=\(redirect)&scope=\(scopes)")
        case .dropbox:
            return URL(string: "https://www.dropbox.com/oauth2/authorize?client_id=\(connection.clientID)&response_type=token&redirect_uri=\(redirect)")
        case .github:
            return URL(string: "https://github.com/login/oauth/authorize?client_id=\(connection.clientID)&redirect_uri=\(redirect)&scope=\(scopes)")
        case .local, .iCloud:
            return nil
        }
    }
}
