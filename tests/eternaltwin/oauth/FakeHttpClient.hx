package eternaltwin.oauth;

/**
    Test double for HttpClient that records requests and returns canned responses.
**/
class FakeHttpClient implements HttpClient {
    /** The URL of the last request made. **/
    public var lastRequestUrl:String;

    /** The headers of the last request made. **/
    public var lastRequestHeaders:Map<String, String>;

    /** The body of the last request made. **/
    public var lastRequestBody:String;

    private var cannedResponse:HttpResponse;

    /**
        Creates a FakeHttpClient that returns the given canned response.

        Parameters
        ----------
        cannedResponse : HttpResponse
            The response to return for any request.
    **/
    public function new(cannedResponse:HttpResponse) {
        this.cannedResponse = cannedResponse;
    }

    /**
        Records the request details and returns the canned response.

        Parameters
        ----------
        url : String
            The URL of the request.
        headers : Map<String, String>
            The request headers.
        body : String
            The request body.

        Returns
        -------
        HttpResponse
            The canned response.
    **/
    public function post(
        url:String,
        headers:Map<String, String>,
        body:String
    ):HttpResponse {
        lastRequestUrl = url;
        lastRequestHeaders = headers;
        lastRequestBody = body;
        return cannedResponse;
    }
}
