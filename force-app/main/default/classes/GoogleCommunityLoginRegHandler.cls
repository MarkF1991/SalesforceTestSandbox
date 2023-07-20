/**
* @author Ben Edwards (ben@cloudinit.nz)
* @date 2017-10-02
* @description Registration Handler to handle logins and signups via Google from external customers
*
* CHANGE LOG
**/
global class GoogleCommunityLoginRegHandler implements Auth.RegistrationHandler {

    // Custom Exception to return a nice error message to the user
    class GoogleCommunityLoginRegHandlerException extends Exception {}

    // Disable any creation of users.
    // We're just using this service to login to existing user accounts
    // This method is not even called, it's only here because it has to be included
    // as part of implementing Auth.RegistrationHandler
    global Boolean canCreateUser(Auth.UserData data) {
        return false;
    }

    // We don't want to create new users, so we'll use this method to attempt
    // to link the user's Google Account to an existing User record in the system.
    global User createUser(Id portalId, Auth.UserData data){

        // Attempt to link to an existing user
        try {

            // First attempt to match on Username
            User existingUser = [SELECT Id FROM User WHERE Username = :data.email][0];
            return existingUser;
        }
        // If we couldn't find them on username, try on email
        catch (Exception ex) {

            try {

                // First attempt to match on Username
                User existingUser = [SELECT Id FROM User WHERE Email = :data.email][0];
                return existingUser;
            }
            catch (Exception ex2) {

                throw new GoogleCommunityLoginRegHandlerException(
                    String.format(Label.Support_Hub_Login_No_User_Found_Error, new List<String>{data.email})
                );
                
            }   
            
        }
        //By Jason unreachable statement : return null;
    }

    // Don't bother updating users
    // This is used if we want to continually sync Google details to the Salesforce User
    // record. Eg. Name, email etc. But let's just use the Google service for login only
    // and not bother syncing Google details to Salesforce.
    global void updateUser(Id userId, Id portalId, Auth.UserData data){}
}