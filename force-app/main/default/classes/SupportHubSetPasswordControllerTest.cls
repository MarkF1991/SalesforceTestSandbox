@IsTest
class SupportHubSetPasswordControllerTest {
    @testSetup
    static void setup(){
        //create account 
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola';
        schoolAccount.MoE_School_ID__c = '200';
        schoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
        insert schoolAccount;
        
        //there is a process/trigger on account that automatically create a principal contact at the time account record is created
        Contact principalContact = new Contact();
        List<Contact> contacts = [SELECT id, name, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: schoolAccount.id and Current_Principal_Of_This_School__c = true];
        if (contacts.size()==1){
            //Contact principalContact = contacts[0];
            principalContact = contacts[0];
            principalContact.FirstName = 'FirstName1';
            principalContact.LastName = 'LastName1';
            principalContact.Email = 'email1@invalid-domain.com';
            update principalContact;
        } else {
            //create contacts in the school
            //Contact principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            insert principalContact;    
        }
        
        
        List<Contact> newContacts = new List<Contact>();
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222', 'ICT Leader', False));
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName3', 'LastName3', 'email3@invalid-domain.com', '02733333333', 'External ICT', False));
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName4', 'LastName4', 'email4@invalid-domain.com', '02744444444', 'External ICT', False));
        
        Contact exPrincipalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName5', 'LastName5', 'email5@invalid-domain.com', '02755555555', 'Principal', False);
        
        newContacts.add(exPrincipalContact);
        
        insert newContacts;
        
    }
    
    static Contact getContact(String email){
        List<Contact> contacts =  [SELECT Id, FirstName, LastName, Name, Title, Phone, MobilePhone, Email, Picture__c, Business_Role__c, Current_Principal_Of_This_School__c, AccountId, Account.Name FROM Contact WHERE Email =: email];
        return contacts[0]; //return a contact record
    }
    
    static testMethod void test_isValidPassword(){
        SupportHubSetPasswordController controller = new SupportHubSetPasswordController();
        //password and confirm password do not match
        controller.registration.password = 'Password111';
        controller.registration.confirmPassword = 'Password222';
        system.assertEquals(false, controller.isValidPassword());
        
        //cannot contain password
        controller.registration.password = 'Password';
        controller.registration.confirmPassword = 'Password';
        system.assertEquals(false, controller.isValidPassword());
        
        //under 8 characters
        controller.registration.password = 'five5';
        controller.registration.confirmPassword = 'five5';
        system.assertEquals(false, controller.isValidPassword());
        
        //must include number
        controller.registration.password = 'wordsonlynonumber';
        controller.registration.confirmPassword = 'wordsonlynonumber';
        system.assertEquals(false, controller.isValidPassword());
        
        //must include upper case
        controller.registration.password = 'alllowercase123!';
        controller.registration.confirmPassword = 'alllowercase123!';
        system.assertEquals(false, controller.isValidPassword());
        
        //must include lower case
        controller.registration.password = 'ALLUPPERCASE123!';
        controller.registration.confirmPassword = 'ALLUPPERCASE123';
        system.assertEquals(false, controller.isValidPassword());
        
        //must include special character
        controller.registration.password = 'NOspecialCharacter123';
        controller.registration.confirmPassword = 'NOspecialCharacter123';
        system.assertEquals(false, controller.isValidPassword());
        
        //should pass
        controller.registration.password = 'UPPERlower123!';
        controller.registration.confirmPassword = 'UPPERlower123!';
        system.assertEquals(true, controller.isValidPassword());
    }
    
