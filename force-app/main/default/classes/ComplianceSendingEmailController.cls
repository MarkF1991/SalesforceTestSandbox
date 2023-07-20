public class ComplianceSendingEmailController {
    @InvocableMethod(label='Compliance Monitoring Sending Emails')
    
    public static void sendingEmail(List<FlowInputs> usefulData){
        string result = JSON.serialize(usefulData).substring(1,JSON.serialize(usefulData).length()-1);
        Map<String, String> jsonValues = (Map<String, String>)JSON.deserialize(result, Map<String, String>.class);   
        
        Id caseId = jsonValues.get('Ids');
        string dynamicContents = jsonValues.get('DynamicContents');
        string ccAddress = jsonValues.get('ccAddress');
        string complianceCaseStatus = jsonValues.get('complianceCaseStatus');
        
        send_Compliance_Email_Method(caseId, dynamicContents, ccAddress, complianceCaseStatus);
    }
    
    public static MethodResponse send_Compliance_Email_Method (Id caseId, string dynamicContents, string ccAddress, string complianceCaseStatus){
        MethodResponse res = new MethodResponse();
        
        //Case
        Case complianceCase = [SELECT id, Alert_status__c, Status, AccountId, ContactId, Contact.FirstName, Account.Name FROM case WHERE id =: caseId];
        
        //case contact
        Contact caseContact = [SELECT id, email FROM Contact WHERE id =: complianceCase.contactId];
        
        //user 
        string userName = UserInfo.getName();
        
        //AccountContactRelation
        //AccountContactRelation accountContactRelation = [SELECT id, roles, AccountId, ContactId FROM AccountContactRelation WHERE  contactId =: complianceCase.ContactId];
        
        //AccountContactRelation principalAccountContactRelation = new AccountContactRelation();
        
        //if(accountContactRelation.roles != 'Principal'){
        //   principalAccountContactRelation = [SELECT id, roles, contactId FROM AccountContactRelation WHERE roles = 'Principal' AND AccountId =: complianceCase.AccountId];
        //}
        
        //principal contact
        //Contact principalContact = [SELECT id, email FROM Contact WHERE id =: principalAccountContactRelation.contactId];
        
        
        //system.debug('@@###$@@#@#@principalAccountContactRelation: '+principalAccountContactRelation);
        
        try{   
            //toAddresses
            List<String> toAddresses = new List<String>();
            if(caseContact != null && String.isNotBlank(caseContact.Email)) toAddresses.add(caseContact.Email);
            
            //ccAddresses - if the send to not principal, then cc will to principal
            List<String> ccAddresses = new List<String>();
            if(!String.IsBlank(ccAddress)) {
                List<string> CCEmails = ccAddress.split(',');
                ccAddresses.addAll(CCEmails);
            }
            
            //get Email Template 
            EmailTemplate emailTemplate;
            
            if(complianceCaseStatus == 'Non-Compliant Accepted' || complianceCaseStatus == 'Closed - Compliance issue Accepted'){
                emailTemplate = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate WHERE developerName = 'Compliance_Monitoring_Non_Compliant_Accepted']; 
            }
            else if(complianceCaseStatus == 'Attempted - Not Reachable'){
                emailTemplate = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate WHERE developerName = 'Compliance_Monitoring_School_not_contactable']; 
            }
            
            OrgWideEmailAddress orgWideEmailAddress = New OrgWideEmailAddress();
            orgWideEmailAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName='N4L Support'];
            
            String htmlBody = emailTemplate.HtmlValue;
            String plainBody = emailTemplate.Body;
            
            htmlBody = htmlBody.replace('[dynamic_content]', nullCheck(dynamicContents)); 
            htmlBody = htmlBody.replace('[Contact.FirstName]', nullCheck(complianceCase.Contact.FirstName)); 
            htmlBody = htmlBody.replace('[Account.Name]', nullCheck(complianceCase.Account.Name)); 
            htmlBody = htmlBody.replace('[User.Name]', nullCheck(userName)); 
            
            //Send Email
            EmailController.sendEmail2(complianceCase.ContactId, complianceCase.Id, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, orgWideEmailAddress);    
            
            res.setStatus(200);
            res.setResult('success', 'Sent ' + emailTemplate.Name +' Email to ' + string.join(toAddresses,','));  
            return res;
            
        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'SafeAndSecureController.send_SafeAndSecureOutboundCall_Email Exception' );
            return res;
        }
        
    }
    
    public static String nullCheck(String input){
        return (String.IsBlank(input) ? '' : input ); //return '' if input is null.
    }
    
    //input details that comes to apex from flow
    public class FlowInputs{
        
        @InvocableVariable
        public String DynamicContents;
        
        @InvocableVariable
        public String Ids;
        
        @InvocableVariable
        public string ccAddress;
        
        @InvocableVariable
        public string complianceCaseStatus;
    }
}