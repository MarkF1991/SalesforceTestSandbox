public with sharing class NetworkDesignCallout {
    
    //empty method to get test coverage on retired class
    public static void doNothing() {
        
    }
    
     /**Retired MARCH-2022** replaced by flow - 'N4L PSI Asset Reconciliation'***
    public static void  GetNetworkDesign(String uuid, String recordId) {
       
        N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
        String token = setting.token__c;
        String endpointDomain = setting.cryptoKey__c; //reusing cryptoKey__c field to store endpoint

        HttpRequest request = new HttpRequest();
        String endpoint = endpointDomain + '/ndr/designs/' + uuid;
        System.debug('GetNetworkDesign request endpoint ' + endpoint);
        request.setEndpoint(endpoint);
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setMethod('GET');


        HttpResponse response = executeGetNetworkDesign(Integer.valueOf(Label.API_Request_Timeout_Limit), 1, request);
        System.debug('GetNetworkDesign response status ' + response.getStatusCode());

        //save service_event__c here with request body and then  the response code and body
        Service_Event__c serviceEvent = ServiceEventController.createServiceEvent_general('Network Design - Devices', request, response, UUIDGenerator.Version4UUIDGenerator(null), recordId);
        
        return response;
  
    }
/**Retired MARCH-2022** replaced by flow - 'N4L PSI Asset Reconciliation'***
    public static HttpResponse executeGetNetworkDesign(Integer timeoutLimit, Integer replayId, HttpRequest request) {
        
        request.setTimeout(timeoutLimit);
       


        HttpResponse response = new HttpResponse();
        try {
            response = new Http().send(request);
 
            if(Test.isRunningTest()){
                if (timeoutLimit == 10){
                    CalloutException e = new CalloutException();
                    e.setMessage('Read timed out');
                    throw e;
                }
            }

            //mock -------------------
            // response.setStatusCode(200);
            // response.setStatus('OK');
            // response.setBody(responseBody_ServiceEventPDFcreatedMock());
            //mock -------------------
                

            if (response.getStatusCode() == 200) {
                //uuids  = response.getBody();
            }  
        } catch (Exception e) {
            if (e instanceof System.CalloutException){
                system.debug('>>>>>>>>>>>>>>>>>>>> System.CalloutException');
                system.debug( e.getMessage() + '   replayId: ' + replayId);

                if ( e.getMessage() == 'Read timed out'){
                    if ( replayId < 3){
                        replayId += 1;
                        response = executeGetNetworkDesign(timeoutLimit, replayId, request); //retry
                    } else {
                        response.setStatusCode(408);
                        response.setStatus('Request Timeout');
                        response.setHeader('replayId', String.valueOf(replayId));
                    }
                }
            }
        }

        return response;
    }
*/
}