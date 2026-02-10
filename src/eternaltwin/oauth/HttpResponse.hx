package eternaltwin.oauth;

/**
    Represents an HTTP response with a status code and body.
**/
class HttpResponse {
    /** The HTTP status code of the response. **/
    public var statusCode:Int;

    /** The response body as a string. **/
    public var body:String;

    /**
        Creates a new HttpResponse.

        Parameters
        ----------
        statusCode : Int
            The HTTP status code.
        body : String
            The response body content.
    **/
    public function new(statusCode:Int, body:String) {
        this.statusCode = statusCode;
        this.body = body;
    }
}
