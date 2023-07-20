@IsTest
public with sharing class MethodResponseTest {
    @TestSetup
    private static void setup() {

    }

    static testMethod void test_MethodResponse_method() {
        MethodResponse res = new MethodResponse();
        system.assertEquals(0, res.messages.size()); 
        system.assertEquals(0, res.results.size()); 
        system.assertEquals(0, res.cases.size()); 

        //if developer forgot to set Status code, this class should return StatusCode 0 and Status = UNSPECIFIED
        system.assertEquals(0, res.statusCode); 
        system.assertEquals('UNSPECIFIED', res.status); 


        res.setStatus(200);
        system.assertEquals(200, res.statusCode); 
        system.assertEquals('OK', res.status); 

        res.setResult('key 1111','value 1111');
        res.setResult('key 2222','value 2222');
        res.setResult('key 3333','value 3333');

        system.assertEquals(3, res.results.size()); 
        system.assertEquals('value 2222', res.results.get('key 2222')); 
        
        //test appendResult
        MethodResponse res2 = new MethodResponse();
        res2.setResult('key 4444','value 4444');
        res2.setResult('key 5555','value 5555');
        system.assertEquals(2, res2.results.size()); //before append it should have 2 items

        res2.appendResult(res.results); //append results from earlier res to this new res2
        system.assertEquals(5, res2.results.size()); //after append it should have 5 items
       
    }

    static testMethod void test_getJSONstring_method() {
        MethodResponse res = new MethodResponse();
        integer expectedStatusCode = 404;
        string expectedStatus = 'NOT_FOUND';
        string expectedResultString = 'Email Template Not Found';
        string expectedJSONContent = '{"statusCode":404,"status":"NOT_FOUND","Error":"Email Template Not Found","messages":["Error: Email Template Not Found"]}';

        res.setStatus(expectedStatusCode);
        system.assertEquals(expectedStatusCode, res.statusCode); 
        system.assertEquals(expectedStatus, res.status); 

        res.setResult('Error',expectedResultString);
        
        String JSONContent = res.getJSONstring();
        system.assertEquals(expectedJSONContent, JSONContent); 

       
        JSONParser parser = JSON.createParser(JSONContent);
        // Advance to the start object marker.
        parser.nextToken();
        // Advance to the next value.
        parser.nextValue();
        // Get the statusCode - integer.
        Integer testStatusCode = parser.getIntegerValue();
        system.assertEquals(expectedStatusCode, testStatusCode); 
        

        parser.nextValue();
        // Get the status - text.
        String testStatus = parser.getText();
        system.assertEquals(expectedStatus, testStatus); 


         parser.nextValue();
        // Get the status - text.
        String testResultString = parser.getText();
        system.assertEquals(expectedResultString, testResultString); 
    }
}