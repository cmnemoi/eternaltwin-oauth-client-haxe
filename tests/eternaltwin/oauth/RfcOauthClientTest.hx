package eternaltwin.oauth;

import haxe.Json;
import utest.Assert;

class RfcOauthClientTest extends utest.Test {
    private var fakeHttpClient:FakeHttpClient;
    private var oauthClient:RfcOauthClient;

    public function setup():Void {
        fakeHttpClient = givenFakeHttpClientWithTokenResponse();
        oauthClient = givenOauthClient(fakeHttpClient);
    }

    function testShouldBuildAuthorizationUri():Void {
        var uri = oauthClient.getAuthorizationUri("base", "mystate");

        thenUriContainsExpectedParameters(uri);
    }

    function testShouldUrlEncodeSpecialCharacters():Void {
        var stateWithSpecialChars = "state with spaces&special=chars";

        var uri = oauthClient.getAuthorizationUri("base", stateWithSpecialChars);

        Assert.stringContains("state%20with%20spaces%26special%3Dchars", uri);
    }

    function testShouldExchangeCodeForAccessToken():Void {
        var accessToken = oauthClient.getAccessToken("one_time_auth_code");

        thenAccessTokenIsParsedCorrectly(accessToken);
    }

    function testShouldSendBasicAuthHeader():Void {
        oauthClient.getAccessToken("one_time_auth_code");

        thenBasicAuthHeaderWasSent();
    }

    function testShouldSendCorrectJsonBody():Void {
        oauthClient.getAccessToken("one_time_auth_code");

        thenRequestBodyContainsExpectedFields();
    }

    function testShouldPostToTokenEndpoint():Void {
        oauthClient.getAccessToken("one_time_auth_code");

        Assert.equals("http://localhost:50320/oauth/token", fakeHttpClient.lastRequestUrl);
    }

    function testShouldThrowOnNonSuccessHttpStatus():Void {
        var errorClient = givenFakeHttpClientWithErrorResponse();
        var client = givenOauthClient(errorClient);

        Assert.raises(function() {
            client.getAccessToken("one_time_auth_code");
        }, OauthError);
    }

    function testShouldThrowOnMalformedJsonResponse():Void {
        var malformedClient = givenFakeHttpClientWithMalformedResponse();
        var client = givenOauthClient(malformedClient);

        Assert.raises(function() {
            client.getAccessToken("one_time_auth_code");
        }, OauthError);
    }

    private function givenFakeHttpClientWithTokenResponse():FakeHttpClient {
        var responseBody = '{"access_token":"test_token","refresh_token":"test_refresh","expires_in":7200,"token_type":"Bearer"}';
        return new FakeHttpClient(new HttpResponse(200, responseBody));
    }

    private function givenFakeHttpClientWithErrorResponse():FakeHttpClient {
        return new FakeHttpClient(new HttpResponse(401, '{"error":"unauthorized"}'));
    }

    private function givenFakeHttpClientWithMalformedResponse():FakeHttpClient {
        return new FakeHttpClient(new HttpResponse(200, "not valid json"));
    }

    private function givenOauthClient(httpClient:FakeHttpClient):RfcOauthClient {
        var config = new OauthClientConfig(
            "http://localhost:50320/oauth/authorize",
            "http://localhost:50320/oauth/token",
            "http://localhost:8080/oauth/callback"
        ).withCredentials("myproject@clients", "dev_secret");

        return new RfcOauthClient(config, httpClient);
    }

    private function thenUriContainsExpectedParameters(uri:String):Void {
        Assert.stringContains("http://localhost:50320/oauth/authorize?", uri);
        Assert.stringContains("access_type=offline", uri);
        Assert.stringContains("response_type=code", uri);
        Assert.stringContains("client_id=myproject%40clients", uri);
        Assert.stringContains("scope=base", uri);
        Assert.stringContains("state=mystate", uri);
    }

    private function thenAccessTokenIsParsedCorrectly(accessToken:AccessToken):Void {
        Assert.equals("test_token", accessToken.accessToken);
        Assert.equals("test_refresh", accessToken.refreshToken);
        Assert.equals(7200, accessToken.expiresIn);
        Assert.equals(TokenType.Bearer, accessToken.tokenType);
    }

    private function thenBasicAuthHeaderWasSent():Void {
        var expectedAuth = "Basic bXlwcm9qZWN0QGNsaWVudHM6ZGV2X3NlY3JldA==";
        var authHeader = fakeHttpClient.lastRequestHeaders.get("Authorization");
        Assert.equals(expectedAuth, authHeader);
    }

    private function thenRequestBodyContainsExpectedFields():Void {
        var body = Json.parse(fakeHttpClient.lastRequestBody);
        Assert.equals("myproject@clients", body.client_id);
        Assert.equals("dev_secret", body.client_secret);
        Assert.equals("one_time_auth_code", body.code);
        Assert.equals("authorization_code", body.grant_type);
    }
}
