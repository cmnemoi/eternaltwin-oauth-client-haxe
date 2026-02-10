package eternaltwin.oauth;

/**
    Configuration for an OAuth client.

    Holds the endpoint URLs and client credentials needed
    for OAuth authorization and token exchange.
**/
class OauthClientConfig {
    /** The URL of the OAuth authorization endpoint. **/
    public var authorizationEndpoint:String;

    /** The URL of the OAuth token endpoint. **/
    public var tokenEndpoint:String;

    /** The URL of the OAuth callback endpoint. **/
    public var callbackEndpoint:String;

    /** The OAuth client identifier. **/
    public var clientId:String;

    /** The OAuth client secret. **/
    public var clientSecret:String;

    /**
        Creates a new OauthClientConfig with endpoint URLs.

        Parameters
        ----------
        authorizationEndpoint : String
            The URL of the OAuth authorization endpoint.
        tokenEndpoint : String
            The URL of the OAuth token endpoint.
        callbackEndpoint : String
            The URL of the OAuth callback endpoint.
    **/
    public function new(
        authorizationEndpoint:String,
        tokenEndpoint:String,
        callbackEndpoint:String
    ) {
        this.authorizationEndpoint = authorizationEndpoint;
        this.tokenEndpoint = tokenEndpoint;
        this.callbackEndpoint = callbackEndpoint;
    }

    /**
        Sets the client credentials on this config.

        Parameters
        ----------
        clientId : String
            The OAuth client identifier.
        clientSecret : String
            The OAuth client secret.

        Returns
        -------
        OauthClientConfig
            This config instance for method chaining.
    **/
    public function withCredentials(
        clientId:String,
        clientSecret:String
    ):OauthClientConfig {
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        return this;
    }
}
