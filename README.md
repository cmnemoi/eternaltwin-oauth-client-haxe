# eternaltwin-oauth-client

RFC-compliant Haxe client for Eternaltwin OAuth 2.0 server.

## Overview

This library provides an OAuth 2.0 client implementation for the Eternaltwin platform, following the RFC 6749 specification. It handles the authorization flow including building authorization URIs and exchanging authorization codes for access tokens.

## Installation

```bash
haxelib install eternaltwin-oauth-client
```

### Dependencies

This library requires:
- `tink_core` (for Future/Promise abstraction)
- `hxnodejs` (for Node.js target support)

These are automatically installed when you install the library via haxelib.

## Usage

### Basic Example

```haxe
import eternaltwin.oauth.*;

// Configure the OAuth client
var config = new OauthClientConfig(
    "https://eternaltwin.org/oauth/authorize",
    "https://eternaltwin.org/oauth/token",
    "https://myapp.com/oauth/callback"
).withCredentials("my-client-id", "my-client-secret");

// Create the client (use NodeJsHttpClient for Node.js, SysHttpClient for sys targets)
var httpClient = new NodeJsHttpClient();
var oauthClient = new RfcOauthClient(config, httpClient);

// Step 1: Build the authorization URI and redirect the user
var authUri = oauthClient.getAuthorizationUri("base", "random-state-value");
// Redirect user to authUri...

// Step 2: Exchange the authorization code for an access token
// (After user is redirected back to your callback with a code)
oauthClient.getAccessToken("authorization-code-from-callback")
    .handle(function(outcome) {
        switch (outcome) {
            case Success(accessToken):
                trace("Access token: " + accessToken.accessToken);
            case Failure(error):
                trace("OAuth error: " + error.message);
        }
    });
```

## Components

### RfcOauthClient

The main OAuth client class that implements the authorization code flow:

- `getAuthorizationUri(scope, state)` - Builds the authorization URI for redirecting users
- `getAccessToken(code)` - Exchanges an authorization code for an access token (returns `Promise<AccessToken>`)

### OauthClientConfig

Configuration class for OAuth endpoints and credentials:

- `authorizationEndpoint` - The OAuth authorization endpoint URL
- `tokenEndpoint` - The OAuth token endpoint URL
- `callbackEndpoint` - Your application's callback URL
- `clientId` - OAuth client identifier
- `clientSecret` - OAuth client secret

### HttpClient

Interface for asynchronous HTTP requests (returns `Future<HttpResponse>`) with platform-specific implementations:

- `NodeJsHttpClient` - For Node.js target — truly asynchronous via `haxe.http.HttpNodeJs` (uses Node.js native http module)
- `SysHttpClient` - For sys targets (Neko, C++, Java, etc.) — blocking call wrapped in `Future.sync()`
- `FakeHttpClient` - For testing (available in tests)

### AccessToken

Represents an OAuth access token response:

- `accessToken` - The access token string
- `refreshToken` - Optional refresh token
- `expiresIn` - Token lifetime in seconds
- `tokenType` - Token type (e.g., Bearer)

## Error Handling

`getAccessToken()` returns a `Promise<AccessToken>`. Errors are represented as `Failure(tink.core.Error)` in the outcome:

- The token endpoint returns a non-success HTTP status
- The token response cannot be parsed

```haxe
oauthClient.getAccessToken(code)
    .handle(function(outcome) {
        switch (outcome) {
            case Success(accessToken):
                trace("Token: " + accessToken.accessToken);
            case Failure(error):
                trace("OAuth error: " + error.message);
        }
    });
```

## License

GNU Affero General Public License v3.0 or later (AGPL-3.0+)

See [LICENSE.md](LICENSE.md) for full license text.

## Links

- [Eternaltwin Project](https://gitlab.com/eternaltwin/eternaltwin)
- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
