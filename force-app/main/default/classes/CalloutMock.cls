@isTest
public class CalloutMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"destination_addresses" : [ "20 Gillies Avenue, Newmarket, Auckland 1023, New Zealand" ],"origin_addresses" : [ "7 Waikawau Road, Waikawau 3985, New Zealand" ],"rows" : [{"elements" : [{"distance" : {"text" : "294 km","value" : 294036   },"duration" : {"text" : "3 hours 50 mins","value" : 13822 },  "status" : "OK"}]}],"status" : "OK"}');
        res.setStatusCode(200);
        return res;
    }
}