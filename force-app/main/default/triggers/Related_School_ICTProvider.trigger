trigger Related_School_ICTProvider on Related_School_ICTProvider__c (before insert,after insert, after update) {

	if(trigger.isAfter){
		flowTriggerHelper.runICTProviderlows(trigger.new,trigger.oldMap);
	}
}