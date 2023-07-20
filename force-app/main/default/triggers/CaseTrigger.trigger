/**
 * OpportunityTrigger.trigger
 * Passes the trigger context to trigger handlers for processing.
 * No logic is performed locally in this trigger.
 * @author Logan Moore (Trineo)
 */
trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  
  new CaseUpdateAccountStatus().run();

}