@IsTest
public with sharing class ContactControllerTest {
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
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222', 'IT Lead', False)); //was ICT Leader
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName3', 'LastName3', 'email3@invalid-domain.com', '02733333333', 'IT Support', False)); //was External ICT
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName4', 'LastName4', 'email4@invalid-domain.com', '02744444444', 'IT Support', False)); //was External ICT
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName6', 'LastName6', 'email6@invalid-domain.com', '02766666666', '', False)); //for blank role test scenario

        Contact exPrincipalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName5', 'LastName5', 'email5@invalid-domain.com', '02755555555', 'Principal', False);
        
        newContacts.add(exPrincipalContact);

        insert newContacts;

        exPrincipalContact.Inactive_Contact_Record__c = true;
        update exPrincipalContact;

        //update relationship
        contacts = [SELECT id, name, email, Business_Role__c, Inactive_Contact_Record__c FROM Contact WHERE AccountId =: schoolAccount.id];
        Map<Id, Contact> contactMap = new Map<Id, Contact>(contacts);

        List<AccountContactRelation> relationships =  [SELECT ContactId, Roles, IsActive FROM AccountContactRelation WHERE AccountId =: schoolAccount.Id];
        for(AccountContactRelation relationship : relationships){
            relationship.Roles = contactMap.get(relationship.ContactId).Business_Role__c;
            relationship.IsActive = !contactMap.get(relationship.ContactId).Inactive_Contact_Record__c;
        }
        update relationships;


    }

    public static testMethod void testtestsetup() {
        List<Account> accounts = [SELECT id, Name FROM Account];      
        Account account = accounts[0];

        List<AccountContactRelation> relationships =  [SELECT ContactId, Roles, IsActive FROM AccountContactRelation WHERE AccountId =: account.Id];
        system.debug('>>>>>>>>>>>>>>> relationships = ' + relationships);
        
        List<Contact> contacts = [SELECT Id, Name, FirstName, LastName, Business_Role__c FROM Contact WHERE AccountId =: account.Id];
        system.debug('>>>>>>>>>>>>>>> contacts = ' + contacts);

        system.assertEquals(True, (1==1));
    }


    public static testMethod void getContactList_test() {
        List<Account> accounts = [SELECT id, Name FROM Account];      
        Account account = accounts[0];
        
        List<Contact> contacts = ContactController.getContactList(account.Id);
        system.assertEquals(5, contacts.size());
    }

    public static testMethod void getRoleBaseContacts_test() {
        List<Account> accounts = [SELECT id, Name FROM Account];      
        Account account = accounts[0];
        
        Map<string, List<Contact>> roleBasedContacts = ContactController.getRoleBaseContacts(account.Id);
        system.assertEquals(4, roleBasedContacts.size()); //should have 3 groups: principal, ICT Leader and IT Support

        system.assertEquals('email1@invalid-domain.com', roleBasedContacts.get('Principal').get(0).email);
        system.assertEquals('email2@invalid-domain.com', roleBasedContacts.get('IT Lead').get(0).email);
        system.assertEquals('email3@invalid-domain.com', roleBasedContacts.get('IT Support').get(0).email);
        system.assertEquals('email4@invalid-domain.com', roleBasedContacts.get('IT Support').get(1).email);
        system.assertEquals('email6@invalid-domain.com', roleBasedContacts.get('blank').get(0).email);
    }





    public static testMethod void findContacts_test1() {
        String searchKey = 'last';
        List<Contact> contacts = ContactController.findContacts(searchKey);
        system.assertEquals(6, contacts.size()); //should include the inactive principal

        searchKey = 'FirstName2';
        contacts = ContactController.findContacts(searchKey);
        system.assertEquals(1, contacts.size());
        system.assertEquals('email2@invalid-domain.com', contacts[0].email);
    }

    public static testMethod void findContacts_test2() {
        String searchKey = 'youcannotfindme';
        List<Contact> contacts = ContactController.findContacts(searchKey);
        system.assertEquals(true, contacts.isEmpty()); //empty list
    }

    public static testMethod void findContacts_test3() {
        String searchKey = ''; //blank
        List<Contact> contacts = ContactController.findContacts(searchKey);
        system.assertEquals(true, contacts.isEmpty()); //empty list
    }

    public static testMethod void getContactList_RoleBased_test() {
        List<Account> accounts = [SELECT id, Name FROM Account];      
        Account account = accounts[0];
        
        // List<Contact> contacts = ContactController.getContactList_RoleBased(account.Id);
        // system.assertEquals(4, contacts.size());

        // Set<String> roles = new Set<String>();
        // For (Contact contact : contacts){
        //     roles.add(contact.Business_Role__c);
        // }
        // system.assertEquals(true, roles.contains('IT Lead'));
        // system.assertEquals(true, roles.contains('IT Support'));
        // system.assertEquals(true, roles.contains('Principal'));

        Map<String,List<Contact>> contacts = ContactController.getContactList_RoleBased(account.Id);
        system.assertEquals(4, contacts.size());

        Set<String> roles = contacts.keySet();
        system.assertEquals(true, roles.contains('IT Lead'.toLowerCase()));
        system.assertEquals(true, roles.contains('IT Support'.toLowerCase()));
        system.assertEquals(true, roles.contains('Principal'.toLowerCase()));
        system.assertEquals(true, roles.contains('blank'));
        
    }

    public static testMethod void getContact_test1() {
        String searchKey = 'FirstName5';
        List<Contact> contacts = ContactController.findContacts(searchKey);
        Contact contact = contacts[0];
        Contact queryContact = ContactController.getContact(contact.id);
        system.assertEquals(contact.email, queryContact.email);
    }

    public static testMethod void getContact_test2() {
        Id invalidContactId = Id.valueOf('001xa000003DIlo');
        Contact queryContact = ContactController.getContact(invalidContactId);
        system.assertEquals(NULL, queryContact); 
    }


    //to test invocableMethod with @future method
    /**n4l
    static testMethod void test_updateUser_FortiPortalfields_method() {
        
        //create external user - for the school contact
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser;
        
        test.startTest();
        Contact contact = [SELECT id, FortiPortal_Access__c, FortiPortal_User_Role__c, account.Fortinet_Adom_Name__c FROM Contact WHERE id =: schoolContact.id LIMIT 1];
        contact.FortiPortal_Access__c = true;
        update contact;

        //simulating when Contact is updated - Process Builder calls the @InvocableMethod here
        List<ID> ids = new List<ID>();
        ids.add(contact.id);
        ContactController.updateUserOfContact(ids); //test invocablemethod to call @future method

        test.stopTest(); 

        
        User testUser = [SELECT id, username, contactId, accountId, FederationIdentifier, FortiPortal_User_Role__c, FortiPortal_Customer_Name__c, Fortinet_Adom_Name__c, UserPermissionsFilteringPortalUser__c FROM User WHERE contactId =: schoolContact.Id LIMIT 1];
        system.assertEquals(testUser.username, testUser.FederationIdentifier);
        system.assertEquals('Advanced', testUser.FortiPortal_User_Role__c);
        system.assertEquals(contact.account.Fortinet_Adom_Name__c, testUser.Fortinet_Adom_Name__c);
        system.assertEquals('sparkb.co.nz', testUser.FortiPortal_Customer_Name__c);
        system.assertEquals(contact.FortiPortal_Access__c, testUser.UserPermissionsFilteringPortalUser__c);
    }   
 **/

    static testMethod void test_getFortiPortalCustomerName_method() {
        String name = '';
        system.assertEquals('sparka.co.nz', ContactController.getFortiPortalCustomerName('Awesome School'));
        system.assertEquals('sparkb.co.nz', ContactController.getFortiPortalCustomerName('Baradene College'));
        system.assertEquals('sparkr.co.nz', ContactController.getFortiPortalCustomerName('Rodney College'));
        system.assertEquals('sparks.co.nz', ContactController.getFortiPortalCustomerName('St Patrick College'));
        system.assertEquals('sparkz.co.nz', ContactController.getFortiPortalCustomerName('Zulu College'));
        system.assertEquals('spark3.co.nz', ContactController.getFortiPortalCustomerName('* name started with other character College'));
        system.assertEquals('spark3.co.nz', ContactController.getFortiPortalCustomerName(' name started with space College'));
        system.assertEquals('', ContactController.getFortiPortalCustomerName(' ')); //blank
        system.assertEquals('', ContactController.getFortiPortalCustomerName('')); //blank
    }

    static testMethod void test_updateContactPictureURL_method() {
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Picture__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];

        Map<string, object> fieldsMap = new Map<string, object>();
        fieldsMap.put('id',schoolContact.id);
        fieldsMap.put('pictureurl','https://www.n4l.co.nz/');
        
        Contact testContact = ContactController.updateContactPictureURL(fieldsMap);
         System.assertEquals('https://www.n4l.co.nz/', testContact.Picture__c); 
    }
    
    

    static testMethod void test_mapContactToUser_method() {
        test.startTest();

        //get a school contact and then create a user for the contact
        Contact schoolContact1 = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(schoolContact1);
        insert externalUser;
        
        //get another school contact, but without creating a user
        Contact schoolContact2 = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c  FROM Contact WHERE email =: 'email3@invalid-domain.com'];

        Map<Id,Contact> map1 = new Map<Id,Contact>();
        map1.put(schoolContact1.id, schoolContact1);
        map1.put(schoolContact2.id, schoolContact2);
        
        List<Map<String, String>> listTest = ContactController.mapContactToUser(map1);
        System.assertEquals(2, listTest.size()); 


        String JSONContent = '';
        JSONParser parser = null;

        //1.0 the map has 3 elements: 'contactid', 'contactstring', 'userstring'
        Map<String, String> mapResult1 = listTest[0];
        
        //1.1 test 'contactid' element
        System.assertEquals(schoolContact1.id, mapResult1.get('contactid')); 
        
        //1.2 test 'contactstring' element
        JSONContent = mapResult1.get('contactstring'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
         // Make calls to nextToken() to point to the second start object marker.
        parser.nextToken();
        // Retrieve the Contact object from the JSON string.
        Contact testContact1 =   (Contact)parser.readValueAs(      Contact.class);
        System.assertEquals(schoolContact1.id, testContact1.id);
        System.assertEquals(schoolContact1.email, testContact1.email);
        
        //1.3 test 'userstring' element
        JSONContent = mapResult1.get('userstring'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
         // Make calls to nextToken() to point to the second start object marker.
        parser.nextToken();
        // Retrieve the Contact object from the JSON string.
        User testUser1 =   (User)parser.readValueAs(      User.class);
        System.assertEquals(externalUser.id, testUser1.id);
        System.assertEquals(externalUser.email, externalUser.email);
        
        

         //2.0 the map has 3 elements: 'contactid', 'contactstring', 'userstring'
        Map<String, String> mapResult2 = listTest[1];
        
        //2.1 test 'contactid' element
        System.assertEquals(schoolContact2.id, mapResult2.get('contactid')); 
        
        //2.2 test 'contactstring' element
        JSONContent = mapResult2.get('contactstring'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
         // Make calls to nextToken() to point to the second start object marker.
        parser.nextToken();
        // Retrieve the Contact object from the JSON string.
        Contact testContact2 =   (Contact)parser.readValueAs(      Contact.class);
        System.assertEquals(schoolContact2.id, testContact2.id);
        System.assertEquals(schoolContact2.email, testContact2.email);
        
        //2.3 test 'userstring' element - should be null
        System.assertEquals('null', mapResult2.get('userstring'));
        


        test.stopTest(); 
    }

    //the unit test in test_mapContactToUser_method above has tested and confirmed the subroutine works.
    static testMethod void test_getContactList_WithUser_method() {
        Account account = [SELECT id, name FROM Account WHERE uuid__c =: 'schoola'];
        List<Map<String, String>> listTest = ContactController.getContactList_WithUser(account.id);
        System.assertEquals(5, listTest.size());  //the size of the list is based on the contacts record created in @TestSetup : only return 4 active, excluding 1 inactive

    }
    
    static testMethod void test_getContact_WithUser_method() {
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];    
        List<Map<String, String>> listTest = ContactController.getContact_WithUser(schoolContact.id);
        System.assertEquals(1, listTest.size());  //should return 1 contact
    }

}