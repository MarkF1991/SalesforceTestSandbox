public class MethodResponse {
    

    public Integer statuscode {get; set;}
    public String status {get; set;}
    //public String error {get; set;}
    public List<String> messages {get; set;}
    public Map<String, String> results {get; set;} //this is useful for LWC to look for the result of a known apex method that the LWC would call

    Private Map<Integer, String> statusCodes = new Map<Integer, String>{
          200 => 'OK'
        , 201 => 'CREATED'
        , 400 => 'BAD_REQUEST'
        , 401 => 'UNAUTHORIZED' 
        , 404 => 'NOT_FOUND'
        , 409 => 'CONFLICT'
        , 0  => 'UNSPECIFIED'
    };

    //----------------------------------- dto -----------------------------------
    public List<Case> cases {get; set;}
    public EmailTemplate emailTemplate {get; set;} //single emailTemplate
    public OrgWideEmailAddress orgWideEmailAddress {get; set;} //when sending email using Apex controllers, we can specify Org Wide Email Address for various Email Template in Custom Metadata Type: Email_Template_Mapping__mdt
    public Token__c token {get; set;}
    public User user {get; set;} //used in UserController.getCustomerUser()
    //----------------------------------- dto -----------------------------------

    public MethodResponse() {
        messages = new List<String>();
        results = new Map<String, String>();
        cases = new List<Case>();
        
        //default status to UNSPECIFIED
        statuscode = 0; 
        status = statusCodes.get(statusCode);
    }

    public void setStatus(Integer code){
        statuscode = code;
        status = statusCodes.get(statusCode);
    }

    public void setResult(String method, String result){
        results.put(method, result);
        //example: ('request-authorisation', 'approved')
    }

    public void appendResult(Map<String, String> inputResults){
        for (String key : inputResults.keySet()) {
            results.put(key, inputResults.get(key));
        }
    }

    public string getJSONstring(){
        JSONGenerator body = JSON.createGenerator(false);
            body.writeStartObject();
            body.writeNumberField('statusCode', statusCode);
            body.writeStringField('status', status);
            if (results != null) {
                for (String key : results.keySet()) {
                    body.writeObjectField(key, results.get(key));//display values of Map<string,string> in json key-value pair format
                }
                
                // body.writeFieldName('results');
                // body.writeStartArray();
                // for (String key : results.keySet()) {
                //     body.writeString(key + ': ' + results.get(key)); //simple string
                // }
                // body.writeEndArray();

            }
            //this is useful for displaying messages on LWC - used in OrderApproval
            //messages:[] can be parsed back (MethodResponse)parser.readValueAs(MethodResponse.class);
                body.writeFieldName('messages'); 
                body.writeStartArray();
                for (String key : results.keySet()) {
                    body.writeString(key + ': ' + results.get(key)); //simple string
                }
                body.writeEndArray();

            body.writeEndObject();
            
        return body.getAsString(); //use this method to return Method Response in string for LWC to JSON.parse(string);: {"statusCode":401,"status":"UNAUTHORIZED","request_authorisation":"Token Expired"}
    }
    // public void setError(String message){
    //     error = new errorClass();
    //     statuscode = code;
    //     status = statusCodes.get(statusCode);
    // }


    // class errorClass {
    //     public String message {get; set;}
    //     public List<String> messages {get; set;}
        
    //     public error(){
    //         messages = new List<String>();
    //     }
    // }
}