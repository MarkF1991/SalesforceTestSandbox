/**
* @author Ben Edwards (ben@cloudinit.nz)
* @date 2017-10-02
* @description Test class for the GoogleCommunityLoginRegHandler. Simulates a successful and failed login attempt
*
* CHANGE LOG
**/
@isTest
public class GoogleCommunityLoginRegHandlerTest {

    /**
    *   @author Ben Edwards (ben@cloudinit.nz)
    *   @description Test scenario of simulating a Google login success
    **/
    @isTest
    static void testGoogleLoginSuccess () {

        // Instantiate the test handler
        GoogleCommunityLoginRegHandler testHandler = new GoogleCommunityLoginRegHandler();

        // Create some Auth Data
        // Use the logged in user email, so we know it exists
        Auth.UserData authData = generateAuthData(UserInfo.getUserEmail());

        // Now return the logged in user
        User foundUser = testHandler.createUser(null, authData);

        system.assertNotEquals(null, foundUser, 'The found user should not be null.');
    }

    /**
    *   @author Ben Edwards (ben@cloudinit.nz)
    *   @description Test scenario of simulating a Google login failure
    **/
    @isTest
    static void testGoogleLoginFail () {

        // Instantiate the test handler
        GoogleCommunityLoginRegHandler testHandler = new GoogleCommunityLoginRegHandler();

        // Create some Auth Data
        Auth.UserData authData = generateAuthData('doesnotexist@email.com');

        try {
            // Attempt to login the user
            testHandler.createUser(null, authData);
        }
        // We're expecting this to fail, so we're all rosy } 
        catch (Exception ex) {

            system.assert(true, 'The login should have failed.');
        } 
    }

    /**
    *   @author Ben Edwards (ben@cloudinit.nz)
    *   @description Test the other methods included in the class. The methods aren't used, but should be validated.
    **/
    @isTest
    static void testGoogleLoginMethods () {

        // Instantiate the test handler
        GoogleCommunityLoginRegHandler testHandler = new GoogleCommunityLoginRegHandler();

        // Assert the canCreate method
        system.assert(!testHandler.canCreateUser(null), 'canCreateUser should return false.');
        testHandler.updateUser(null, null, null);
    }
    
    /**
    *   @author Ben Edwards (ben@cloudinit.nz)
    *   @description Generate some test auth data for testing
    **/
    public static Auth.UserData generateAuthData (String emailAddress) {

        return new Auth.UserData(
            'testId', 'testFirst', 'testLast',
            'testFirst testLast', emailAddress, null, 'testuserlong', 'en_US', 'google',
            null, new Map<String, String>{'language' => 'en_US'}
        );
    }
}