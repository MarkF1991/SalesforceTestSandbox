public virtual class ApiResponse {
    //Non-virtual and non-abstract type cannot be extended: HttpResponse
    
    public Integer statusCode {get; set;}
    public String status {get; set;}
    public String internalReferenceId {get;set;} 
    public List<String> messages {get; set;}
    public Error error {get; set;}
    public Record record {get;set;}
        
    public ApiResponse(){
        messages = new List<String>();
        error = new Error();
        
        setStatus(400);
    }
    
    public void setStatus(Integer code){
        statusCode = code;
        switch on code{
            when 200 {status = 'OK';}
            when 201 {status = 'Created';}
            when 400 {status = 'Bad Request';}
            when 401 {status = 'Unauthorized';}
            when 404 {status = 'Not Found';}
            when 408 {status = 'Request Timeout';}
            when 409 {status = 'Conflict';}
            when 500 {status = 'Internal Server Error';}
        }
        If(code < 400){error = null;}
    }

    public void setRecord(Id id){
        record = new Record();
        record.Id = id;
        record.sObjectType = string.valueOf(id.getSobjectType());
    }

    //error messages
    public void showDMLExeption(DMLException e, boolean isAppend){
		if (!isAppend){
			messages.clear();
		}
		setErrorMessage(e);
	}

    public void setErrorMessage(String message, integer code){
        this.error.Message = message; //this is a message defined by developer
        setStatus(code); //to allow developer to specify a different error code instead of default 400
    }

    public void setErrorMessage(Exception e, integer code){
        setErrorMessage(e);
        setStatus(code); //to allow developer to specify a different error code instead of default 400
    }

	public void setErrorMessage(Exception e){
        this.error.Type = e.getTypeName();
        this.error.Message = e.getMessage();
        this.error.StackTraceString = e.getStackTraceString();

        If (e instanceof System.DmlException) {
            this.error.DmlFieldNames = string.join(e.getDmlFieldNames(0),','); //display array of strings into string
            this.error.DmlId = e.getDmlId(0);
            this.error.DmlMessage = e.getDmlMessage(0);
            this.error.DmlType = e.getDmlType(0);
        }
        
		setErrorCode(e.getMessage());
    }
    
    public void setErrorCode(string message){
		if (message.contains('DUPLICATE') ) {
			setStatus(409); //Conflict
		} else {
			setStatus(400); //Bad Request for generate error //message.contains('VALIDATION')
		}
    }
    
    //inner class
    public class Error {
        public String type {get; set;}
        public String message {get; set;}
        public String stackTraceString {get; set;}
        public String dmlMessage {get; set;}
        public String dmlFieldNames {get; set;}
        public String dmlId {get; set;}
        public System.statusCode dmlType {get; set;}
    }
    
    public class Record {
        public String sObjectType {get;set;}
        public String Id {get;set;}
    }
}