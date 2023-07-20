public with sharing class AccountController {

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccessibleSchools(id userid){
        User user = AccountController.getUser(userid); //TODO: refactor
        List<Account> schools = new List<Account>();
        if(user != null && user.UserPermissionsSchoolReportingUser__c) { //TODO: refactor
        List<Account> accounts = AccountController.getAccessibleAccounts(userid);
        
        for (Account account : accounts) {
            if(account.uuid__c != null) {
                schools.add(account);
            }
        }
        }//TODO: refactor

        return schools;
    }

    @AuraEnabled(cacheable=true)
    public static User getUser(id userid) {//TODO: refactor
        List<User> users = [SELECT id, FirstName, LastName, username, LastLoginDate, IsActive, IsPortalEnabled, ContactId, Contact.AccountId, Contact.Account.Type, UserType, ProfileId, Profile.Name, UserPermissionsSchoolReportingUser__c  FROM User WHERE id =: userid AND IsActive =: TRUE];
        if(!users.isEmpty()) {
            return users[0];
        }

        return null;
    }//TODO: refactor

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccessibleAccounts(id userid){
        List<Account> accounts = new List<Account>();
        List<Account> result = new List<Account>();
        List<User> users = [SELECT id, FirstName, LastName, username, LastLoginDate, IsActive, IsPortalEnabled, ContactId, Contact.AccountId, Contact.Account.Type, UserType, ProfileId, Profile.Name  FROM User WHERE id =: userid AND IsActive =: TRUE];
        if(!users.isEmpty()){
            User user = users[0];
            if (user.UserType == 'PowerCustomerSuccess' ){ //customer community plus users
                result = [SELECT id, Name, uuid__c FROM Account WHERE id IN 
                            (SELECT School__c
                            FROM Related_School_ICTProvider__c
                            WHERE ICT_Provider__c =: user.contact.accountId
                            AND Status__c = 'Current'
                            AND School_Data_Sharing_on_Portal_Authorised__c = true)
                        ];
                return result; //Related_School_ICTProvider__c records specified individual school and remote sites that an ICT Provider has access to

            } else if (user.UserType == 'CspLitePortal'){ //customer community users
                if(user.Contact.Account.Type == 'School ICT Provider') { 
                    //customer community user belonged to ICT Provider
                    //it depends on business or marketting approach on whether we want to use school reporting to up sell to ICT Provider to upgrade Customer Community license to Customer Community Plus license.
                    result = [SELECT id, Name, uuid__c FROM Account WHERE id IN 
                                (SELECT School__c
                                FROM Related_School_ICTProvider__c
                                WHERE ICT_Provider__c =: user.contact.accountId
                                AND Status__c = 'Current'
                                AND School_Data_Sharing_on_Portal_Authorised__c = true)
                            ];
                    return result; //Related_School_ICTProvider__c records specified individual school and remote sites that an ICT Provider has access to
                } else {
                    //customer community user under a school 
                    //string accountid = user.Contact.AccountId;
                    accounts = [SELECT id, Name, uuid__c FROM Account WHERE id =: user.Contact.AccountId];
                }

            } else if  (user.UserType == 'Standard'){ //internal users: show all schools
                accounts = [SELECT id, Name, uuid__c FROM Account WHERE recordtype.name = 'school' ];
            }

            if(!accounts.isEmpty()){
                List<id> parentIds = new List<id>();
                for(Account account : accounts){
                    parentIds.add(account.id); //prepare a list of parent account ids for soql query
                    result.add(account); //add to result collection now.
                }
                //soql query to get a list of remote site accounts
                List<Account> sites = [SELECT id, Name, uuid__c FROM Account WHERE ParentId IN : parentIds ];
                if(!sites.isEmpty()){
                    for(Account account : sites){
                        result.add(account); //add remote site acconts to result collection
                    }
                }
            }
    	}
        return result;
	}

    @AuraEnabled(cacheable=true)
    public static Account getAccount_uuid(string uuid){
        List<Account> accounts = [SELECT id, Name, OwnerId, uuid__c, BillingAddress, BillingCity, BillingCountry, BillingCountryCode, BillingGeocodeAccuracy, BillingLatitude, BillingLongitude, BillingPostalCode, BillingState, BillingStateCode, BillingStreet, ShippingAddress, ShippingCity, ShippingCountry, ShippingCountryCode, ShippingGeocodeAccuracy, ShippingLatitude, ShippingLongitude, ShippingPostalCode, ShippingState, ShippingStateCode, ShippingStreet FROM Account WHERE uuid__c =: uuid ];
        Account result = new Account();
        if(!accounts.isEmpty()){
            result = accounts[0];
    	}
        return result;
	}

    @AuraEnabled(cacheable=true)
    public static List<Account> findAccounts(String searchKey) {
        String key = '%' + searchKey + '%';
        return [SELECT id, Name, ShippingStreet, ShippingCity, Owner.Name FROM Account WHERE Name LIKE :key LIMIT 10];
    }

    //Updated November-2022 by Carolyn Hayward (Micado) to include CC_Wireless_AP_Make__c
    @AuraEnabled(cacheable=true)
    public static Account getAccount(string accountId){
        List<Account> accounts = [SELECT id, Name, OwnerId, uuid__c, MoE_School_ID__c, CC_MOU_Received_Date__c, CC_Wireless_AP_Make__c FROM Account WHERE Id =: accountId];
        Account result = new Account();
        if(!accounts.isEmpty()){
            result = accounts[0];
    	}
        return result;
	}

    @AuraEnabled(cacheable=true)
    public static Event getNHRFeedbackResponses(string accountId){
        List<Event> events = [SELECT id, subject, EndDateTime, whatId FROM event WHERE whatid =: accountId AND subject = 'GetFeedback Survey Response: ATP Form for NHR'];
        Event event = new Event();
        if(events.size()>0){ 
            event = events[0];
        } 
        return event;
    }
    
    @AuraEnabled(cacheable=true)
    public static Event getNSEFeedbackResponses(string accountId){
        List<Event> events = [SELECT id, subject, EndDateTime, whatId FROM event WHERE whatid =: accountId AND subject = 'GetFeedback Survey Response: ATP Form for NSE'];
        Event event = new Event();
        if(events.size()>0){ 
            event = events[0]; 
        } 
        return event;
    }

    @AuraEnabled(cacheable=true)
    public static Event getEmailProtectionFeedbackResponses(string accountId){
        List<Event> events = [SELECT id, subject, EndDateTime, whatId FROM event WHERE whatid =: accountId AND subject = 'GetFeedback Survey Response: Email Protection ATP'];
        Event event = new Event();
        if(events.size()>0){ 
            event = events[0]; 
        } 
        return event;
    }

    @AuraEnabled(cacheable=true)
    public static Event get_IEM_ATP_Link_Responses(string accountId){
        List<Event> events = [SELECT id, subject, EndDateTime, whatId FROM event WHERE whatid =: accountId AND subject = 'GetFeedback Survey Response: Dataloggers ATP'];
        Event event = new Event();
        if(events.size()>0){ 
            event = events[0]; 
        } 
        return event;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<string> get_ICT_Providers(string accountId){
        List<Related_School_ICTProvider__c> ictProviders = [SELECT Id, School__c, ICT_Provider__r.Name, ICT_Provider__c, Relationship__c, Status__c FROM Related_School_ICTProvider__c WHERE School__c =: accountId];
        List<string> ictProviderCollection = new List<string>();

        for(Related_School_ICTProvider__c ictProvider : ictProviders){
            if(ictProvider.status__c == 'Current'){
                ictProviderCollection.add(ictProvider.ICT_Provider__r.Name + ' . ' + ictProvider.Relationship__c);
            }else{
                
            }
        }
        return ictProviderCollection;
    }

    //Added 22/06/2023 by Carolyn Hayward (Micado) - Get the latest ER Onboarding Opportunity for ER ATP link (MNTC-1349) 
    @AuraEnabled(cacheable=true)
    public static String get_ER_Opportunity_Id(string accountId){
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity 
            WHERE Campaign.Programme__c = 'Equipment Replacement and Secure Access' AND StageName != 'Committed' AND Type = 'Onboarding' AND AccountId = :accountId 
            ORDER BY CreatedDate DESC];
        Opportunity opportunity = new Opportunity();
        if(opportunities.size()>0){ 
            opportunity = opportunities[0]; 
            return opportunity.Id;
        } 
        return null;
    }
}