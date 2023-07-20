/**
 * CaseUpdateAccountStatus.cls
 * extends TriggerHandler.cls
 * Updates the status of an Account according to changes in the
 * status of a case belonging to the Account.
 * @author Logan Moore (Trineo)
 */
public class CaseUpdateAccountStatus extends TriggerHandler {
    private static Id tsoRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('TSO Case').getRecordTypeId();
    private static Id ttRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Transition Team Case').getRecordTypeId();
    private List<Case> TTcaseNew = new List<Case>() ;
    private List<Case> caseNew;
    private Map<Id,Case> caseOldMap;
    private Map<Id,Account> accountMap;
    private List<Account> accountUpdates;
    private Map<Id,Id> caseAccountMap;
    private List<Id> accountIds;
    public void init() {
        caseNew = (List<Case>)Trigger.new;
        caseAccountMap= new  Map<Id,Id> ();
        // only get the oldMap for update context
        if (trigger.isUpdate) {
            caseOldMap = (Map<Id,Case>)Trigger.oldMap;
        }
        // build map of related accounts
        accountIds = new List<Id>();
        
        for (Case c : caseNew) {
            accountIds.add(c.AccountId);
            caseAccountMap.put(c.Id, c.AccountId);

        }
        accountMap = new Map<Id,Account>([SELECT School_Migration_Status__c FROM Account WHERE Id IN :accountIds]);
        accountUpdates = new List<Account>();
    }
    protected override void beforeInsert() {
        init();
        for (Case c : caseNew) { 
        //hardcode fix: if(c.accountid!=null && c.RecordTypeId=='01290000000SzFa' && !CaseTriggerHelpMethods.AccountHasNoTSOCase(c.accountid))
        if(c.accountid!=null && c.RecordTypeId==tsoRT && !CaseTriggerHelpMethods.AccountHasNoTSOCase(c.accountid)) 
        {
            c.addError('There is an existing TSO case. Only 1 TSO case allowed per school.');
        }
        }
        
    }
    // afterinsert and afterUpdate trigger was replaced by a new process builder process " TSO Case Status Updated"
   protected override void afterInsert() {
        init();
        for (Case c : caseNew) {
            if (isTSO(c) && accountMap.containsKey(c.AccountId)) {
                CaseTriggerHelpMethods.linkDeviceToTSOCase(caseAccountMap); 
            }
 /*               
                Account a = accountMap.get(c.AccountId);
                if (a.School_Migration_Status__c == '4-Contract Signed' && c.Status == 'Under Action') {
                    a.School_Migration_Status__c = '5-In Transition';
                    accountUpdates.add(a);
                }
                else if (a.School_Migration_Status__c == '5-In Transition' && c.TCNZ_Work_Stream_Status__c == 'CLNE Installed with Service Configuration') {
                    a.School_Migration_Status__c = '6-Connected';
                    accountUpdates.add(a);
                }
                else if (a.School_Migration_Status__c == '6-Connected' && c.Status == 'Service Activated') {
                    a.School_Migration_Status__c = '7-In Use';
                    accountUpdates.add(a);
                }
            }
            
            if(isTT(c)){
                //Database.DMLOptions dmo = new Database.DMLOptions();
                //dmo.emailHeader.triggerUserEmail = true;
                //dmo.assignmentRuleHeader.useDefaultRule = true;
                //c.setOptions(dmo);
                TTcaseNew.add(new case(id=c.id));
            }
        }
        if (accountUpdates.size() > 0) {
            update accountUpdates;
        }
        if (TTcaseNew.size() > 0) {
            
             Database.DMLOptions dmo = new Database.DMLOptions();
             dmo.assignmentRuleHeader.useDefaultRule = true;
             try{
             Database.update(TTcaseNew, dmo);}
             catch(DmlException e){
             System.debug('The following exception has occurred: ' + e.getMessage());
             }
*/           
        }
}
/*
    protected override void afterUpdate() {
        init();
        for (Case c : caseNew) {
            if (isTSO(c) && accountMap.containsKey(c.AccountId)) {
                Account a = accountMap.get(c.AccountId);
                Case oldCase = caseOldMap.get(c.Id);
                if (a.School_Migration_Status__c == '4-Contract Signed' && oldCase.Status != 'Under Action' && c.Status == 'Under Action') {
                    a.School_Migration_Status__c = '5-In Transition';
                    accountUpdates.add(a);
                }
                else if (a.School_Migration_Status__c == '5-In Transition' && oldCase.TCNZ_Work_Stream_Status__c != 'CLNE Installed with Service Configuration' && c.TCNZ_Work_Stream_Status__c == 'CLNE Installed with Service Configuration') {
                    a.School_Migration_Status__c = '6-Connected';
                    accountUpdates.add(a);
                }
                else if (a.School_Migration_Status__c == '6-Connected' && oldCase.Status != 'Service Activated' && c.Status == 'Service Activated') {
                    a.School_Migration_Status__c = '7-In Use';
                    accountUpdates.add(a);
                }
            }
        }
        if (accountUpdates.size() > 0) {
            update accountUpdates;
        }
    }
*/
    
    private static Boolean isTSO(Case c) {
        return c.RecordTypeId == tsoRT;
    }
    private static Boolean isTT(Case c) {
        return c.RecordTypeId == ttRT;
    }

}