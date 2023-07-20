/**
 * @Date               : March 29, 2021
 * @Description        : apex handler test class for related school ict provider trigger
 * @Author             : Heidi Tang (heitang@deloitte.com)
**/
@isTest (seeAllData = false)
public with sharing class N4LRelatedICTTriggerHandlerTest {

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
            
            Account childSchoolAccount = TestClassUtility.createAccount('Semi Baradene College',  'Non-School Organisation');
            childSchoolAccount.uuid__c = 'schoolb';
            childSchoolAccount.Type = 'School ICT Provider';
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
            
            exPrincipalContact.Inactive_Contact_Record__c = true;
            update exPrincipalContact;
        }
    }

    static testMethod void testInsertUpdate() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Account childSchoolAccount = [SELECT Id,Host_School__c FROM Account WHERE Type = 'School ICT Provider' LIMIT 1];

            Test.startTest();
                Related_School_ICTProvider__c ictProvider = new Related_School_ICTProvider__c(
                                                                School__c = childSchoolAccount.Host_School__c,Status__c = 'Current',
                                                                Relationship__c = 'Primary / Contracted', ICT_Provider__c=childSchoolAccount.Id);
                insert ictProvider;
                update ictProvider;
            Test.stopTest();

            Account updatedAccount = [SELECT Id,Has_External_ICT_Provider__c,School_Nominated_ICT_Provider__c FROM Account WHERE Id = :childSchoolAccount.Host_School__c];
            System.assert(updatedAccount.Has_External_ICT_Provider__c == true);
            System.assert(updatedAccount.School_Nominated_ICT_Provider__c == ictProvider.ICT_Provider__c);
        }
    }

    static testMethod void testInsertMoreThan1Primary() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Account childSchoolAccount = [SELECT Id,Host_School__c FROM Account WHERE Type = 'School ICT Provider' LIMIT 1];

            Boolean isError = false;
            String errorMessage = '';

            Test.startTest();
                Related_School_ICTProvider__c ictProvider = new Related_School_ICTProvider__c(
                                                                School__c = childSchoolAccount.Host_School__c,Status__c = 'Current',
                                                                Relationship__c = 'Primary / Contracted', ICT_Provider__c=childSchoolAccount.Id);
                insert ictProvider;

                Related_School_ICTProvider__c ictProvider2 = new Related_School_ICTProvider__c(
                                                                School__c = childSchoolAccount.Host_School__c,Status__c = 'Current',
                                                                Relationship__c = 'Primary / Contracted', ICT_Provider__c=childSchoolAccount.Id);

                try {
                    insert ictProvider2;
                } catch(DmlException dmle) {
                    isError = true;
                    errorMessage = dmle.getDmlMessage(0);
                }
            Test.stopTest();
            
            System.assert(isError == true);
            System.assert(errorMessage == System.Label.Screen_ICTOnePrimary);
        }
    }

    static testMethod void testDelete() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Account childSchoolAccount = [SELECT Id,Host_School__c FROM Account WHERE Type = 'School ICT Provider' LIMIT 1];

            Test.startTest();
                Related_School_ICTProvider__c ictProvider = new Related_School_ICTProvider__c(
                    School__c = childSchoolAccount.Host_School__c,Status__c = 'Current',
                    Relationship__c = 'Primary / Contracted', ICT_Provider__c=childSchoolAccount.Id);
                insert ictProvider;
                delete ictProvider;
            Test.stopTest();

            Account updatedAccount = [SELECT Id,Has_External_ICT_Provider__c,School_Nominated_ICT_Provider__c FROM Account WHERE Id = :childSchoolAccount.Host_School__c];
            System.assert(updatedAccount.Has_External_ICT_Provider__c == false);
            System.assert(updatedAccount.School_Nominated_ICT_Provider__c == null);
        }
    }

    static testMethod void testUnDelete() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Account childSchoolAccount = [SELECT Id,Host_School__c FROM Account WHERE Type = 'School ICT Provider' LIMIT 1];

            Related_School_ICTProvider__c ictProvider = new Related_School_ICTProvider__c(
                School__c = childSchoolAccount.Host_School__c,Status__c = 'Current',
                Relationship__c = 'Primary / Contracted', ICT_Provider__c=childSchoolAccount.Id);
            insert ictProvider;
            delete ictProvider;

            Test.startTest();
                undelete ictProvider;
            Test.stopTest();

            Account updatedAccount = [SELECT Id,Has_External_ICT_Provider__c,School_Nominated_ICT_Provider__c FROM Account WHERE Id = :childSchoolAccount.Host_School__c];
            System.assert(updatedAccount.Has_External_ICT_Provider__c == false);
            System.assert(updatedAccount.School_Nominated_ICT_Provider__c == null);
        }
    }
}