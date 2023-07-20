@IsTest
public class SupportHubDelegateAuthorityTest {
    
    @TestSetup
    
    private static void setup(){
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
        List<Campaign> newCampaigns = new List<Campaign>();
        //newCampaigns.add(TestClassUtility.createCampaign('Filtering Portal (Pilot)', '', 'Filtering Portal', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //newCampaigns.add(TestClassUtility.createCampaign('Identity Awareness (Pilot)', '', 'Identity Awareness', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //newCampaigns.add(TestClassUtility.createCampaign('School Reporting (Pilot)', '', 'School Reporting', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //newCampaigns.add(TestClassUtility.createCampaign('NHR (Pilot)', Helper.getProgrammeNameMapping().get('NHR').Programme__c, 'Managed Network To The Classroom', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //newCampaigns.add(TestClassUtility.createCampaign('NSE (Pilot)', Helper.getProgrammeNameMapping().get('NSE').Programme__c, 'Managed Network Extension', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //due to product__c picklist value change:
        newCampaigns.add(TestClassUtility.createCampaign('NHR (Pilot)', Helper.getProgrammeNameMapping().get('NHR').Programme__c, 'Support Hub', 'Onboarding', 'In Progress', 'Generic Campaign'));
        insert newCampaigns;
        
    }
    
    static testMethod void test_delegate01() {
        test.startTest();
        String type='School Contacts Update';
        //create account, campaign, campaignAccount - for the campaignAccountContact
        Account account = [SELECT Id,Email_Domain__c, Name FROM Account WHERE uuid__c = 'schoola'];
        Campaign campaign = [SELECT id, name, Programme__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        Campaign_Account__c campaignAccount = TestClassUtility.createCampaignAccount(campaign, account);
        insert campaignAccount;
        Campaign_Account_Contact__c campaignAccountContact = TestClassUtility.createCampaignAccountContact(campaign, contact, campaignAccount);
        insert campaignAccountContact;
        campaignAccountContact = [SELECT Id, Campaign__c, Contact__c, Campaign_Account__r.Account__c  FROM Campaign_Account_Contact__c WHERE Id =: campaignAccountContact.Id];
        PageReference myVfPage = Page.SupportHubDelegateAuthority;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('campaignId',campaign.Id); 
        ApexPages.currentPage().getParameters().put('accountId',account.Id); 
        SupportHubDelegateAuthorityController shac = new SupportHubDelegateAuthorityController();
        SupportHubDelegateAuthorityController.getSelectOptionListByField();
        shac.registration = new SupportHubDelegateAuthorityController.Registration();
        shac.accountId = account.Id;
        shac.campaignId = campaign.Id;
        shac.registration.firstName ='delegate test 00';
        shac.registration.lastName ='n4l';
        shac.registration.email ='delegatetest00';
        shac.registration.mobile = '021 123 4567';
        shac.registration.phone = '09 123 4567';
        shac.errors = new SupportHubDelegateAuthorityController.ErrorFlags();
        shac.errors.firstNameErrors = null;
        shac.errors.lastNameErrors = null;
        shac.errors.emailErrors = null;
        shac.errors.phoneErrors = null;
        shac.errors.otherErrors = null;
        shac.errors.mobileHasError = false;
        shac.errors.phoneHasError = false;
        shac.selectSchool();
        shac.doDelegate();
        shac.doDelegate();
        account.Email_Domain__c = null;
        update account;
        shac.selectSchool();
        test.stopTest(); 
    }

}