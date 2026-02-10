package eternaltwin.oauth;

#if nodejs
import haxe.http.HttpNodeJs;
#else
import haxe.Http;
#end
import tink.core.Future;

/**
    HttpClient adapter for the Node.js target.

    Uses haxe.http.HttpNodeJs to make asynchronous HTTP requests
    in Node.js environments.
**/
class NodeJsHttpClient implements HttpClient {
    /** Creates a new NodeJsHttpClient. **/
    public function new() {}

    /**
        Sends an HTTP POST request using Node.js http module.

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
        #if nodejs
        var http = createRequest(url, headers, body);
        return executeRequest(http);
        #else
        // Fallback for non-nodejs targets
        var http = new haxe.Http(url);
        setHeaders(http, headers);
        http.setPostData(body);
        return executeRequestGeneric(http);
        #end
    }

    #if nodejs
    private function createRequest(
        url:String,
        headers:Map<String, String>,
        body:String
    ):HttpNodeJs {
        var http = new HttpNodeJs(url);
        // Note: HttpNodeJs doesn't have an 'async' field
        // because Node.js http is always asynchronous
        setHeadersNodeJs(http, headers);
        http.setPostData(body);
        return http;
    }

    private function setHeadersNodeJs(
        http:HttpNodeJs,
        headers:Map<String, String>
    ):Void {
        for (key in headers.keys()) {
            http.setHeader(key, headers.get(key));
        }
        http.setHeader("Content-Type", "application/json");
    }

    private function executeRequest(http:HttpNodeJs):Future<HttpResponse> {
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

        http.request(true); // true = POST
        return trigger.asFuture();
    }
    #else
    private function setHeaders(
        http:haxe.Http,
        headers:Map<String, String>
    ):Void {
        for (key in headers.keys()) {
            http.setHeader(key, headers.get(key));
        }
        http.setHeader("Content-Type", "application/json");
    }

    private function executeRequestGeneric(http:haxe.Http):Future<HttpResponse> {
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

        http.request(true); // true = POST
        return trigger.asFuture();
    }
    #end
}
