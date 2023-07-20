@IsTest

public class MockHttpResponderTest {
    static TestMethod void test_constructor() {
        String endpoint = 'http://example.com/example/';
        String method = 'GET';
        Integer statusCode = 200;
        String body = '"test body"';

        MockHttpResponder result = null;

        Test.startTest();
            result = new MockHttpResponder(endpoint, method, statusCode, body);
        Test.stopTest();

        System.assert(result != null, 'constructor result was null');
    }

    static TestMethod void test_respond_success() {
        String endpoint = 'http://example.com/example/';
        String method = 'GET';
        Integer statusCode = 200;
        String body = '"test body"';

        MockHttpResponder result = new MockHttpResponder(endpoint, method, statusCode, body);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);

        HttpResponse response = null;

        Test.startTest();
            response = result.respond(req);
        Test.stopTest();

        System.assert(response != null, 'response was null');
        System.assertEquals(body, response.getBody(), 'response body didn\'t match');
        System.assertEquals(statusCode, response.getStatusCode(), 'response status code didn\'t match');
    }
}