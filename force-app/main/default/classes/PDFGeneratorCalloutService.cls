public class PDFGeneratorCalloutService {
    
    public static HttpResponse executeCallout (String method, String requestBody, String recordId) {
        
        // Instantiate a new request
        HttpRequest request = new HttpRequest();
        
        // Set request parameters
        request.setMethod(method);
        
        // Set max timeout
        request.setTimeout(120000);

        //get token and endpoint from custom metadata type
        N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
        String token = setting.token__c;
        String endpointDomain = setting.cryptoKey__c; //reusing cryptoKey__c field to store endpoint

        request.setEndpoint(endpointDomain + '/pdf/generate/1814ffd8-7b3c-4e34-a461-41382fa4b0ce');
        request.setHeader('Authorization', 'Bearer ' + token);

        request.setMethod(method);
        
        
        // If the callout includes a body (POST and PUT requests)
        if (String.isNotBlank(requestBody)) {
        
            // Set the body to the callout
            request.setBody(requestBody);
            
            // Set the content to XML
            request.setHeader('Content-Type', 'application/json');
        }
        
        // Execute the callout
        HttpResponse response = new Http().send(request);
        
        //save request and response
        Service_Event__c serviceEvent = ServiceEventController.createServiceEvent_general('PDF (old fashion)', request, response,  UUIDGenerator.Version4UUIDGenerator(null), recordId);

        // Execute callout and return
        return response;
    }  

    
}