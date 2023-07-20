public with sharing class ServiceEventOutbound {
    static final Integer CALLOUT_TIMEOUT = 120000;

    public Service_Event__c serviceEvent;
    public ServiceEventMessageHeader header;
    public Map<String,Object> data;

    @TestVisible
    class ServiceEventMessage {
        ServiceEventMessageHeader header;
        Map<String,Object> data;
    }
    
    /**
     * Create a new Outbound message to be sent to Platform Services
     * @param string eventType: the type of the event e.g. NetworkDesign, LinkAsset
     * @param string action: the action to take or taken e.g. create, created, delete, deleted
     */
    public ServiceEventOutbound(String eventType, String action) {
        this.header = new ServiceEventMessageHeader();
        this.header.direction = 'OUTBOUND';
        this.header.origin = 'Salesforce';
        this.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        this.header.eventType = eventType;
        this.header.action = action;
        this.data = new Map<String,Object>();
        this.serviceEvent = new Service_Event__c(
            Event_Type__c = eventType, 
            Action__c = action, 
            Event_Date__c  = this.header.eventDate, 
            Internal_Reference_Id__c = this.header.internalReferenceId, 
            Origin__c = this.header.origin, 
            Request_Body__c = 'event created',
            Response_Body__c = 'Not processed'
        );
        insert this.serviceEvent;
        this.serviceEvent = ServiceEventOutbound.getServiceEventByInternalReferenceId(this.header.internalReferenceId);
    }

    /**
     * Add an object to the data section of the message, storing at the provided key
     * Message JSON is structured as follows: { header: {...}, data: {...} }
     * Duplicate keys will be overwritten
     * @param string key: the key to use
     * @param obj obj: the object to include, which will be serialized into JSON
     */
    public void add(String key, Object obj) {
        this.data.put(key, obj);
    }

    /**
     * Ready the message for sending
     * Only needs to be called manually when calling sendEvent directly (bypassing class method send)
     */
    public void finalise() {
        this.header.eventDate = Datetime.now();
        this.serviceEvent.Event_Date__c = this.header.eventDate;
        //Set replayId to ServiceEvent autonumber
        List<String> serviceEventNameParts = this.serviceEvent.Name.split('-',2);
        String replayId = '';
        if(serviceEventNameParts.size() > 1) {
            replayId = serviceEventNameParts[1];
        }
        this.header.replayId = Integer.valueOf(replayId);
        this.serviceEvent.Replay_Id__c = this.header.replayId;
        ServiceEventMessage message = new ServiceEventMessage();
        message.header = this.header;
        message.data = this.data;
        String body = JSON.serialize(message);
        this.serviceEvent.Request_Body__c = body;
        update this.serviceEvent;
    }

    /**
     * Send the stored ServiceEvent to Platform Services
     */
    public Id send() {
        Id jobId = null;
        try {
            this.finalise(); //Prepare the event for sending
            String internalReferenceId = this.serviceEvent.Internal_Reference_Id__c;
            jobId = System.enqueueJob(new QueueableOutboundEvent(internalReferenceId));
        }
        catch (Exception e) {
            e.setMessage('unable to send event to Platform Services: '+e.getMessage());
            this.saveError(e, 500);
        }
        return jobId;
    }

    public void saveError(Exception err, Integer status) {
        String errorText = err.getMessage()+' '+err.getStackTraceString();
        this.serviceEvent.Response_Body__c = errorText;
        this.serviceEvent.Status_Code__c = status;
        update this.serviceEvent;
    }

    public class QueueableOutboundEvent implements Queueable, Database.AllowsCallouts {
        String internalReferenceId;

        public QueueableOutboundEvent(String internalReferenceId) {
            this.internalReferenceId = internalReferenceId;
        }
        
        public void execute(QueueableContext context) {
            Service_Event__c serviceEvent = ServiceEventController.getServiceEventByInternalReferenceId(this.internalReferenceId);
            if(serviceEvent != null) {
                N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
                String token = setting.token__c;
                String endpointDomain = setting.cryptoKey__c; //Storing endpoint in cryptoKey__c field
    
                HttpRequest request = new HttpRequest();
                request.setEndpoint(endpointDomain + '/sfs/events/');
                request.setHeader('Authorization', 'Bearer ' + token);
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setTimeout(CALLOUT_TIMEOUT);
                request.setBody(serviceEvent.Request_Body__c);
    
                HttpResponse response = new Http().send(request);
                if(response != null) {
                    serviceEvent.Response_Body__c = response.getBody();
                    serviceEvent.Status_Code__c = response.getStatusCode();
                }
                update serviceEvent;
            }
        }
    }

    private static Service_Event__c getServiceEventByInternalReferenceId(String internalReferenceId) {
        List<Service_Event__c> events = [SELECT Action__c, Event_Date__c, Event_Id__c, Event_Type__c, Internal_Reference_Id__c, Name, Origin__c, Replay_Id__c, Request_Header__c, Request_Body__c, Response_Body__c, Status_Code__c, Record_Id__c, url__c, Result_Status_Code__c, Result_Message__c
                                         FROM Service_Event__c
                                         WHERE Internal_Reference_Id__c =: internalReferenceId];
        Service_Event__c event;
        If (!events.isEmpty()){
            event = events[0];
        }
        return event;
    }
}