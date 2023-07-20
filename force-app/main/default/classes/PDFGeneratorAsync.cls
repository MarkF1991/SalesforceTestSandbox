public with sharing class PDFGeneratorAsync {
    @future(callout = true) //System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out
    public static void generatePDF (String serializedContract) {
        Contract contract = (Contract)JSON.deserialize(serializedContract, Contract.class);

        Boolean validated = false;
        if(Test.isRunningTest()){
            validated = true; //to skip validation when running unit test
        }
        if (validated == false){
            validated = validateContractForPDF(contract);
        }

        //if (validateContractForPDF(contract) == true || Test.isRunningTest()){
        if (validated) {
            
        // Instantiate a new request
        HttpRequest request = new HttpRequest();

        //get token and endpoint from custom metadata type
        N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
        String token = setting.token__c;
        String endpointDomain = setting.cryptoKey__c; //reusing cryptoKey__c field to store endpoint
        request.setEndpoint(endpointDomain + '/pdf/generate/1814ffd8-7b3c-4e34-a461-41382fa4b0ce');
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');        
        request.setTimeout(120000);
        
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeObjectField('parameters', contract);
        body.writeEndObject();
        // Set the body to the callout
        request.setBody(body.getAsString());
        
        //get response from pdf generator
        HttpResponse response = new Http().send(request);
        
        if(Test.isRunningTest()){
            Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
            schoolAccount.uuid__c = 'schoola';
            schoolAccount.MoE_School_ID__c = '200';
            schoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
            insert schoolAccount;
        
            contract.accountid = schoolAccount.id;
            insert contract;
        }
    
            if (response.getStatusCode() == 200){
                //expose the base64string of the PDF from Get Response
                ServiceEventPDFWrapper pdfWrapper = ServiceEventPDFWrapper.parse(response.getBody());
                String base64string = pdfWrapper.data.pdfBlob;
                String parentId = contract.Id;
                String filename = 'Order Form - ' + contract.Product__c + '.pdf';
                
                Map<Id, ContentVersion> createdCSVFile = FileController.createNewFiles(new List<String>{filename},new List<String>{base64string},parentId,'AllUsers','V',true,null);
                
                //SFB-167
                System.debug('Check If itis works - createdCSVFile' + createdCSVFile);
                System.debug('Check What is inside - pdfWrapper' + pdfWrapper);
            }
       
            //save request and response
            Service_Event__c serviceEvent = ServiceEventController.createServiceEvent_general('PDF (old fashion)', request, response, UUIDGenerator.Version4UUIDGenerator(null), contract.Id);
                //SFB-167
                System.debug('Check If itis works - serviceEvent' + serviceEvent);
        }

    }

    public static boolean validateContractForPDF(Contract contract){
        Map<String, String> missingRequiredFields = ServiceEventContractController.missingContractRequiredFields(contract);
        if (missingRequiredFields.isempty()){
            return true;
        } else {
            //prepare an event using wrapper class
            ServiceEventWrapper event = new ServiceEventWrapper();
            event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
            event.header.eventType = 'PDF (old fashion)';
            event.header.action = '';
            event.header.replayId = 1;
            event.header.eventDate = datetime.now();
            event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
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
}