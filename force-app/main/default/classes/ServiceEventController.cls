/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2020-09-11
* @description  to handle CRUD operations for custom objects Service_Event__c
*
* CHANGE LOG
* 2021/03/09 added criteria AND Record_Id__c != null to SoQL in getServiceEventbyInternalReferenceId()
**/
public with sharing class ServiceEventController {
    public static Service_Event__c getServiceEventbyEventId(String eventId){
        List<Service_Event__c> events = [SELECT Action__c, Event_Date__c, Event_Id__c, Event_Type__c, Internal_Reference_Id__c, Name, Origin__c, Replay_Id__c, Request_Header__c, Request_Body__c, Response_Body__c, Status_Code__c, Record_Id__c, url__c, Result_Status_Code__c, Result_Message__c
                                        FROM Service_Event__c
                                        WHERE Event_Id__c =: eventId];
        Service_Event__c event;
        If (!events.isEmpty()){
            event = events[0];
        }
        return event;
    }

    public static Service_Event__c getServiceEventbyInternalReferenceId(String internalReferenceId){
        List<Service_Event__c> events = [SELECT Action__c, Event_Date__c, Event_Id__c, Event_Type__c, Internal_Reference_Id__c, Name, Origin__c, Replay_Id__c, Request_Header__c, Request_Body__c, Response_Body__c, Status_Code__c, Record_Id__c, url__c, Result_Status_Code__c, Result_Message__c
                                        FROM Service_Event__c
                                        WHERE Internal_Reference_Id__c =: internalReferenceId];
        Service_Event__c event;
        If (!events.isEmpty()){
            event = events[0];
        }
        return event;
    }

    public static Service_Event__c getServiceEventbyInternalReferenceIdHavingRecordId(String internalReferenceId){
        List<Service_Event__c> events = [SELECT Action__c, Event_Date__c, Event_Id__c, Event_Type__c, Internal_Reference_Id__c, Name, Origin__c, Replay_Id__c, Request_Header__c, Request_Body__c, Response_Body__c, Status_Code__c, Record_Id__c, url__c, Result_Status_Code__c, Result_Message__c
                                        FROM Service_Event__c
                                        WHERE Internal_Reference_Id__c =: internalReferenceId AND Record_Id__c != null];
        Service_Event__c event;
        If (!events.isEmpty()){
            event = events[0];
        }
        return event;
    }

    public static Service_Event__c getServiceEventbyId(String id){
        List<Service_Event__c> events = [SELECT Action__c, Event_Date__c, Event_Id__c, Event_Type__c, Internal_Reference_Id__c, Name, Origin__c, Replay_Id__c, Request_Header__c, Request_Body__c, Response_Body__c, Status_Code__c, Record_Id__c, url__c, Result_Status_Code__c, Result_Message__c
                                        FROM Service_Event__c
                                        WHERE Id =: id];
        Service_Event__c event;
        If (!events.isEmpty()){
            event = events[0];
        }
        return event;
    }

    //Create the service event before deserializing the whole message 
    public static Service_Event__c createServiceEvent(String eventId, String internalReferenceId, String action, String eventType, Datetime eventDate, String origin, String body){
        Service_Event__c serviceEvent = new Service_Event__c(
            Event_Id__c = eventId,
            Event_Type__c = eventType, 
            Action__c = action, 
            Event_Date__c  = eventDate, 
            Internal_Reference_Id__c = internalReferenceId, 
            Origin__c = origin, 
            Request_Body__c = body.left(131072),
            Response_Body__c = 'Not processed yet'
        );
        insert serviceEvent;
        return serviceEvent;
    }

    public static Service_Event__c createServiceEvent(ServiceEventWrapper event, HttpResponse response, String recordId){
        Service_Event__c serviceEvent = new Service_Event__c(
            Event_Id__c = event.eventId, 
            Event_Type__c = event.header.eventType, 
            Action__c = event.header.action, 
            Event_Date__c  = event.header.eventDate, 
            Internal_Reference_Id__c = event.header.internalReferenceId, 
            Origin__c = event.header.origin, 
            
            Request_Body__c = JSON.serialize(event).left(131072),
            Status_Code__c = response.getStatusCode(),
            Response_Body__c = response.getBody().left(131072),
            
            Replay_Id__c = (response.getHeader('replayId') != null ? decimal.valueOf(response.getHeader('replayId')) : event.header.replayId),
            Record_Id__c = recordId,
            url__c = (string.isblank(recordId) ? '' : System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId)
        );
        insert serviceEvent;
        emailSystemAdminOnError(serviceEvent);
        return serviceEvent;
    }

    public static Service_Event__c updateServiceEvent(String internalReferenceId, HttpResponse response){
        //get existing Service_Event__c record
        Service_Event__c serviceEvent = getServiceEventbyInternalReferenceId(internalReferenceId);
        
        //update Service_Event__c record
        return updateServiceEvent(serviceEvent, response);
    }

    public static Service_Event__c updateServiceEvent(String serviceEventId, ServiceEventWrapper event, HttpResponse response, String recordId){
        //get existing Service_Event__c record
        Service_Event__c serviceEvent = getServiceEventById(serviceEventId);
        if(serviceEvent != null) {
            serviceEvent.Event_Id__c = event.eventId;
            serviceEvent.Origin__c = event.header.origin;
            serviceEvent.Status_Code__c = response.getStatusCode();
            serviceEvent.Response_Body__c = response.getBody().left(131072);
            serviceEvent.Replay_Id__c = (response.getHeader('replayId') != null ? decimal.valueOf(response.getHeader('replayId')) : event.header.replayId);
            serviceEvent.Record_Id__c = recordId;
            serviceEvent.url__c = (string.isblank(recordId) ? '' : System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId);
            //update Service_Event__c record
            update serviceEvent;
            emailSystemAdminOnError(serviceEvent);
        }
        return serviceEvent;
    }

    public static Service_Event__c updateServiceEvent(Service_Event__c serviceEvent, HttpResponse response){
        //update Service_Event__c record
        if(serviceEvent != null){
            serviceEvent.Status_Code__c = response.getStatusCode();
            serviceEvent.Response_Body__c = response.getBody().left(131072);
            String replayId = response.getHeader('replayId');
            if (replayId != null){
                serviceEvent.Replay_Id__c = decimal.valueOf(replayId);
            }
            update serviceEvent;
            emailSystemAdminOnError(serviceEvent);
        }
        return serviceEvent;
    }

    public static Service_Event__c updateServiceEvent_Result(ServiceEventWrapper event, ApiResponse result){
        String recordId = (result.record != null ? Helper.getStringValue(result.record.Id) : '');

        Service_Event__c serviceEvent = new Service_Event__c(
            Event_Id__c = event.eventId, 
            Result_Status_Code__c = result.statusCode,
            Result_Message__c = JSON.serialize(result).left(131072),
            Record_Id__c = recordId,
            url__c = (string.isblank(recordId) ? '' : System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId)
            
        );
        upsert serviceEvent Event_Id__c; //Event_Id__c is 	Text(40) (External ID) (Unique Case Insensitive), therefore upsert will take care of the update part.
        
        serviceEvent = getServiceEventbyEventId(event.eventId); //after upsert, get a complete copy of service event to send
        emailSystemAdminOnError(serviceEvent);
        return serviceEvent;
    }
    
    public static Service_Event__c createServiceEvent_GetPDF(String pdfId, HttpRequest request, HttpResponse response){
        
        ServiceEventPDFWrapper pdfWrapper = ServiceEventPDFWrapper.parse(response.getBody());

        Service_Event__c serviceEvent = new Service_Event__c(
            //Event_Id__c = pdfWrapper.data.eventId,     //commented out when using mock response
            Event_Id__c = UUIDGenerator.Version4UUIDGenerator(null),  //to return a different _id when using mock
            
            Event_Type__c = 'PDF', 
            Action__c = 'get', 
            Event_Date__c  = datetime.now(), 
            Internal_Reference_Id__c = pdfId, 
            Origin__c = 'Salesforce', 
            
            Request_Header__c = request.toString(), //get request does not have Body. Therefore storce the request.tostring here.
            Request_Body__c = request.getBody().left(131072),

            Status_Code__c = response.getStatusCode(),
            Response_Body__c = response.getBody().left(131072),
            
            Replay_Id__c = (response.getHeader('replayId') != null ? decimal.valueOf(response.getHeader('replayId')) : 1)
            
        );
        insert serviceEvent;
        emailSystemAdminOnError(serviceEvent);
        return serviceEvent;
    }

    public static Service_Event__c createServiceEvent_general(String label, HttpRequest request, HttpResponse response, String internalReference, String recordId){
        Service_Event__c serviceEvent = new Service_Event__c(
            Event_Id__c =  UUIDGenerator.Version4UUIDGenerator(null),  //to return a different _id when using mock
            Event_Type__c = label, 
            Action__c = '', 
            Event_Date__c  = datetime.now(), 
            Internal_Reference_Id__c = internalReference, 
            Origin__c = 'Salesforce', 
            
            Request_Header__c = request.toString(),
            Request_Body__c = request.getBody().left(131072), 

            Status_Code__c = response.getStatusCode(),
            Response_Body__c = response.getBody().left(131072),
            
            Replay_Id__c = (response.getHeader('replayId') != null ? decimal.valueOf(response.getHeader('replayId')) : 1),
            Record_Id__c = recordId,
            url__c = (string.isblank(recordId) ? '' : System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId)
            
        );
        insert serviceEvent;
        emailSystemAdminOnError(serviceEvent);
        return serviceEvent;
    }

    //overloaded method.
    public static Service_Event__c createServiceEvent_general(String type, String action, HttpRequest request, HttpResponse response, String internalReference, String recordId){
        Service_Event__c serviceEvent = new Service_Event__c(
            Event_Id__c =  UUIDGenerator.Version4UUIDGenerator(null),  //to return a different _id when using mock
            Event_Type__c = type, 
            Action__c = action, 
            Event_Date__c  = datetime.now(), 
            Internal_Reference_Id__c = internalReference, 
            Origin__c = 'Salesforce', 
            
            Request_Header__c = request.toString(),
            Request_Body__c = request.getBody().left(131072), 

            Status_Code__c = response.getStatusCode(),
            Response_Body__c = response.getBody().left(131072),
            
            Replay_Id__c = (response.getHeader('replayId') != null ? decimal.valueOf(response.getHeader('replayId')) : 1),
            Record_Id__c = recordId,
            url__c = (string.isblank(recordId) ? '' : System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId)
            
        );
        insert serviceEvent;
        emailSystemAdminOnError(serviceEvent);
        return serviceEvent;
    }

    @Future()
    public static void createServiceEvent_async(String label, String requestHeader, String requestBody, String responseStatusCode, String responseBody,  String internalReference, String recordId) {
        Service_Event__c serviceEvent = new Service_Event__c(
            Event_Id__c =  UUIDGenerator.Version4UUIDGenerator(null),  //to return a different _id when using mock
            Event_Type__c = label, 
            Action__c = '', 
            Event_Date__c  = datetime.now(), 
            Internal_Reference_Id__c = internalReference, 
            Origin__c = 'Salesforce', 
            
            Request_Header__c = requestHeader,
            Request_Body__c = requestBody.left(131072), 

            Status_Code__c = Integer.valueOf(responseStatusCode),
            Response_Body__c = responseBody.left(131072),
            
            Replay_Id__c = 1,
            Record_Id__c = recordId,
            url__c = (string.isblank(recordId) ? '' : System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId)
            
        );
        insert serviceEvent;
        emailSystemAdminOnError(serviceEvent);
    }

    public static void emailSystemAdminOnError(Service_Event__c serviceEvent){
        if (serviceEvent.Status_Code__c >= 400 || serviceEvent.Result_Status_Code__c >= 400){

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.toAddresses = Label.N4L_notification_email_on_error.split(',');
            //email.toAddresses = new List<String>{'ben.soh@n4l.co.nz'};
            email.subject = 'Service Events Error';
            //email.plainTextBody = JSON.serializePretty(serviceEvent);


            email.plainTextBody =   '_id : ' + serviceEvent.Event_Id__c + '\n' + 
                                    'Event Type : ' + serviceEvent.Event_Type__c + '\n' + 
                                    'Action : ' + serviceEvent.Action__c + '\n' + 
                                    'Event Date : ' + serviceEvent.Event_Date__c + '\n' + 
                                    'Internal Reference Id : ' + serviceEvent.Internal_Reference_Id__c + '\n' + 
                                    'Origin : ' + serviceEvent.Origin__c + '\n' + 
                                    'Replay Id : ' + serviceEvent.Origin__c + '\n' + 
                                    '\n\n' +
                                    'Request Header : ' + serviceEvent.Request_Header__c + '\n' + 
                                    'Request Body : \n' + serviceEvent.Request_Body__c + '\n' + 
                                    '\n\n' +
                                    'Status Code : ' + serviceEvent.Status_Code__c + '\n' + 
                                    'Response Body : \n' + serviceEvent.Response_Body__c + '\n' +
                                    '\n\n' +
                                    'Result Status Code : ' + serviceEvent.Result_Status_Code__c + '\n' + 
                                    'Result Message : \n' + serviceEvent.Result_Message__c + '\n' +
                                    '\n\n' +
                                    'Record Id : ' + serviceEvent.Record_Id__c + '\n' +
                                    'url : ' + serviceEvent.url__c + '\n';
                                    
            try {
                Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email});
            } catch (Exception e) {
                System.debug('Email send limit reached '+e);
            }
            
            
        }
    }


    public static Service_Event__c createServiceEvent_validationError(ServiceEventWrapper event, String message, String recordId){
        Service_Event__c serviceEvent = new Service_Event__c(
            Event_Id__c = event.eventId, 
            Event_Type__c = event.header.eventType, 
            Action__c = event.header.action, 
            Event_Date__c  = event.header.eventDate, 
            Internal_Reference_Id__c = event.header.internalReferenceId, 
            Origin__c = event.header.origin, 
            
            Request_Body__c = JSON.serializePretty(event).left(131072),
            Status_Code__c = 400,
            Response_Body__c = message.left(131072),
            
            Replay_Id__c = 1,
            Record_Id__c = recordId,
            url__c = (string.isblank(recordId) ? '' : System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId)
        );
        insert serviceEvent;
        emailSystemAdminOnError(serviceEvent);
        return serviceEvent;
    }

    public static Service_Event__c updateEventResponse(String serviceEventId, HttpResponse response, String recordId) {
        Service_Event__c serviceEvent = getServiceEventbyId(serviceEventId);
        if(serviceEvent != null){
            serviceEvent.Status_Code__c = response.getStatusCode();
            serviceEvent.Response_Body__c = response.getBody().left(131072);
            String replayId = response.getHeader('replayId');
            if (replayId != null){
                serviceEvent.Replay_Id__c = decimal.valueOf(replayId);
            }
            if(!String.isBlank(recordId)) {
                serviceEvent.Record_Id__c = recordId;
                serviceEvent.url__c = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId;
            } else {
                serviceEvent.Record_Id__c = '';
                serviceEvent.url__c = '';
            }
            update serviceEvent;
            // Chris France - 27/07/2021
            // Turn this into a report, so that many emails are not sent
            // emailSystemAdminOnError(serviceEvent);
        }
        return serviceEvent;
    }
}