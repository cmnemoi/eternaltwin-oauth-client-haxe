package eternaltwin.oauth;

import haxe.http.HttpJs;
import tink.core.Future;

/**
    HttpClient adapter for the JavaScript target.

    Uses haxe.http.HttpJs (XMLHttpRequest) to make asynchronous
    HTTP requests in browser or Node.js environments.
**/
class JsHttpClient implements HttpClient {
    /** Creates a new JsHttpClient. **/
    public function new() {}

    /**
        Sends an HTTP POST request using XMLHttpRequest.

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
    public function post(
        url:String,
        headers:Map<String, String>,
        body:String
    ):Future<HttpResponse> {
        var http = createRequest(url, headers, body);
        return executeRequest(http);
    }

    private function createRequest(
        url:String,
        headers:Map<String, String>,
        body:String
    ):HttpJs {
        var http = new HttpJs(url);
        http.async = true;
        setHeaders(http, headers);
        http.setPostData(body);
        return http;
    }

    private function setHeaders(
        http:HttpJs,
        headers:Map<String, String>
    ):Void {
        for (key in headers.keys()) {
            http.setHeader(key, headers.get(key));
        }
        http.setHeader("Content-Type", "application/json");
    }

    private function executeRequest(http:HttpJs):Future<HttpResponse> {
        var trigger = Future.trigger();
        var statusCode:Int = 0;

        http.onStatus = function(status:Int):Void {
            statusCode = status;
        };
        http.onData = function(data:String):Void {
            trigger.trigger(new HttpResponse(statusCode, data));
        };
        http.onError = function(error:String):Void {
            trigger.trigger(new HttpResponse(statusCode, error));
        };

        http.request(true);
        return trigger.asFuture();
    }
}
