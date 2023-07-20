/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2020-09-08
* @description  to handle HTTP Requests.
*               POST request handles different eventTypes and subsequent processes
*
* CHANGE LOG
* 26/11/2020 Ben Soh NP-1944 Service Event - track inbound POST request
* 15/01/2021 Ben Soh replaced ServiceEventNetworkDesignController.NetworkDesignRouting(event) with ServiceEventNDQController.NetworkDesignValidation(event) to run NetworkDesign actions on Queueable Apex
**/
@RestResource(urlMapping='/n4l/platform/events/*')
global with sharing class ServiceEventRest {
    @HttpPost
    global static ServiceEventRestApiResponse doPost() {
        
        RestRequest req = RestContext.request;
        //RestResponse res = RestContext.response;
        
        ServiceEventRestApiResponse result = new ServiceEventRestApiResponse();
        ApiResponse apiResponse = null;
        String requestBody = req.requestBody.toString();
        ServiceEventWrapper event = ServiceEventWrapper.parse(requestBody);
        String safeRequestBody = requestBody.replaceAll('_id', 'psId');
        // Log service events before fully deserializing
        // This will deserialize just the header
        ServiceEventMessage message = (ServiceEventMessage)JSON.deserialize(safeRequestBody, ServiceEventMessage.class);
        Service_Event__c serviceEvent = null;
        if(message.header != null) {
            if(message.header.eventType != 'asset.link') { // Don't create service event if asset.link is the event type CJF 27/09/2021
                serviceEvent = ServiceEventController.createServiceEvent(message.psId, message.header.internalReferenceId, message.header.action, message.header.eventType, message.header.eventDate, message.header.origin, requestBody);
            }
        }
        
        //validate request body by casting to ServiceEventWrapper
        if(event.error != null){
            result.setErrorMessage(event.error);
        } else {
            switch on event.header.eventType {
                when 'ServiceRequestWebFiltering' {
                    //System.TypeException: Invalid conversion from runtime type ApiResponse to EventRest.ServiceEventRestApiResponse Class.EventRest.doPost: line 46, column 1
                    apiResponse = ServiceEventCaseController.ServiceRequestWebFiltering(event);
                }
                when 'NetworkDesign' {
                    apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
                }
                when 'asset.link' {
                    if(message.header.action == 'create') {
                        apiResponse = ServiceEventAssetController.linkAsset(requestBody);
                        event = null;
                    }
                    if(message.header.action == 'delete') {
                        apiResponse = ServiceEventAssetController.linkAsset(requestBody);
                        event = null;
                    }
                }
                when 'PDF' {
                    apiResponse = ServiceEventContractController.GetPDFforContractCompletion(event);
                }
            }
            if (apiResponse != null){
                result.setStatus(apiResponse.statuscode);
                result.messages = apiResponse.messages;
                result.error = apiResponse.error;
                result.internalReferenceId = apiResponse.internalReferenceId;
                result.record = apiResponse.record;
            }
            
        }
        
        //NP-1944 track inbound API POST Request and Result as Response
        //If processing of header failed, was probably a malformed message or died for some other reason
        //For now, will fallback to the old behaviour and call trackServiceEvent with the processed event
        if(message.header.eventType != 'asset.link') { // Don't try to update service event if asset.link is the event type CJF 27/09/2021
            if(serviceEvent == null) {
                trackServiceEvent(event, result);
            } else {
                if(event != null) {
                    updateServiceEvent(serviceEvent.Id, event, result);
                } else {
                    updateServiceEvent(serviceEvent.Id, result);
                }
            }
        }
        
        //RestContext.response.statusCode = result.statuscode; //include statuscode in response header
        //res.statusCode = result.statuscode;
        return result;
    }

    //NP-1944 track inbound API POST Request and Result as Response
    public static void trackServiceEvent(ServiceEventWrapper event, ServiceEventRestApiResponse result){
        HttpResponse response = new HttpResponse();
        response.setStatusCode(result.statuscode);
        response.setStatus(result.status);
        response.setBody(System.JSON.serialize(result));

        String recordId = '';
        if(result.record != null){
            recordId = Helper.getStringValue(result.record.Id);
        }
        ServiceEventController.createServiceEvent(event, response, recordId);
    }

    //Update an existing ServiceEvent based on Id
    public static void updateServiceEvent(String serviceEventId, ServiceEventWrapper event, ServiceEventRestApiResponse result) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(result.statuscode);
        response.setStatus(result.status);
        response.setBody(System.JSON.serialize(result));
        String recordId = '';
        if(result.record != null){
            recordId = Helper.getStringValue(result.record.Id);
        }
        ServiceEventController.updateServiceEvent(serviceEventId, event, response, recordId);
    }

    public static void updateServiceEvent(String serviceEventId, ServiceEventRestApiResponse result) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(result.statuscode);
        response.setStatus(result.status);
        response.setBody(System.JSON.serialize(result));
        String recordId = '';
        if(result.record != null){
            recordId = Helper.getStringValue(result.record.Id);
        }
        ServiceEventController.updateEventResponse(serviceEventId, response, recordId);
    }

    //inner class
    global class ServiceEventRestApiResponse extends ApiResponse{

    }

    class ServiceEventMessage {
        public String psId;
        public ServiceEventMessageHeader header;
    }
}