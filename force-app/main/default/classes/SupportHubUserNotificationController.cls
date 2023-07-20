/**
* @author Ben Soh 
* @date 2021-03-12
* @description replace Community Welcome Email function. Process builder invokes the method and let it decide which email to send according to custom metadata mapping
*
* CHANGE LOG
**/
public without sharing class SupportHubUserNotificationController {
    public enum Origin {SELFSIGNUP, SCHOOLCONTACTSUPDATECAMPAIGN}

    public SupportHubUserNotificationController() {

    }

    @InvocableMethod(label='Send user notification email' description='asynchronously send various notification email based on User Origin and Custom Metadata: Support Hub User Creation Mapping')
    public static void SendUserNotificationEmails(List<ID> ids) {
        system.enqueueJob(new queue_SendUserNotificationEmails(ids));
        
    }

    //inner class
    public class queue_SendUserNotificationEmails implements Queueable {
        Private List<User> users;
        Private Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap;
        Private Map<String, EmailTemplate> emailTemplateMap;
        Private String partialURL;
        
        public queue_SendUserNotificationEmails(List<ID> ids){
            this.users = new List<User>();
            this.users = [SELECT id, FirstName, LastName, Name, username, email, Phone, MobilePhone, ContactId, Contact.userOrigin__c, AccountId
                            , LastLoginDate, IsActive, IsPortalEnabled, UserType, ProfileId, Profile.Name
                            , UserPermissionsFilteringPortalUser__c, UserPermissionsSchoolReportingUser__c, UserPermissionsNMSUser__c FROM User WHERE id IN: ids];
            if(!this.users.isEmpty()){
                //prepare a map to hold custom metadata records
                this.userCreationMap = SupportHubUserNotificationController.getUserCreationMapping('origin');
                
                //prepare a set of template api names
                Set<String> templateNames = new Set<String>();
                for (Support_Hub_User_Creation_Mapping__mdt mapping : this.userCreationMap.values()){
                    if(!String.isBlank(mapping.Welcome_Email_Template_Mapping__r.EmailTemplateApiName__c)){
                        templateNames.add(mapping.Welcome_Email_Template_Mapping__r.EmailTemplateApiName__c);
                    }
                }
                
                //get a list of email templates
                this.emailTemplateMap = new Map<String, EmailTemplate>();
                List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate WHERE developerName IN: templateNames];
                if(!emailTemplates.isEmpty()){
                    for(EmailTemplate emailTemplate : emailTemplates){
                        emailTemplateMap.put(emailTemplate.developerName, emailTemplate);
                    }
                } else {
                    trackServiceEvent(400, 'BAD_REQUEST', 'queue_SendUserNotificationEmails() error: List<EmailTemplate> emailTemplates cannot be empty. ' + System.JSON.serialize(this.users));
                }

                this.partialURL = Helper.supportHubURL();

            } else {
                trackServiceEvent(400, 'BAD_REQUEST', 'queue_SendUserNotificationEmails() error: List<User> users cannot be empty.');
            }
        }

        public void execute(QueueableContext context) {
            

            try{
                if(!Test.isRunningTest()){ //to prevent it from running the chained queue. System.LimitException: Apex CPU time limit exceeded  
                system.enqueueJob(new queue_RecursiveSendUserNotificationEmails(this.users, this.userCreationMap, this.emailTemplateMap, this.partialURL));
                }
            } catch (System.Exception e) {
                trackServiceEvent(400, 'BAD_REQUEST', 'queue_SendUserNotificationEmails().execute ' + e.getMessage() + e.getStackTraceString());
            }
        }

        

        public void trackServiceEvent(Integer code, String status, String body ){
            ServiceEventWrapper event = new ServiceEventWrapper();
            event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
            event.header.eventType = 'Send user notification email';
            event.header.action = 'email';
            event.header.replayId = 1;
            event.header.eventDate = datetime.now();
            event.header.internalReferenceId = 'queue_SendUserNotificationEmails() error';
            event.header.origin = 'Salesforce';
            
            HttpResponse response = new HttpResponse();
            response.setStatusCode(code);
            response.setStatus(status);
            response.setBody(body);

            String recordId = '';
            
            ServiceEventController.createServiceEvent(event, response, recordId);
        }
    }

    public class queue_RecursiveSendUserNotificationEmails implements Queueable {
        Private List<User> users;
        Private Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap;
        Private Map<String, EmailTemplate> emailTemplateMap;
        Private String partialURL;

        public queue_RecursiveSendUserNotificationEmails(List<User> users, Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap, Map<String, EmailTemplate> emailTemplateMap, String partialURL){
            this.users = users;
            this.userCreationMap = userCreationMap;
            this.emailTemplateMap = emailTemplateMap;
            this.partialURL = partialURL;
        }

        public void execute(QueueableContext context) {
            execute_SendUserNotificationEmail(); //get pdf and safe as file, and then remove 1 item from the list.
            
            if (!this.users.isEmpty()){
                //when there are more pdf to get, chain to another queue and do it again
                if(!Test.isRunningTest()){
                    system.enqueueJob(new SupportHubUserNotificationController.queue_RecursiveSendUserNotificationEmails(this.users, this.userCreationMap, this.emailTemplateMap, this.partialURL));    
                }
            }
        }

        public void execute_SendUserNotificationEmail(){
            if (!this.users.isEmpty()){
                User user = this.users.remove(0);
                try{
                    Support_Hub_User_Creation_Mapping__mdt mapping = this.userCreationMap.get(user.Contact.userOrigin__c);
                    OrgWideEmailAddress owa = EmailController.getOrgWideEmailAddress(mapping.Welcome_Email_Template_Mapping__r.OWA__c);
                    EmailTemplate emailTemplate = this.emailTemplateMap.get(mapping.Welcome_Email_Template_Mapping__r.EmailTemplateApiName__c);
                    String hyperlink = SupportHubUserNotificationController.GenerateHyperlink(user.AccountId, mapping, this.partialURL);
                    
                    
                    //if(!Test.isRunningTest()){
                        MethodResponse res  = SupportHubUserNotificationController.send_UserNotification_Email(user, emailTemplate, owa, hyperlink);
                        if(res.statuscode >= 400){
                            trackServiceEvent(res.statuscode, res.status, 'queue_RecursiveSendUserNotificationEmails().execute_SendUserNotificationEmail ' + res.getJSONstring() , user.Id);
                        }
                    //}
                } catch (System.Exception e) {
                    trackServiceEvent(400, 'BAD_REQUEST', 'queue_RecursiveSendUserNotificationEmails().execute_SendUserNotificationEmail ' + e.getMessage() + e.getStackTraceString() , user.Id);
                }    
            }
        }

        
        

        public void trackServiceEvent(Integer code, String status, String body, String recordId ){
            ServiceEventWrapper event = new ServiceEventWrapper();
            event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
            event.header.eventType = 'Send user notification email';
            event.header.action = 'email';
            event.header.replayId = 1;
            event.header.eventDate = datetime.now();
            event.header.internalReferenceId = recordId;
            event.header.origin = 'Salesforce';
            
            HttpResponse response = new HttpResponse();
            response.setStatusCode(code);
            response.setStatus(status);
            response.setBody(body);

            
            ServiceEventController.createServiceEvent(event, response, recordId);
        }

        
    }

    public static MethodResponse send_UserNotification_Email (User user, EmailTemplate emailTemplate, OrgWideEmailAddress orgWideEmailAddress, String hyperlink){
        MethodResponse res = new MethodResponse();
        try{           
            //toAddresses
            List<String> toAddresses = new List<String>();
            if(user != null && String.isNotBlank(user.Email)) toAddresses.add(user.Email);
            
            //ccAddresses - no cc required, but leave it as empty list
            List<String> ccAddresses = new List<String>();
            
            if(emailTemplate == null){
                res.setStatus(400);
                res.setResult('error', 'send_UserNotification_Email() error: emailTemplate cannot be null');
                return res;
            }

            if(orgWideEmailAddress == null){
                res.setStatus(400);
                res.setResult('error', 'send_UserNotification_Email() error: orgWideEmailAddress cannot be null');
                return res;
            }
            
            //Email Template

            String htmlBody = emailTemplate.HtmlValue;
            htmlBody = htmlBody.replace('{!Contact.FirstName}', user.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            htmlBody = htmlBody.replace('[username]', user.username); 
            htmlBody = htmlBody.replace('[hyperlink]', hyperlink); 
            
            String plainBody = emailTemplate.Body;
            plainBody = plainBody.replace('{!Contact.FirstName}', user.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            plainBody = plainBody.replace('[username]', user.username); 
            plainBody = plainBody.replace('[hyperlink]', hyperlink); 

            
            EmailController.sendEmail2(user.ContactId, user.AccountId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, orgWideEmailAddress);    
            res.setStatus(200);
            res.setResult('success', 'Sent ' + emailTemplate.Name +' Email to ' + string.join(toAddresses,','));  
            return res;
            
        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            return res;
        }
    }
    
    public static string GenerateHyperlink(String recordId, Support_Hub_User_Creation_Mapping__mdt mapping , String partialURL){
        String result = '#'; 
        if(mapping.IsVisualforcePage__c){
            partialURL = partialURL.left(partialURL.length()-2); //just to remove the "s/" at the End
        }

        //TODO: in the future, when we need more enhancement or specify url param on the destinateion page, modify the switch on code here.
        switch on mapping.Key__c.toLowerCase() {
            when 'schoolcontactsupdatecampaign'{
                result = partialURL + mapping.startURL__c + '?recId=' + recordId;
            }
            when else {
                result = partialURL + Helper.getStringValue(mapping.startURL__c);
            }
        }

        return result;
    }

    public static Map<string, Support_Hub_User_Creation_Mapping__mdt> getUserCreationMapping(String key){
        Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap = new Map<string, Support_Hub_User_Creation_Mapping__mdt>();
        List<Support_Hub_User_Creation_Mapping__mdt> mappings = [SELECT DeveloperName, Id, MasterLabel, Key__c, Description__c, UserOrigin__c, startURL__c, IsVisualforcePage__c
                                                                                , Invitation_Email_Template_Mapping__r.EmailTemplateApiName__c, Invitation_Email_Template_Mapping__r.OWA__c
                                                                                , Welcome_Email_Template_Mapping__r.EmailTemplateApiName__c, Welcome_Email_Template_Mapping__r.OWA__c
                                                                                , Message_on_Verify_Email_Page__c 
                                                                                FROM Support_Hub_User_Creation_Mapping__mdt];
        switch on key {
            when 'key' {
                For (Support_Hub_User_Creation_Mapping__mdt mapping : mappings){
                    userCreationMap.put(mapping.Key__c, mapping);
                }
            }
            when 'origin' {
                For (Support_Hub_User_Creation_Mapping__mdt mapping : mappings){
                    userCreationMap.put(mapping.UserOrigin__c, mapping);
                }
            }
        }
        
        return userCreationMap;
    }
}