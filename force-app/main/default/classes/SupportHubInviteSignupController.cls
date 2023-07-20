/**
* @author Ben Soh 
* @date 2021-03-23
* @description Controller for the LWC contactSingleItem.js call and execute the operations InviteToCreateCustomerUser
*               generate Verification Code and send it via email
*               redirect to visualforce pages.
*
* CHANGE LOG
**/
public with sharing class SupportHubInviteSignupController {
    
    @AuraEnabled() //using cacheable=true will cause error LIMIT_USAGE_FOR_NS   Number of DML statements: 1 out of 0 ******* CLOSE TO LIMIT
    public static List<Map<String, String>> InviteToCreateCustomerUser(id contactId, string userOrigin) {
        //parameter string userOrigin receives values from LWC: contactSingleItem.js which shall allow Internal User to choose the User Origin for the contact
        List<Map<String, String>> result = New List<Map<String, String>>();
        MethodResponse res = new MethodResponse();
        Map<String, String> resMap = New Map<String, String>(); //for adding into list result

        List<Contact> contacts =  [SELECT Id, FirstName, LastName, AccountId, Email, MobilePhone, Phone FROM Contact WHERE Id =: contactId];
		
        //error
        if(contacts.isEmpty()){
            if (String.isNotBlank(contactId)){
                res.setStatus(404);
                res.setResult('error', 'Could not find a Contact record with id = ' + contactId);   
            } else {
                res.setStatus(400);
                res.setResult('error', 'Missing contactId');    
            }
            resMap.put('response', res.getJSONstring());
            result.add(resMap);
            return result;
        }

        //get contact successful
        Contact contact = contacts[0];
        
        // Validate that an existing user doesn't already exist and raise an error
        //copied from SupportHubSignUpController.submit
        List<User> checkUsers = [SELECT Id FROM User WHERE Username = :contact.Email];
        if (!checkUsers.isEmpty()){
            res.setStatus(400);
            res.setResult('error', 'User already exist with the email address:' + contact.Email );  

            resMap.put('response', res.getJSONstring());
            result.add(resMap);
            return result;
        } 

        MethodResponse res1 = InviteToCreateUser_email_actions(contact, userOrigin);

        if(res1.statuscode >= 400){
            res.setStatus(400);
            res.setResult('error', 'error sending email to invite contact to create user.' );  
            
            resMap.put('response', res.getJSONstring());
            result.add(resMap);
            return result;
        }
        
        //just return the same contact
        result =  ContactController.getContact_WithUser(contact.Id); //return the same JSON structure as getContract() above
        return result;
        
    }



    //main method for sending email
    public static MethodResponse InviteToCreateUser_email_actions(Contact contact, String userOrigin){
        MethodResponse res = new MethodResponse();
        try{
            String type='Invite-SignUp';

            //create Token
                MethodResponse res1= createToken(contact, type, userOrigin);
                if (res1.statusCode >= 400) return res1; //stop and return with error message
                Token__c token = res1.token;
                res.results.putAll(res1.results); //append results in res1 to res.
    
                // ------------------------ generate encrypted JWT ----------------------------
                Map<String, String> responseTokens = generateResponseTokens(token, type);
                token.JWT1__c = responseTokens.get('respondToken'); 
                update token; //save JWT1 and 2
                MethodResponse res2 = TokenController.getToken(token.id);
                token = res2.token;
                
                // ---------------------------- send email to principal ----------------------------
                MethodResponse res3 = send_InviteToCreateUser_Email(contact, token);
                if (res3.statusCode >= 400) return res3; //stop and return the caseResponse with error message
                res.results.putAll(res3.results); //append results in res3 to res.

                res.setStatus(200);
                return res;
                
        }catch (Exception e) {
            res.setStatus(400);
            res.setResult('error', e.getMessage());
            return res;
        }
    }
   
    public static MethodResponse createToken(Contact contact, String type, String userOrigin){
        MethodResponse res = new MethodResponse();
   
        try {
            Token__c token = new Token__c(
                RecordId__c = String.valueOf(contact.Id),
                Account__c = contact.AccountId, //account Id
                Requester__c = null,
                Approver__c = contact.Id, //contact Id,
                Type__c = type,
                Status__c = 'Invited',
                IsClosed__c = false,
                Parent__c = null,
                UserOrigin__c = userOrigin //'N4L Invitation - Default'
            );
            insert token;
            
            //return response
            res.setStatus(201);
            res.setResult('success', 'Generate Token : ' + token.Id);  
            res.token = token; //return dto
            return res;
        } catch (Exception e) {
            res.setStatus(400);
            res.setResult('error', e.getStackTraceString());
            return res;
        }
    }

    Public Static Map<String, String> generateResponseTokens(Token__c token, String type){
        Boolean isEncrypted = true;
        Map<String, String> claimsMap = new Map<String, String>();
        claimsMap.put('tokenId', token.Id);
        claimsMap.put('response', 'Responded');
        String respondToken = JWTController.issueJWT(type, claimsMap, isEncrypted);
        Map<String, String> result = new Map<String, String>();
        result.put('respondToken', respondToken);
        return result;
    }

    public static MethodResponse send_InviteToCreateUser_Email (Contact contact, Token__c token){
        MethodResponse res = new MethodResponse();

        try{           
            //toAddresses
            List<String> toAddresses = new List<String>();
            if(contact != null && String.isNotBlank(contact.Email)) toAddresses.add(contact.Email); //add campaign contact's email to address
            
            //ccAddresses - no cc required, but leave it as empty list
            List<String> ccAddresses = new List<String>();
            
            //based on token.UserOrigin__c, dynamically get Email Template based on Metadata: Support Hub User Creation Mapping + Email Template Mapping
            Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap = SupportHubUserNotificationController.getUserCreationMapping('origin');
            Support_Hub_User_Creation_Mapping__mdt mapping = userCreationMap.get(token.UserOrigin__c);
            OrgWideEmailAddress owa = EmailController.getOrgWideEmailAddress(mapping.Invitation_Email_Template_Mapping__r.OWA__c);
            
            List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate WHERE developerName =: mapping.Invitation_Email_Template_Mapping__r.EmailTemplateApiName__c];
            if(emailTemplates.isEmpty()){
                res.setStatus(400);
                res.setResult('error', 'Cannot find Email Template - ' + mapping.Invitation_Email_Template_Mapping__r.EmailTemplateApiName__c);
                return res;
            }
            EmailTemplate emailTemplate = emailTemplates[0];

            // //get Email Template Name based on MetaData - Email Template Mapping
            // String masterLabel = ('n4l invitation default to create user').toLowerCase();
            // MethodResponse res2 = EmailController.getEmailTemplateByMasterLabel(masterLabel);
            // if(res2.statusCode >= 400) return res2;
            // EmailTemplate emailTemplate = res2.emailTemplate; //dto in res
            // OrgWideEmailAddress orgWideEmailAddress = res2.orgWideEmailAddress; //dto in res
            
            String partialURL = Helper.supportHubURL();
            String hyperlink = partialURL + 'request-authorisation?p=invite-signup&t=' + token.JWT1__c;

            //Email Template
            String htmlBody = emailTemplate.HtmlValue;         
            String plainBody = emailTemplate.Body;
            
            htmlBody = htmlBody.replace('{!Contact.FirstName}', Helper.getStringValue(contact.FirstName)); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work             
            htmlBody = htmlBody.replace('[hyperlink]', Helper.getStringValue(hyperlink)); 
            
            plainBody = plainBody.replace('{!Contact.FirstName}', Helper.getStringValue(contact.FirstName)); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            plainBody = plainBody.replace('[hyperlink]', Helper.getStringValue(hyperlink)); 

            EmailController.sendEmail2(token.Approver__c, token.Account__c, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, owa);    
            res.setStatus(200);
            res.setResult('success', 'Sent ' + emailTemplate.Name +' Email to ' + string.join(toAddresses,','));  
            return res;
            
        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            return res;
        }
    }

    //need to response back to LWC in request-authorisation page so that it knows how to redirect
    //claimsMap comes from JWTController.request_authorisation_action
    public static MethodResponse RespondedToCreateUserByInvitation(Map<String, Object> claimsMap){
        MethodResponse res = new MethodResponse();

        Id tokenId = String.valueOf(claimsMap.get('tokenId')); 
        String response = String.valueOf(claimsMap.get('response'));

        MethodResponse res1 = TokenController.getToken(tokenId);
        if (res1.statusCode >= 400) return res1;
        Token__c token = res1.token; //res1 return token as dto
        
        if(token.IsClosed__c){
            res.setResult('request_authorisation', 'invite signup');
            res.setResult('navigate_to_url', 'supporthubsignup'); //directly go to the sign up page
            res.setStatus(200);
            return res;
        }

        Id contactId = token.Approver__c;

        //query to find existing user record
        List<User> users = [SELECT contactId, name, username, IsActive, IsPortalEnabled, LastLoginDate  FROM user WHERE contactId =: contactId];

        if(users.isEmpty()){
            //no user
            //generate VerificationCode and send it via email
            MethodResponse res3 = SupportHubUserSetupController.SendVerificationCode_actions(token); //passing token as parentToken for verificationToken
            if (res3.statusCode >= 400) return res3;
            Token__c verificationToken = res3.token;

            res.setResult('request_authorisation', 'invite signup - no user yet');
            
            //create the second part of url for LWC in request-authorisation page to navigate to
            //res.setResult('navigate_to_url', 'supporthubverifyemail?t=' + verificationToken.JWT1__c + '&startUrl=' + startURL_ManageContact());
            res.setResult('navigate_to_url', 'supporthubverifyemail?t=' + verificationToken.JWT1__c);

            token.Status__c = 'Responded'; //only update status, don't close yet.
            update token;

            
        } else {
            //has user
            res.setResult('request_authorisation', 'invite signup - already has user');
            res.setResult('navigate_to_url', ''); //directly go to the main page

            MethodResponse res4 = TokenController.closeToken(tokenId, 'Responded');
            if (res4.statusCode >= 400) return res4;
        }

        res.setStatus(200);
        return res; 
    }

    @AuraEnabled(cacheable=true)
    public static boolean inviteBtnIsClicked (id contactId) {
        boolean isClicked = false;

        List<Token__c> tokenlist = [SELECT id, Type__c, isClosed__c, Approver__c FROM token__c
        WHERE Type__c = 'Invite-SignUp' AND Approver__c =: contactId];
        
        if(!tokenlist.isEmpty()){
            isClicked = true;
            return isClicked;
        }else{
            return false;
        }

    }

    @AuraEnabled(cacheable=true)
    public static String InviteBtnClickedTime (id contactId) {
        List<Token__c> tokenlist = [SELECT id, CreatedDate, Type__c, isClosed__c, Approver__c FROM token__c
        WHERE Type__c = 'Invite-SignUp' AND Approver__c =: contactId order by createdDate DESC limit 1];
        
        token__c token = tokenlist[0];
        String btnClickedTime = Helper.formatNZdatetime(token.createdDate);
        return btnClickedTime;
    }


}