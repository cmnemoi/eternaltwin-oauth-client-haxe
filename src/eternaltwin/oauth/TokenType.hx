package eternaltwin.oauth;

/**
    Represents the type of an OAuth access token.

    Currently only "Bearer" tokens are supported per RFC 6749.
**/
enum abstract TokenType(String) {
    /** The Bearer token type per RFC 6750. **/
    var Bearer = "Bearer";

    /**
        Returns the string representation of this token type.

        Returns
        -------
        String
            The token type as a string (e.g. "Bearer").
    **/
    public function toString():String {
        return this;
    }

    /**
        Creates a TokenType from its string representation.

        Parameters
        ----------
        raw : String
            The string to parse (e.g. "Bearer").

        Returns
        -------
        TokenType
            The corresponding TokenType value.

        Throws
        ------
        String
            If the string does not match any known token type.
    **/
    public static function fromString(raw:String):TokenType {
        return switch (raw) {
            case "Bearer": Bearer;
            default: throw "Unexpected TokenType value: " + raw;
        }
    }
}
