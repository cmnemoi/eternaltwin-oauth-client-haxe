package eternaltwin.oauth;

/**
    Domain error for OAuth operations.

    Thrown when an OAuth token request fails due to a non-success
    HTTP status or an unparseable response.
**/
class OauthError {
    /** The error message describing what went wrong. **/
    public var message:String;

    /**
        Creates a new OauthError.

        Parameters
        ----------
        message : String
            The error message.
    **/
    public function new(message:String) {
        this.message = message;
    }

    /**
        Returns the string representation of this error.

        Returns
        -------
        String
            The error message.
    **/
    public function toString():String {
        return message;
    }
}
