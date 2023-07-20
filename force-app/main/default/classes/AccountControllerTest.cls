/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2019-09-02
* @description Test AccountController
*
* CHANGE LOG
**/

@IsTest
public with sharing class AccountControllerTest {
    
    @TestSetup
    private static void setup(){
        
        //create account
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola'; //for reporting test
        schoolAccount.MoE_School_ID__c = '100';
        insert schoolAccount;
        
        //there is a process/trigger on account that automatically create a principal contact at the time account record is created
        List<Contact> contacts = [SELECT id, name, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: schoolAccount.id and Current_Principal_Of_This_School__c = true];
        if (contacts.size()==1){
            Contact principalContact = contacts[0];
            principalContact.FirstName = 'FirstName1';
            principalContact.LastName = 'LastName1';
            principalContact.Email = 'email1@invalid-domain.com';
            update principalContact;
        } else {
            //create contacts in the school
            Contact principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            insert principalContact;    
        }
        
        
        Contact schoolContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222', 'ICT Leader', False);
        insert schoolContact;
        
        //create internal user - relationship manager
        User rmUser = TestClassUtility.createInternalUser(); //email is internaluser@invalid-domain.com
        rmUser.UserPermissionsSchoolReportingUser__c = true; //allow user to getAccessibleSchools for School Reporting
        insert rmUser;
        
        
        
        
        //create external user - for the principal
        /*Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
User externalUser = TestClassUtility.createExternalUser(principalContact); 
insert externalUser;
*/
        
        //ICT Provider
        List<Account> accounts = new List<Account>();
        Account ictAccount = TestClassUtility.createAccount('New Era IT',  'Non-School Organisation');
        accounts.add(ictAccount); 
        
        Account schoolB = TestClassUtility.createAccount('schoolB',  'School');
        schoolB.uuid__c = 'schoolb';
        schoolB.MoE_School_ID__c = '200';
        accounts.add(schoolB);
        
        Account schoolC = TestClassUtility.createAccount('schoolC',  'School');
        schoolC.uuid__c = null; //this will be excluded in getAccessibleSchools method
        schoolC.MoE_School_ID__c = '300';
        accounts.add(schoolC);
        
        Account schoolD = TestClassUtility.createAccount('schoolD',  'School');
        schoolD.uuid__c = 'schoolD'; 
        schoolD.MoE_School_ID__c = '400';
        accounts.add(schoolD);
        
        insert accounts; //bulk insert
        
        //we had to do this after a record is create because of process builder - Account Creation Process force the new account's Type = 'Other/Adhoc (Unmanaged). Waiting for system admin/helpdesk to manually update this value'
        ictAccount.Type = 'School ICT Provider';
        update ictAccount; 
        
        Contact ictContact = TestClassUtility.createContact(ictAccount.Id, 'ICT', 'Tech001', 'ict.tech001@invalid-domain.com', '0273333333', 'External ICT', False);
        insert ictContact;
        
        system.debug('>>>>>> schoolAccount.id' + schoolAccount.id);
        Account schoola = [SELECT id, name, recordtype.name FROM Account where id =: schoolAccount.id ];
        system.debug('>>>>>> schoolAccount.name' + schoola.name);
        system.debug('>>>>>> schoolAccount.recordtype' + schoola.recordtype.name);
        
        
        
        system.debug('>>>>>> schoolB.id' + schoolB.id);
        schoolB = [SELECT id, name, recordtype.name FROM Account where uuid__c = 'schoolb' ];
        system.debug('>>>>>> schoolB.name' + schoolB.name);
        system.debug('>>>>>> schoolB.recordtype' + schoolB.recordtype.name);
        
        List<Related_School_ICTProvider__c> relatedICTs = new List<Related_School_ICTProvider__c>();
        Related_School_ICTProvider__c relatedICT1 = new Related_School_ICTProvider__c(
            School__c = schoolAccount.id,
            ICT_Provider__c = ictAccount.Id,
            Status__c = 'Current',
            School_Data_Sharing_on_Portal_Authorised__c = true
        );
        relatedICTs.add(relatedICT1);
        //insert relatedICT1;
        
        system.debug('>>>>>> schoolB.id' + schoolB.id);
        Related_School_ICTProvider__c relatedICT2 = new Related_School_ICTProvider__c(
            School__c = schoolB.id,
            ICT_Provider__c = ictAccount.Id,
            Status__c = 'Current',
            School_Data_Sharing_on_Portal_Authorised__c = true
        );
        relatedICTs.add(relatedICT2);
        //insert relatedICT2;
        insert relatedICTs;
    }
    
    static testMethod void test_getAccount_uuid_method() {
        test.startTest();
        String uuid = 'schoola';
        Account account = AccountController.getAccount_uuid(uuid);
        system.assertEquals('Baradene College',  account.name); 
        test.stopTest(); 
    }
    
    static testMethod void test_getAccessibleAccounts_PowerCustomerSuccessUser_method() {
        String testEmail = 'ict.tech001@invalid-domain.com';
        test.startTest();
        Contact contact = [SELECT id, FirstName, LastName, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: testEmail];
        //create PowerCustomerSuccess user - external ICT personnel
        User ictUser = TestClassUtility.createPowerCustomerSuccessUser(contact);
        ictUser.UserPermissionsSchoolReportingUser__c = true; //allow user to getAccessibleSchools for School Reporting
        insert ictUser;
        test.stopTest();
        
        User testUser = [SELECT id, username, name, contactId, AccountId FROM User WHERE email =: testEmail ];
        List<Account> testAccounts = AccountController.getAccessibleSchools(testUser.id);
        System.assertEquals(2, testAccounts.size()); //should have access to schoola and schoolb, not schoolc
        
    }
    
    static testMethod void test_getAccessibleAccounts_CspLitePortalUser_ICTProvider_method() {
        String testEmail = 'ict.tech001@invalid-domain.com';
        test.startTest();
        Contact contact = [SELECT id, FirstName, LastName, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: testEmail];
        //create normal ICT Provider user - external ICT personnel
        User ictUser = TestClassUtility.createExternalUser(contact);
        ictUser.UserPermissionsSchoolReportingUser__c = true; //allow user to getAccessibleSchools for School Reporting
        insert ictUser;
        test.stopTest();
        User testUser = [SELECT id, username, name, contactId, AccountId FROM User WHERE email =: testEmail ];
        List<Account> testAccounts = AccountController.getAccessibleSchools(testUser.id);
        System.assertEquals(2, testAccounts.size()); //should have access to schoola and schoolb, not schoolc
        
    }
    
    static testMethod void test_getAccessibleAccounts_CspLitePortalUser_School_method() {
        String testEmail = 'email1@invalid-domain.com'; //to get principal contact
        test.startTest();
        Contact contact = [SELECT id, FirstName, LastName, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: testEmail];
        //create normal community login user - external school
        User schoolUser = TestClassUtility.createExternalUser(contact);
        schoolUser.UserPermissionsSchoolReportingUser__c = true; //allow user to getAccessibleSchools for School Reporting
        insert schoolUser;
        test.stopTest();
        User testUser = [SELECT id, username, name, contactId, AccountId FROM User WHERE email =: testEmail ];
        List<Account> testAccounts = AccountController.getAccessibleSchools(testUser.id);
        System.assertEquals(1, testAccounts.size()); //principal of schoolda should have access to schoola
        
    }
    
    static testMethod void test_getAccessibleAccounts_InternalUser_method() {
        String testEmail = 'internaluser@invalid-domain.com'; //to get internal user
        User testUser = [SELECT id, username, name, contactId, AccountId FROM User WHERE email =: testEmail ];
        List<Account> testAccounts = AccountController.getAccessibleSchools(testUser.id);
        System.assertEquals(3, testAccounts.size()); //internal user should have access to all schools with uuid schoola and schoolb, schoold
        
    }
    
    static testMethod void test_findAccounts_method() {
        List<Account> testAccounts = AccountController.findAccounts('scho');
        System.assertEquals(3, testAccounts.size()); //internal user should have access to all schools with uuid schoola and schoolb, schoold
        
    }
    
    static testMethod void test_getAccount_method() {
        test.startTest();
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        string accountId = schoolAccount.Id;
        Account account = AccountController.getAccount(accountId);
        system.assert(true, accountId);
        test.stopTest(); 
    }
    
    static testMethod void test_getNHRFeedbackResponses() {
        test.startTest();
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        string accountId = schoolAccount.Id;
        Event event = AccountController.getNHRFeedbackResponses(accountId);
        test.stopTest();  
        system.assert(true, event);
    }
    
    static testMethod void test_getNSEFeedbackResponses() {
        test.startTest();
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        string accountId = schoolAccount.Id;
        Event event = AccountController.getNSEFeedbackResponses(accountId);
        test.stopTest(); 
        system.assert(true, event);
    }
    
    static testMethod void test_getEmailProtectionFeedbackResponses() {
        test.startTest();
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        string accountId = schoolAccount.Id;
        Event event = AccountController.getEmailProtectionFeedbackResponses(accountId);
        test.stopTest(); 
        system.assert(true, event);
    }
    
    static testMethod void test_get_IEM_ATP_Link_Responses() {
        test.startTest();
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        string accountId = schoolAccount.Id;
        Event event = AccountController.get_IEM_ATP_Link_Responses(accountId);
        test.stopTest(); 
        system.assert(true, event);
    }
    
    static testMethod void test_get_ICT_Providers() {
        test.startTest();
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        string accountId = schoolAccount.Id;
        List<string> ictProviders = AccountController.get_ICT_Providers(accountId);
        test.stopTest(); 
        system.assert(true, ictProviders);
    }
        
    static testMethod void test_get_ER_Opportunity_Id() {
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        Campaign erCampaign = TestClassUtility.createCampaign('ER ATP Campaign', 'Equipment Replacement and Secure Access',
                                                                'MNttC - Managed Network to the Classroom', 'Onboarding', 'In Progress'
                                                              , 'Generic Campaign');        
        Opportunity onboardingOpportunity = TestClassUtility.createOpportunity(schoolAccount, erCampaign, date.today(), 'Onboarding', 
                                                                               'New', 'Onboarding');
        string accountId = schoolAccount.Id;
        test.startTest();
        
        String opportunityId = AccountController.get_ER_Opportunity_Id(accountId);
        test.stopTest(); 
        system.assertEquals(onboardingOpportunity.Id, opportunityId);
    }   
    
}