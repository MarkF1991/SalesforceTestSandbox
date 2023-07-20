global class MockHttpResponder implements HttpCalloutMock {
    // Implement this interface method
    String endpoint;
    String method;
    Integer statusCode;
    String body;

    global MockHttpResponder(String endpoint, String method, Integer statusCode, String body) {
        this.endpoint = endpoint;
        this.method = method;
        this.statusCode = statusCode;
        this.body = body;
    }

    public HTTPResponse respond(HTTPRequest req) {
        // These work like expectations - can remove these lines to respond in all cases
        System.assertEquals(this.endpoint, req.getEndpoint());
        System.assertEquals(this.method, req.getMethod());

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.body);
        res.setStatusCode(this.statusCode);
        return res;
    }
}