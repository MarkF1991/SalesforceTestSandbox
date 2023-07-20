/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2020-09-15
* @description to execute Callouts
* CHANGE LOG
* 2021-02-18 MNTC-414 Add error handling on GetPDFandSaveAsFile method when Get PDF HttpResponse return status code other than 200
* 2021-03-05 MNTC-447 Overwriting PDF with the same name under the same parent record
**/
public with sharing class ServiceEventGeneratePDFCallout {
   
    @Future(callout=true)
    public static void GeneratePDF(String jsonEvent, String recordId) {
        //ServiceEventWrapper event  = (ServiceEventWrapper) JSON.deserialize(jsonEvent, ServiceEventWrapper.Class);
        ServiceEventWrapper event = ServiceEventWrapper.parse(jsonEvent);

        N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
        String token = setting.token__c;
        String endpointDomain = setting.cryptoKey__c; //reusing cryptoKey__c field to store endpoint

        HttpRequest request = new HttpRequest();
         //request.setEndpoint('https://test-api.n4l.co.nz/sfs/events/');
         //request.setEndpoint('https://dev-api.n4l.co.nz/sfs/events/');
         request.setEndpoint(endpointDomain + '/sfs/events/');
         request.setHeader('Authorization', 'Bearer ' + token);
         request.setMethod('POST');
         request.setBody(JSON.serialize(event));
         request.setHeader('Content-Type', 'application/json');

        //callout out with retry
        HttpResponse response =  executeGeneratePDF(Integer.valueOf(Label.API_Request_Timeout_Limit), event, request);
        
        //save service_event__c here with request body and then  the response code and body
        ServiceEventController.createServiceEvent(event, response, recordId);
    }

    
    public static HttpResponse executeGeneratePDF(Integer timeoutLimit, ServiceEventWrapper event, HttpRequest request) {

        request.setTimeout(timeoutLimit);

        HttpResponse response = new HttpResponse();
        try {
            response = new Http().send(request);

            if(Test.isRunningTest()){
                if (timeoutLimit == 10){
                    CalloutException e = new CalloutException();
                    e.setMessage('Read timed out');
                    throw e;
                } else if (timeoutLimit == 20){
                    CalloutException e = new CalloutException();
                    e.setMessage('Internal Server Error');
                    throw e;
                }
            }

            //mock -------------------
            // response.setStatusCode(200);
            // response.setStatus('OK');
            // response.setBody(responseBody_ServiceEventPDFcreateResponseMock());
            //mock -------------------

            if (response.getStatusCode() == 200) {
                //uuids  = response.getBody();
            }  
        } catch (Exception e) {
            if (e instanceof System.CalloutException){
                system.debug('>>>>>>>>>>>>>>>>>>>> System.CalloutException');
                system.debug( e.getMessage() + '   event.header.replayId: ' + event.header.replayId);

                if ( e.getMessage() == 'Read timed out'){
                    if ( event.header.replayId < 3){
                        event.header.replayId += 1;
                        response = executeGeneratePDF(timeoutLimit, event, request); //retry
                    } else {
                        response.setStatusCode(408);
                        response.setStatus('Request Timeout');
                        response.setHeader('replayId', String.valueOf(event.header.replayId));
                    }
                } else {
                    response.setStatusCode(500);
                    response.setStatus('Internal Server Error');
                    response.setHeader('error',  e.getStackTraceString());
                }
            }
        }

        return response;
    }


    
    @Future(callout=true)
    public static void  GetPDF(String pdfId, String jsonEvent) {
        N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
        String token = setting.token__c;
        String endpointDomain = setting.cryptoKey__c; //reusing cryptoKey__c field to store endpoint

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointDomain + '/pdf/' + pdfId);
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setMethod('GET');


        HttpResponse response = executeGetPDF(Integer.valueOf(Label.API_Request_Timeout_Limit), 1, request);

        //save service_event__c here with request body and then  the response code and body
        ServiceEventController.createServiceEvent_GetPDF(pdfId, request, response);

        ServiceEventWrapper event = ServiceEventWrapper.parse(jsonEvent);
        //finish the rest of contract completion workflows here
        ServiceEventContractController.ContractCompletion(event, response);
    }

    
    public static MethodResponse GetPDFandSaveAsFile(String pdfId, String filename, String parentId) {
        //MNTC-414: Add error handling on GetPDFandSaveAsFile method when Get PDF HttpResponse return status code other than 200
        MethodResponse result = new MethodResponse();

        //MNTC-447 look for existing file with the same name
        Map<Id, sObject> existingFilesOnRecord = FileController.getAttachmentOrFileIds(parentId, new List<String>{filename},'Both');
        
        //if not found, proceed to create the get PDF and save as file
        if (existingFilesOnRecord.isEmpty()){
            N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
            String token = setting.token__c;
            String endpointDomain = setting.cryptoKey__c; //reusing cryptoKey__c field to store endpoint
    
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpointDomain + '/pdf/' + pdfId);
            request.setHeader('Authorization', 'Bearer ' + token);
            request.setMethod('GET');
    
    
            HttpResponse response = executeGetPDF(Integer.valueOf(Label.API_Request_Timeout_Limit), 1, request);
    
            //prepare result to return HttpResponse status
            result.setStatus(response.getStatusCode());
            
            //recordId is for the file created in this method, the default value can remain as null when HttpResponse returned an error
            String fileRecordId = null;
    
            if(response.getStatusCode() == 200){
                //expose the base64string of the PDF from Get Response
                ServiceEventPDFWrapper pdfWrapper = ServiceEventPDFWrapper.parse(response.getBody());
    
                //save the PDF as file
                String base64string = pdfWrapper.data.pdfBlob;
                if (!filename.endsWith('.pdf')){
                    filename += '.pdf';
                }
                Map<Id, ContentVersion> createdPDFFile = FileController.createNewFiles(new List<String>{filename},new List<String>{base64string},parentId,'AllUsers','V',true,null);
                List<Id> ids = new List<Id>(createdPDFFile.keyset());
                fileRecordId = (ids.size() == 1 ? string.valueOf(ids[0]) : null);
            } else {
                result.setResult('HttpResponse', response.toString());    
            }
    
            //save service_event__c here with request body and then the response code (and body and recordId of created file in serviceEvent if HttpResponse return 200)
            Service_Event__c serviceEvent = ServiceEventController.createServiceEvent_general('PDF', 'get', request, response, pdfId, fileRecordId);
            
            //return recordId of the file in MethodResponse.result
            result.setResult('fileRecordId', fileRecordId);
        } 
        else {
            //MNTC-447 Overwriting PDF with the same name under the same parent record
            //th file already exist, return the id of the file
            ContentVersion cv = (ContentVersion) existingFilesOnRecord.values()[0];
            //return recordId of the file in MethodResponse.result
            result.setStatus(200);
            result.setResult('fileRecordId', cv.Id);
        }

       

        return result;
    }


    @Future(callout=true)
    public static void  GetPDFandSaveAsFileAsync(String pdfId, String filename, String parentId) {
        MethodResponse result = GetPDFandSaveAsFile(pdfId, filename, parentId);
    }

    public static HttpResponse executeGetPDF(Integer timeoutLimit, Integer replayId, HttpRequest request) {
        
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
                

        } catch (Exception e) {
            if (e instanceof System.CalloutException){
                system.debug('>>>>>>>>>>>>>>>>>>>> System.CalloutException');
                system.debug( e.getMessage() + '   replayId: ' + replayId);

                if ( e.getMessage() == 'Read timed out'){
                    if ( replayId < 3){
                        replayId += 1;
                        response = executeGetPDF(timeoutLimit, replayId, request); //retry
                    } else {
                        response.setStatusCode(408);
                        response.setStatus('Request Timeout');
                        response.setHeader('replayId', String.valueOf(replayId));
                    }
                } else {
                    response.setStatusCode(500);
                    response.setStatus('Request Timeout');
                    response.setBody('System.CalloutException : '  +  e.getMessage());
                }
            }
        }

        return response;
    }

    public static string responseBody_ServiceEventPDFcreateResponseMock(){
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventPDFcreateResponseMock' LIMIT 1];
        return staticResource.Body.toString();
    }
    public static string responseBody_ServiceEventPDFcreatedMock(){
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventPDFcreatedMock' LIMIT 1];
        return staticResource.Body.toString();
    }
    public static string strPDFbase64string(){
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventPDFcreatedMock' LIMIT 1];
        String json = staticResource.Body.toString();
        ServiceEventPDFWrapper r = ServiceEventPDFWrapper.parse(json);
        return r.data.pdfBlob;
    }

}