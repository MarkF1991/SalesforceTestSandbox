/**
 * When sandboxes refresh, all users email addresses have .invalid appended to them,
 * This is a safety feature to remove .invalid from their email address.
 * This class reverts active admin users' email addresses by removing the .invalid
 */
public with sharing class SandboxRefresh_RevertUserEmail_Ctl implements Database.Batchable<SObject> {

    public Database.QueryLocator start( Database.BatchableContext context ) {
        return Database.getQueryLocator( [SELECT id, email FROM User WHERE isActive = true AND profile.name = 'N4L System Administrator']);
    }

    public void execute( Database.BatchableContext context, List<User> users ) {

        for ( User u : users ) {

            System.debug( 'user sandbox email: ' + u.email );

            u.email = u.email.remove('.invalid');

            System.debug( 'user reverted email: ' + u.email );

        }

        update users;

    }

    public void finish( Database.BatchableContext context ) {

    }

}