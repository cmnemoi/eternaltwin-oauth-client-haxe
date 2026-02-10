package eternaltwin.oauth;

import utest.Assert;

class TokenTypeTest extends utest.Test {
    function testShouldSerializeBearerToString():Void {
        var tokenType = TokenType.Bearer;

        Assert.equals("Bearer", tokenType.toString());
    }

    function testShouldDeserializeBearerFromString():Void {
        var tokenType = TokenType.fromString("Bearer");

        Assert.equals(TokenType.Bearer, tokenType);
    }

    function testShouldThrowOnUnknownTokenType():Void {
        Assert.raises(function() {
            TokenType.fromString("Unknown");
        });
    }
}
