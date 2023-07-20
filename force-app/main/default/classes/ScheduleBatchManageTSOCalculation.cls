/**
ScheduleBatchManageTSOCalculation smcds = new ScheduleBatchManageTSOCalculation();
string sch='0 0 10 * * ?';
system.schedule('ScheduleBatchManageTSOCalculation', sch, smcds);
**/


global class ScheduleBatchManageTSOCalculation implements Schedulable {
    public static Id tsoRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('TSO Case').getRecordTypeId();
	public Boolean bolIsTest = false;
	// NOTE: The format for this string is 'YYYY-MM-DDTHH:MM:SSz' per API docs
	public String strProcessingDateTime;

	global void execute(SchedulableContext SC){
		executeOneOff();
	}

	public void executeOneOff() {
		BatchManageTSOCalculation bmcds = new BatchManageTSOCalculation();
		String strTestLimit = '';
		if (bolIsTest) {
			System.debug(LoggingLevel.INFO, '## Testing mode - query will be limited to 50 records');
			strTestLimit = 'LIMIT 50';
		}
        /* replace hard code
		bmcds.query =	'SELECT Id, RecordTypeId, TCNZ_Work_Order_Submitted_Date__c, TCNZ_Work_Order_Accepted_Date__c, ' +
						'TCNZ_Work_Order_Acceptance_Days_Lapsed__c, BusinessHoursId,' +
						' LFC_Order_Submitted_Date__c, LFC_Order_Submission_Days_Lapsed__c,' +
						' LFC_Access_RFS_Date__c, LFC_Access_RFS_Days_Lapsed__c, Site_Audit_Completion_Days_Lapsed__c,' +
						' SoW_Submitted_Date__c, Audit_Completed_Date__c' +
						' FROM Case' +
						' WHERE RecordTypeId ='+'\''+'01290000000SzFa'+'\''+
						' And isclosed=false ' +
						strTestLimit;
       */
        bmcds.query =	'SELECT Id, RecordTypeId, TCNZ_Work_Order_Submitted_Date__c, TCNZ_Work_Order_Accepted_Date__c, ' +
						'TCNZ_Work_Order_Acceptance_Days_Lapsed__c, BusinessHoursId,' +
						' LFC_Order_Submitted_Date__c, LFC_Order_Submission_Days_Lapsed__c,' +
						' LFC_Access_RFS_Date__c, LFC_Access_RFS_Days_Lapsed__c, Site_Audit_Completion_Days_Lapsed__c,' +
						' SoW_Submitted_Date__c, Audit_Completed_Date__c' +
						' FROM Case' +
						' WHERE RecordTypeId =: tsoRT'+
						' And isclosed=false ' +
						strTestLimit;
        
		system.debug('xxxxxxxxx='+bmcds.query);				
		Database.ExecuteBatch(bmcds);
	}
}