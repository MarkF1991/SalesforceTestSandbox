/**
 * @Date               : February 10, 2021
 * @Description        : test class for user reset password
 * @Author             : Heidi Tang (heitang@deloitte.com)
**/
@isTest (seeAllData = false)
public with sharing class N4LUserResetPasswordTest {

    @testSetup
    private static void setup(){
        //create account
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola';
        schoolAccount.MoE_School_ID__c = '200';
        schoolAccount.Email__c = 'email1@invalid-domain.com';
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
            principalContact = TestClassUtility.createContactBasic(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111');
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

    static testMethod void testresetPassword() {
        Contact principalContact = [SELECT id, name, Email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        
        //create user
        User externalUser = TestClassUtility.createExternalUser(principalContact);
        insert externalUser;
        
        //execute reset password for user
        Test.startTest();
            N4LUserResetPassword.resetPassword(new List<User>{externalUser});        
        Test.stopTest();
    }
}