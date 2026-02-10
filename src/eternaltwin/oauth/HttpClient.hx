package eternaltwin.oauth;

import tink.core.Future;

/**
    Interface for making HTTP requests.

    Implementations are provided for different Haxe targets:
    JsHttpClient for JavaScript and SysHttpClient for sys targets.
    FakeHttpClient is available in tests for unit testing.
**/
interface HttpClient {
    /**
        Sends an HTTP POST request.

        Parameters
        ----------
        url : String
            The URL to send the request to.
        headers : Map<String, String>
            HTTP headers to include in the request.
        body : String
            The request body content.

        Returns
        -------
        Future<HttpResponse>
            A future that resolves to the server response.
    **/
    function post(
        url:String,
        headers:Map<String, String>,
        body:String
    ):Future<HttpResponse>;
}
