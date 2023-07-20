/**
1. TCNZ Work Order Acceptance Days Lapsed - Business days in between TCNZ Work Order Submitted Date and TCNZ Work Order Accepted Date.
2. LFC Order Submission Days Lapsed - Business days in between TCNZ Work Order Accepted Date and LFC Order Submitted Date.
3. LFC Access RFS Days Lapsed - Business days in between LFC Order Submitted Date And LFC Access RFS Date.
4. Site Audit Completion Days Lapsed - Business days in between Audit SoW Submitted Date And Audit Completed Date.
**/

global class BatchManageTSOCalculation implements Database.Batchable<sObject> {
    public static Id tsoRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('TSO Case').getRecordTypeId();
	global string query;
	global List<case> updateCaseList = new List<case>();
	global database.querylocator start(Database.BatchableContext BC){
        System.debug(LoggingLevel.INFO, '## Query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Case> scope){
        //Get the default business hours  TCNZ_Work_Order_Acceptance_Days_Lapsed__c TCNZ_Work_Order_Submitted_Date__c;TCNZ_Work_Order_Accepted_Date__c
          BusinessHours defaultHours = [select Id,MondayStartTime,MondayEndTime from BusinessHours where IsDefault=true];
          system.debug(defaultHours.MondayStartTime +'xxxxx'+defaultHours.MondayEndTime);
          system.debug(string.valueOf(double.valueOf(string.valueOf(defaultHours.MondayEndTime).substringBefore(':'))-double.valueOf(string.valueOf(defaultHours.MondayStartTime).substringBefore(':'))) +'xxxxxxxxxxx');
          double mondayHours = double.valueOf(string.valueOf(defaultHours.MondayEndTime).substringBefore(':'))-double.valueOf(string.valueOf(defaultHours.MondayStartTime).substringBefore(':'));
          for(case c: scope){
          	  boolean ischanged = false;
              Id hoursToUse = c.BusinessHoursId!=null?c.BusinessHoursId:defaultHours.Id;
              if(c.TCNZ_Work_Order_Submitted_Date__c !=null ){
                 double newdays = businessDayCalculation (hoursToUse,c.TCNZ_Work_Order_Submitted_Date__c,c.TCNZ_Work_Order_Accepted_Date__c,mondayHours);
                 if(c.TCNZ_Work_Order_Acceptance_Days_Lapsed__c == null || (newdays-c.TCNZ_Work_Order_Acceptance_Days_Lapsed__c)>0.1 ){
                   c.TCNZ_Work_Order_Acceptance_Days_Lapsed__c=newdays;
                   ischanged= true;
                 }
              }
              
              if(c.TCNZ_Work_Order_Accepted_Date__c !=null ){
                 double newdays = businessDayCalculation (hoursToUse,c.TCNZ_Work_Order_Accepted_Date__c,c.LFC_Order_Submitted_Date__c,mondayHours);
                 if(c.LFC_Order_Submission_Days_Lapsed__c == null || (newdays-c.LFC_Order_Submission_Days_Lapsed__c)>0.1 ){
                   c.LFC_Order_Submission_Days_Lapsed__c=newdays;
                   ischanged= true;
                 }
              }
              
              if(c.LFC_Order_Submitted_Date__c !=null ){
                 double newdays = businessDayCalculation (hoursToUse,c.LFC_Order_Submitted_Date__c,c.LFC_Access_RFS_Date__c,mondayHours);
                 if(c.LFC_Access_RFS_Days_Lapsed__c == null || (newdays-c.LFC_Access_RFS_Days_Lapsed__c)>0.1 ){
                   c.LFC_Access_RFS_Days_Lapsed__c=newdays;
                   ischanged= true;
                 }
              }
              
              if(c.SoW_Submitted_Date__c !=null ){
                 double newdays = businessDayCalculation (hoursToUse,c.SoW_Submitted_Date__c,c.Audit_Completed_Date__c,mondayHours);
                 if(c.Site_Audit_Completion_Days_Lapsed__c == null || (newdays-c.Site_Audit_Completion_Days_Lapsed__c)>0.1 ){
                    c.Site_Audit_Completion_Days_Lapsed__c=newdays;
                   ischanged= true;
                 }
              }
          // update case if any one of above 4 has been changed.     
          if(ischanged==true){
          updateCaseList.add(c);
          }
          }   
          
          try {
    
    Database.SaveResult[] results = Database.update(updateCaseList,false); 
    if (results != null){
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                Database.Error[] errs = result.getErrors();
                for(Database.Error err : errs)
                    System.debug(err.getStatusCode() + ' - ' + err.getMessage());
 
            }
        }
    }
 
} catch (Exception e) {
    System.debug(e.getTypeName() + ' - ' + e.getCause() + ': ' + e.getMessage());
}
    
    }
    private double businessDayCalculation (Id hoursToUse,datetime start,datetime finish,double mondayHours){
    	
    double diff=0.00;	
    if(finish!=null){
                    //The diff method comes back in milliseconds, so we divide by 3600000 *24 to get days.
       diff=(double) BusinessHours.diff(hoursToUse, start, finish)/(3600000.00*mondayHours);
    }else{
       diff=(double) BusinessHours.diff(hoursToUse, start, system.now())/(3600000.00*mondayHours); 
                 
                 } 
    	
     
    return diff;
    }
    
    global void finish(Database.BatchableContext BC){}
}