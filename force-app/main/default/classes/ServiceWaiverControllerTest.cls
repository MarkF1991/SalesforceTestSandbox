@IsTest
public with sharing class ServiceWaiverControllerTest {
    @TestSetup
    private static void setup(){
        //create account
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        insert schoolAccount;

        //there is a process/trigger on account that automatically create a principal contact at the time account record is created
		List<Contact> contacts = [SELECT id, name, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: schoolAccount.id and Current_Principal_Of_This_School__c = true];
        if (contacts.size()==1){
            Contact principalContact = contacts[0];
            principalContact.FirstName = 'FirstName1';
            principalContact.LastName = 'LastName1';
            principalContact.Email = 'email1@test.com';
            update principalContact;
        } else {
            //create contacts in the school
            Contact principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@test.com', '02711111111', 'Principal', True);
            insert principalContact;    
        }
        

        Contact schoolContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@test.com', '02722222222', 'ICT Leader', False);
        insert schoolContact;
        schoolContact.Current_Principal_Of_This_School__c = true;//n4l for Service Waiver Creation Process
        update schoolContact;
        //create internal user - relationship manager
        User rmUser = TestClassUtility.createInternalUser();
        insert rmUser;

        //create Service Waiver
		Service_Waiver__c waiver = new Service_Waiver__c(
				Account__c = schoolAccount.Id,
                Contact__c = schoolContact.Id,
                InitiatedBy__c = rmUser.Id,
                Submitter_Name__c = 'John de Submitter', 
                Submitter_Email__c = 'email3@test.com',
                Firewall_Removed__c = 'Yes', 
                Web_Security_Removed__c = 'Yes', 
                Default_Categories_Removed__c = 'Yes',
                Default_Categories__c = 'Child Abuse;Drug Abuse;Hacking',
                Waiver_Link__c = 'http://getfeedback.com/test/1234'
		);
        insert waiver;

		
	}
    static testMethod void test_testsetup() {
  		List<Account> accounts = [SELECT id FROM Account];      
        system.assertEquals(1, accounts.size());
        List<Contact> contacts = [SELECT id FROM Contact];      
        system.assertEquals(2, contacts.size());
        //List<User> users = [SELECT id FROM User];      
        //system.assertEquals(1, users.size());
        //
        Account account = accounts[0];
        
        contacts = [SELECT id, name, email FROM Contact WHERE AccountId =: account.id and Current_Principal_Of_This_School__c = true];
		system.assertEquals(1, contacts.size());            
        //system.assertEquals('email1@test.com', contacts[0].email);//n4l            
                
            
    }

    static testMethod void test_sendWaiverAcknowledgementEmail() {
         List<Service_Waiver__c> waivers = [SELECT Submitter_Name__c, Submitter_Email__c, InitiatedBy__r.email, Contact__c, Contact__r.FirstName, Contact__r.email, Account__c
                                           , Waiver_Link__c, Firewall_Removed__c, Web_Security_Removed__c, Default_Categories_Removed__c, Default_Categories__c
                                           FROM Service_Waiver__c];
        Service_Waiver__c waiver = waivers[0];
        
        ServiceWaiverController.sendWaiverAcknowledgementEmail(waiver);
        system.assertEquals(1, waivers.size());
    }

    static testMethod void test_updateAccount() {
        List<Service_Waiver__c> waivers = [SELECT Submitter_Name__c, Submitter_Email__c, InitiatedBy__r.email, Contact__c, Contact__r.FirstName, Contact__r.email, Account__c
                                           , Waiver_Link__c, Firewall_Removed__c, Web_Security_Removed__c, Default_Categories_Removed__c, Default_Categories__c
                                           FROM Service_Waiver__c];
        
        Service_Waiver__c waiver = waivers[0];
        ServiceWaiverController.updateAccount(waiver);
        Account account = [SELECT id, Waiver_Firewall_Removed__c, Waiver_Web_Security_Removed__c, Waiver_Default_Categories_Removed__c, Waiver_Default_Categories__c FROM Account WHERE Id =: waiver.Account__c];

        system.assertEquals(true, account.Waiver_Firewall_Removed__c);
        system.assertEquals(true, account.Waiver_Web_Security_Removed__c);
        system.assertEquals(true, account.Waiver_Default_Categories_Removed__c);
        system.assertEquals('Child Abuse;Drug Abuse;Hacking', account.Waiver_Default_Categories__c);
    }
    
    static testMethod void negative_test_updateAccount() {
        List<Service_Waiver__c> waivers = [SELECT Submitter_Name__c, Submitter_Email__c, InitiatedBy__r.email, Contact__c, Contact__r.FirstName, Contact__r.email, Account__c
                                           , Waiver_Link__c, Firewall_Removed__c, Web_Security_Removed__c, Default_Categories_Removed__c, Default_Categories__c
                                           FROM Service_Waiver__c];
        
        Service_Waiver__c waiver = waivers[0];
        waiver.Firewall_Removed__c = 'No'; 
        waiver.Web_Security_Removed__c = '';
        waiver.Default_Categories_Removed__c = null;
        update waiver;    
            
        ServiceWaiverController.updateAccount(waiver);
        Account account = [SELECT id, Waiver_Firewall_Removed__c, Waiver_Web_Security_Removed__c, Waiver_Default_Categories_Removed__c, Waiver_Default_Categories__c FROM Account WHERE Id =: waiver.Account__c];

        system.assertEquals(false, account.Waiver_Firewall_Removed__c);
        system.assertEquals(false, account.Waiver_Web_Security_Removed__c);
        system.assertEquals(false, account.Waiver_Default_Categories_Removed__c);
        
    }
    
    static testMethod void test_processWaiver() {
        List<Service_Waiver__c> waivers = [SELECT id FROM Service_Waiver__c];
        List<ID> ids = new List<ID>();
        ids.add(waivers[0].id);

        ServiceWaiverController.processWaiver(ids);
        system.assertEquals(1, waivers.size());
    }

    //LWC Service Waiver will call this method
    static testMethod void test_sendWaiverRequestEmail_ServiceWaiverDuringUpdate() {

        List<Account> accounts = [SELECT id, Name, FortiGate_Rollout_Completed_Date__c FROM Account];      
        Account account = accounts[0];

        List<Contact> contacts = [SELECT id, email FROM Contact];      
        Contact contact = contacts[0];
        
        User user = TestClassUtility.createInternalUser('Another', 'InternalUser');
        insert user;

        String hyperlink = 'https://getfeedback.com/123';
        String additionalNote = ' - please read the additional notes.';

        String result = ServiceWaiverController.sendWaiverRequestEmail(contact.id, account.id, user.id, hyperlink, additionalNote);
        system.assertEquals( 'Successfully sent email to ' + contact.Email, result);
    }

      static testMethod void test_sendWaiverRequestEmail_ServiceWaiverAfterUpdate() {

        List<Account> accounts = [SELECT id, Name, FortiGate_Rollout_Completed_Date__c FROM Account];      
        Account account = accounts[0];
        //this will call email template : ServiceWaiverAfterUpdate
        account.FortiGate_Rollout_Completed_Date__c =  date.newInstance(2019, 1, 31);
        update account;

        List<Contact> contacts = [SELECT id, email FROM Contact];      
        Contact contact = contacts[0];
        
        User user = TestClassUtility.createInternalUser('Another', 'InternalUser');
        insert user;

        String hyperlink = 'https://getfeedback.com/123';
        String additionalNote = ' - please read the additional notes.';

        String result = ServiceWaiverController.sendWaiverRequestEmail(contact.id, account.id, user.id, hyperlink, additionalNote);
        system.assertEquals( 'Successfully sent email to ' + contact.Email, result);
    }

  static testMethod void test_ContactController_getContactList() {
    //there is already a default school created in @TestSetup, with 2 Contacts

    //now simply create another school, with a default principal contact
    Account schoolAccount = TestClassUtility.createAccount('Another School Name',  'School');
    insert schoolAccount;

    //when query all contact records, it should be 2 + 1, total of 3
    List<Contact> contacts = [SELECT id FROM Contact]; 
    //system.assertEquals(3, contacts.size());//n4l

    //when get a list of contact by the id of this newly added account, there should be only 1 contact 
    List<Contact> listContacts = ContactController.getContactList(schoolAccount.Id);
    //system.assertEquals(1, listContacts.size());//n4l
  }

}