/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2020-09-11
* @description  to handle subsequent processes from Service Event POST Request (ServiceEventRest.cls) 
*               in order to generate PDF and finish ContractCompletion processes..
*
* CHANGE LOG
**/
public with sharing class ServiceEventContractController {
    
    public static string getPDF_templateId(string key){
        key = key.toLowerCase();
        List<PDF_Template__mdt> pdfTemplates = [SELECT DeveloperName, Id, Label, Key__c, templateId__c, Description__c FROM PDF_Template__mdt WHERE Key__c =: key LIMIT 1];
        return (pdfTemplates.isEmpty() ? '' : pdfTemplates[0].templateId__c);
    }
    
    public static void GeneratePDF (Contract contract) {
        /*when Community License user clicks on 'I accept' button on Order Form LWC hosted on Support Hub, 
it's auraEnabled apex method will call this method to start generating PDF
this method is the step 1 in N4L confluence page https://n4lconz.atlassian.net/wiki/spaces/BSYS/pages/1108902056/Contract+Completion+and+PDF+Generation
*/
        
        //prepare an event using wrapper class
        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'PDF';
        event.header.action = 'create';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        //event.header.internalReferenceId = contract.Id;
        event.header.origin = 'Salesforce';
        
        ServiceEventWrapper.Data_PDFcreate data = new ServiceEventWrapper.Data_PDFcreate();
        data.templateId = getPDF_templateId(contract.Programme__c + ' Contract pdf'); //to make it flexible for various programmes in the future. But make sure to maintain Custome Metadata Types to match
        data.contract = contract;
        
        event.data = data; //casting to inherited component
        
        event.whenCreated = datetime.now();
        
        Map<String, String> missingRequiredFields = missingContractRequiredFields(contract);
        if (missingRequiredFields.isempty()){
            //run @future method to execute callout ... with retry, and finally update service_event__c record
            ServiceEventGeneratePDFCallout.GeneratePDF(JSON.serialize(event), contract.Id);
        } else {
            String message = 'Salesforce Validation: \n\n' +
                'Failed to generate PDF for an invalid Contract record \n' +
                'The following fields cannot be null: \n' +
                JSON.serializePretty(missingRequiredFields) ;
            
            Service_Event__c serviceEvent = ServiceEventController.createServiceEvent_validationError(event, message, contract.Id);
        }
    }
    
    public static Map<String, String> missingContractRequiredFields (Contract contract) {
        Map<String, String> result = new Map<String, String>();
        if (contract == null) result.put('contract', null);
        if (contract.Name == null) result.put('Contract Name', null);
        
        if (contract.Programme__c == null) result.put('Programme__c', null);
        if (contract.Product__c == null) result.put('Product__c', null);
        if (contract.Contract_Type__c == null) result.put('Contract_Type__c', null);
        if (contract.Status == null) result.put('Status', null);
        if (contract.ActivatedDate == null) result.put('ActivatedDate', null);
        
        if (contract.CustomerSignedId == null)  result.put('CustomerSignedId', null);
        if (contract.CustomerSigned.FirstName == null) result.put('CustomerSigned.FirstName', null);
        if (contract.CustomerSigned.Name == null) result.put('CustomerSigned.Name', null);
        if (contract.CustomerSigned.Email == null) result.put('CustomerSigned.Email', null);
        if (contract.CustomerSignedDate == null) result.put('CustomerSignedDate', null);
        //if (contract.CustomerSignedTitle == null) result.put('CustomerSignedTitle', null);
        if (contract.CustomerSignedUser__c == null) result.put('CustomerSignedUser__c', null);
        
        if (contract.AccountId == null) result.put('AccountId', null);
        if (contract.Account.MoE_School_ID__c == null) result.put('Account.MoE_School_ID__c', null);
        if (contract.Account.Name == null) result.put('Account.Name', null);
        
        if (contract.Programme__c == Helper.getProgrammeNameMapping().get('NHR').Programme__c || contract.Programme__c == Helper.getProgrammeNameMapping().get('NSE').Programme__c ){
            if (contract.N4L_Signatory_Name__c == null) result.put('N4L_Signatory_Name__c', null);
            if (contract.N4L_Signatory_Email__c == null) result.put('N4L_Signatory_Email__c', null);
            if (contract.School_Principal_Name__c == null) result.put('School_Principal_Name__c', null);
            if (contract.School_Principal_Email__c == null) result.put('School_Principal_Email__c', null);
            if (contract.MoE_Party_Name__c == null) result.put('MoE_Party_Name__c', null);
            if (contract.MoE_Party_Email__c == null) result.put('MoE_Party_Email__c', null);
            
            if (contract.Educount_Rolls_as_at__c == null) result.put('Educount_Rolls_as_at__c', null);
            if (contract.Educount_Rolls__c == null) result.put('Educount_Rolls__c', null);
            if (contract.Annual_Contribution__c == null) result.put('Annual_Contribution__c', null);
            if (contract.Order_Total_Amount__c == null) result.put('Order_Total_Amount__c', null);
        }
        return result;
    }
    
    public static ApiResponse GetPDFforContractCompletion (ServiceEventWrapper event) {
        ApiResponse result = new ApiResponse();
        try{
            
            //casting event.data class to a data class for ServiceRequestContractCompletion
            ServiceEventWrapper.Data_PDFid data = (ServiceEventWrapper.Data_PDFid) event.data;
            
            if( string.isEmpty(data.pdfId)){
                result.setErrorMessage('data._id is required', 400);
            }else {
                //@future method with callout
                ServiceEventGeneratePDFCallout.GetPDF(data.pdfId, JSON.serialize(event));
                
                //response to platform service's POST request that Salesforce doPost() has received this call.
                result.setStatus(200);
                result.messages.add('started Contract Completion asynchronous process: getting PDF...');
                result.messages.add('data._id = ' + data.pdfId);    
            }
            
        } catch (Exception e) {
            result.setStatus(500);
            result.setErrorMessage(e,500);//display as internal error
        }
        result.record = null;
        result.internalReferenceId = event.header.internalReferenceId;
        return result;
    }
    
    
    public static void ContractCompletion (ServiceEventWrapper event, HttpResponse response) {
        
        //get serviceEvent record
        Service_Event__c serviceEvent = ServiceEventController.getServiceEventbyInternalReferenceIdHavingRecordId(event.Header.internalReferenceId);
        
        //SFB-167
        System.debug('SVCeventContractController - Check What is inside - serviceEvent' + serviceEvent);
        
        If(serviceEvent != null && serviceEvent.Record_Id__c != null){           
            Map<String,String> result = ContractController.getContract(serviceEvent.Record_Id__c);
            Contract contract = (Contract) JSON.deserialize(result.get('contract'), Contract.class);
            
            
            //expose the base64string of the PDF from Get Response
            ServiceEventPDFWrapper pdfWrapper = ServiceEventPDFWrapper.parse(response.getBody());
            
            //MNTC-1665
            if(contract.Contract_Type__c != 'Variation'){
            //save the PDF as file
            String base64string = pdfWrapper.data.pdfBlob;
            String subject = 'Order Form - ' + contract.Product__c + '.pdf';
            String parentId = contract.Id;
            Map<Id, ContentVersion> createdCSVFile = FileController.createNewFiles(new List<String>{subject},new List<String>{base64string},parentId,'AllUsers','V',true,null);
            
            List<Id> fileIdsToAttach = new List<Id>();
            fileIdsToAttach.addAll(createdCSVFile.Keyset()); //get the Id of the PDF file created and add to fileIdsToAttach variable.
            
            MethodResponse res2 = update_statusOf_OnboardingTask(contract, 'Contract Completion', 'Completed'); //for both NSE and NHR
            }
            else if(contract.Contract_Type__c == 'Variation'){
                //save the PDF as file
            String base64string = pdfWrapper.data.pdfBlob;
            String subject = 'Order Form <' + contract.ContractNumber + '> - ' + contract.Product__c + '.pdf';
            String parentId = contract.Id;
            Map<Id, ContentVersion> createdCSVFile = FileController.createNewFiles(new List<String>{subject},new List<String>{base64string},parentId,'AllUsers','V',true,null);
            
            List<Id> fileIdsToAttach = new List<Id>();
            fileIdsToAttach.addAll(createdCSVFile.Keyset()); //get the Id of the PDF file created and add to fileIdsToAttach variable.
      
            //MethodResponse res2 = update_statusOf_OnboardingTask(contract, 'Contract Updation - Phase 2', 'Completed'); //for both NSE and NHR
            
            //mntc-1665 update contract completion phase 2 task to completed
            List<Task> tasks = [SELECT id, type, status, task_template__c
            FROM Task
            WHERE RecordType.name = 'Onboarding' 
            AND type = 'Contract Updation - Phase 2'
            AND WhatId =: contract.Related_Case__c];
            Task task = tasks[0];
            task.Status = 'Completed';
            update task;
            }
            // switch on String.valueOf(contract.Programme__c) {
            //     when 'Network Hardware Replacement' {
            //         //send Contract confirmation email with PDF as attachment
            //         //MethodResponse res1 = send_ContractSignedConfirmation_Email_withPDF(contract, fileIdsToAttach);
            
            //         //make onboarding Task: ContractCompletion status = completed
            //         MethodResponse res2 = update_statusOf_OnboardingTask(contract, 'Contract Completion', 'Completed');
            //     }
            //     // when 'Network Support Extension' {
            //     //     //TODO:
            //     // }
            
            // }
        }else {
            //SFB-167
            System.debug('Here has issue, check serviceEvent:' + serviceEvent);
        }
    }
    
    
    public static MethodResponse send_ContractSignedConfirmation_Email_withPDF (Contract contract, List<Id> fileIdsToAttach){
        MethodResponse res = new MethodResponse();
        try{
            
            //toAddresses
            List<String> toAddresses = new List<String>();
            if(contract.CustomerSignedId != null && String.isNotBlank(contract.CustomerSigned.Email)) toAddresses.add(contract.CustomerSigned.Email); //add designated contact's email to address
            
            //ccAddresses - no cc required, but leave it as empty list
            List<String> ccAddresses = new List<String>();
            if (Helper.isSandbox()){
                ccAddresses.add('ben.soh+as_moe_contact_insandbox@n4l.co.nz');
            } else {
                ccAddresses.add(contract.MoE_Party_Email__c);
            }
            
            if(Test.isRunningTest()){
                if (contract.Name == 'Throw Exception'){
                    System.NullPointerException e = new System.NullPointerException();
                    e.setMessage('This is an exception');
                    throw e;
                }
            }
            
            //get Email Template Name based on MetaData - Email Template Mapping
            // String masterLabel = ('mou designated signatory confirmation').toLowerCase();
            String masterLabel = String.valueOf(contract.Programme__c).toLowerCase() + ' order form confirmation email';
            MethodResponse res2 = EmailController.getEmailTemplateByMasterLabel(masterLabel);
            if(res2.statusCode >= 400) return res2;
            EmailTemplate emailTemplate = res2.emailTemplate; //dto in res
            OrgWideEmailAddress orgWideEmailAddress = res2.orgWideEmailAddress; //dto in res
            
            String contractRecordHyperlink = Helper.supportHubURL() + 'contract/' + contract.Id;
            
            String htmlBody = emailTemplate.HtmlValue;
            htmlBody = htmlBody.replace('{!Contact.FirstName}', contract.CustomerSigned.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            htmlBody = htmlBody.replace('[contractRecordHyperlink]', contractRecordHyperlink); //for authorised signatory to refer back to what they have signed. 
            
            String plainBody = emailTemplate.Body;
            plainBody = plainBody.replace('{!Contact.FirstName}',  contract.CustomerSigned.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            plainBody = plainBody.replace('[contractRecordHyperlink]', contractRecordHyperlink); //for authorised signatory to refer back to what they have signed. 
            
            
            Messaging.Singleemailmessage email = EmailController.constructEmail2(contract.CustomerSignedId, contract.AccountId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, orgWideEmailAddress);
            
            if(!fileIdsToAttach.isEmpty()){
                email.setEntityAttachments(fileIdsToAttach); //attach all the file ids to be sent into email.   
            }
            
            email.setSubject(emailTemplate.Subject);
            Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email});
            
            res.setStatus(200);
            res.setResult('success', 'Sent ' + emailTemplate.Name +' Email to ' + string.join(toAddresses,','));  
            return res;
            
        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'ContractController.send_ContractSignatoryInvite_Email Exception' );
            return res;
        }
    }
    
    //NP-897 - Make onboarding Task "Contract Completion" status = 'Completed'
    public static MethodResponse update_statusOf_OnboardingTask (Contract contract, String type, String status){
        MethodResponse res = new MethodResponse();
        try{
            List<Task> tasks = [SELECT id, type, status, task_template__c
                                FROM Task
                                WHERE RecordType.name = 'Onboarding' 
                                AND Task_Template__r.Type__c =: type
                                //AND Status !=: status
                                AND WhatId IN (SELECT id 
                                               FROM Case 
                                               WHERE Opportunity__r.Contract.Id =: contract.Id AND RecordType.Name = 'Onboarding')
                               ];
            if(!tasks.isEmpty()){
                Task task = tasks[0]; //get the first task.
                task.status = status;
                update task;
            }
            res.setStatus(200);
        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('update_statusOf_OnboardingTask error', ex.getMessage());
        }
        return res;
    }
    
    
}