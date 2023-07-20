/**
* @author Ben Edwards (ben@cloudinit.nz)
* @date 2017-10-02
* @description Controller for the SupportHubSignup page
*
* CHANGE LOG
**/
public without sharing class SupportHubSignupController {
    
    //Declare and initialize containers.
    public String selectedSchoolId {get;set;}
    public Boolean noEmailDomain {get;set;}
    public transient String accountsJson {get;set;}
    
    public SupportHubSignupController() {
        
        getAccountsJson();
    }
    
    
    /**
*   @author Ben Edwards (ben@cloudinit.nz)
*   @description Built the JSON string for the available accounts for the search bar
**/
    public void getAccountsJson() {
        
        //accountsJson = JSON.serialize([SELECT Name FROM Account ORDER BY Name]);
        accountsJson = JSON.serialize([SELECT Support_Hub_Searchable_Name__c FROM Account WHERE RecordType.Name = 'School' ORDER BY Support_Hub_Searchable_Name__c]); //n4lconz.atlassian.net/browse/SFT-65
        
    }
    
    /**
*   @author David Catindoy (david@cloudinit.nz)
*   @description Error flags instance
**/
    public ErrorFlags errors {
        get {
            if (errors == null) {
                errors = new ErrorFlags();
            }
            return errors;
        }
        set;
    }
    
    /**
*   @author David Catindoy (david@cloudinit.nz)
*   @description Will store details of the selected school.
**/
    public Account selectedSchool {
        get {
            if (selectedSchool == null){
                selectedSchool = new Account(); 
            }
            return selectedSchool;
        }
        set;
    }
    
    
    /**
*   @author Ben Edwards (ben@cloudinit.nz)
*   @description The instance of the registration details for the user
**/
    public Registration registration {
        get {
            if (registration == null) {
                registration = new Registration();
            }
            return registration;
        }
        set;
    }
    
    /**
*   @author David Catindoy (david@cloudinit.nz)
*   @description Set variables to null.
**/
    public void initializeVariables() {
        selectedSchoolId = null;
        registration = null;
        selectedSchool = null;
        errors = null;
    }
    
    
    /**
*   @author David Catindoy (david@cloudinit.nz)
*   @description Get selected school details
**/
    public void selectSchool() {
        
        noEmailDomain = false;
        
        if (selectedSchoolId != null) {
            
            try {
                
                // Query for the selected school
                selectedSchool = [SELECT Name, Email_Domain__c FROM Account WHERE Id = :selectedSchoolId];
                
                if (String.isBlank(selectedSchool.Email_Domain__c)){
                    noEmailDomain = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Support_Hub_No_Email_Domain_Error));
                }
            }
            catch (Exception ex) {
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Support_Hub_Signup_Error_Selecting_School));
                selectedSchool = null;
            }
        } 
        else {
            selectedSchool = null;
            registration = null;
            errors = null;
        }
    }
    
    
    /**
*   @author David Catindoy (david@cloudinit.nz)
*   @description Process details submitted in the registration page.
*
* CHANGE LOG
*   2021-03-13 Ben Soh commented out the section that creates user in this block of code, 
then added another section below it to implement sign up process improvement - create contact first > verify email > set password > site.login()
**/
    public PageReference submit() {
        
        // Clear the errors, we need to re-evaluate them
        errors = null;
        
        if (!validateUserInput()){
            
            // When Sign Up button is clicked, create contact and user (if contact/user record does not exist yet).
            SavePoint sp = Database.setSavepoint(); //Set save point to be used when rolling back changes if an error is encountered.
            Boolean errorEncountered = false;
            
            try {
                
                // Build the email address
                // Based on the user input and the school domain
                String emailAdd = getEmail();
                
                // Validate that an existing user doesn't already exist
                // And raise an error
                List<User> checkUsers = [SELECT Id FROM User WHERE Username = :emailAdd];
                
                if (!checkUsers.isEmpty()){
                    
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Support_Hub_User_Exist_Error_Message));
                    errorEncountered = true;
                    return null;
                } 
                
                /* commented out by Ben Soh @ 13/03/2021 - improvement on Sign Up process --------------------------------------
// Otherwise, we can start generating a new user
User newUser = newUser(emailAdd);

// Make the Nickname Unique
newUser.CommunityNickname = uniqueNickname();
newUser.CompanyName = selectedSchool.Name;


// Query for any existing contacts with that email address
List<Contact> checkContacts = new List<Contact>([
SELECT 
Id
, Title
FROM 
Contact 
WHERE 
Email = :emailAdd 
AND 
AccountId = :selectedSchool.Id
AND 
Inactive_Contact_Record__c = false
ORDER BY 
CreatedDate
]);

// If there is an existing Contact, we'll match the new user to that
if (!checkContacts.isEmpty()){

// Take the first contact
Contact existingContact = checkContacts.get(0);

// Asisgn the contactId to the user
newUser.ContactId = existingContact.Id;
newUser.Title = existingContact.Title;

// Update the contact with the new details
existingContact.FirstName = registration.firstName.capitalize();
existingContact.LastName = registration.lastName.capitalize();

// Update the mobile phone value if it has a value
if (String.isNotBlank(registration.mobile)) {
existingContact.MobilePhone = registration.mobile;
}

// Uplodate the phone value if it has a value
if (String.isNotBlank(registration.phone)) {
existingContact.Phone = registration.phone;
}

Database.update(existingContact);
}


// Alrighty, time to create the user
String userId = Site.createExternalUser(newUser, selectedSchool.Id); //this is current support hub sign up process.

if (String.isBlank(userId) && !Test.isRunningTest()){ //https://salesforce.stackexchange.com/questions/96859/site-createportaluser-returning-null-in-test-context
errorEncountered = true;
}

if (String.isNotBlank(userId)) {
// Update checkbox to trigger email to user
triggerEmailForNewUser(userId, true);
}
*/ //commented out by Ben Soh @ 13/03/2021 - improvement on Sign Up process -------------------------------------- 
                
                //added by Ben Soh @ 13/03/2021  - improvement on Sign Up process -------------------------------------- 
                //since we have implemented Deloitte's changes to contact management and unique email address rules, we can search for contact by the email
                List<Contact> contacts = [SELECT Id, FirstName, LastName, AccountId, Email, MobilePhone, Phone, UserOrigin__c FROM Contact WHERE Email =: emailAdd ];
                Contact contact;
                if(contacts.isEmpty()){
                    contact = new Contact(
                        FirstName = registration.firstName.capitalize(),
                        LastName = registration.lastName.capitalize(),
                        AccountId = selectedSchool.Id,
                        Email = emailAdd,
                        MobilePhone = registration.mobile,
                        Phone = registration.phone,
                        UserOrigin__c = 'Self-SignUp'
                    );
                    insert contact;

                    //SFB-200
                    Account account = [SELECT id, name, RecordType.name, RecordTypeId FROM Account WHERE id =: contact.AccountId];
                    if(account.RecordType.name == 'School' || account.RecordType.name == 'School Additional Site'){
                        AccountContactRelation accountContactRelation = [SELECT id, Authority__c, roles, ContactId FROM AccountContactRelation WHERE contactId =: contact.id];
                        system.debug('@@!!$$accountContactRelation:'+accountContactRelation);
                        accountContactRelation.roles = 'School Staff';
                        accountContactRelation.Authority__c = n4lAutoCompleteContact.getAuthorityByRoles((String) accountContactRelation.roles);
                        update accountContactRelation;
                    } else if(account.RecordType.name == 'Non-School Organisation'){
                        AccountContactRelation accountContactRelation = [SELECT id, Authority__c, roles, ContactId FROM AccountContactRelation WHERE contactId =: contact.id];
                        system.debug('@@!!$$accountContactRelation:'+accountContactRelation);
                        accountContactRelation.roles = 'ICT Engineer';
                        accountContactRelation.Authority__c = n4lAutoCompleteContact.getAuthorityByRoles((String) accountContactRelation.roles);
                        update accountContactRelation;
                    }
    
                } else {
                    //copy the logic from original code above
                    contact = contacts[0];
                    
                    // Update the contact with the new details
                    contact.FirstName = registration.firstName.capitalize();
                    contact.LastName = registration.lastName.capitalize();
                    
                    // Update the mobile phone value if it has a value
                    if (String.isNotBlank(registration.mobile)) {
                        contact.MobilePhone = registration.mobile;
                    }
                    
                    // Uplodate the phone value if it has a value
                    if (String.isNotBlank(registration.phone)) {
                        contact.Phone = registration.phone;
                    }
                    update(contact);
                }
                
                //create parent token for subsequent tokens: verification code and set passwords in the new sign up flow
                Token__c parentToken = new Token__c(
                    RecordId__c = String.valueOf(contact.Id),
                    Account__c = contact.AccountId,
                    Requester__c = null,
                    Approver__c = contact.Id,
                    Type__c = 'Self-SignUp',
                    Status__c = 'Invited',
                    IsClosed__c = false,
                    UserOrigin__c = 'Self-SignUp'
                );
                insert parentToken;
                
                
                //create verification code token and send email
                MethodResponse res = SupportHubUserSetupController.SendVerificationCode_actions(parentToken);
                if (res.statusCode >= 400) {
                    system.debug('Support Hub Sign Up error: ' + res.getJSONstring());
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error processing your registration. Please try again and contact N4L if the problem persists.'));
                } else {
                    Token__c verificationToken = res.token;
                    
                    String urlToken = verificationToken.JWT1__c;
                    
                    String startURL = System.currentPageReference().getParameters().get('startURL');
                    
                    //navigate to verify email visualforce page for next step, with url parameter
                    String pageRef_url = (Helper.isSandbox() ? '/schoolictsupport/' : '/') + 'supporthubverifyemail?t='  + urlToken + (String.isBlank(startURL) ? '' : '&startUrl=' + startURL);
                    
                    //copied 2 lines from David Catindoy's original code below to pass unit test
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Support_Hub_Signup_Success));
                    initializeVariables();
                    
                    //redirect
                    PageReference pageRef = new PageReference(pageRef_url);
                    pageRef.setRedirect(true);
                    return pageRef;
                }
                //added by Ben Soh @ 13/03/2021  - improvement on Sign Up process -------------------------------------- 
                
                
            } catch (Exception e){
                errorEncountered = true;
                system.debug('### Error creating user:' + e.getMessage() + '\n\n' + e.getStackTraceString());
                
                ApexPages.addMessages(e);
            }
            
            if (errorEncountered) {
                
                Database.rollback(sp);
                
                // If there are no errors entered, enter a generic error
                if (!ApexPages.hasMessages()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error processing your registration. Please try again and contact N4L if the problem persists.'));
                }
            } 
            else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Support_Hub_Signup_Success));
                initializeVariables();
            }
        }
        
        return null;
    }
    
    /**
*   @author David Catindoy (david@cloudinit.nz)
*   @description This method validates user input.
**/
    public Boolean validateUserInput() {
        
        errors.firstNameErrors = String.isBlank(registration.firstName) ? Label.Support_Hub_Signup_First_Name_Error : null;
        errors.lastNameErrors = String.isBlank(registration.lastName) ? Label.Support_Hub_Signup_Last_Name_Error : null;
        errors.emailErrors = String.isBlank(registration.email) ? Label.Support_Hub_Signup_No_Email_Error : null;
        //errors.termsNotAccepted = !registration.acceptTerms;
        
        // Validate that one of the phone fields has been filled out
        if (String.isBlank(registration.mobile) && String.isBlank(registration.phone)) {
            errors.phoneErrors = Label.Signup_Hub_Signup_Phone_Error;
            errors.mobileHasError = true;
            errors.phoneHasError = true;
        }
        
        // If the user has entered their email, raise an error
        // We only want the username of their email
        if (registration.email != null && registration.email.contains('@')) {
            errors.emailErrors = Label.Support_Hub_Invalid_Email_Address;
        }
        
        // Validate the phone
        if (String.isNotBlank(registration.mobile)) {
            // If the mobile isn't in correct format, raise an error
            if (!Pattern.matches('[0]\\d\\d?\\d?\\d?\\s\\d\\d\\d\\s\\d+', registration.mobile)) {
                // Apply the error
                errors.phoneErrors = Label.Support_Hub_Signup_Mobile_Format_Error;
                errors.mobileHasError = true;
            }
        }
        
        // Validate the phone
        if (String.isNotBlank(registration.phone)) {
            // If the mobile isn't in correct format, raise an error
            if (!Pattern.matches('[0]\\d\\d?\\d?\\s\\d\\d\\d\\s\\d+', registration.phone)) {
                
                if (errors.phoneErrors != null) {
                    errors.phoneErrors += '<br/>' + Label.Support_Hub_Signup_Phone_Format_Error;
                }
                else {
                    errors.phoneErrors = Label.Support_Hub_Signup_Phone_Format_Error;
                }
                errors.phoneHasError = true;
            }
        }
        
        return 
            String.isNotBlank(errors.firstNameErrors) || 
            String.isNotBlank(errors.lastNameErrors) || 
            String.isNotBlank(errors.emailErrors) || 
            String.isNotBlank(errors.phoneErrors); //|| 
        //errors.termsNotAccepted;
    }
    
    /**
*   @author Ben Edwards (ben@cloudinit.nz)
*   @description Generate the email address from the user's input and the school domain
**/
    public String getEmail () {
        
        return registration.email + '@' + selectedSchool.Email_Domain__c;
    }
    
    /**
*   @author Ben Edwards (ben@cloudinit.nz)
*   @description Generate the new user from the registration details
*   @changes: Ben Soh added EmailEncodingKey = 'UTF-8' for Email Template to show Latin characters in Maori words like: Tēnā koe and Ngā mihi
*             ref: https://en.wikipedia.org/wiki/UTF-8 and https://www.key-shortcut.com/en/writing-systems/abc-latin-alphabet
**/
    public User newUser (String email) {
        
        return new User(
            FirstName = registration.firstName.capitalize(), 
            LastName = registration.lastName.capitalize(), 
            Username = email, 
            Email = email, 
            MobilePhone = registration.mobile, 
            Phone = registration.phone,
            EmailEncodingKey = 'UTF-8'
        );
    }
    
    /**
*   @author Ben Edwards (ben@cloudinit.nz)
*   @description Make sure the Nickname is unique
**/
    public String uniqueNickname () {
        
        /* commented out by Ben Soh to fix duplicated nickname issue on support hub 10/06/2020
// Default to the username for the community
String nickname = registration.firstName.toLowerCase() + '.' + registration.lastname.toLowerCase();
nickname = nickname.left(40);

// Query for existing nicknames until a unique one is found
List<User> existingUserByNickname;

do {

// Query for existing nicknames
existingUserByNickname = [SELECT CommunityNickname FROM User WHERE CommunityNickname = :nickname];

// Suffic 1 on the end
nickname += '1';
}
while (!existingUserByNickname.isEmpty());
//----------------------------------------------------------------------------------------------------------*/
        
        //replaced with the following by Ben Soh 12/06/2020
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
        //----------------------------------------------------------------------------------------------------------*/
        
        return nickname;
    }
    
    /**
*   @author Ben Edwards (ben@cloudinit.nz)
*   @description Trigger update of the checkbox on user to send email
*                This executes in a future method to restrict editing of setup and non-setup objects in the same transactions
**/
    @future
    public static void triggerEmailForNewUser (Id userId, Boolean isTriggerOn) {
        //update new User(Id = userId, Send_Email_School_Principal__c = true);
        
        system.debug('>>>> triggerEmailForNewUser hit!');
        User user  = new User(Id = userId, Send_Email_School_Principal__c = isTriggerOn);
        update user;
        system.debug('>>>> updated user Send_Email_School_Principal__c = ' + user.Send_Email_School_Principal__c);
    }
    
    /**
*   @author Ben Soh (ben.soh@n4l.co.nz)
*   @Date: 20/9/2019
*   @description existing VF email template has limitation: During Support Hub sign up, running as Guest User, it cannot access {!recipient.FirstName} 
*                Therefore, using @InvocableMethod for Scheduled Action in Process Builder to send email to principal, only when the recently signed up user, did not request access to Filtering Portal
**/
    //!!!Only one method in a class can have the InvocableMethod annotation.
    //Only one parameter is supported on methods with @Invocable annotation: cannot use (List<ID> ids, String method){}
    //reference https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm
    @InvocableMethod(label='Support Hub Sign Up Principal Notification' description='Scheduled actions to send email to principal')
    public static void SupportHubSignUp_PrincipalNotification(List<ID> ids) { 
        
        String userId = ids[0]; //default to first element
        MethodResponse res = send_SupportHubSignUp_PrincipalNotification_Email(userId);        
        
        if(res.statusCode >= 400){
            System.debug( 'Error in SupportHubSignupController.SupportHubSignUpUser(): ' + JSON.serializePretty(res) );
        }
        
    }
    
    public static MethodResponse send_SupportHubSignUp_PrincipalNotification_Email(String userId){
        MethodResponse res = new MethodResponse();
       // try{
            //get User
            MethodResponse res1= UserController.getCustomerUser(userId);
            if (res1.statusCode >= 400) return res1; //stop and return with error message
            User user = res1.user;// res1 is used as dto here.
            res.setResult('log', 'SupportHubSignupController.send_SupportHubSignUp_PrincipalNotification_Email() assigned user' );
            res.results.putAll(res1.results); 
            
            system.debug('>>> 2 user.Send_Email_School_Principal__c' + user.Send_Email_School_Principal__c);
            try{
            if (user.Send_Email_School_Principal__c){//to make sure we do not accidentally send email to principal when this is not checked.
                //get principal
                Map<string, List<Contact>> roleBasedContacts = ContactController.getRoleBaseContacts(user.Contact.AccountId);
                Contact approver =  roleBasedContacts.get('Principal').get(0); //get principal of the school
                
                if(approver.Email == user.Email){
                    res.setStatus(200);
                    res.setResult('skipped', 'approver.Email = user.Email');  
                    return res;
                }
                
                
                //toAddresses
                List<String> toAddresses = new List<String>();
                if(approver != null && String.isNotBlank(approver.Email)) toAddresses.add(approver.Email); //add designated contact's email to address
                
                //ccAddresses - no cc required, but leave it as empty list
                List<String> ccAddresses = new List<String>();
                
                //get Email Template Name based on MetaData - Email Template Mapping
                String masterLabel = 'support hub principal notification';
                MethodResponse res2 = EmailController.getEmailTemplateByMasterLabel(masterLabel);
                if(res2.statusCode >= 400) return res2;
                EmailTemplate emailTemplate = res2.emailTemplate; //dto in res
                
                
                String htmlBody = emailTemplate.HtmlValue;
                htmlBody = htmlBody.replace('[approverFirstName]', approver.FirstName); 
                htmlBody = htmlBody.replace('[requesterFullName]', user.Name); 
                htmlBody = htmlBody.replace('[requesterFirstName]', user.FirstName); 
                htmlBody = htmlBody.replace('[requesterEmail]', user.Email); 
                htmlBody = htmlBody.replace('[requesterPhone]', (String.isBlank(user.Phone) ? '' : user.Phone));  //to prevent runtime error: common.apex.runtime.impl.ExecutionException: Argument cannot be null.
                htmlBody = htmlBody.replace('[requesterMobile]', (String.isBlank(user.MobilePhone) ? '' : user.MobilePhone)); 
                
                String plainBody = emailTemplate.Body;
                plainBody = plainBody.replace('[approverFirstName]', approver.FirstName); 
                plainBody = plainBody.replace('[requesterFullName]', user.Name); 
                plainBody = plainBody.replace('[requesterFirstName]', user.FirstName); 
                plainBody = plainBody.replace('[requesterEmail]', user.Email); 
                plainBody = plainBody.replace('[requesterPhone]', (String.isBlank(user.Phone) ? '' : user.Phone)); 
                plainBody = plainBody.replace('[requesterMobile]', (String.isBlank(user.MobilePhone) ? '' : user.MobilePhone));  
                
                
                EmailController.sendEmail(approver.id, approver.accountId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody);    
                res.setStatus(200);
                res.setResult('success', 'Sent ' + emailTemplate.Name +' Email to ' + string.join(toAddresses,','));  
                
                //additional user record update: to replace existing Workflow Rule - field updates
                user.School_Principal_Email__c = approver.Email;
                user.Send_Email_School_Principal__c = false;
                return res;
            } else {
                res.setStatus(200);
                res.setResult('skipped', 'user.School_Principal_Email__c = false');  
                return res;
            }
            
            
        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'SupportHubSignupController.send_SupportHubSignUp_PrincipalNotification_Email() Exception' );
            return res;
        }
    }
    
    /**
*   @author Ben Edwards (ben@cloudinit.nz)
*   @description Wrapper class to hold the details of the user registration
**/
    public class Registration {
        
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String email {get;set;}
        public String mobile {get;set;}
        public String phone {get;set;}
        //public Boolean acceptTerms {get;set;}
    }
    
    /**
*   @author David Catindoy (@cloudinit.nz)
*   @description Wrapper class to hold error boolean flags
**/
    public class ErrorFlags {
        
        public String firstNameErrors {get;set;}
        public String lastNameErrors {get;set;}
        public String emailErrors {get;set;}
        public String phoneErrors {get;set;}
        //public Boolean termsNotAccepted {get;set;}
        public Boolean mobileHasError {get;set;}
        public Boolean phoneHasError {get;set;}
    }
}