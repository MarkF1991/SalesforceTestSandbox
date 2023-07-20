/**
* @author Ben Soh 
* @date 2021-02-25
* @description Controller for the JWTController to route and execute the operations SchoolContactUpdate_Confirm_or_Update
*               generate Verification Code and send it via email
*               redirect to visualforce pages.
*
* CHANGE LOG
**/
public without sharing class SupportHubUserSetupController {
    public static JWT testJWT;// for testing purpose
    public static MethodResponse testRes;
    public SupportHubUserSetupController() {
        
    }
    
    public static MethodResponse getTokenRecord(String urlToken, String Type){
        MethodResponse res = new MethodResponse();
        //decrypt the token, and then decode JWT in order to get jwt.claims
        Boolean isEncrypted = true;
        //String type = 'Verification Code';
        JWT jwt = Test.isRunningTest()? testJWT :JWTController.decodeJWT(type, urlToken, isEncrypted); 
        if(!jwt.verified || jwt.expired){
            res.setStatus(400);
            string result = jwt.expired ? 'Sorry, the session token has expired.': 'unverified token';
            res.setResult('error', result);
            return res;
        }
        //merge into above method
        //if(jwt.expired){
        // res .setStatus(400);
        //  res.setResult('error', 'Sorry, the session token has expired.');
        // return res;
        // }
        
        Map<String, Object> claimsMap = jwt.claims;
        
        //get token record id and then return token record
        Id tokenId = String.valueOf(claimsMap.get('tokenId')); 
        
        return TokenController.getToken(tokenId);
    }
    
    //need to response back to LWC in request-authorisation page so that it knows how to redirect
    //claimsMap comes from JWTController.request_authorisation_action
    public static MethodResponse SchoolContactsUpdate_Confirm_or_Update(Map<String, Object> claimsMap){
        MethodResponse res = new MethodResponse();
        
        Id tokenId = String.valueOf(claimsMap.get('tokenId')); 
        String response = String.valueOf(claimsMap.get('response'));
        
        //only allow 'confirm' or 'update' to operate here.
        
        
        MethodResponse res1 = Test.isRunningTest()? testRes : TokenController.getToken(tokenId);
        if (res1.statusCode >= 400) return res1;
        Token__c token = res1.token; //res1 return token as dto
        
        // if(token.IsClosed__c){
        //     res.setStatus(401);
        //     res.setResult('error', 'token has been used and is now closed');
        //     return res;
        // }
        
        switch on response {
            when  'confirmed'{
                if(token.IsClosed__c){
                    res.setStatus(401);
                    res.setResult('request_authorisation', 'school contact update - confirmed');
                    return res;
                }
                
                //action for contact up to date
                // Get list of business contact roles
                List<AccountContactRelation> accountContactRelationList = new List<AccountContactRelation>();
                List<N4L_Business_Contact_Role__mdt> businessRoles = [SELECT ID, MasterLabel 
                                                                      FROM N4L_Business_Contact_Role__mdt ORDER BY Id];
                
                List<String> businessRolesList = new List<String>();
                List<String> roleSet = new List<String>();
                for(N4L_Business_Contact_Role__mdt businessRole : businessRoles) {
                    businessRolesList.add(businessRole.MasterLabel);
                    roleSet.add('\''+ businessRole.MasterLabel + '\'');
                }
                
                String acrQueryString = 'SELECT Id,AccountId,Contact.Name,Roles, Contact.Email FROM AccountContactRelation '+
                    'WHERE AccountId = \''+token.Account__c+'\' AND isActive = True AND Roles INCLUDES ( ' +
                    String.join(roleSet, ',')+' )' ;
                accountContactRelationList = (List<AccountContactRelation>) Database.query(acrQueryString);
                List<string> cttId = new List<string>();
                for(AccountContactRelation accountContactRelation : accountContactRelationList){
                    cttId.add(accountContactRelation.contactId);
                }
                List<Contact> updateContacts = new List<Contact>();
                List<Contact> contacts = [SELECT Id, Name, Last_Update__c, AccountId From Contact WHERE Id IN: cttId];
                for(Contact contact : contacts){
                    contact.Last_Update__c = System.today();
                    updateContacts.add(contact);
                    
                }
                update updateContacts;
                
                //Redirect page
                res.setResult('request_authorisation', 'school contact update - confirm');
                MethodResponse res2 = Test.isRunningTest()? testRes : TokenController.closeToken(tokenId, 'Confirmed');
                if (res2.statusCode >= 400) return res2;
                
                MethodResponse res3 = Test.isRunningTest()? testRes : send_SchoolContactConfirmed_Email(token);
                if (res3.statusCode >= 400) return res3;
            }
            when  'updated'{
                Id contactId = token.Approver__c;
                
                //query to find existing user record
                List<User> users = [SELECT contactId, name, username, IsActive, IsPortalEnabled, LastLoginDate  FROM user WHERE contactId =: contactId];
                
                if(token.IsClosed__c && !users.isEmpty()){
                    res.setResult('request_authorisation', 'school contact update - already has user');
                    res.setResult('navigate_to_url', 'account/' + token.Account__c); //directly go to the comunities page manage-contacts with LWC
                    res.setStatus(200);
                    return res;
                }
                
                
                
                if(users.isEmpty()){
                    //no user
                    //generate VerificationCode and send it via email
                    //MethodResponse res3 = SendVerificationCode_actions(contactId, token);
                    MethodResponse res3 = SendVerificationCode_actions(token); //passing token as parentToken for verificationToken
                    if (res3.statusCode >= 400) return res3;
                    Token__c verificationToken = res3.token;
                    
                    res.setResult('request_authorisation', 'school contact update - no user yet');
                    
                    //create the second part of url for LWC in request-authorisation page to navigate to
                    //res.setResult('navigate_to_url', 'supporthubverifyemail?t=' + verificationToken.JWT1__c + '&startUrl=' + startURL_ManageContact());
                    res.setResult('navigate_to_url', 'supporthubverifyemail?t=' + verificationToken.JWT1__c);
                    
                    token.Status__c = 'Updated'; //only update status, don't close yet.
                    update token;
                    
                    
                } else {
                    //has user
                    res.setResult('request_authorisation', 'school contact update - already has user');
                    res.setResult('navigate_to_url', 'manage-contacts?recId=' + token.Account__c); //directly go to the comunities page manage-contacts with LWC
                    
                    MethodResponse res4 = TokenController.closeToken(tokenId, 'Updated');
                    if (res4.statusCode >= 400) return res4;
                }
                
            }
            when  'delegate'{
                // if(token.IsClosed__c){
                //     res.setStatus(401);
                //     res.setResult('error', 'token has been used and is now closed');
                //     return res;
                // }
                
                res.setResult('request_authorisation', 'school contact delegate');
                
                res.setResult('navigate_to_url', 'SupportHubDelegateAuthority?t=' + Token.JWT3__c);
                token.Status__c = 'Delegated'; //only update status, don't close yet.
                update token;
                
            }
            when else {
                res.setStatus(400);
                res.setResult('error', 'School Contact Update request authorisation requires token.claims to consist "confirmed" or "updated"');
                return res;
            }
        }
        
        
        res.setStatus(200);
        return res; 
        
    }
    
    // public static string startURL_ManageContact(){
    //     //create the second part of url for LWC in request-authorisation page to navigate to
    //     return (Helper.isSandbox() ? '/schoolictsupport/s/manage-contacts' : '/s/manage-contacts');
    // }
    
    
    
    //------------------------- verification code ------------------------------------------------------------------
    //public static MethodResponse SendVerificationCode_actions(Id contactId, Token__c parentToken){
    public static MethodResponse SendVerificationCode_actions(Token__c parentToken){
        MethodResponse res = new MethodResponse();
        String type = 'Verification Code';
        try {
            //Contact contact = ContactController.getContact(contactId);
            
            // ---------------------------- create VerificationCode Token ----------------------------
            // MethodResponse res1 = create_VerificationCode_Token(contact, type, parentToken);
            MethodResponse res1 = create_VerificationCode_Token(type, parentToken);
            if (res1.statusCode >= 400) return res1; //stop and return the caseResponse with error message
            //res.setResult('log', 'create_VerificationCode_Token created token. Next step: Token__c token = res1.token' );
            Token__c token = res1.token;
            //res.setResult('log', 'create_VerificationCode_Token assigned token' );
            res.results.putAll(res1.results); //append results in res2 to res.
            
            // ---------------------------- generate encrypted JWT ----------------------------
            Map<String, String> responseTokens =  generate_VerificationCode_ResponseTokens(token, type); 
            //res.setResult('log', 'create_VerificationCode_Token successfully ran generateResponseTokens()' );
            token.JWT1__c = responseTokens.get('urlToken'); 
            token.JWT2__c = responseTokens.get('verificationCode'); 
            update token;
            
            MethodResponse res3 = TokenController.getToken(token.id);
            if (res3.statusCode >= 400) return res3;
            token = res3.token; //res1 return token as dto
            
            // ---------------------------- send ContractSignatoryInvite email to Contract Designated Signatory ----------------------------
            MethodResponse res4 = send_VerificationCode_Email(token);
            if (res4.statusCode >= 400) return res4; //stop and return the caseResponse with error message
            //res.setResult('log', 'send_VerificationCode_Email successfully ran send_PermissionRequired_Email()' );
            res.results.putAll(res4.results); //append results in res3 to res.
            
            res.setStatus(200);
            res.token = token; //return with a token
            return res;
            
        } catch (Exception e) {
            res.setStatus(400);
            res.setResult('error', e.getStackTraceString());
            //res.setResult('log', 'UserSetupController.SendVerificationCode_actions exception' );
            return res;
        }
    }
    
    Public Static Map<String, String> generate_VerificationCode_ResponseTokens(Token__c token, String type){
        Boolean isEncrypted = true;
        Map<String, String> claimsMap = new Map<String, String>();
        claimsMap.put('tokenId', token.Id);
        String urlToken = JWTController.issueJWT(type, claimsMap, isEncrypted);
        
        //String verificationCode = String.valueOf(Math.abs(Crypto.getRandomInteger())).left(5);
        String verificationCode = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        
        Map<String, String> result = new Map<String, String>();
        result.put('urlToken', urlToken);
        result.put('verificationCode', verificationCode);
        return result;
    }
    
    Public Static MethodResponse create_VerificationCode_Token(String type, Token__c parentToken){
        //Public Static MethodResponse create_VerificationCode_Token(Contact contact, String type, Token__c parentToken){
        MethodResponse res = new MethodResponse();
        
        try {
            Token__c token = new Token__c(
                RecordId__c = parentToken.RecordId__c, // String.valueOf(contact.Id),
                Account__c = parentToken.Account__c, //contact.AccountId,
                Requester__c = null,
                Approver__c = parentToken.Approver__c, //contact.Id,
                Type__c = type,
                Status__c = 'Invited',
                IsClosed__c = false,
                Parent__c = parentToken.Id,
                UserOrigin__c = parentToken.UserOrigin__c
            );
            insert token;
            
            //return response
            res.setStatus(201);
            res.setResult('success', 'Created Verification Code Token : ' + token.Id);  
            res.token = token; //return dto
            return res;
        } catch (Exception e) {
            res.setStatus(400);
            res.setResult('error', e.getMessage());
            res.setResult('log', 'ContractController.create_VerificationCode_Token exception' );
            return res;
        }
    }
    
    public static MethodResponse send_VerificationCode_Email (Token__c token){
        MethodResponse res = new MethodResponse();
        try{
            
            //toAddresses
            List<String> toAddresses = new List<String>();
            if(token.Approver__c != null && String.isNotBlank(token.Approver__r.Email)) toAddresses.add(token.Approver__r.Email); //add designated contact's email to address
            
            //ccAddresses - no cc required, but leave it as empty list
            List<String> ccAddresses = new List<String>();
            
            //get Email Template Name based on MetaData - Email Template Mapping
            //String masterLabel = ('mou designated signatory invitation').toLowerCase();
            String masterLabel = 'email verification code';
            MethodResponse res2 = EmailController.getEmailTemplateByMasterLabel(masterLabel);
            if(res2.statusCode >= 400) return res2;
            EmailTemplate emailTemplate = res2.emailTemplate; //dto in res
            OrgWideEmailAddress orgWideEmailAddress = res2.orgWideEmailAddress; //dto in res
            
            String verificationCode = token.JWT2__c;
            //String verificationCode = JSON.serialize(token);
            
            
            
            
            String htmlBody = emailTemplate.HtmlValue;
            htmlBody = htmlBody.replace('[Verification code]', verificationCode); 
            htmlBody = htmlBody.replace('{!Contact.FirstName}', token.Approver__r.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            //htmlBody = htmlBody.replace('[schoolName]', token.Account__r.Name); //relate to case's school name
            
            String plainBody = emailTemplate.Body;
            plainBody = plainBody.replace('[Verification code]', verificationCode); 
            plainBody = plainBody.replace('{!Contact.FirstName}', token.Approver__r.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            //plainBody = plainBody.replace('[schoolName]', token.Account__r.Name); //relate to case's school name
            
            EmailController.sendEmail2(token.Approver__c, token.Account__c, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, orgWideEmailAddress);    
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
    //------------------------- verification code ------------------------------------------------------------------
    
    //------------------------- set password token ------------------------------------------------------------------
    public static MethodResponse setPasswordToken_actions(Id contactId, Id parentTokenId, String userOrigin){
        MethodResponse res = new MethodResponse();
        String type = 'User Set Password';
        try {
            Contact contact = ContactController.getContact(contactId);
            
            // ---------------------------- create VerificationCode Token ----------------------------
            MethodResponse res1 = Test.isRunningTest()? testRes : create_SetPassword_Token(contact, type, parentTokenId, userOrigin);
            if (res1.statusCode >= 400) return res1; //stop and return the caseResponse with error message
            res.setResult('log', 'create_SetPassword_Token created token. Next step: Token__c token = res1.token' );
            Token__c token = res1.token;
            res.setResult('log', 'create_SetPassword_Token assigned token' );
            res.results.putAll(res1.results); //append results in res2 to res.
            
            // ---------------------------- generate encrypted JWT ----------------------------
            Map<String, String> responseTokens =  generate_SetPassword_ResponseTokens(token, type); 
            res.setResult('log', 'create_SetPassword_Token successfully ran generateResponseTokens()' );
            token.JWT1__c = responseTokens.get('urlToken'); 
            update token;
            
            MethodResponse res3 = TokenController.getToken(token.id);
            if (res3.statusCode >= 400) return res3;
            token = res3.token; //res1 return token as dto
            
            res.setStatus(200);
            res.token = token; //return with a token
            return res;
            
        } catch (Exception e) {
            res.setStatus(400);
            res.setResult('error', e.getStackTraceString());
            res.setResult('log', 'UserSetupController.SendVerificationCode_actions exception' );
            return res;
        }
    }
    
    Public Static Map<String, String> generate_SetPassword_ResponseTokens(Token__c token, String type){
        Boolean isEncrypted = true;
        Map<String, String> claimsMap = new Map<String, String>();
        claimsMap.put('tokenId', token.Id);
        String urlToken = JWTController.issueJWT(type, claimsMap, isEncrypted);
        
        Map<String, String> result = new Map<String, String>();
        result.put('urlToken', urlToken);
        
        return result;
    }
    
    Public Static MethodResponse create_SetPassword_Token(Contact contact, String type, Id parentTokenId, String userOrigin){
        MethodResponse res = new MethodResponse();
        
        try {
            Token__c token = new Token__c(
                RecordId__c = String.valueOf(contact.Id),
                Account__c = contact.AccountId,
                Requester__c = null,
                Approver__c = contact.Id,
                Type__c = type,
                Status__c = 'Invited',
                IsClosed__c = false,
                Parent__c = parentTokenId,
                UserOrigin__c = userOrigin
            );
            insert token;
            
            //return response
            res.setStatus(201);
            res.setResult('success', 'Created Set Password Token : ' + token.Id);  
            res.token = token; //return dto
            return res;
        } catch (Exception e) {
            res.setStatus(400);
            res.setResult('error', e.getMessage());
            res.setResult('log', 'ContractController.create_SetPassword_Token exception' );
            return res;
        }
    }
    
    
    //------------------------- set password token ------------------------------------------------------------------
    
    //------------------------- confirmation ------------------------------------------------------------------
    
    public static MethodResponse send_SchoolContactConfirmed_Email (Token__c token){
        MethodResponse res = new MethodResponse();
        try{
            
            //toAddresses
            List<String> toAddresses = new List<String>();
            if(token.Approver__c != null && String.isNotBlank(token.Approver__r.Email)) toAddresses.add(token.Approver__r.Email); //add designated contact's email to address
            
            //ccAddresses - no cc required, but leave it as empty list
            List<String> ccAddresses = new List<String>();
            
            //get Email Template Name based on MetaData - Email Template Mapping
            //String masterLabel = ('mou designated signatory invitation').toLowerCase();
            String masterLabel = 'school confirmed contacts are correct';
            MethodResponse res2 = Test.isRunningTest()? testRes : EmailController.getEmailTemplateByMasterLabel(masterLabel);
            if(res2.statusCode >= 400) return res2;
            EmailTemplate emailTemplate = res2.emailTemplate; //dto in res
            OrgWideEmailAddress orgWideEmailAddress = res2.orgWideEmailAddress; //dto in res
            
            String hyperlink = Helper.supportHubURL() + 'manage-contacts?recId=' + token.Account__c;
            String htmlBody = emailTemplate.HtmlValue;
            htmlBody = htmlBody.replace('{!Contact.FirstName}', token.Approver__r.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            htmlBody = htmlBody.replace('[hyperlink]', hyperlink);
            String plainBody = emailTemplate.Body;
            plainBody = plainBody.replace('{!Contact.FirstName}', token.Approver__r.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            plainBody = plainBody.replace('[hyperlink]', hyperlink);
            
            EmailController.sendEmail2(token.Approver__c, token.Account__c, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, orgWideEmailAddress);    
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
    
    
    //------------------------- confirmation ------------------------------------------------------------------
    
    //N4L Invitation - Default --------------------------------------------------------------------------------
    @AuraEnabled() //using cacheable=true will cause error LIMIT_USAGE_FOR_NS   Number of DML statements: 1 out of 0 ******* CLOSE TO LIMIT
    public static List<Map<String, String>> InviteToCreateCustomerUser(id contactId, boolean approvedUnmatchEmailDomain) {
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
        
        MethodResponse res1 = InviteToCreateUser_email_actions(contact);
        
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
    public static MethodResponse InviteToCreateUser_email_actions(Contact contact){
        MethodResponse res = new MethodResponse();
        try{
            String type='Invite-SignUp';
            
            //create Token
            MethodResponse res1= createToken(contact, type);
            if (res1.statusCode >= 400) return res1; //stop and return with error message
            Token__c token = res1.token;
            res.results.putAll(res1.results); //append results in res1 to res.
            
            // ------------------------ generate encrypted JWT ----------------------------
            Map<String, String> responseTokens = generateResponseTokens(token, type);
            token.JWT1__c = responseTokens.get('respondToken'); 
            update token; //save JWT1 and 2
            token  = [SELECT id, Account__c, Type__c, Approver__c, IsClosed__c, JWT1__c, JWT2__c FROM Token__c WHERE id =: token.id LIMIT 1];
            
            // ---------------------------- send email to principal ----------------------------
            MethodResponse res2 = send_InviteToCreateUser_Email(contact, token);
            if (res2.statusCode >= 400) return res2; //stop and return the caseResponse with error message
            res.results.putAll(res2.results); //append results in res3 to res.
            
            res.setStatus(200);
            return res;
            
        }catch (Exception e) {
            res.setStatus(400);
            res.setResult('error', e.getMessage());
            return res;
        }
    }
    
    public static MethodResponse createToken(Contact contact, String type){
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
                UserOrigin__c = 'N4L Invitation - Default'
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
            
            //get Email Template Name based on MetaData - Email Template Mapping
            String masterLabel = ('n4l invitation default to create user').toLowerCase();
            MethodResponse res2 = Test.isRunningTest()? testRes : EmailController.getEmailTemplateByMasterLabel(masterLabel);
            if(res2.statusCode >= 400) return res2;
            EmailTemplate emailTemplate = res2.emailTemplate; //dto in res
            OrgWideEmailAddress orgWideEmailAddress = res2.orgWideEmailAddress; //dto in res
            
            String partialURL = Helper.supportHubURL();
            String hyperlink = partialURL + 'request-authorisation?p=invite-signup&t=' + token.JWT1__c;
            
            //Email Template
            String htmlBody = emailTemplate.HtmlValue;   
            system.debug('htmlbody:'+htmlBody);
            String plainBody = emailTemplate.Body;
            system.debug('plainBody:'+plainBody);
            htmlBody = htmlBody.replace('{!Contact.FirstName}', Helper.getStringValue(contact.FirstName)); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work             
            htmlBody = htmlBody.replace('[hyperlink]', Helper.getStringValue(hyperlink)); 
            
            plainBody = plainBody.replace('{!Contact.FirstName}', Helper.getStringValue(contact.FirstName)); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            plainBody = plainBody.replace('[hyperlink]', Helper.getStringValue(hyperlink)); 
            
            EmailController.sendEmail2(token.Approver__c, token.Account__c, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, orgWideEmailAddress);    
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
        
        MethodResponse res1 = Test.isRunningTest()? testRes : TokenController.getToken(tokenId);
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
            system.debug('user list is empty');
            MethodResponse res3 = SendVerificationCode_actions(token); //passing token as parentToken for verificationToken
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
}