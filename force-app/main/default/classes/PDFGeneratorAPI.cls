public without sharing class PDFGeneratorAPI {
    
    
    public static MethodResponse generatePDF (Contract contract) {
        MethodResponse res = new MethodResponse();
        if (validateContractForPDF(contract) == false){
            res.setStatus(500);
            res.setResult('PDF Generator', 'Failed to generate PDF for an invalid Contract record');
            return res;
        }
        
        try {
            //-----------------------RequestBody Start------------------------
            
            //String jsonContract = json.serialize(contract);
            JSONGenerator body = JSON.createGenerator(false);
            body.writeStartObject();
            body.writeObjectField('parameters', contract);
            body.writeEndObject();
            //-----------------------RequestBody End------------------------
            
            
            // Send the Contact to 
            HttpResponse response = PDFGeneratorCalloutService.executeCallout('POST', body.getAsString(), contract.Id);
            
            
            
            if (response.getStatusCode() == 200){
                
                //expose the base64string of the PDF from Get Response
                ServiceEventPDFWrapper pdfWrapper = ServiceEventPDFWrapper.parse(response.getBody());
                
                String base64string = pdfWrapper.data.pdfBlob;
                String filename = 'Order Form - ' + contract.Product__c + '.pdf';
                String parentId = contract.Id;
                
                Map<Id, ContentVersion> createdCSVFile = FileController.createNewFiles(new List<String>{filename},new List<String>{base64string},parentId,'InternalUsers','V',true,null);
                
                res.setStatus(200);
                
                //SFB-167
                System.debug('PDFAPIcontroller - Check What is inside - pdfWrapper' + pdfWrapper);
                
            } else {
                res.setStatus(400);
                res.setResult('PDF Generator', 'PDF Generator API call response.getStatusCode() = ' + response.getStatusCode());
            }
        }
        catch (Exception ex) {
            res.setStatus(400);
            res.setResult('PDF Generator','### Error from PDF Generator: ' + ex.getMessage() + ex.getStackTraceString());
        }
        
        
        return res;
    }
    
    public static boolean validateContractForPDF(Contract contract){
        Map<String, String> missingRequiredFields = ServiceEventContractController.missingContractRequiredFields(contract);
        if (missingRequiredFields.isempty()){
            return true;
        } else {
            //prepare an event using wrapper class
            ServiceEventWrapper event = new ServiceEventWrapper();
            event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
            event.header.eventType = 'General';
            event.header.action = '';
            event.header.replayId = 1;
            event.header.eventDate = datetime.now();
            event.header.internalReferenceId = 'generate PDF the old way';
            event.header.origin = 'Salesforce';
            
            ServiceEventWrapper.Data_PDFcreate data = new ServiceEventWrapper.Data_PDFcreate();
            data.templateId = 'v0 - old fashion';
            data.contract = contract;
            event.data = data; //casting to inherited component
            event.whenCreated = datetime.now();
            
            String message = 'Salesforce Validation: \n\n' +
                'Failed to generate PDF for an invalid Contract record \n' +
                'The following fields cannot be null: \n' +
                JSON.serializePretty(missingRequiredFields) ;
            
            Service_Event__c serviceEvent = ServiceEventController.createServiceEvent_validationError(event, message, contract.Id);
            return false;
        }
    }
    
    
    // public static void generatePDF2 (Contract contract) {
    //     if (validateContractForPDF(contract) == true){
    //         //-----------------------RequestBody Start------------------------
    //         JSONGenerator body = JSON.createGenerator(false);
    //         body.writeStartObject();
    //         body.writeObjectField('parameters', contract);
    //         body.writeEndObject();
    //         //-----------------------RequestBody End------------------------
    //         String filename = 'Order Form - ' + contract.Product__c + '.pdf';
    //         generatePDFcore(body.getAsString(), filename, contract.Id);        
    //     }
    
    // }
    
    // @future(callout = true) //System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out
    // public static void generatePDFcore (String jsonBody, String filename, String parentId) {
    
    //     // Send the Contact to 
    //     HttpResponse response = PDFGeneratorCalloutService.executeCallout('POST', jsonBody, parentId);
    
    //     if (response.getStatusCode() == 200){
    
    //         //expose the base64string of the PDF from Get Response
    //         ServiceEventPDFWrapper pdfWrapper = ServiceEventPDFWrapper.parse(response.getBody());
    //         String base64string = pdfWrapper.data.pdfBlob;
    
    //         Map<Id, ContentVersion> createdCSVFile = FileController.createNewFiles(new List<String>{filename},new List<String>{base64string},parentId,'InternalUsers','V',true,null);
    
    //     }
    
    // }
    
    
    
}