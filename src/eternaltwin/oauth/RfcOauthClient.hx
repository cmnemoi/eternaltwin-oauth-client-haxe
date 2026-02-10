package eternaltwin.oauth;

import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.Json;

/**
    RFC-compliant OAuth client for the Eternaltwin platform.

    Provides methods to build authorization URIs and exchange
    authorization codes for access tokens following RFC 6749.
**/
class RfcOauthClient {
    private var config:OauthClientConfig;
    private var httpClient:HttpClient;

    /**
        Creates a new RfcOauthClient.

        Parameters
        ----------
        config : OauthClientConfig
            The OAuth configuration with endpoints and credentials.
        httpClient : HttpClient
            The HTTP client used to make token requests.
    **/
    public function new(
        config:OauthClientConfig,
        httpClient:HttpClient
    ) {
        this.config = config;
        this.httpClient = httpClient;
    }

    /**
        Builds the authorization URI where the user should be redirected.

        Parameters
        ----------
        scope : String
            The OAuth scope string (e.g. "base").
        state : String
            The client state for CSRF protection.

        Returns
        -------
        String
            The full authorization URI with query parameters.
    **/
    public function getAuthorizationUri(
        scope:String,
        state:String
    ):String {
        var queryString = buildAuthorizationQuery(scope, state);
        return config.authorizationEndpoint + "?" + queryString;
    }

    /**
        Exchanges a one-time authorization code for an access token.

        Parameters
        ----------
        code : String
            The one-time authorization code from the callback.

        Returns
        -------
        AccessToken
            The OAuth access token.

        Throws
        ------
        OauthError
            If the server returns a non-success status or an unparseable response.
    **/
    public function getAccessToken(code:String):AccessToken {
        var headers = buildTokenRequestHeaders();
        var body = buildTokenRequestBody(code);
        var response = httpClient.post(config.tokenEndpoint, headers, body);
        validateResponse(response);
        return parseTokenResponse(response.body);
    }

    private function validateResponse(response:HttpResponse):Void {
        var isSuccess = response.statusCode >= 200 && response.statusCode < 300;
        if (!isSuccess) {
            throw new OauthError(
                "Token request failed with status " + response.statusCode + ": " + response.body
            );
        }
    }

    private function parseTokenResponse(body:String):AccessToken {
        try {
            return AccessToken.fromJson(body);
        } catch (error:Dynamic) {
            throw new OauthError("Failed to parse token response: " + body);
        }
    }

    private function buildTokenRequestHeaders():Map<String, String> {
        var headers = new Map<String, String>();
        headers.set("Authorization", buildBasicAuthHeader());
        return headers;
    }

    private function buildBasicAuthHeader():String {
        var credentials = config.clientId + ":" + config.clientSecret;
        var encoded = Base64.encode(Bytes.ofString(credentials));
        return "Basic " + encoded;
    }

    private function buildTokenRequestBody(code:String):String {
        return Json.stringify({
            client_id: config.clientId,
            client_secret: config.clientSecret,
            code: code,
            grant_type: "authorization_code"
        });
    }

    private function buildAuthorizationQuery(
        scope:String,
        state:String
    ):String {
        var params = [
            "access_type=" + urlEncode("offline"),
            "response_type=" + urlEncode("code"),
            "redirect_uri=" + urlEncode(config.callbackEndpoint),
            "client_id=" + urlEncode(config.clientId),
            "scope=" + urlEncode(scope),
            "state=" + urlEncode(state),
        ];
        return params.join("&");
    }

    private static function urlEncode(value:String):String {
        return StringTools.urlEncode(value);
    }
}
