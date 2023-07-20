trigger Generate_Contact_Unique_Import_ID on Contact (after insert) {

    List<Contact> contactsToUpdate = new List<Contact>();

    for (Contact currContact: Trigger.new){
        
        //Seed is unique provided the AutoNumber is not rebased using the same naming scheme:
        //    i.e. if the Contact AutoNum exceeds 9999999999 and needs to be reset to 0.
        //    If rebasing is necessary - recommend rebasing with the addition of a String at the Start:
        //      - As at 08/10/2013 the AutoNumber format was {0000000000}
        //      - If this ever needs rebasing the AutoNumber format was {0000000000}, 
        //          and should be changed to (e.g.) V2-{0000000000}
        //      
        //EVEN in the case where AutoNumber is rebased improperly, further uniqueness is provided 
        //  to the seed by concatenating the AutoNumber with a Long i.e. in the range 
        //  -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807 (inc).
        //  As such, even if the AutoNumber 1 was used twice, there is only a 1 in 1.84467440737096E19
        //  of collision - impossible for all practical purposes.
        //  
        //As always, this is limited by the Pigeonhole Principle - as this is 32 hex digits wide 
        //  that gives 3.402823669209387e+38 different values - again making a collision impossible 
        //  for practical purposes
        
        Contact contactForUpdate = new Contact(ID = currContact.ID);

        Blob seed = Blob.valueOf(currContact.Unique_AutoNumber__c + String.valueOf(Crypto.getRandomLong()));
        String guid = EncodingUtil.ConvertTohex(Crypto.generateDigest('MD5',seed));
        contactForUpdate.Unique_Import_ID__c = guid;

        contactsToUpdate.add(contactForUpdate);
    }

    update contactsToUpdate;
}