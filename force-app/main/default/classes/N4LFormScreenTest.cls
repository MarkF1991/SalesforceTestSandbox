/**
 * @Date               : February 10, 2021
 * @Description        : test class for form screen
 * @Author             : Heidi Tang (heitang@deloitte.com)
**/
@isTest (seeAllData = false)
public with sharing class N4LFormScreenTest {

    @testSetup
    private static void setup(){
        UserRole uRole = TestClassUtility.createUserRole('Admin');
        insert uRole; 
	    
        User adminUser = TestClassUtility.createAdminUser('testing','admin@n4l.test.com');
        adminUser.UserRoleId = uRole.Id;
        insert adminUser;
        
        System.runAs(adminUser) {
            //create account
            Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
            schoolAccount.uuid__c = 'schoola';
            schoolAccount.MoE_School_ID__c = '200';
            schoolAccount.Email__c = 'email1@invalid-domain.com';
            schoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
            insert schoolAccount;
            
            Account childSchoolAccount = TestClassUtility.createAccount('Semi Baradene College',  'School');
            childSchoolAccount.uuid__c = 'schoolb';
            childSchoolAccount.Host_School__c = schoolAccount.Id;
            childSchoolAccount.MoE_School_ID__c = '200';
            childSchoolAccount.Email__c = 'email1@invalid-domain.com';
            childSchoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
            insert childSchoolAccount;


            //there is a process/trigger on account that automatically create a principal contact at the time account record is created
            Contact principalContact = new Contact();
            List<Contact> contacts = [SELECT id,System_Accessible__c, name, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: schoolAccount.id and Current_Principal_Of_This_School__c = true];
            if (contacts.size()==1){
                //Contact principalContact = contacts[0];
                principalContact = contacts[0];
                principalContact.FirstName = 'FirstName1';
                principalContact.LastName = 'LastName1';
                principalContact.System_Accessible__c = 'Fortiportal';
                principalContact.Email = 'email1@invalid-domain.com';
                update principalContact;
            } else {
                //create contacts in the school
                principalContact = TestClassUtility.createContactBasic(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111');
                principalContact.System_Accessible__c = 'Fortiportal';
                insert principalContact;    
            }
            
            List<Contact> newContacts = new List<Contact>();
            newContacts.add(TestClassUtility.createContactBasic(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222'));
            newContacts.add(TestClassUtility.createContactBasic(schoolAccount.Id, 'FirstName3', 'LastName3', 'email3@invalid-domain.com', '02733333333'));
            newContacts.add(TestClassUtility.createContactBasic(schoolAccount.Id, 'FirstName4', 'LastName4', 'email4@invalid-domain.com', '02744444444'));
            
            Contact exPrincipalContact = TestClassUtility.createContactBasic(schoolAccount.Id, 'FirstName5', 'LastName5', 'email5@invalid-domain.com', '02755555555');        
            newContacts.add(exPrincipalContact);        
            insert newContacts;
            
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation WHERE ContactId = :principalContact.Id];
            accRelation.Roles = 'Principal';
            accRelation.Authority__c = 'Manage contacts';
            update accRelation;    

            exPrincipalContact.Inactive_Contact_Record__c = true;
            update exPrincipalContact;
        }
    }

    static testMethod void testMatchRolesAndAuthorities() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {

            Test.startTest();
                N4LFormScreen.matchRolesAndAuthorities();  
                N4LFormScreen.getUserLicense();  
            Test.stopTest();
        }
    }

    static testMethod void testGetContactEmail() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;

            Test.startTest();
                N4LFormScreen.getContactEmail(String.valueOf(accRelation.Id));     
            Test.stopTest();
        }
    }

    static testMethod void testCaptureContactPrimaryAccountName() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;

            Test.startTest();
                N4LFormScreen.captureContactPrimaryAccountName(String.valueOf(accRelation.Id));   
                N4LFormScreen.retrieveScreenSettings();

            Test.stopTest();
        }
    }

    static testMethod void testGetResultFromExistingSchool() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,AccountId,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;

            Test.startTest();
                N4LFormScreen.getResultFromExistingSchool('email1@invalid',principalContact.AccountId);     
            Test.stopTest();
        }
    }

    static testMethod void testGetResults() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,AccountId,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;

            Test.startTest();
                N4LFormScreen.getResults('Account','Name','Baradene College',principalContact.AccountId);     
            Test.stopTest();
        }
    }

    static testMethod void testGetResultsContact() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Account acct = [SELECT Id FROM Account WHERE Name = 'Semi Baradene College'];
            Test.startTest();
                N4LFormScreen.getResults('Contact',null,'email1@invalid-domain.com',acct.Id);     
            Test.stopTest();
        }
    }

    static testMethod void testGetAccountDetails() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,AccountId,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;

            Test.startTest();
                N4LFormScreen.getAccountDetails(accRelation.Id,principalContact.AccountId);     
                N4LFormScreen.getAccountDetails(accRelation.Id,principalContact.Id);     
            Test.stopTest();
        }
    }

    static testMethod void testGetRecordDetails() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,AccountId,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;

            Test.startTest();
                N4LFormScreen.getRecordDetails(accRelation.Id,accRelation.ContactId,'Contact', false,principalContact.AccountId,'');     
                N4LFormScreen.getRecordDetails(accRelation.Id,accRelation.ContactId,'AccountContactRelation', false,principalContact.AccountId,'');     
                N4LFormScreen.getRecordDetails(accRelation.Id,accRelation.ContactId,'AccountContactRelation', true,principalContact.AccountId,'existingSchool');     
                N4LFormScreen.getRecordDetails(accRelation.Id,accRelation.ContactId,'Contact', true,principalContact.AccountId,'existingSchool');     
                N4LFormScreen.getRecordDetails(null,accRelation.ContactId,'AccountContactRelation', false,principalContact.AccountId,'');     
                N4LFormScreen.getRecordDetails(null,null,'Contact', false,principalContact.AccountId,'');     
            Test.stopTest();
        }
    }

    static testMethod void testCheckEmailDuplicates() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,AccountId,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;
            update accRelation;

            Test.startTest();
                N4LFormScreen.checkEmailDuplicates('email1@invalid-domain.com',accRelation.Id,false);
            Test.stopTest();
        }
    }

    static testMethod void testCheckSupportHubUser() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,AccountId,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;
            update accRelation;

            Test.startTest();
                N4LFormScreen.checkSupportHubUser(accRelation.Id,principalContact.Id,'AccountContactRelation',false);
            Test.stopTest();
        }
    }

    static testMethod void testCheckEmailDomain() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,AccountId,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            Account acct = [SELECT Id,Email_Domain__c FROM Account WHERE Id = :principalContact.AccountId];
            acct.Email_Domain__c = 'n4l.co.nz';
            update acct;

            Test.startTest();
                N4LFormScreen.checkEmailDomain('email1@invalid-domain.com',acct.Id);
            Test.stopTest();
        }
    }

    static testMethod void testRetrieveMultipicklistValues() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        Contact principalContact = [SELECT id, System_Accessible__c,Title,Account.Name,Name,Phone,MobilePhone, Email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        N4LUserFlowScreen.flowUserCreation(new List<Contact>{principalContact});        

        User objUser = [SELECT Id FROM User WHERE ContactId = :principalContact.Id LIMIT 1];

        System.runAs(objUser) {
            Test.startTest();
                N4LFormScreen.retrieveMultipicklistValues('AccountContactRelation','roles',principalContact.AccountId);
                N4LFormScreen.retrieveMultipicklistValues('AccountContactRelation','authority__c',principalContact.AccountId);
                N4LFormScreen.retrieveMultipicklistValues('Contact','system_accessible__c',principalContact.AccountId);
            Test.stopTest();
        }
    }

    static testMethod void testAddNewContact() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,AccountId,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;
            update accRelation;

            Test.startTest();
                N4LFormScreen.addNewContact(principalContact.Email,'Test Firstname', 'Test LastName','Principal',
                                            '',true,true,true,true,principalContact.AccountId,accRelation.Id,false,'',false,'test@test.com','',true);
                N4LFormScreen.addNewContact('email10@invalid-domain.com','Test Firstname 2', 'Test LastName 2','IT Lead',
                '',true,true,true,true,principalContact.AccountId,accRelation.Id,false,'',true,'test@test.com','',true);

                try {
                    N4LFormScreen.addNewContact('','Test Firstname 2', 'Test LastName 2','IT Lead',
                    '',true,true,true,true,principalContact.AccountId,accRelation.Id,false,'',true,'test@test.com','',true);    
                } catch (Exception ex) {}

            Test.stopTest();
        }
    }

    static testMethod void testAddNewContactOutage() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,AccountId,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;
            update accRelation;

            Test.startTest();
                try {
                    N4LFormScreen.addNewContact(principalContact.Email,'Test Firstname', 'Test LastName','Principal',
                    '',false,true,true,true,principalContact.AccountId,accRelation.Id,false,'',false,'test@test.com','',true);
                } catch (Exception ex) {}
            Test.stopTest();
        }
    }

    static testMethod void testSaveRelationship() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,AccountId,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;
            update accRelation;

            Test.startTest();
                N4LFormScreen.saveRelationship(accRelation.Id,principalContact.AccountId,principalContact.Id,true, 
                    true,'Principal;IT Lead','',true,'',false,'',false,false,'');

                try{
                    N4LFormScreen.saveRelationship(accRelation.Id,principalContact.AccountId,null,true, 
                    true,'Principal;IT Lead','',true,'',false,'',true,false,'');
                } catch (Exception ex){}
            Test.stopTest();
        }
    }

    static testMethod void testSaveRelationshipChangeOldEmail() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Account childAccount = [SELECT Id FROM Account WHERE Name = 'Semi Baradene College' LIMIT 1];
            Contact principalContact = [SELECT Id,AccountId,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;
            update accRelation;

            Test.startTest();
                N4LFormScreen.saveRelationship(accRelation.Id,childAccount.Id,principalContact.Id,true, 
                    true,'IT Lead','',true,'',false,'',true,true,'');
            Test.stopTest();
        }
    }

    static testMethod void testValidateContactFieldEdits() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT Id,AccountId,Email FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;
            update accRelation;

            Test.startTest();
                N4LFormScreen.validateContactFieldEdits(accRelation.Id,principalContact.AccountId);
            Test.stopTest();
        }
    }

    static testMethod void testValidateContactsForExternalUser() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT id, System_Accessible__c,Title,Account.Name,Name,Phone,MobilePhone, Email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
            AccountContactRelation accRelation = [SELECT Id,IsActive,ContactId FROM AccountContactRelation 
                                                    WHERE ContactId = :principalContact.Id];
            accRelation.isActive = true;
            update accRelation;
                                            
            Test.startTest();
                N4LUserFlowScreen.flowUserCreation(new List<Contact>{principalContact}); 
                
                User externalUser = [SELECT Id FROM User WHERE ContactId = :principalContact.Id];

                System.runAs(externalUser){
                    try{
                        N4LFormScreen.validateContactFieldEdits(accRelation.Id,principalContact.AccountId);
                    } catch(Exception ex) {}
                }
            Test.stopTest();
        }
    }

}