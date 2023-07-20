public class SandboxRefresh_ModifyActEmail_Ctl implements Database.Batchable<sObject>{
    Public Database.QueryLocator start(Database.BatchableContext BC){
        //exclude all accounts without email and emails that are already modified
        String query = 'select Id, Email__c from Account';
        //return results to process only if the current instance is a sandbox or a test is running
        Boolean sandbox;
        for(Organization o:[Select isSandbox from Organization limit 1]){
            sandbox = o.isSandbox;
        }
        if(sandbox == TRUE){
            return Database.getQueryLocator(query);
        }  else {
            return Database.getQueryLocator(query + ' limit 0');
        }
    }
    
    Public void execute(Database.BatchableContext BC, List<Account> accounts){
        List<Account> ListToUpdate = new List<Account>();
        if(accounts!=null){
            for(Account a : accounts){
                if(a.Email__c != null && ! a.Email__c.contains('.invalid')){
                a.Email__c += '.invalid';
                ListToUpdate.add(a);  
                    }
            }
        }
        if(ListToUpdate.size()>0){
            //Update all Accounts that can be updated
            database.update(ListToUpdate,false);
        }
    }
    
    Public void finish(Database.BatchableContext BC){
        system.debug('***** SandboxRefresh_ModifyActEmail_Ctl is complete.');    
    }
}