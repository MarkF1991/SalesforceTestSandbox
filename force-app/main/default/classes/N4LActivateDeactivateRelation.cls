/**
 * @Date               : March 22, 2021
 * @Description        : deactivates and activates contact and user
 * @Author             : Heidi Tang (heitang@deloitte.com)
**/
public without sharing class N4LActivateDeactivateRelation {

    @InvocableMethod(label='Contact activation' description='contact activation and deactivation' category='AccountContactRelation')
    public static void flowActivateDeactivateRelation(List<AccountContactRelation> accRelationList) {
        if(accRelationList != null) {
            AccountContactRelation accRelation = [SELECT isActive,Id,ContactId,AccountId,Contact.Email
                                                    FROM AccountContactRelation WHERE Id = :accRelationList[0].Id];

            if(accRelation.isActive) {
                if(accRelation.Contact.Email.contains('.former')){
                    String oldEmail = accRelation.Contact.Email.substringBefore('.former');
                    Contact updatedContact = new Contact(Id=accRelation.ContactId,Email=oldEmail);
                    updatedContact.Original_Email__c = oldEmail;
                    updatedContact.Inactive_Contact_Record__c = false;
                    update updatedContact;
                }                
            } else {
                List<AccountContactRelation> contactRelationList = [SELECT Id,isActive,ContactId FROM AccountContactRelation 
                                                                    WHERE ContactId = :accRelation.ContactId AND isActive = true];
                
                if(contactRelationList.isEmpty()) {
                    String former = '%' +'.former'+ '%';
                    List<AccountContactRelation> conList = [SELECT Id,Contact.Email FROM AccountContactRelation WHERE Contact.Email LIKE :former AND AccountId = :accRelation.AccountId];
    
                    Integer ctr = 1;
    
                    for(AccountContactRelation con : conList) {
                        if(Integer.valueOf(con.Contact.Email.substringAfter('.former')) >= ctr){
                            ctr = Integer.valueOf(con.Contact.Email.substringAfter('.former'))+1;
                        }
                    }
    
                    Contact updatedContact = new Contact(Id=accRelation.ContactId,Email=accRelation.Contact.Email+'.former'+ctr);
                    updatedContact.Original_Email__c = accRelation.Contact.Email;
                    updatedContact.Inactive_Contact_Record__c = true;
                    update updatedContact;    
                }
            }
        }
    }
}