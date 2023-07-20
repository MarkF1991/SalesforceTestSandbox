/**
* @author Ben Soh 
* @date 2021-02-25
* @description Controller for the SupportHubSetPassword page
*
* CHANGE LOG
**/
public without sharing class SupportHubSetPasswordController {
    //Declare and initialize containers.
    
    // public String password {get; set {password = value == null ? value : value.trim(); } }
    // public String confirmPassword {get; set { confirmPassword = value == null ? value : value.trim(); } }
    public MethodResponse testRes = new MethodResponse();//temp var for test purpose
    public SupportHubSetPasswordController() {

    }

    

    public ErrorFlags errors {
        get {
            if (errors == null) {
                errors = new ErrorFlags();
            }
            return errors;
        }
        set;
    }

    public SetPassword setPassword {
        get {
            if (setPassword == null) {
                setPassword = new SetPassword();
            }
            return setPassword;
        }
        set;
    }

    public Registration registration {
        get {
            if (registration == null) {
                registration = new Registration();
            }
            return registration;
        }
        set;
    }

    public void initializeVariables() {
        setPassword = null;
        errors = null;
    }

    public class SetPassword {

        public String password {get;set;}
        public String confirmPassword {get;set;}
        public Boolean acceptTerms {get;set;}
    }

    public class Registration {
        public String password {get;set;}
        public String confirmPassword {get;set;}
        public Boolean acceptTerms {get;set;}
    }
    
   
    public class ErrorFlags {

        public String userSetupErrors {get;set;}
        public Boolean userSetupHasError {get;set;}

        public String passwordErrors {get;set;}
        public Boolean termsNotAccepted {get;set;}
    }

   

    // public PageReference submit2() {
    //     ApexPages.PageReference pageRef = ApexPages.currentPage();
    //     errors = null;
    //     String startURL = System.currentPageReference().getParameters().get('startURL');
    //     String decision = 'stay with startURL from url param';
    //     if(startURL == null){
    //         decision = 'go get startURL from metadata';
    //     }
    //     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'decision = ' + decision + '   startUrl = ' + startURL + '   isnull = ' + (startURL == null)));
    //     return null;
    // }

    




    public PageReference submit() {
        ApexPages.PageReference pageRef = ApexPages.currentPage();
        
        // Clear the errors, we need to re-evaluate them
        // this.errors.userSetupHasError = false;
        // this.errors.userSetupErrors = '';
        errors = null;
        if (!isValidPassword() || !isTermAccepted()) {
            return null;
        } 

        //if(!isTermAccepted()){
           // return null;
       // }

        
        try{

            String urlToken = System.currentPageReference().getParameters().get('t');
            String startUrl = System.currentPageReference().getParameters().get('startURL');
            MethodResponse res1 = Test.isRunningTest()? testRes : SupportHubUserSetupController.getTokenRecord(urlToken, 'User Set Password');
            if(res1.statuscode == 200){
                
                //a token record is returned from the res above
                Token__c token = res1.token;

                if(token.IsClosed__c){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Sorry, the session has already ended.'));
                    return null;
                }
                
                Id contactId = token.Approver__c;
                String password = this.registration.password;
                Boolean sendEmailConfirmation = false;

                //create user
                MethodResponse res2 = this.create_N4L_user(contactId, password, sendEmailConfirmation, token.UserOrigin__c);
                
                if(res2.statuscode == 200){
                    token.Status__c = 'Responded'; //only update status, don't close yet.
                    update token;

                    //close all tokens under the parent token
                    MethodResponse res3 = TokenController.closeTokenTree(token.Parent__c);
                    
                    //get username
                    String username = res2.user.Username;

                    //get startURL
                    startURL = GetStartURL(startUrl, token);//token must include UserOrigin__c value
                    
                    //Allows users to log in to the current site with the given username and password, then takes them to the startUrl. If startUrl is not a relative path, it defaults to the site's designated index page.
                    pageRef = Site.login(username, password, startURL);

                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, res2.results.get('error')));
                    return null;
                }
                
                
                
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, res1.results.get('error')));
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'invalid url parameters'));
                return null;
                
            }

            
        } catch (Exception e){
            system.debug('### Error creating user:' + e.getMessage() + '\n\n' + e.getStackTraceString());
            ApexPages.addMessages(e);
        }
        
        return pageRef;
       
    }

    

    public void setError(String errorMessage){
    
        this.errors.passwordErrors = errorMessage;
        ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage);
        ApexPages.addMessage(msg);
    }

    public Boolean isValidPassword(){
        //user input must match
        
        if(this.registration.password != this.registration.confirmPassword){
            this.setError(Label.site.passwords_dont_match);
            return false;
        }

        //password cannot contain 'password'
        if (this.registration.password.containsIgnoreCase('password')){
            this.setError('password cannot contain "password"');
            return false;
        }
        //Minimum password length: 8 character
        //Password complexity requirement: Must include numbers, uppercase and lowercase letters, and special characters
        String passwordRegex = '^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[`~!@#$%^&*()_+\\-={}|\\[\\]:\\";\\\'<>?,./])[A-Za-z\\d`~!@#$%^&*()_+\\-={}|\\[\\]:\\";\\\'<>?,./]{8,}$';
        Pattern PasswordPattern = Pattern.compile(passwordRegex);
        Matcher PasswordMatcher = PasswordPattern.matcher(registration.password);
        if(!PasswordMatcher.matches()){
            this.setError('Password length must be at least 8 characters long, include numbers, uppercase and lowercase letters, and special characters');
            return false;
        }

        return true;
    }

    public Boolean isTermAccepted(){
        errors.termsNotAccepted = !registration.acceptTerms;
        return registration.acceptTerms;
    }


     public MethodResponse create_N4L_user(Id contactId, String password, Boolean sendEmailConfirmation, String userOrigin) {
        MethodResponse result = new MethodResponse();

        List<Contact> contacts =  [SELECT Id, FirstName, LastName, Name, Title, Phone, MobilePhone, Email, Picture__c, Business_Role__c, Current_Principal_Of_This_School__c, AccountId, Account.Name FROM Contact WHERE Id =: contactId];

       //error
        if(contacts.isEmpty()){
            if (String.isNotBlank(contactId)){
                result.setStatus(404);
                result.setResult('error', 'Could not find a Contact record with id = ' + contactId);   
            } else {
                result.setStatus(400);
                result.setResult('error', 'Missing contactId');    
            }
            return result;
        }

        //get contact successful
        Contact contact = contacts[0];
        
        // Validate that an existing user doesn't already exist and raise an error
        //copied from SupportHubSignUpController.submit
        List<User> checkUsers = [SELECT Id FROM User WHERE Username = :contact.Email];
        if (!checkUsers.isEmpty()){
            result.setStatus(400);
            result.setResult('error', 'User already exist with the email address:' + contact.Email );  
            return result;
        } 

        // Otherwise, we can start generating a new user
        Profile profileObj = [SELECT id, Name FROM Profile WHERE Name =: Label.Support_Hub_Signup_user_profile];
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
            Title = contact.Title
        );


        String prefix = 'N4LCustomer.'; 
        String nickname = prefix + Helper.getRandomNumber(40 - prefix.length()); //maximum length = 40 characters; ie: N4LCustomer.3470874501362091830450379767
        
        // Query for existing nicknames until a unique one is found
        List<User> existingUserByNickname;
        do {

            // Query for existing nicknames
            existingUserByNickname = [SELECT CommunityNickname FROM User WHERE CommunityNickname = :nickname];
        
            nickname = prefix + Helper.getRandomNumber(40 - prefix.length()); //maximum length = 40 characters
        }
        while (!existingUserByNickname.isEmpty());
        
        newuser.CommunityNickname = nickname;


        //create user and then let process builder to send email
        try {
            String userId = Site.createExternalUser(newUser, contact.accountId, password, sendEmailConfirmation);
            if (String.isNotBlank(userId)) {
                // Update checkbox to trigger email to principal that a user has been created to access their school details on support hub
                SupportHubSignupController.triggerEmailForNewUser(userId, true);
            }
            result = UserController.getCustomerUser(userId);

        } catch (System.Exception ex) {
			result.setStatus(400);
            result.setResult('error', ex.getMessage());
            return result;
		}
        result.setStatus(200);
        return result;
    }


    public String GetStartURL(String startUrl, Token__c token){
        String result = '';
        if(startUrl != null){
            result = startURL;//example:  url = ...&startUrl=/schoolictsupport/s/manage-contacts
        } else {
            //prepare mappings
            Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap = SupportHubUserNotificationController.getUserCreationMapping('origin');
            
            if(userCreationMap.containsKey(token.UserOrigin__c)){
                //get mapping by user origin
                Support_Hub_User_Creation_Mapping__mdt mapping = userCreationMap.get(token.UserOrigin__c);

                //prepare startURL 
                result = (Helper.isSandbox() ? '/schoolictsupport/' : '/') + (mapping.IsVisualforcePage__c ? '' : 's/') + Helper.getStringValue(mapping.startURL__c);

                //add url parameters
                //TODO: in the future, when we need more enhancement or specify url param on the destinateion page, modify the switch on code here.
                switch on mapping.Key__c.toLowerCase() {
                    when 'schoolcontactsupdatecampaign' {
                        result += '/' + token.Account__c;

                        //ITR-1467
                        Contact contact = [SELECT id, name, UserOrigin__c FROM Contact WHERE Id =: token.Approver__c]; 
                        contact.UserOrigin__c = token.userOrigin__c;
                        update contact;
                    }

                    when 'selfsignup' {
                        //ITR-1467
                        Contact contact = [SELECT id, name, UserOrigin__c FROM Contact WHERE Id =: token.Approver__c]; 
                        contact.UserOrigin__c = token.userOrigin__c;
                        update contact;
                    }

                    when 'n4linvitationdefault' {
                        //ITR-1467
                        Contact contact = [SELECT id, name, UserOrigin__c FROM Contact WHERE Id =: token.Approver__c]; 
                        contact.UserOrigin__c = token.userOrigin__c;
                        update contact;
                    }

                    //ITR-1397 direct to order form after user account create
                    when 'signcontractorderform' {
                        String type = 'MOU';
                        Contract contract = [SELECT Id, Name, AccountId, Account.Name, Account.MoE_School_ID__c, ActivatedDate, Contract_Type__c, CustomerSignedDate, CustomerSignedId, CustomerSigned.Name, 
                        CustomerSigned.FirstName, CustomerSigned.Email, CustomerSignedTitle, MoE_Project_Manager__c, MoE_Project_Manager__r.Name, MoE_Project_Manager__r.Email, MoE_Signatory__c, 
                        MoE_Signatory__r.Name, MoE_Signatory__r.Email, Per_Pupil_Contribution__c, Annual_Contribution__c, Order_Total_Amount__c, Programme__c, Status, StatusCode, 
                        Accepted_N4L_Terms_and_Conditions__c, Accepted_N4LCharges_Terms_and_Conditions__c, Accepted_MoE_Terms_and_Conditions__c, N4L_Signatory_Name__c, N4L_Signatory_Email__c, 
                        MoE_Party_Name__c, MoE_Party_Email__c, School_Principal_Name__c, School_Principal_Email__c, OwnerId, Account.Owner.Name, Account.Owner.MobilePhone, CustomerSignedUser__c, 
                        Product__c, Educount_Rolls__c, Educount_Rolls_as_at__c FROM Contract WHERE id =: token.parent__r.recordId__c];
      
                        User user = [SELECT Id, Username FROM User WHERE Username = :contract.CustomerSigned.Email];
                        contract.OwnerId = user.Id;
                        update contract;

                        //create a new token to handle the orderform
                            Token__c newToken = new Token__c(
                                RecordId__c = String.valueOf(contract.Id),
                                Account__c = contract.AccountId,
                                Requester__c = null,
                                Approver__c = contract.CustomerSignedId, //designated signatory contact id
                                Type__c = type,
                                Status__c = 'Invited',
                                IsClosed__c = false,
                                //ITR1397 - add userorigin
                                UserOrigin__c = 'N4L Invitation - Contract Signatory' 
                            );
                            insert newToken;
                            

                        //MethodResponse res = ContractController.create_ContractSignatoryInvite_Token(contract, 'MOU');
                        //token__c inviteToken = res.token;
                        system.debug('@#!!**#&inviteToken:'+newToken);
                        // ---------------------------- generate encrypted JWT ----------------------------
                        Map<String, String> inviteTokens =  ContractController.generateJWTToken(newToken, type);
     
                        newToken.JWT1__c = inviteTokens.get('inviteToken'); 
                        update newToken; //save JWT1

                        result += '?t=' + newToken.JWT1__c + '&p=mou';

                        //ITR-1467
                        Contact contact = [SELECT id, name, UserOrigin__c FROM Contact WHERE Id =: newToken.Approver__c]; 
                        contact.UserOrigin__c = newToken.userOrigin__c;
                        update contact;

                    }
                    when else {
                        //do nothing
                    }
                }
            }
        }
        return result;
    }

    

    
}