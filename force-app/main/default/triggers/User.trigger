trigger User on User (after insert) {

	if(trigger.isInsert){
		if(trigger.isAfter){
			flowTriggerHelper.runAddNewlyCreatedICTUserstoExistingGroups(trigger.new);
		}
	}
}