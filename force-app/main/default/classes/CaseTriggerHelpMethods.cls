public class CaseTriggerHelpMethods {
 static Id tsoRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('TSO Case').getRecordTypeId();
@future
      public static void linkDeviceToTSOCase (Map<Id,Id> caseAccountMap)
    {
    Map<id,set<id>> accountCaseSet= new Map<id,set<id>>();  
    List<Device__c>  updateDevList = new List<Device__c>();
    system.debug('test'+caseAccountMap.size());
    
    
    //for(integer i=0;i<caseAccountMap.size();i++){
    	for(id cid:caseAccountMap.keyset()){
    	
       if(accountCaseSet.containskey(caseAccountMap.get(cid))){
       	
       	  accountCaseSet.get(caseAccountMap.get(cid)).add(cid);
       
       }else{
          set<id> newSet = new set<id>();
          newSet.add(cid);
          accountCaseSet.put(caseAccountMap.get(cid),newSet);
       
       }
    
    }
    
    List<Device__c> deviceList = new List<Device__c>([Select d.RecordTypeId, d.Provision_Case__c, d.Id, d.Customer__c From Device__c d where d.Customer__c in:caseAccountMap.values()]);
    if(deviceList.size()>0){
    
      for(Device__c d:deviceList){
      	 for(id cid:accountCaseSet.get(d.Customer__c)){
      	      if(d.Provision_Case__c==null){
      	         d.Provision_Case__c=cid;
      	      }
      	 }
      
      updateDevList.add(d);
      }
    
    
    }
    
    if(updateDevList.size()>0){
    
     update updateDevList;
    }
}
    public static boolean AccountHasNoTSOCase (Id accountId){
        List<Case> TSOList = new List<Case>();
        //hardcode fix TSOList = [select Id,accountId from case where recordtypeid=:'01290000000SzFa' and accountid=:accountId];
        TSOList = [select Id,accountId from case where recordtypeid=:tsoRT and accountid=:accountId];
        return TSOList.isEmpty();
        
    }
    
}