/**
 * @Date               : February 10, 2021
 * @Description        : test class for user flow screen
 * @Author             : Heidi Tang (heitang@deloitte.com)
**/
@isTest (seeAllData = false)
public with sharing class N4LUserFlowScreenTest {
    
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

    static testMethod void testFlowUserCreation() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@n4l.test.com'];
        
        System.runAs(adminUser) {
            Contact principalContact = [SELECT id, System_Accessible__c,Title,Account.Name,Name,Phone,MobilePhone, Email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        
            Test.startTest();
                //create user
                N4LUserFlowScreen.flowUserCreation(new List<Contact>{principalContact});        
            Test.stopTest();

            User objUser = [SELECT Id FROM User WHERE ContactId = :principalContact.Id LIMIT 1];
            System.assert(objUser != null);
        }
    }
}