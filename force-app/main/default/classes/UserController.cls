public class UserController {
	@InvocableMethod(label='Update User FederationsID' description='using @future method to update FederationID and Fortinet ADOM when a user is created.')
    public static void updateUsers(List<ID> ids) {
        String userId = ids[0];
		updateUserSAMLfields(userId);
    }

    @future
    public static void updateUserSAMLfields(string userId){
        User user = [SELECT id, username, FederationIdentifier, User.Fortinet_Adom_Name__c, AccountId FROM User WHERE id =: userId LIMIT 1];
         //Error Account.Fortinet_Adom_Name__c FROM ^ ERROR at Row:1:Column:90 Didn't understand relationship 'Account' in field path.
        
        
        String federationId = user.username;
        //check if the federationId already exist
        List<User> users = [SELECT id, FederationIdentifier FROM User WHERE FederationIdentifier =: federationId];
        If (users.isEmpty()){
            user.FederationIdentifier = federationId;
            
            List<Account> accounts = [SELECT id, Fortinet_Adom_Name__c FROM Account WHERE id =: user.AccountId LIMIT 1 ];
            If(!accounts.isEmpty()){
                Account account = accounts[0];
            	user.Fortinet_Adom_Name__c = account.Fortinet_Adom_Name__c;
            }
            
            update user;
        } //else do nothing
    }
    
    public static MethodResponse getCustomerUser(string userId){
    MethodResponse res = new MethodResponse();
    //get User
        List<User> users = [SELECT id, FirstName, LastName, Name, username, email, Phone, MobilePhone, LastLoginDate, IsActive, IsPortalEnabled, UserPermissionsFilteringPortalUser__c, UserPermissionsSchoolReportingUser__c, ContactId, Contact.AccountId, Contact.Account.Type, UserType, ProfileId, Profile.Name, Contact.Account.Pond_Registration_Approval_Email_Address__c, School_Principal_Email__c, Send_Email_School_Principal__c  FROM User WHERE id =: userid];
        //validate input - userId and error handling
        if(users.isEmpty()){
            if (String.isNotBlank(userId)){
                res.setStatus(404);
                res.setResult('error', 'Could not find a User record with id = "' + userId + '"');   
            } else {
                res.setStatus(400);
                res.setResult('error', 'Missing userId');    
            }
            return res;
        }
        User user = users[0];//default to the first user in list 
    
        res.setStatus(200);
        res.setResult('success', 'Found user'); 
        res.user = user;
        return res;
   }
   


    @AuraEnabled() //using cacheable=true will cause error LIMIT_USAGE_FOR_NS   Number of DML statements: 1 out of 0 ******* CLOSE TO LIMIT
    public static List<Map<String, String>> createCustomerUser(id contactId, boolean approvedUnmatchEmailDomain) {
        List<Map<String, String>> result = New List<Map<String, String>>();
        MethodResponse res = new MethodResponse();
        Map<String, String> resMap = New Map<String, String>(); //for adding into list result

        List<Contact> contacts =  [SELECT Id, FirstName, LastName, Name, Title, Phone, MobilePhone, Email, Picture__c, Business_Role__c, Current_Principal_Of_This_School__c, AccountId, Account.Name FROM Contact WHERE Id =: contactId];
		
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

        // Otherwise, we can start generating a new user
        Profile profileObj = [SELECT id, Name FROM Profile WHERE Name = 'Support Hub Community Member User - Login Licence MFA'];
        User newUser = new User(
            profileId = profileObj.id,
            FirstName = contact.FirstName, 
            LastName = contact.LastName, 
            Username = contact.Email, 
            Email = contact.Email, 
            MobilePhone = contact.MobilePhone, 
            Phone = contact.phone,
            EmailEncodingKey = 'UTF-8',
            localesidkey = 'en_US',
            languagelocalekey = 'en_US',
            timezonesidkey = 'Pacific/Auckland',
            alias = contact.firstName.left(1) + contact.lastName.left(5),
            CompanyName = contact.Account.Name,
            ContactId = contact.Id,
            Title = contact.Title,
            approved_Email_With_Unmatch_Email_Domain__c = approvedUnmatchEmailDomain
        );

        // Make the Nickname Unique
        Integer randomNumber = Integer.valueof((Math.random() * 10000)); //4 digit random number
        String nickname = contact.firstName.toLowerCase() + '.' + contact.lastname.toLowerCase();
        newUser.CommunityNickname = nickname.left(36) + String.valueOf(randomNumber); //user.CommunityNickname allows maximum 40 characters
       

        
        try {

            insert newUser;

            // system.debug('>>>>> object serializePretty newUser = ' + JSON.serializePretty(newUser));
            // system.debug('>>>>> object serializePretty ends -------------------------- = ');
            // String userId = Site.createExternalUser(newUser, contact.AccountId); //create user
            // system.debug('>>>>> string userid = ' + userId);
            // if (String.isBlank(userId) && !Test.isRunningTest()){ //https://salesforce.stackexchange.com/questions/96859/site-createportaluser-returning-null-in-test-context
            // //https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_sites.htm
            //     res.setStatus(400);
            //     res.setResult('error', 'failed to create user in Site.createExternalUser()');
            //     res.setResult('log', 'Site.createExternalUser Exception' );
                
            //     resMap.put('response', res.getJSONstring());
            //     result.add(resMap);
            //     return result;
            // }
            // if (String.isNotBlank(userId)) {
            //     SupportHubSignupController.triggerEmailForNewUser(userId, true); //reuse existing method in SupportHubSignupController to send email to user
            // }
            result =  ContactController.getContact_WithUser(contact.Id); //return the same JSON structure as getContract() above
            

        } catch (System.Exception ex) {
			res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'UserController.createUser Exception' );
            
            resMap.put('response', res.getJSONstring());
            result.add(resMap);
            
		}

        system.debug(JSON.serializePretty(result));
        return result;

    }

    @AuraEnabled()
    public static Map<String,String> updateUser_SchoolReporting_fields(string userId, Boolean isSchoolReportingUser){
        Map<String,String> result = New Map<String,String>();
        MethodResponse res = new MethodResponse();

        List<User> users = [SELECT id, username, UserPermissionsSchoolReportingUser__c FROM User WHERE Id =: userId LIMIT 1];
        //error
        if(users.isEmpty()){
            if (String.isNotBlank(userId)){
                res.setStatus(404);
                res.setResult('error', 'Could not find a user record with id = ' + userId);   
            } else {
                res.setStatus(400);
                res.setResult('error', 'Missing userId');    
            }
            result.put('response', res.getJSONstring());
            return result;
        }

        try {
            User user = users[0] ;
            user.UserPermissionsSchoolReportingUser__c	= isSchoolReportingUser;
            update user;
            
            //successful
            res.setStatus(200);
            result.put('response', res.getJSONstring());

        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'UserController.updateUser_SchoolReporting_fields Exception' );
            
            result.put('response', res.getJSONstring());
            
        }
        return result;
    }

    @AuraEnabled()
    public static Map<String,String> updateUser_FilteringPortal_fields(string userId, Boolean isFilteringPortalUser){
        Map<String,String> result = New Map<String,String>();
        MethodResponse res = new MethodResponse();

        List<User> users = [SELECT id, username, FederationIdentifier, FortiPortal_User_Role__c, FortiPortal_Customer_Name__c, Fortinet_Adom_Name__c, UserPermissionsFilteringPortalUser__c
                            , ContactId, Contact.Account.Fortinet_Adom_Name__c, Contact.Account.Name  FROM User WHERE Id =: userId LIMIT 1];
        //error
        if(users.isEmpty()){
            if (String.isNotBlank(userId)){
                res.setStatus(404);
                res.setResult('error', 'Could not find a user record with id = ' + userId);   
            } else {
                res.setStatus(400);
                res.setResult('error', 'Missing userId');    
            }
            result.put('response', res.getJSONstring());
            return result;
        }

        try {
            User user = users[0] ;

            //Ben Soh @ 18/06/2020 : some part the code was copied from original process builder's @future method in ContactController.updateUser_FortiPortal_fields (which can be replaced by this block of code called from LWC)
            user.FederationIdentifier = user.username;
            user.Fortinet_Adom_Name__c = user.Contact.Account.Fortinet_Adom_Name__c;
            user.FortiPortal_User_Role__c = 'Advanced';//before this custom field was created, existing 18,296 contact records will have null FortiPortal_User_Role__c. Therefore, default the value in user.FortiPortal_User_Role__c to be 'Advanced'

            user.UserPermissionsFilteringPortalUser__c	= isFilteringPortalUser;
            user.FortiPortal_Customer_Name__c = (isFilteringPortalUser ? ContactController.getFortiPortalCustomerName(user.Contact.Account.Name) : '');
            
            update user;
            
            //successful
            res.setStatus(200);
            result.put('response', res.getJSONstring());

        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'UserController.updateUser_FilteringPortal_fields Exception' );
            
            result.put('response', res.getJSONstring());
            
        }
        return result;
    }

    @AuraEnabled()
    public static Map<String,String> updateUser_NMS_fields(string userId, Boolean isNMSUser){
        Map<String,String> result = New Map<String,String>();
        MethodResponse res = new MethodResponse();

        List<User> users = [SELECT id, username, UserPermissionsNMSUser__c FROM User WHERE Id =: userId LIMIT 1];
        //error
        if(users.isEmpty()){
            if (String.isNotBlank(userId)){
                res.setStatus(404);
                res.setResult('error', 'Could not find a user record with id = ' + userId);   
            } else {
                res.setStatus(400);
                res.setResult('error', 'Missing userId');    
            }
            result.put('response', res.getJSONstring());
            return result;
        }

        try {
            User user = users[0] ;
            user.UserPermissionsNMSUser__c	= isNMSUser;
            update user;
            
            //successful
            res.setStatus(200);
            result.put('response', res.getJSONstring());

        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'UserController.updateUser_NMS_fields Exception' );
            
            result.put('response', res.getJSONstring());
            
        }
        return result;
    }
}