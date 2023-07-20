public with sharing class ServiceEventMessageHeader {
    public String eventType;
    public String action;
    public Integer replayId;
    public Datetime eventDate;
    public String internalReferenceId;
    public String origin;
    public String direction;
    
    public ServiceEventMessageHeader() {

    }
}