import utest.Runner;
import utest.ui.Report;

class TestAll {
    public static function main():Void {
        var runner = new Runner();
        runner.addCase(new eternaltwin.oauth.TokenTypeTest());
        runner.addCase(new eternaltwin.oauth.AccessTokenTest());
        runner.addCase(new eternaltwin.oauth.RfcOauthClientTest());
        Report.create(runner);
        runner.run();
    }
}