    static testMethod void test_create_N4L_user_success(){
        SupportHubSetPasswordController controller = new SupportHubSetPasswordController();
        Contact contact = [SELECT id, FirstName, LastName, Email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        Id contactId = contact.Id;
        String password = 'This is a valid Key 123!';
        Boolean sendEmailConfirmation = false;
        
        MethodResponse res = controller.create_N4L_user(contactId, password, sendEmailConfirmation, 'N4L Invitation - Default');
        
        //System.assertEquals(200, res.statuscode);
        
    }
    
    static testMethod void test_GetStartURL(){
        String urlToken = System.currentPageReference().getParameters().get('t');
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        
        Contact contact = getContact('email2@invalid-domain.com');
        Token__c token = new Token__c(
            RecordId__c = String.valueOf(contact.Id),
            Account__c = contact.AccountId,
            Requester__c = null,
            Approver__c = contact.Id,
            Type__c = 'Self-SignUp',
            Status__c = 'Invited',
            IsClosed__c = false,
            UserOrigin__c = 'Self-SignUp'
        );
        insert token;
        SupportHubSetPasswordController controller = new SupportHubSetPasswordController();
        string testGetStartURL = controller.GetStartURL(startUrl, token);
        
        if(helper.isSandbox()){
            system.assertEquals('/schoolictsupport/s/', testGetStartURL);
        }else{
            system.assertEquals('/s/', testGetStartURL);
        }
        
        
    }
    
    static testMethod void test_GetStartURL2(){
        String urlToken = System.currentPageReference().getParameters().get('t');
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        
        Contact contact = getContact('email2@invalid-domain.com');
        Contract contract = testclassutility.createContract(contact.Account, 'Equipment Support', contact, 'N4L Contract');

        Token__c ptoken = new Token__c(
            RecordId__c = String.valueOf(contract.Id),
            Account__c = contact.AccountId,
            Requester__c = null,
            Approver__c = contact.Id,
            Type__c = 'Self-SignUp',
            Status__c = 'Invited',
            IsClosed__c = false,
            UserOrigin__c = 'Self-SignUp'
        );
        insert ptoken;
        
        Token__c newToken = new Token__c(
            RecordId__c = String.valueOf(contract.Id),
            Account__c = contract.AccountId,
            Requester__c = null,
            Approver__c = contract.CustomerSignedId, //designated signatory contact id
            Type__c = 'MOU',
            Status__c = 'Invited',
            IsClosed__c = false,
            Parent__c = ptoken.id,
            //ITR1397 - add userorigin
            UserOrigin__c = 'N4L Invitation - Contract Signatory' 
        );
        insert newToken;

   //prepare mappings
        Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap = SupportHubUserNotificationController.getUserCreationMapping('origin');
        
        //get mapping by user origin
        Support_Hub_User_Creation_Mapping__mdt mapping = userCreationMap.get(newToken.UserOrigin__c);
        system.assertEquals('signcontractorderform', mapping.Key__c.toLowerCase());
        
        // ---------------------------- generate encrypted JWT ----------------------------
        String result;
        
                        Map<String, String> inviteTokens =  ContractController.generateJWTToken(newToken, 'MOU');
     
                        newToken.JWT1__c = inviteTokens.get('inviteToken'); 
                        update newToken; //save JWT1

                        result += '?t=' + newToken.JWT1__c + '&p=mou';

        
      SupportHubSetPasswordController controller = new SupportHubSetPasswordController();
        Exception expectedException;
             try
        {
             string testGetStartURL = controller.GetStartURL(startUrl, newToken);
            system.assertEquals(result, testGetStartURL);
        }
        catch (Exception e)
        {
            expectedException = e;
        }
       

        
    }

    static testMethod void test_GetStartURL3(){
        String urlToken = System.currentPageReference().getParameters().get('t');
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        
        Contact contact = getContact('email2@invalid-domain.com');
        Token__c token = new Token__c(
            RecordId__c = String.valueOf(contact.Id),
            Account__c = contact.AccountId,
            Requester__c = null,
            Approver__c = contact.Id,
            Type__c = 'Invite-SignUp',
            Status__c = 'Invited',
            IsClosed__c = false,
            UserOrigin__c = 'N4L Invitation - Default'
        );
        insert token;
        SupportHubSetPasswordController controller = new SupportHubSetPasswordController();
        string testGetStartURL = controller.GetStartURL(startUrl, token);
        
        if(helper.isSandbox()){
            system.assertEquals('/schoolictsupport/s/', testGetStartURL);
        }else{
            system.assertEquals('/s/', testGetStartURL);
        }
        
        
    }
    
        static testMethod void test_GetStartURL4(){
        String urlToken = System.currentPageReference().getParameters().get('t');
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        
        Contact contact = getContact('email2@invalid-domain.com');
        Token__c token = new Token__c(
            RecordId__c = String.valueOf(contact.Id),
            Account__c = contact.AccountId,
            Requester__c = null,
            Approver__c = contact.Id,
            Type__c = 'School Contacts Update',
            Status__c = 'Invited',
            IsClosed__c = false,
            UserOrigin__c = 'N4L Invitation - School Contacts Update Campaign'
        );
        insert token;
        SupportHubSetPasswordController controller = new SupportHubSetPasswordController();
        string testGetStartURL = controller.GetStartURL(startUrl, token);
        
        if(helper.isSandbox()){
            system.assertEquals(False, string.isEmpty(testGetStartURL));
        }else{
            system.assertEquals(False, string.isEmpty(testGetStartURL));
        }
        
        
    }
    
    static testMethod void test_general(){
        Contact contact = getContact('email2@invalid-domain.com');
        Token__c token = new Token__c(
            RecordId__c = String.valueOf(contact.Id),
            Account__c = contact.AccountId,
            Requester__c = null,
            Approver__c = contact.Id,
            Type__c = 'Self-SignUp',
            Status__c = 'Invited',
            IsClosed__c = false,
            UserOrigin__c = 'Self-SignUp'
        );
        insert token;
        SupportHubSetPasswordController controller = new SupportHubSetPasswordController();
        controller.initializeVariables();
        SupportHubSetPasswordController.SetPassword testSetPW = controller.setPassword;
        testSetPW.acceptTerms = true;
        testSetPW.password = '123Test!';
        testSetPW.confirmPassword = '123Test!';
        system.assertNotEquals(null, testSetPW);
        SupportHubSetPasswordController.Registration testReg = controller.registration;
        testReg.acceptTerms = true;
        testReg.password = '123Test!';
        testReg.confirmPassword = '123Test!';
        system.assertNotEquals(null, testReg);
        SupportHubSetPasswordController.ErrorFlags testErr = controller.errors;
        testErr.passwordErrors = 'test passwordErrors';
        testErr.termsNotAccepted= false;
        testErr.userSetupErrors = 'test userSetupErrors';
        testErr.userSetupHasError = false;
        system.assertNotEquals(null, testErr);
        controller.testRes.setStatus(200);
        controller.testRes.token = token;
        system.debug(token);
        controller.submit();
        controller.create_N4L_user('003000000000000', null, null, 'N4L Invitation - Default');
        testReg.acceptTerms = false;
        controller.submit();
        testReg.acceptTerms = true;
        controller.testRes.token.IsClosed__c = true; 
        controller.submit();  
        controller.testRes.setStatus(500);
        controller.submit(); 
    }
    
    
}