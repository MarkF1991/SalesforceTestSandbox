/*
@Author : Ben Soh
@Description: Get the the Org Wide Email Adrdress
@Param: Email Address
@Return: The Org Wide Email Address for the provided Email
*/
public without sharing class EmailController {
    public static OrgWideEmailAddress getOrgWideEmailAddress(String email){
        List<OrgWideEmailAddress> lstOrgEmailAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = : email];
        if(!lstOrgEmailAddress.isEmpty()) return lstOrgEmailAddress[0];
        else return null ;
    }
 
    public static Map<String, Email_Template_Mapping__mdt> getEmailTemplateMappings(){
        Map<String, Email_Template_Mapping__mdt> emailTemplateMap = new Map<String, Email_Template_Mapping__mdt>();
        
        for(Email_Template_Mapping__mdt obj: [SELECT DeveloperName, MasterLabel, Key__c, OWA__c, EmailTemplateApiName__c FROM  Email_Template_Mapping__mdt]){
            //emailTemplateMap.put(obj.MasterLabel, obj);
            emailTemplateMap.put(obj.Key__c, obj);
        }
        return emailTemplateMap;
    }
    
    public static MethodResponse getEmailTemplateByMasterLabel(String masterLabel){ //from Custom Metadata Types: Email Template Mappings
        MethodResponse res = new MethodResponse();
        
        //get Email Template Name based on MetaData - Email Template Mapping
        Map<String, Email_Template_Mapping__mdt> emailTemplateMap = EmailController.getEmailTemplateMappings();
        
        String templateName = '';
        OrgWideEmailAddress owa = null;

        if(emailTemplateMap.containsKey(masterLabel)) {
            templateName = emailTemplateMap.get(masterLabel).EmailTemplateApiName__c;
            owa = getOrgWideEmailAddress(emailTemplateMap.get(masterLabel).OWA__c);
            
        } else {
            res.setStatus(400);
            res.setResult('error', 'Failed to send email - could not find Email template name to match Metadata ' + masterLabel);
            return res;
        }
        
        List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate WHERE developerName =: templateName];
        if(emailTemplates.isEmpty()){
            res.setStatus(409);
            res.setResult('error', 'Could not find email template with developerName = ' + templateName);
            res.setResult('log', 'EmailController.getEmailTemplateByLabel Handled Exception: Could not find email template with developerName = ' + templateName );
            return res;
        }
        
        EmailTemplate emailTemplate = emailTemplates[0];  
        res.setStatus(200);
        res.setResult('log', 'Found and return email template with developerName = ' + templateName);
        res.emailTemplate = emailTemplate;
        res.orgWideEmailAddress = owa; //return OrgWideEmailAddress object
        return res;
    }
    
    //Original - TO BE REFACTORED------------------------------------------------------------Start---------------------------------------------------------------------------------
    //ContractController, EmailControllerTest, OnboardingController, ServiceWaiverController, SupportHubSignupController
    public static void sendEmail(ID whoId, ID whatId, EmailTemplate emailTemplate, List<String> toAddresses, List<String> ccAddresses, String htmlBody, String plainBody){
        Messaging.Singleemailmessage email = constructEmail(whoId, whatId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody);
        try{
            Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email});
        }
        catch( Exception ex ){
           system.debug('EmailController.sendEmail error on code: Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email}); ' + ex.getMessage());
       }
        
    }
    
    public static Messaging.Singleemailmessage constructEmail(ID whoId, ID whatId, EmailTemplate emailTemplate, List<String> toAddresses, List<String> ccAddresses, String htmlBody, String plainBody){
        //build the email message - testable code in EmailControllerTest.testConstructEmail(testUser)
        Messaging.Singleemailmessage email = new Messaging.Singleemailmessage();
        
        email.setTemplateId(emailTemplate.Id);
        
        if(!toAddresses.isEmpty()) email.setToAddresses(toAddresses);
        if(!ccAddresses.isEmpty()) email.setccAddresses(ccAddresses);
        
        //if (UserInfo.getUserType() == 'Guest' || UserInfo.getUserType() == 'CspLitePortal'){
            //email.setSenderDisplayName('N4L Support'); //don't let external user use Org Wide Email Address
           
            // no-reply@n4l.co.nz
        //} else {
            //get Org Wide Email Address
            OrgWideEmailAddress owa = getOrgWideEmailAddress(Label.N4L_Sender_Email); 
            if(owa != null ) {
                email.setOrgWideEmailAddressId(owa.Id);         
            } else {
                email.setSenderDisplayName('N4L Support'); //default to display name when we could not find Org Wide Email Address
            }
        //}
        
        if(String.isNotBlank(whoId)) email.setTargetObjectId(whoId);
        if(String.isNotBlank(whatId)) email.setWhatId(whatId);
        email.setSaveAsActivity(true);
        
        String subject = emailTemplate.Subject;
        email.setSubject(subject);
        if(String.isNotBlank(htmlBody)) email.setHtmlBody(htmlBody);
        if(String.isNotBlank(plainBody)) email.setPlainTextBody(plainBody);
        
        return email;
    }
    //Original - TO BE REFACTORED------------------------------------------------------------End---------------------------------------------------------------------------------

    //Temporary Workaround------------------------------------------------------------Start---------------------------------------------------------------------------------
    //ContractController, EmailControllerTest - for MOU 20/2/2020
    public static void sendEmail2(ID whoId, ID whatId, EmailTemplate emailTemplate, List<String> toAddresses, List<String> ccAddresses, String htmlBody, String plainBody, OrgWideEmailAddress owa){
        Messaging.Singleemailmessage email = constructEmail2(whoId, whatId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, owa);
        Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email});
    }

    public static Messaging.Singleemailmessage constructEmail2(ID whoId, ID whatId, EmailTemplate emailTemplate, List<String> toAddresses, List<String> ccAddresses, String htmlBody, String plainBody, OrgWideEmailAddress owa){
        //build the email message - testable code in EmailControllerTest.testConstructEmail(testUser)
        Messaging.Singleemailmessage email = new Messaging.Singleemailmessage();
        
        email.setTemplateId(emailTemplate.Id);
        
        if(!toAddresses.isEmpty()) email.setToAddresses(toAddresses);
        if(!ccAddresses.isEmpty()) email.setccAddresses(ccAddresses);
        
        
        if(owa != null ) {
            email.setOrgWideEmailAddressId(owa.Id); //set Org Wide Email Address
        } else {
            email.setSenderDisplayName('N4L Support'); //default to display name when we could not find Org Wide Email Address
        }
        
        if(String.isNotBlank(whoId)) email.setTargetObjectId(whoId);
        if(String.isNotBlank(whatId)) email.setWhatId(whatId);
        email.setSaveAsActivity(true);
        
        String subject = emailTemplate.Subject;
        email.setSubject(subject);
        if(String.isNotBlank(htmlBody)) email.setHtmlBody(htmlBody);
        if(String.isNotBlank(plainBody)) email.setPlainTextBody(plainBody);
        
        return email;
    }
}

