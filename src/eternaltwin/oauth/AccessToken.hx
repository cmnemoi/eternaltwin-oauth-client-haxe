package eternaltwin.oauth;

import haxe.Json;

/**
    Represents an OAuth access token response.

    Contains the access token, optional refresh token, expiration time,
    and token type as returned by the OAuth token endpoint.
**/
class AccessToken {
    /** The OAuth access token string. **/
    public var accessToken:String;

    /** The refresh token, or null if not provided. **/
    public var refreshToken:Null<String>;

    /** The token lifetime in seconds. **/
    public var expiresIn:Int;

    /** The type of the access token (e.g. Bearer). **/
    public var tokenType:TokenType;

    /**
        Creates a new AccessToken.

        Parameters
        ----------
        accessToken : String
            The OAuth access token string.
        refreshToken : Null<String>
            The refresh token, or null if not provided.
        expiresIn : Int
            The token lifetime in seconds.
        tokenType : TokenType
            The type of the access token.
    **/
    public function new(
        accessToken:String,
        refreshToken:Null<String>,
        expiresIn:Int,
        tokenType:TokenType
    ) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.expiresIn = expiresIn;
        this.tokenType = tokenType;
    }

    /**
        Serializes this access token to a JSON string.

        Returns
        -------
        String
            JSON string with snake_case keys matching the OAuth spec.
    **/
    public function toJson():String {
        return Json.stringify(toDynamic());
    }

    /**
        Deserializes an access token from a JSON string.

        Parameters
        ----------
        json : String
            JSON string with OAuth token fields.

        Returns
        -------
        AccessToken
            The parsed access token.
    **/
    public static function fromJson(json:String):AccessToken {
        return fromDynamic(Json.parse(json));
    }

    /**
        Deserializes an access token from a dynamic object.

        Parameters
        ----------
        raw : Dynamic
            Object with access_token, refresh_token, expires_in,
            and token_type fields.

        Returns
        -------
        AccessToken
            The parsed access token.
    **/
    public static function fromDynamic(raw:Dynamic):AccessToken {
        return new AccessToken(
            raw.access_token,
            raw.refresh_token,
            raw.expires_in,
            TokenType.fromString(raw.token_type)
        );
    }

    private function toDynamic():Dynamic {
        return {
            access_token: accessToken,
            refresh_token: refreshToken,
            expires_in: expiresIn,
            token_type: tokenType.toString()
        };
    }
}
