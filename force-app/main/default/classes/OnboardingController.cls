/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2019-08-30
* @description Using AuraEnabled method to handle user request for access to various product: Filtering Portal, School Reporting and etc 
*
* CHANGE LOG
**/
public without sharing class OnboardingController {
    public OnboardingController() {

    }
    @AuraEnabled() //LWC onboaringFiltering will call this method to send email
    public static string request_access_prerequisite(String productName, ID userId){
        //to prevent customer license user from requesting for access to fortiportal if their email domain does not match school domain.
        MethodResponse res = new MethodResponse();

        //get User
        //List<User> users = [SELECT id, FirstName, LastName, Name, username, email, LastLoginDate, IsActive, IsPortalEnabled, UserPermissionsFilteringPortalUser__c, UserPermissionsSchoolReportingUser__c, ContactId, Contact.Email_Domain_Matched__c, Contact.AccountId, Contact.Account.Type, Contact.Account.RecordType.Name, UserType, ProfileId, Profile.Name, Contact.Account.Pond_Registration_Approval_Email_Address__c  FROM User WHERE id =: userid];
        List<User> users = [SELECT id, IsPortalEnabled, Contact.Email, Contact.Email_Domain_Matched__c, Contact.Account.RecordType.Name, Contact.Account.Email_Domain__c, Contact.Account.Onboarding_Filtering_Portal__c FROM User WHERE id =: userid];
        //validate input - userId and error handling
        if(users.isEmpty()){
            if (String.isNotBlank(userId)){
                res.setStatus(404);
                res.setResult('error', 'Could not find a User record with id = ' + userId);   
            } else {
                res.setStatus(400);
                res.setResult('error', 'Missing userId');    
            }
            return res.getJSONstring();
        }
        User user = users[0];//default to the first user in list 
    	//contactId and accountId comes from the Community License user record from LWC that calls this method.

        if (productName == 'filtering-portal'){
            
            if(!String.isBlank(user.Contact.Account.Onboarding_Filtering_Portal__c)){
                if(user.Contact.Account.Onboarding_Filtering_Portal__c == 'Opt In' || user.Contact.Account.Onboarding_Filtering_Portal__c == 'Activated'){
                    if(user.Contact.Account.RecordType.Name == 'School' && user.IsPortalEnabled && user.contact.Email_Domain_Matched__c){
                        res.setStatus(200);
                        res.setResult('prerequisite', 'allow request access');    
                    } else {
                        res.setStatus(400); //use 400 BAD_REQUEST to be the opposite of 200 above.
                        res.setResult('prerequisite', 'forbid request access');   
                        res.setResult('email', user.Contact.email); 
                        res.setResult('domain', user.Contact.Account.Email_Domain__c); 
                    } 
                }
            } else {
                    res.setStatus(401); //use 401 UNAUTHORIZED: this school has not signed up for filtering portal yet. Do not let them sign up
                    res.setResult('prerequisite', 'forbid request access');    
            }
        } else {
            //TODO: for other products just allow request for now.
            res.setStatus(200);
            res.setResult('prerequisite', 'allow request access');    
        }
        
        return res.getJSONstring();

        //TODO: we could consider white listing schools that do not have domain or limitation to user's email domain
    }

    @AuraEnabled() //LWC onboaringFiltering will call this method to send email
    public static string request_access(String productName, ID userId, String partialURL){
        MethodResponse res = request_access_actions(productName, userId, partialURL );
        //  MethodResponse res = new MethodResponse();
        // if (productName == 'good' || productName == 'filtering-portal'){
        //     res.setStatus(200);
        //     res.setResult('success', 'Test response from Apex');  
        //     res.setResult('productName', productName);  
        //     res.setResult('userId', userId); 
        //     res.setResult('UserInfo_getUserType', UserInfo.getUserType()); 
        // }

        // if (productName == 'bad'){
        //     res.setStatus(400);
        //     res.setResult('error', 'Test error response from Apex');  
        //     res.setResult('productName', productName);  
        //     res.setResult('userId', userId);  
        // }
        
        return res.getJSONstring(); 
    }
    
    
    public static MethodResponse request_access_actions(String productName, ID userId, String partialURL){
        MethodResponse res = new MethodResponse();
    try {
        //mapping URL parameter to Case.Product__c, and Metadata Type
        Map<String, String> productTypes = new Map<String, String>();
        productTypes.put('filtering-portal', 'Filtering Portal');
        productTypes.put('school-reporting', 'School Reporting');

        //validate input - productName and error handling
        String type='';
        if (productTypes.containsKey(productName)){
            type = productTypes.get(productName);   
        } else {
            res.setStatus(400);
            res.setResult('error', 'Invalid Product Name: ' + productName);
            return res;
        }

        //get User
        MethodResponse res1= UserController.getCustomerUser(userid);
        if (res1.statusCode >= 400) return res1; //stop and return with error message
        User user = res1.user;// res1 is used as dto here.
        res.setResult('log', 'OnboardingController.request_access_actions assigned user' );
        res.results.putAll(res1.results); //append results in res1 to res.


        // ---------------------------- create Request Token ----------------------------
        MethodResponse res2 = createOnboardingToken(user, type);
        if (res2.statusCode >= 400) return res2; //stop and return the caseResponse with error message
        res.setResult('log', 'OnboardingController.request_access_actions created token. Next step: Token__c token = res2.token' );
        Token__c token = res2.token;
        res.setResult('log', 'OnboardingController.request_access_actions assigned token' );
        res.results.putAll(res2.results); //append results in res2 to res.


        // ---------------------------- generate encrypted JWT ----------------------------
        Map<String, String> responseTokens =  generateResponseTokens(token, type);
        res.setResult('log', 'OnboardingContooller.request_access_actions successfully ran generateResponseTokens()' );
        token.JWT1__c = responseTokens.get('approvedToken'); 
        token.JWT2__c = responseTokens.get('declinedToken'); 
            
        update token; //save JWT1 and 2
        token  = [SELECT id, Account__c, Account__r.Name, Requester__c, Requester__r.FirstName, Requester__r.Name, Requester__r.Email, Approver__r.FirstName, Approver__r.Name, Approver__r.Email,  Type__c, Status__c, IsClosed__c, ClosedDate__c, JWT1__c, JWT2__c FROM Token__c WHERE id =: token.id LIMIT 1];
        

        // ---------------------------- send email to principal ----------------------------
        MethodResponse res3 = send_PermissionRequired_Email(token, partialURL);
        if (res3.statusCode >= 400) return res3; //stop and return the caseResponse with error message
        res.setResult('log', 'OnboardingContooller.request_access_actions successfully ran send_PermissionRequired_Email()' );
        res.results.putAll(res3.results); //append results in res3 to res.


        // ---------------------------- send email to requester ----------------------------
        MethodResponse res4 = Filtering_Portal_Send_Request_Response_Email(token, 'confirmation');
        if (res4.statusCode >= 400) return res4; //stop and return the caseResponse with error message
        res.setResult('log', 'OnboardingContooller.request_access_actions successfully ran Filtering_Portal_Send_Request_Response_Email(Confirmation)' );
        res.results.putAll(res4.results); //append results in res4 to res.
        

        // ---------------------------- update user ----------------------------
        SupportHubSignupController.triggerEmailForNewUser(user.id, false); //@future method to turn off the scheduled action for sending email to principal due to Support Hub sign up
        

        res.setStatus(200);
        return res;

        } catch (Exception e) {
            res.setStatus(400);
            res.setResult('error', e.getMessage());
            res.setResult('log', 'OnboardingContooller.request_access_actions exception' );
            return res;
        }
    }

    Public Static MethodResponse createOnboardingToken(User user, String type){
        MethodResponse res = new MethodResponse();
        try {
            Map<string, List<Contact>> roleBasedContacts = ContactController.getRoleBaseContacts(User.Contact.AccountId);
            Contact approver =  roleBasedContacts.get('Principal').get(0); //get principal of the school

            Token__c token = new Token__c(
                Account__c = user.Contact.AccountId,
                Requester__c = user.ContactId,
                Approver__c = approver.Id,
                Type__c = type,
                Status__c = 'Awaiting Approval',
                IsClosed__c = false
            );
            insert token;

            //return response
            res.setStatus(201);
            res.setResult('success', 'Created Onboarding Token : ' + token.Id);  
            res.token = token; //return dto
            return res;
        } catch (Exception e) {
            res.setStatus(400);
            res.setResult('error', e.getMessage());
            res.setResult('log', 'OnboardingContooller.createOnboardingToken exception' );
            return res;
        }
    }

    Public Static Map<String, String> generateResponseTokens(Token__c token, String type){
        Boolean isEncrypted = true;
        Map<String, String> claimsMap = new Map<String, String>();
        claimsMap.put('tokenId', token.Id);
        claimsMap.put('response', 'approved');
        String approvedToken = JWTController.issueJWT(type, claimsMap, isEncrypted);

        claimsMap.remove('response');
        claimsMap.put('response', 'declined');
        String declinedToken = JWTController.issueJWT(type, claimsMap, isEncrypted);

        Map<String, String> result = new Map<String, String>();
        result.put('approvedToken', approvedToken);
        result.put('declinedToken', declinedToken);
        return result;
    }

    

    public static MethodResponse send_PermissionRequired_Email(Token__c token,  String partialURL){
        MethodResponse res = new MethodResponse();
        try{
           
            //toAddresses
            List<String> toAddresses = new List<String>();
            if(token.Approver__c != null && String.isNotBlank(token.Approver__r.Email)) toAddresses.add(token.Approver__r.Email); //add designated contact's email to address
            
            //ccAddresses - no cc required, but leave it as empty list
            List<String> ccAddresses = new List<String>();
            
            //get Email Template Name based on MetaData - Email Template Mapping
            String masterLabel = (token.Type__c + ' principal approval').toLowerCase();
            MethodResponse res2 = EmailController.getEmailTemplateByMasterLabel(masterLabel);
            if(res2.statusCode >= 400) return res2;
            EmailTemplate emailTemplate = res2.emailTemplate; //dto in res

           
            // system.debug('1.Approve Token: ' + token.JWT1__c);
            // system.debug('2.Decline Token: ' + token.JWT2__c);
            // system.debug('3. token.Approver__r.FirstName: ' + token.Approver__r.FirstName);
            // system.debug('4. token.Account__r.Name: ' +  token.Account__r.Name);
            // system.debug('5.token.Requester__r.Name: ' + token.Requester__r.Name);

            //String approveHyperlink = 'https://onboarding-n4lportal.cs152.force.com/schoolictsupport/s/request-authorisation?p=filtering-portal&t=' + token.JWT1__c;
            //String declineHyperlink = 'https://onboarding-n4lportal.cs152.force.com/schoolictsupport/s/request-authorisation?p=filtering-portal&t=' + token.JWT2__c;
            String approveHyperlink = partialURL + 'request-authorisation?p=filtering-portal&t=' + token.JWT1__c;
            String declineHyperlink = partialURL + 'request-authorisation?p=filtering-portal&t=' + token.JWT2__c;

            String htmlBody = emailTemplate.HtmlValue;
            htmlBody = htmlBody.replace('[approveHyperlink]', approveHyperlink); 
            htmlBody = htmlBody.replace('[declineHyperlink]', declineHyperlink); 
            htmlBody = htmlBody.replace('[approverFirstName]', token.Approver__r.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            htmlBody = htmlBody.replace('[schoolName]', token.Account__r.Name); //relate to case's school name
            htmlBody = htmlBody.replace('[requesterName]', token.Requester__r.Name); //relate to case's school name
            
            String plainBody = emailTemplate.Body;
            plainBody = plainBody.replace('[approveHyperlink]', approveHyperlink); 
            plainBody = plainBody.replace('[declineHyperlink]', declineHyperlink); 
            plainBody = plainBody.replace('[approverFirstName]', token.Approver__r.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            plainBody = plainBody.replace('[schoolName]', token.Account__r.Name); //relate to case's school name
            plainBody = plainBody.replace('[requesterName]', token.Requester__r.Name); //relate to case's school name
            
            
            EmailController.sendEmail(token.Approver__c, token.Account__c, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody);    
            res.setStatus(200);
            res.setResult('success', 'Sent ' + emailTemplate.Name +' Email to ' + string.join(toAddresses,','));  
            return res;
        
        } catch (System.Exception ex) {
			res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'OnboardingController.send_PermissionRequired_Email Exception' );
            return res;
		}
    }



    
    public static MethodResponse Filtering_Portal_Request_Approved_or_Declined(Map<String, Object> claimsMap){
        MethodResponse res = new MethodResponse();
        try{
            System.debug('>>>> checkpoint 1');
            //for unit testing only: in order to make sure that JWTController.processToken() can call this method.
            if (claimsMap.containsKey('unitTestEscaped')  && Boolean.valueOf(claimsMap.get('unitTestEscaped'))) {
                res.setStatus(200);
                return res;
                //return 'Unit Test Escaped successfully';
            }
            
            System.debug('>>>> checkpoint 2');
            //the rest of the code will be tested in OnboardingControllerTest.cls
            Id tokenId = String.valueOf(claimsMap.get('tokenId')); 
            String response = String.valueOf(claimsMap.get('response'));

            //only allow 'approved' or 'declined' to operate here.
            if(response == 'approved' || response == 'declined'){
                System.debug('>>>> checkpoint 3');
                //get case requestCase: using contact.FirstName, contact.Name, contact.Email, account.Name for email content
                List<Token__c> tokens  = [SELECT id, Account__c, Account__r.Name, Requester__c, Requester__r.FirstName, Requester__r.Name, Requester__r.Email, Approver__r.FirstName, Approver__r.Name, Approver__r.Email,  Type__c, Status__c, IsClosed__c, ClosedDate__c, JWT1__c, JWT2__c FROM Token__c WHERE id =: tokenId LIMIT 1];
                //error handling
                if (tokens.isEmpty()){
                    if (String.isNotBlank(tokenId)){
                        res.setStatus(404);
                        res.setResult('error', 'Could not find a Request Token__c record with id = "' + tokenId + '"');    
                    } else {
                        res.setStatus(400);
                        res.setResult('error', 'Missing Token__c id in token claims');    
                    }
                    return res;
                } 
                Token__c token  = tokens[0]; //default to the first case in list - when a token has included a valid case, it should return only 1 record
                //get contact of this token: get ready for setting FortiPortal_Access: true/false
                Contact contact = [SELECT id, FortiPortal_Access__c FROM Contact WHERE id =: token.Requester__c LIMIT 1];

                System.debug('>>>> checkpoint 4');
                if (response == 'approved'){
                    token.Status__c = 'Approved'; //defined in Support Process: Onboarding ...Status =  New > Waiting Approval > Closed - Approved (Closed) OR Closed - Declined (Closed)
                    System.debug('>>>> checkpoint 5');
                    //update contact - to update user and grant access to Forti Portal.
                    contact.FortiPortal_Access__c = true; //grant access to the user of this contact. Process Builder will update the rest.
                } else if (response == 'declined'){
                    token.Status__c = 'Declined'; //defined in Support Process: Onboarding ...Status =  New > Waiting Approval > Closed - Approved (Closed) OR Closed - Declined (Closed)
                    System.debug('>>>> checkpoint 6');
                    //update contact - to update user and remove access to Forti Portal.
                    contact.FortiPortal_Access__c = false; //grant access to the user of this contact. Process Builder will update the rest.
                }
                token.IsClosed__c = true;
                token.ClosedDate__c = datetime.now(); //token.ClosedDate__c is datetime. Similar to Case.CloseDate
                update token;
                update contact;
                
                res.setStatus(200);
                res.setResult('request_authorisation', response);
                res.setResult('request_token_Status', token.Status__c);
                System.debug('>>>> checkpoint 7');

                

                MethodResponse resEmail = Filtering_Portal_Send_Request_Response_Email(token, response);
                //if error occurs, overwrite res with the response in resEmail
                if (resEmail.statusCode >= 400){
                    res = resEmail;
                }
                
            } else {
                res.setStatus(400);
                res.setResult('error', 'Request Authorisation requires token.claims to consist "approved" or "declined"');
            }

            System.debug('>>>> checkpoint 8');
            return res; 

            
            
        } catch (System.Exception ex) {
            System.debug('>>>> checkpoint 9');
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'OnboardingContooller.Filtering_Portal_Request_Approved_or_Declined Exception' );
            return res;
		}
    }

     public static MethodResponse Filtering_Portal_Send_Request_Response_Email(Token__c token, String response){
         MethodResponse res = new MethodResponse();
         //making this method reusable for 3 email templates for Filtering Portal - request: approved, declined and confirmation

         try{
            //toAddresses
            List<String> toAddresses = new List<String>();
            if(token.Requester__c != null && String.isNotBlank(token.Requester__r.Email)) toAddresses.add(token.Requester__r.Email); //add designated contact's email to address
            
            //ccAddresses - no cc required, but leave it as empty list
            List<String> ccAddresses = new List<String>();
            
            //get Email Template Name based on MetaData - Email Template Mapping
            String masterLabel = (token.Type__c + ' request ' + response).toLowerCase();//response can be: approved, declined and confirmation
            MethodResponse res2 = EmailController.getEmailTemplateByMasterLabel(masterLabel);
            if(res2.statusCode >= 400) return res2;
            EmailTemplate emailTemplate = res2.emailTemplate; //dto in res

            
            String htmlBody = emailTemplate.HtmlValue;
            htmlBody = htmlBody.replace('[requesterFirstName]', token.Requester__r.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            htmlBody = htmlBody.replace('[schoolName]', token.Account__r.Name); //relate to case's school name
            
            
            String plainBody = emailTemplate.Body;
            plainBody = plainBody.replace('[requesterFirstName]', token.Requester__r.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            plainBody = plainBody.replace('[schoolName]', token.Account__r.Name); //relate to case's school name
            
            if(response == 'confirmation' && token.Approver__c != null){
                //additional information on confirmation email
                htmlBody = htmlBody.replace('[principalFullName]', token.Approver__r.Name); //principal's firstname and lastname
                htmlBody = htmlBody.replace('[principalEmail]', token.Approver__r.Email); //Principal's email

                plainBody = plainBody.replace('[principalFullName]', token.Approver__r.Name); //principal's firstname and lastname
                plainBody = plainBody.replace('[principalEmail]', token.Approver__r.Email); //Principal's email
            }

            EmailController.sendEmail(token.Requester__c, token.Account__c, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody);    
            res.setStatus(200);
            res.setResult('success', 'Sent ' + emailTemplate.Name +' Email to ' + string.join(toAddresses,','));  
            return res;
        
        } catch (System.Exception ex) {
			res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'OnboardingContooller.Filtering_Portal_Send_Request_Response_Email Exception' );
            return res;
		}
    }

    // public static String FilteringPortal_CustomerName(String Name){
    //     //Filtering Portal has a limit of number of 1095 customer names. But we have 2005
    // }

   

    // @AuraEnabled() //LWC onboaringFiltering will call this method to send email
    // public static string witchHunt(string subject){
    //     system.debug('>>>>>>> Witch Hunt Started');
    //     Case newCase = new Case(
    //             AccountId = '0015P000001pfcYQAQ',
    //             ContactId = '0035P000001Xl0xQAC',
    //             Type = 'Customer Onboarding',
    //             Status = 'Waiting Approval', //'New',
    //             Subject = subject,
    //             Origin = 'Support Hub Submission',
    //             Product_Category__c = 'Support Hub',
    //             Case_Category__c = 'Account Access',
    //             Product__c = 'Filtering Portal',
    //             Call_Driver__c = 'Access Request',
    //             OwnerId =  '0050o00000Vd2SaAAJ', //user = Ben Soh
                
    //             RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Onboarding').getRecordTypeId()
    //         );
    //         insert newCase;
    //     system.debug('>>>>>>> Witch Hunt:  JSON.serializePretty(newCase) :::' + JSON.serializePretty(newCase));

    //     MethodResponse res = new MethodResponse();
        
    //     res.setStatus(200);
    //     res.setResult('success', 'Case created');  
    //     res.setResult('case id', newCase.id);  
    //     res.setResult('case subject', newCase.subject);  
    //     res.setResult('UserInfo_getUserType', UserInfo.getUserType()); 
        
    //     system.debug('>>>>>>> Witch Hunt Ended');
        
    //     return res.getJSONstring();
    // }

}