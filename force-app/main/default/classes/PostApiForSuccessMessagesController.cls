public class PostApiForSuccessMessagesController {
    @InvocableMethod(label='PostApiForSuccessMessages')
    
    public static void postSuccessMessageToPS_Method(List<FlowInputs> usefulData){
        string data = JSON.serialize(usefulData);
        string finalData = data.substring(1,data.length()-1);
        system.debug('usefulData: '+finalData);
        postSuccessMessageToPS(finalData);
    }
    
    @future(callout=true)
    public static void postSuccessMessageToPS(string usefulData){

        Map<String, String> jsonValues = (Map<String, String>)JSON.deserialize(usefulData, Map<String, String>.class);
        String origin = jsonValues.get('origin');
        String internalReferenceId = jsonValues.get('internalReferenceId');
        String ids = jsonValues.get('Ids');
        String eventType = jsonValues.get('eventType');
        String action = jsonValues.get('action');
        

        String jsonString;
        jsonString = '{"header":{"origin":"'+origin+'", "internalReferenceId":"'+internalReferenceId+'", "eventType":"'+eventType+'", "action":"'+action+'"}, "data":{"message":"success", "ids":"'+ids+'"}}';
        system.debug('jsonString: '+jsonString);
        N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
        String token = setting.token__c;
        String endpointDomain = setting.cryptoKey__c; //reusing cryptoKey__c field to store endpoint
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointDomain + '/sfs/events/');
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setMethod('POST');
        request.setBody(jsonString); 
        request.setHeader('Content-Type', 'application/json');
        
        HttpResponse response = new Http().send(request);       
        response.setStatusCode(200);
        
    }
    
    //input details that comes to apex from flow
    public class FlowInputs{
        
        @InvocableVariable
        public String eventType;
        
        @InvocableVariable
        public String internalReferenceId;
        
        @InvocableVariable
        public String action;
        
        @InvocableVariable
        public String origin;

        @InvocableVariable
        public String Ids;
        
    }
}