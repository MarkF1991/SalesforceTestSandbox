/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2019-03-07
* @description Various get contact methods for LWC.
*
* CHANGE LOG
**/
public without sharing class ContactController {

    @AuraEnabled (cacheable = false)
    public static string getRelatedAccountFields(String recordId){
        return null;

    }

    @AuraEnabled(cacheable=true) //used in Service Waiver - Account's Contact combo box
    public static List<Contact> getContactList(string accountId) {
        return [SELECT Id, Name, Title, Phone, Email, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: accountId AND Inactive_Contact_Record__c = False];
    }

    public static Map<string, List<Contact>> getRoleBaseContacts(string accountId){
        // OLD ------------------------------
        // //based on Kevin's SOQL statement and DO NOT USE Contact.Current_Principal_Of_This_School__c
        // List<Contact> contacts  =  [SELECT Id, Name, FirstName, LastName, Business_Role__c, accountId, Email, account.Name, account.moe_school_id__c,account.MoE_Site_ID_Lookup__r.name FROM Contact where AccountId =: accountId AND Inactive_Contact_Record__c = FALSE];
        // Map<string, List<Contact>> roleBasedContacts = New Map<string, List<Contact>>();
        // For (Contact contact : contacts){
        //     if (roleBasedContacts.containsKey(contact.Business_Role__c)){
        //         roleBasedContacts.get(contact.Business_Role__c).add(contact);
        //     } else {
        //         List<Contact> newList =  new List<Contact>();
        //         newList.add(contact);
        //         roleBasedContacts.put(contact.Business_Role__c, newList);
        //     }
        // }
        // return roleBasedContacts;

        // NEW ------------------------------
        Map<string, List<Contact>> result = New Map<string, List<Contact>>();
        if (String.isBlank(accountId)) return result;
        List<AccountContactRelation> relationships =  [SELECT ContactId, Roles FROM AccountContactRelation WHERE  AccountId =: accountId AND IsActive = TRUE];
        
        Set<Id> Ids = new Set<Id>();
        for(AccountContactRelation relationship : relationships){
            Ids.add(relationship.ContactId);
        }

        List<Contact> contacts = [SELECT Id, Name, FirstName, LastName, Business_Role__c, accountId, Email, account.Name, account.moe_school_id__c,account.MoE_Site_ID_Lookup__r.name, Title, Phone, Picture__c FROM Contact WHERE Id IN: Ids];
        Map<Id, Contact> mapContact =  new Map<Id,Contact>(contacts);
        
        for(AccountContactRelation relationship : relationships){
            if(!String.IsBlank(relationship.roles)){
                List<String> roles = relationship.roles.split(';');
                for (String role : roles){
                    if(result.containsKey(role)){ 
                        result.get(role).add(mapContact.get(relationship.ContactId));
                    } else {
                        result.put(role, new List<Contact>{mapContact.get(relationship.ContactId)});
                    }
                }
            } else {
                if(result.containsKey('blank')){
                    result.get('blank').add(mapContact.get(relationship.ContactId));
                } else {
                    result.put('blank', new List<Contact>{mapContact.get(relationship.ContactId)});
                }
            }
        }

        return result;
    }
    
    @AuraEnabled(cacheable=true) //used in lwc-recipe contactList
    public static List<Contact> findContacts(String searchKey) {
        if (!string.isBlank(searchKey)){
            String key = '%' + searchKey + '%';
            return [SELECT Id, Name, Title, Phone, Email, Picture__c FROM Contact WHERE Name LIKE :key LIMIT 10];
        }
        return new List<Contact>();
    }

    // @AuraEnabled(cacheable=true) //used in RM One Pager - lwc
    // public static List<Contact> getContactList_RoleBased(string accountId) {
    //     List<Contact> result  = new List<Contact>();
    //     if (String.isBlank(accountId)) return result;
    //     //based on Kevin's SOQL statement and DO NOT USE Contact.Current_Principal_Of_This_School__c
    //     result  =  [SELECT Id, Name, FirstName, LastName, Business_Role__c, accountId, Email, account.Name, account.moe_school_id__c,account.MoE_Site_ID_Lookup__r.name, Title, Phone, Picture__c FROM Contact where AccountId =: accountId AND Inactive_Contact_Record__c = FALSE];
    //     // List<Contact> result  = new List<Contact>();
    //     // result = [SELECT Id, Name, Title, Phone, Email, Picture__c, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: accountId 
    //     // AND (Current_Principal_Of_This_School__c = true OR Business_Role__c IN ('ICT Leader', 'External ICT'))
    //     // AND Inactive_Contact_Record__c = false
    //     // ORDER BY Current_Principal_Of_This_School__c Desc, Name
    //     // ];
    //     return result;
    // }        
      
    // @AuraEnabled(cacheable=true) //used in RM One Pager - lwc
    // public static String getContactList_RoleBased(string accountId) {
    //     List<ContactRolesWrapper> result  = new List<ContactRolesWrapper>();

    //     if (String.isBlank(accountId)) return JSON.serialize(result);
             
    //     List<AccountContactRelation> relationships =  [SELECT ContactId, Contact.Name, Contact.FirstName, Contact.LastName, Roles, accountId, Contact.Email, Contact.Title, Contact.Phone, Contact.Picture__c, account.Name, account.moe_school_id__c,account.MoE_Site_ID_Lookup__r.name 
    //                 FROM AccountContactRelation
    //                 where  AccountId =: accountId AND IsActive = TRUE];
        
    //     for(AccountContactRelation relationship : relationships){
    //         ContactRolesWrapper contactRole = new ContactRolesWrapper();
    //         contactRole.account = new Account(
    //                                             Id = relationship.accountId,
    //                                             Name = relationship.account.Name, 
    //                                             MoE_School_ID__c = relationship.account.MoE_School_ID__c
    //                                             );
    //         contactRole.contact = new Contact(
    //                                             Id = relationship.contactId,
    //                                             FirstName = relationship.Contact.FirstName, 
    //                                             LastName = relationship.Contact.LastName,
    //                                             Email = relationship.Contact.Email,
    //                                             Title = relationship.Contact.Title, 
    //                                             Phone = relationship.Contact.Phone, 
    //                                             Picture__c = relationship.Contact.Picture__c
    //                                         );         
    //         contactRole.setRoles(relationship.Roles);  
    //         result.add(contactRole);                 
    //     }           

    //     return JSON.serialize(result);
    //     //return result;
    // } 

    @AuraEnabled(cacheable=true) //used in RM One Pager - lwc
    public static Map<String,List<Contact>> getContactList_RoleBased(string accountId) {
        // Map<String,List<Contact>> result  = new Map<String,List<Contact>>();

        // if (String.isBlank(accountId)) return result;
             
        // List<AccountContactRelation> relationships =  [SELECT ContactId, Roles FROM AccountContactRelation WHERE  AccountId =: accountId AND IsActive = TRUE];
        
        // Set<Id> Ids = new Set<Id>();
        // for(AccountContactRelation relationship : relationships){
        //     Ids.add(relationship.ContactId);
        // }

        // List<Contact> contacts = [SELECT Id, Name, FirstName, LastName, Business_Role__c, accountId, Email, account.Name, account.moe_school_id__c,account.MoE_Site_ID_Lookup__r.name, Title, Phone, Picture__c FROM Contact WHERE Id IN: Ids];
        // Map<Id, Contact> mapContact =  new Map<Id,Contact>(contacts);
        
        // for(AccountContactRelation relationship : relationships){
        //     if(!String.IsBlank(relationship.roles)){
        //         List<String> roles = relationship.roles.split(';');
        //         for (String role : roles){
        //             if(result.containsKey(role.toLowerCase())){ //use lowercase for js in lwc
        //                 result.get(role.toLowerCase()).add(mapContact.get(relationship.ContactId));
        //             } else {
        //                 result.put(role.toLowerCase(), new List<Contact>{mapContact.get(relationship.ContactId)});
        //             }
        //         }
        //     } else {
        //         if(result.containsKey('blank')){
        //             result.get('blank').add(mapContact.get(relationship.ContactId));
        //         } else {
        //             result.put('blank', new List<Contact>{mapContact.get(relationship.ContactId)});
        //         }
        //     }
        // }
        Map<string, List<Contact>> contactMap = getRoleBaseContacts(accountId);

        Map<String,List<Contact>> result  = new Map<String,List<Contact>>();
        for(String role : contactMap.keyset()){
            result.put(role.toLowerCase(), contactMap.get(role));
        }
        
        return result;
    } 
    

    @AuraEnabled()
    public static Contact getContact(Id contactId) {
        List<Contact> contacts =  [SELECT Id, FirstName, LastName, Name, Title, Phone, Email, Picture__c, Business_Role__c, Current_Principal_Of_This_School__c, AccountId, Account.Name FROM Contact WHERE Id =: contactId];
		if(!contacts.isEmpty()) return contacts[0] ;
        //return new Contact(); //return a new contact instead of null
        return null;
    }

    //!!!Only one method in a class can have the InvocableMethod annotation.
    //reference https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm
    @InvocableMethod(label='Update User of a Contact' description='using @future method to update a customer user when a customer contact is updated.')
    public static void updateUserOfContact(List<ID> ids) {
        String contactId = ids[0]; //default to first element
		updateUser_FortiPortal_fields(contactId);
    }

    @future
    public static void updateUser_FortiPortal_fields(string contactId){
        //get Contact with Account.Fortinet_Adom_Name__c
        Contact contact = [SELECT id, FortiPortal_Access__c, FortiPortal_User_Role__c, account.Fortinet_Adom_Name__c, account.Name FROM Contact WHERE id =: contactId LIMIT 1];

        List<User> users = [SELECT id, username, contactId, accountId, FederationIdentifier, FortiPortal_User_Role__c, FortiPortal_Customer_Name__c, Fortinet_Adom_Name__c, UserPermissionsFilteringPortalUser__c FROM User WHERE contactId =: contactId LIMIT 1];
        if(!users.isEmpty()) {
            User user = users[0] ;

            user.FederationIdentifier = user.username;
            user.Fortinet_Adom_Name__c = contact.account.Fortinet_Adom_Name__c;
            user.FortiPortal_User_Role__c = contact.FortiPortal_User_Role__c;

            user.FortiPortal_User_Role__c = (String.isEmpty(contact.FortiPortal_User_Role__c) ? 'Advanced' : contact.FortiPortal_User_Role__c); //before this custom field was created, existing 18,296 contact records will have null FortiPortal_User_Role__c. Therefore, default the value in user.FortiPortal_User_Role__c to be 'Advanced'

            user.UserPermissionsFilteringPortalUser__c	= contact.FortiPortal_Access__c;

            //user.FortiPortal_Customer_Name__c = (contact.FortiPortal_Access__c ? 'spark.co.nz' : '');
            user.FortiPortal_Customer_Name__c = (contact.FortiPortal_Access__c ? getFortiPortalCustomerName(contact.account.Name) : '');
            
            update user;
        }
        
    }

    public static string getFortiPortalCustomerName(string name){
        if (String.isBlank(name)){
            return '';
        }

        Integer[] chars = name.toLowerCase().getChars();
        Integer asciicode = chars[0];

        String label = Label.FilteringPortalCustomerNamesRange;
        //String label = '97,108,spark.co.nz;109,114,spark2.co.nz;115,122,spark3.co.nz;'; //from custom label
        
        List<String> mylist = label.split(';');
        for (string item : mylist){
            List<String> range = item.split(',');
            //system.debug('from ' + Integer.valueOf(range[0]) + '    to ' + Integer.valueOf(range[1]) + '  return: ' + range[2]);    
            if (asciicode >= Integer.valueOf(range[0]) && asciicode <= Integer.valueOf(range[1])){
            	return range[2];
            }
        }
        return 'spark3.co.nz'; //out of range; by default
    }

    @AuraEnabled() //using cacheable=true will cause error LIMIT_USAGE_FOR_NS   Number of DML statements: 1 out of 0 ******* CLOSE TO LIMIT
    public static Contact updateContactPictureURL(Map<string, object> fieldsMap ) {
        system.debug('>>>>> fieldsMap = ' + JSON.serializePretty(fieldsMap));
        Contact contact = new Contact();
        contact.Id = String.valueOf(fieldsMap.get('id'));
        contact.Picture__c = String.valueOf(fieldsMap.get('pictureurl'));
        
        update contact; 
        system.debug('>>>>> update contact = ' + JSON.serializePretty(contact));
        
        String recordId = contact.Id;
        return [SELECT Id, Name, FirstName, LastName, Business_Role__c, accountId, Email, account.moe_school_id__c,account.MoE_Site_ID_Lookup__r.name, Title, Phone, Picture__c FROM Contact WHERE Id =: recordId];
        
    }
    

    @AuraEnabled(cacheable=true) //used in RM One Pager - lwc
    public static List<Map<String, String>> getContactList_WithUser(string accountId) {
        //Lesson learnt: must return Map<String, String> to LWC. Map<String, Object> will not work for LWC. Map must use Primitive—Boolean, Date, DateTime, Decimal, Double, Integer, Long, and String.
        //https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.apex
        
        // OLD --------------
        // List<Contact> contacts = [SELECT Id, Name, FirstName, LastName, Business_Role__c, accountId, Email, account.Name, account.moe_school_id__c,account.MoE_Site_ID_Lookup__r.name, Title, Phone, Picture__c, Email_Domain_Matched__c FROM Contact WHERE AccountId =: accountId  AND Inactive_Contact_Record__c = FALSE ORDER BY Name];
        // Map<Id,Contact> map1 = new Map<Id,Contact>(contacts);
        
        // NEW --------------
        List<AccountContactRelation> relationships =  [SELECT ContactId, Roles FROM AccountContactRelation WHERE  AccountId =: accountId AND IsActive = TRUE];
        
        Set<Id> Ids = new Set<Id>();
        for(AccountContactRelation relationship : relationships){
            Ids.add(relationship.ContactId);
        }

        List<Contact> contacts = [SELECT Id, Name, FirstName, LastName, Business_Role__c, accountId, Email, account.Name, account.moe_school_id__c,account.MoE_Site_ID_Lookup__r.name, Title, Phone, Picture__c FROM Contact WHERE Id IN: Ids ORDER BY Name];
        Map<Id, Contact> map1 =  new Map<Id,Contact>(contacts);

        for(AccountContactRelation relationship : relationships){
            map1.get(relationship.ContactId).Business_Role__c = relationship.Roles;//use the old custom field to transport data only. This is useful in contatTile.js
        }
        
        return mapContactToUser(map1);
    }        

    @AuraEnabled(cacheable=true) //used in RM One Pager - lwc
    public static List<Map<String, String>> getContact_WithUser(string contactId) {
        //Lesson learnt: must return Map<String, String> to LWC. Map<String, Object> will not work for LWC. Map must use Primitive—Boolean, Date, DateTime, Decimal, Double, Integer, Long, and String.
        //https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.apex
        
        List<Contact> contacts = [SELECT Id, Name, FirstName, LastName, Business_Role__c, accountId, Email, account.Name, account.moe_school_id__c,account.MoE_Site_ID_Lookup__r.name, Title, Phone, Picture__c, Email_Domain_Matched__c FROM Contact WHERE id =: contactId];
        Map<Id,Contact> map1 = new Map<Id,Contact>(contacts);
        
        return mapContactToUser(map1);
    }    
    
    public static List<Map<String, String>> mapContactToUser(Map<Id,Contact> map1){
        List<User> users = [SELECT Id, contactId, name, username, IsActive, IsPortalEnabled, LastLoginDate, UserPermissionsSchoolReportingUser__c, UserPermissionsFilteringPortalUser__c,UserPermissionsNMSUser__c  FROM user WHERE contactId =: map1.keyset()];
        Map<Id,User> map2 = new Map<Id,User>();
        for (User user : users){
            map2.put(user.contactId, user);
        }
        
        List<Map<String, String>>  result = new List<Map<String, String>>();
        for (Id contactId : map1.keyset()){
            Map<String, String> mapx = new Map<String, String>();
            mapx.put('contactid', contactId);
            mapx.put('contactstring', JSON.serialize(map1.get(contactId)));
            mapx.put('userstring', JSON.serialize(map2.get(contactId)));
        
            result.add(mapx); //accumulate in list
        }

        return result;
    }

    
}