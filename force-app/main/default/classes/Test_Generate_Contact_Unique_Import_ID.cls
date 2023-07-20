@isTest
private class Test_Generate_Contact_Unique_Import_ID {
	//private static final String STANDARD_CONTACT_RECORD_TYPE_NAME = 'Provider';//n4l
   // private static final String STANDARD_ACCOUNT_RECORD_TYPE_NAME = 'Provider';//n4l
    private static final String STANDARD_CONTACT_RECORD_TYPE_NAME = 'School';//n4l
    private static final String STANDARD_ACCOUNT_RECORD_TYPE_NAME = 'School';//n4l
    
    //Constants that may need updating if changed in org
    private static final String STANDARD_USER_PROFILE_NAME = 'N4L Standard User';
    //private static final String STANDARD_CONTACT_RECORD_TYPE_NAME = 'Service Provider';
    //private static final String STANDARD_ACCOUNT_RECORD_TYPE_NAME = 'Service Provider';
   

	@isTest 
    static void testWithStandardUser() {
		
        //Generate Standard User
        ID standardUserProfileID = [
                SELECT 
                    ID 
                FROM 
                    Profile 
                WHERE 
                    Name=:STANDARD_USER_PROFILE_NAME
                LIMIT 
                    1
            ].ID;
        User newStandardUser = new User(
                ProfileID =  standardUserProfileID,
                Username = (math.random() + '@fake.invalid.testing'), 
                LastName = ('testLName' + math.random()), 
                Email = (math.random() + '@fake.invalid.testing'), 
                Alias = String.valueOf(math.random()).right(6), 
                CommunityNickname = ('testComName' + math.random()), 
                TimeZoneSidKey = 'Pacific/Auckland', 
                LocaleSidKey = 'en_GB', 
                EmailEncodingKey = 'UTF-8', 
                LanguageLocaleKey = 'en_US'
            );
        insert newStandardUser;
        

        System.runAs(newStandardUser) {
            //Insert a contact parent acount
            ID accountRecordTypeID = [
                    SELECT 
                        Id 
                    FROM 
                        RecordType 
                    WHERE 
                            SObjectType = 'Account' 
                        AND Name = :STANDARD_ACCOUNT_RECORD_TYPE_NAME
                    LIMIT 
                        1
                ].ID;
            Account parentAccount = new Account(
                    RecordTypeId = accountRecordTypeID,
                    Name = 'TestAccountName'
                );
            insert parentAccount;



            //Insert a few contacts
            ID contactRecordTypeID = [
                    SELECT 
                        Id 
                    FROM 
                        RecordType 
                    WHERE 
                            SObjectType = 'Contact' 
                        AND Name = :STANDARD_CONTACT_RECORD_TYPE_NAME
                    LIMIT 
                        1
                ].ID;

            List<Contact> contactsToInsert = new List<Contact>();
            for(Integer contactCounter = 1; contactCounter <= 5; contactCounter++) {
                contactsToInsert.add(new Contact(
                        AccountID = parentAccount.ID,
                        //RecordTypeId = contactRecordTypeID,//n4l
                        FirstName = ('testFName'),
                        Email='generatecontacttest@n4l.co.nz',
                        LastName = ('testLName')
                    ));
            }
            insert contactsToInsert;


            //Re-query the contacts, and check that their Unique Import IDs have been populated, are 32 chars long, and are unique
            List<Contact> contactsToCheck = [
                    SELECT
                        ID,
                        Unique_AutoNumber__c,
                        Unique_Import_ID__c
                    FROM
                        Contact
                    WHERE
                        ID in :(new Map<ID,Contact>(contactsToInsert)).keySet()
                ];

            Set<String> uniqueGuids = new Set<String>();
            for(Contact contactToCheck : contactsToCheck) {
                System.assert(
                        contactToCheck.Unique_Import_ID__c != null,
                        'Unique Import ID was null, and should not have been'
                    );
                System.assert(
                        contactToCheck.Unique_Import_ID__c.length() == 32,
                        'Unique Import ID length was not 32 chars'
                    );
                uniqueGuids.add(contactToCheck.Unique_Import_ID__c);
            }

            System.assert(contactsToCheck.size() == uniqueGuids.size());
        }
	}
	
}