package eternaltwin.oauth;

import utest.Assert;

class AccessTokenTest extends utest.Test {
    function testShouldSerializeToJson():Void {
        var accessToken = givenAccessTokenWithRefreshToken();

        var json = accessToken.toJson();

        thenJsonContainsExpectedFields(json);
    }

    function testShouldDeserializeFromJson():Void {
        var json = givenValidTokenJson();

        var accessToken = AccessToken.fromJson(json);

        thenAccessTokenMatchesExpected(accessToken);
    }

    function testShouldHandleNullRefreshToken():Void {
        var json = givenJsonWithoutRefreshToken();

        var accessToken = AccessToken.fromJson(json);

        Assert.isNull(accessToken.refreshToken);
    }

    function testShouldRoundTripThroughJson():Void {
        var original = givenAccessTokenWithRefreshToken();

        var roundTripped = AccessToken.fromJson(original.toJson());

        Assert.equals(original.accessToken, roundTripped.accessToken);
        Assert.equals(original.refreshToken, roundTripped.refreshToken);
        Assert.equals(original.expiresIn, roundTripped.expiresIn);
        Assert.equals(original.tokenType, roundTripped.tokenType);
    }

    private function givenAccessTokenWithRefreshToken():AccessToken {
        return new AccessToken(
            "AMHILF5gGddDnfqVj9K8yIeP3VMIgaxG",
            "HfznfQUg1C2p87ESIp6WRq945ppG6swD",
            7200,
            TokenType.Bearer
        );
    }

    private function givenValidTokenJson():String {
        return '{"access_token":"AMHILF5gGddDnfqVj9K8yIeP3VMIgaxG","refresh_token":"HfznfQUg1C2p87ESIp6WRq945ppG6swD","expires_in":7200,"token_type":"Bearer"}';
    }

    private function givenJsonWithoutRefreshToken():String {
        return '{"access_token":"AMHILF5gGddDnfqVj9K8yIeP3VMIgaxG","expires_in":7200,"token_type":"Bearer"}';
    }

    private function thenJsonContainsExpectedFields(json:String):Void {
        Assert.stringContains("AMHILF5gGddDnfqVj9K8yIeP3VMIgaxG", json);
        Assert.stringContains("HfznfQUg1C2p87ESIp6WRq945ppG6swD", json);
        Assert.stringContains("7200", json);
        Assert.stringContains("Bearer", json);
    }

    private function thenAccessTokenMatchesExpected(accessToken:AccessToken):Void {
        Assert.equals("AMHILF5gGddDnfqVj9K8yIeP3VMIgaxG", accessToken.accessToken);
        Assert.equals("HfznfQUg1C2p87ESIp6WRq945ppG6swD", accessToken.refreshToken);
        Assert.equals(7200, accessToken.expiresIn);
        Assert.equals(TokenType.Bearer, accessToken.tokenType);
    }
}