/*
public without sharing class EmailController {
    public static OrgWideEmailAddress getOrgWideEmailAddress(String email){
        List<OrgWideEmailAddress> lstOrgEmailAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = : email];
        if(!lstOrgEmailAddress.isEmpty()) return lstOrgEmailAddress[0];
        else return null ;
    }
 
    public static Map<String, Email_Template_Mapping__mdt> getEmailTemplateMappings(){
        Map<String, Email_Template_Mapping__mdt> emailTemplateMap = new Map<String, Email_Template_Mapping__mdt>();
        
        for(Email_Template_Mapping__mdt obj: [SELECT DeveloperName,MasterLabel FROM  Email_Template_Mapping__mdt]){
            emailTemplateMap.put(obj.MasterLabel, obj) ;
        }
        return emailTemplateMap;
    }
    
    public static MethodResponse getEmailTemplateByMasterLabel(String masterLabel){ //from Custom Metadata Types: Email Template Mappings
        MethodResponse res = new MethodResponse();
        
        //get Email Template Name based on MetaData - Email Template Mapping
        Map<String, Email_Template_Mapping__mdt> emailTemplateMap = EmailController.getEmailTemplateMappings();
        
        String templateName = '';
        if(emailTemplateMap.containsKey(masterLabel)) {
            templateName = emailTemplateMap.get(masterLabel).DeveloperName;
        } else {
            res.setStatus(400);
            res.setResult('error', 'Failed to send email - could not find Email template name to match Metadata ' + masterLabel);
            return res;
        }
        
        List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate WHERE developerName =: templateName];
        if(emailTemplates.isEmpty()){
            res.setStatus(409);
            res.setResult('error', 'Could not find email template with developerName = ' + templateName);
            res.setResult('log', 'EmailController.getEmailTemplateByLabel Handled Exception: Could not find email template with developerName = ' + templateName );
            return res;
        }
        
        EmailTemplate emailTemplate = emailTemplates[0];  
        res.setStatus(200);
        res.setResult('log', 'Found and return email template with developerName = ' + templateName);
        res.emailTemplate = emailTemplate;
        return res;
    }
    
    public static void sendEmail(ID whoId, ID whatId, EmailTemplate emailTemplate, List<String> toAddresses, List<String> ccAddresses, String htmlBody, String plainBody){
        Messaging.Singleemailmessage email = constructEmail(whoId, whatId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody);
        Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email});
    }
    
    public static Messaging.Singleemailmessage constructEmail(ID whoId, ID whatId, EmailTemplate emailTemplate, List<String> toAddresses, List<String> ccAddresses, String htmlBody, String plainBody){
        //build the email message - testable code in EmailControllerTest.testConstructEmail(testUser)
        Messaging.Singleemailmessage email = new Messaging.Singleemailmessage();
        
        email.setTemplateId(emailTemplate.Id);
        
        if(!toAddresses.isEmpty()) email.setToAddresses(toAddresses);
        if(!ccAddresses.isEmpty()) email.setccAddresses(ccAddresses);
        
        //if (UserInfo.getUserType() == 'Guest' || UserInfo.getUserType() == 'CspLitePortal'){
            //email.setSenderDisplayName('N4L Support'); //don't let external user use Org Wide Email Address
           
            // no-reply@n4l.co.nz
        //} else {
            //get Org Wide Email Address
            OrgWideEmailAddress owa = getOrgWideEmailAddress(Label.N4L_Sender_Email);
            if(owa != null ) {
                email.setOrgWideEmailAddressId(owa.Id);
            } else {
                email.setSenderDisplayName('N4L Support'); //default to display name when we could not find Org Wide Email Address
            }
        //}
        
        if(String.isNotBlank(whoId)) email.setTargetObjectId(whoId);
        if(String.isNotBlank(whatId)) email.setWhatId(whatId);
        email.setSaveAsActivity(true);
        
        String subject = emailTemplate.Subject;
        email.setSubject(subject);
        if(String.isNotBlank(htmlBody)) email.setHtmlBody(htmlBody);
        if(String.isNotBlank(plainBody)) email.setPlainTextBody(plainBody);
        
        return email;
    }
}
*/