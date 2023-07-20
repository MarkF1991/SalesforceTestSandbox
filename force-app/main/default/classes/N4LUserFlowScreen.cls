/**
 * @Date               : February 05, 2021
 * @Description        : class that's being called for new contact user creation
 * @Author             : Heidi Tang (heitang@deloitte.com)
**/
public without sharing class N4LUserFlowScreen {

    @InvocableMethod(label='User creation' description='creation of user on new contact' category='User')
    public static void flowUserCreation(List<Contact> contactList) {
        if(contactList != null) {
            if(!contactList.isEmpty()){

                AccountContactRelation accRelation = [SELECT Id,Contact.System_Accessible__c FROM AccountContactRelation
                                                         WHERE ContactId = :contactList[0].Id AND AccountId = :contactList[0].AccountId LIMIT 1];
    
                Profile profileObj = [SELECT Id, Name FROM Profile WHERE Name = 'Support Hub Community Member User - Login Licence MFA'];
        
                User newUser = new User(
                    profileId = profileObj.id,
                    FirstName = contactList[0].FirstName, 
                    LastName = contactList[0].LastName, 
                    Username = contactList[0].Email, 
                    Email = contactList[0].Email, 
                    MobilePhone = contactList[0].MobilePhone, 
                    Phone = contactList[0].phone,
                    EmailEncodingKey = 'UTF-8',
                    localesidkey = 'en_US',
                    languagelocalekey = 'en_US',
                    timezonesidkey = 'Pacific/Auckland',
                    alias = contactList[0].firstName.left(1) + contactList[0].lastName.left(5),
                    CompanyName = contactList[0].Account.Name,
                    ContactId = contactList[0].Id,
                    Title = contactList[0].Title,
                    approved_Email_With_Unmatch_Email_Domain__c = true,
                    UserPermissionsFilteringPortalUser__c = accRelation.Contact.System_Accessible__c.contains('Fortiportal') ? true: false,
                    UserPermissionsNMSUser__c = accRelation.Contact.System_Accessible__c.contains('Network Management System') ? true: false,
                    UserPermissionsSchoolReportingUser__c = accRelation.Contact.System_Accessible__c.contains('Reporting') ? true: false                
                );
    
                // Make the Nickname Unique
                Integer randomNumber = Integer.valueof((Math.random() * 10000)); //4 digit random number
                String nickname = contactList[0].firstName.toLowerCase() + '.' + contactList[0].lastname.toLowerCase();
                newUser.CommunityNickname = nickname.left(36) + String.valueOf(randomNumber); //user.CommunityNickname allows maximum 40 characters
                
                try {
                    insert newUser;
                } catch (Exception ex) {
                    System.debug('Error ====>'+ex.getMessage());
                }
            }
        }
    }
}