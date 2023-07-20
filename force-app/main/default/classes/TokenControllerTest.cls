@IsTest
public with sharing class TokenControllerTest {
    @TestSetup
    private static void setup(){
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

        exPrincipalContact.Inactive_Contact_Record__c = true;
        update exPrincipalContact;
    }
    
    public static testMethod void test_getToken_method() {
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Picture__c  FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Picture__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];

        Token__c token = new Token__c(
            Account__c = account.Id,
            Approver__c =  principalContact.Id,
            Requester__c = schoolContact.Id,
            Type__c = 'Filtering Portal',
            Status__c = 'Awaiting Approval',
            IsClosed__c = false
        );
        insert token;

        MethodResponse res = TokenController.getToken(token.id);
        Token__c testToken = res.token; //res1 return token as dto

        system.assertEquals(account.Name, testToken.Account__r.Name);
        system.assertEquals(principalContact.Email, testToken.Approver__r.Email);
    }

    public static testMethod void test_getToken_method_negative1() {
        String tokenId = 'a2C5O00000017oXUAQ';
        integer expectedStatusCode = 404;
        string expectedStatus = 'NOT_FOUND';
        string expectedResultString = 'Could not find a Token__c record with id = "' + tokenId + '"';

        MethodResponse res = TokenController.getToken(tokenId);

        system.assertEquals(expectedStatusCode, res.statuscode);
        system.assertEquals(expectedStatus, res.status);
    }
    
    public static testMethod void test_getToken_method_negative2() {
        String tokenId = null;
        integer expectedStatusCode = 400;
        string expectedStatus = 'BAD_REQUEST';
        string expectedResultString = 'Missing Token__c id in token claims';

        MethodResponse res = TokenController.getToken(tokenId);

        system.assertEquals(expectedStatusCode, res.statuscode);
        system.assertEquals(expectedStatus, res.status);
    }

    public static testMethod void test_closeToken_method() {
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Picture__c  FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Picture__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];

        Token__c token = new Token__c(
            Account__c = account.Id,
            Approver__c =  principalContact.Id,
            Requester__c = schoolContact.Id,
            Type__c = 'Filtering Portal',
            Status__c = 'Awaiting Approval',
            IsClosed__c = false
        );
        insert token;

        MethodResponse res1 = TokenController.closeToken(token.id, 'Approved');
        system.assertEquals(200, res1.statuscode);
        
        MethodResponse res2 = TokenController.getToken(token.id);
        Token__c testToken = res2.token; //res1 return token as dto
        system.assertEquals('Approved', testToken.Status__c);
        system.assertEquals(true, testToken.IsClosed__c);
        system.assertEquals(System.now().date(), testToken.ClosedDate__c.date()); //compare date instead of time
    }

    public static testMethod void test_closeToken_method_negative1() {
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Picture__c  FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Picture__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];

        Token__c token = new Token__c(
            Account__c = account.Id,
            Approver__c =  principalContact.Id,
            Requester__c = schoolContact.Id,
            Type__c = 'Filtering Portal',
            Status__c = 'Awaiting Approval',
            IsClosed__c = false
        );
        insert token;

        //Token__c.Status__c has restriction: Restrict picklist to the values defined in the value set
        MethodResponse res = TokenController.closeToken(token.id, 'thisIsInvalidStatus');
        
        integer expectedStatusCode = 400;
        string expectedStatus = 'BAD_REQUEST';
        string expectedResultString = 'TokenController.closeToken Exception';

        system.assertEquals(expectedStatusCode, res.statuscode);
        system.assertEquals(expectedStatus, res.status);
        
    }

    public static testMethod void test_closeTokenTree_method() {
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Picture__c  FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Picture__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];

        List<Token__c> tokens = new List<Token__c>();

        Token__c parentToken = new Token__c(
            Account__c = account.Id,
            Approver__c =  principalContact.Id,
            Requester__c = schoolContact.Id,
            Type__c = 'School Contacts Update',
            Status__c = 'Invited',
            IsClosed__c = false
        );
        insert parentToken;

        Token__c Token1 = new Token__c(
            Account__c = account.Id,
            Approver__c =  principalContact.Id,
            Requester__c = schoolContact.Id,
            Type__c = 'Verification Code',
            Status__c = 'Invited',
            IsClosed__c = false,
            Parent__c = parentToken.Id
        );
        tokens.add(Token1);
        
        Token__c Token2 = new Token__c(
            Account__c = account.Id,
            Approver__c =  principalContact.Id,
            Requester__c = schoolContact.Id,
            Type__c = 'User Set Password',
            Status__c = 'Invited',
            IsClosed__c = false,
            Parent__c = parentToken.Id
        );
        tokens.add(Token2);
        
        insert tokens;

        test.startTest();
        MethodResponse res1 = TokenController.closeTokenTree(parentToken.Id);
        system.assertEquals(200, res1.statuscode);
        
        //parent token should be closed
        MethodResponse res2 = TokenController.getToken(parentToken.id);
        Token__c testToken = res2.token; //res1 return token as dto
        system.assertEquals(true, testToken.IsClosed__c);
        system.assertEquals(System.now().date(), testToken.ClosedDate__c.date()); //compare date instead of time
        
        //all child tokens should be closed too
        List<Token__c> childTokens = [SELECT Id, IsClosed__c, ClosedDate__c, Parent__c FROM Token__c WHERE Parent__c =: parentToken.Id];
        for(Token__c childToken : childTokens){
            system.assertEquals(true, childToken.IsClosed__c);
            system.assertEquals(System.now().date(), childToken.ClosedDate__c.date()); //compare date instead of time
        }

        test.stopTest();
    }

}