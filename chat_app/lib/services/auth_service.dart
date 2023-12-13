import 'package:Groupie/helper/helper_function.dart';
import 'package:Groupie/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/*
The code defines a class called AuthService and creates an instance of FirebaseAuth, which is used for authentication.
*/
class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  // login function
  /*
  defines a function loginWithUserNameAndPassword that takes an email and password as parameters. It attempts to sign in the user with the provided email and password using signInWithEmailAndPassword. If the sign-in is successful, it returns true. If there is an error, it catches the FirebaseAuthException and returns the error message.
  */
  Future loginWithUserNameAndPassword(String email, String password) async {
    try {
      User user = (await firebaseAuth.signInWithEmailAndPassword(
              email: email, password: password))
          .user!;
      if (user != null) {
        return true;
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // register function
  /*
  The code defines a function registerUserWithEmailAndPassword that takes a full name, email, and password as parameters. It attempts to create a new user with the provided email and password using createUserWithEmailAndPassword. If the user creation is successful, it calls the savingUserData function from the DatabaseService to update the user details in the database. Finally, it returns true. If there is an error, it catches the FirebaseAuthException and returns the error message.
  */
  Future registerUserWithEmailAndPassword(
      String fullName, String email, String password) async {
    try {
      User user = (await firebaseAuth.createUserWithEmailAndPassword(
              email: email, password: password))
          .user!;
      if (user != null) {
        // call the database service to update the user details in the database
        await DatabaseService(uid: user.uid).savingUserData(fullName, email);
        return true;
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // sign out function
  /*
  The code defines a function signOut that attempts to sign out the current user. It first uses HelperFunctions to remove the user values from the shared preferences on the device. Then, it calls signOut from firebaseAuth to perform the sign-out operation. If there is an error, it catches the exception and returns null.
  */
  Future signOut() async {
    try {
      // to remove the user values from the shared preferences, in the device
      await HelperFunctions.saveUserLoggedInStatus(false);
      await HelperFunctions.saveUserEmailSF("");
      await HelperFunctions.saveUserNameSF("");
      // through this sign-out will be done
      await firebaseAuth.signOut();
    } catch (e) {
      return null;
    }
  }
}
