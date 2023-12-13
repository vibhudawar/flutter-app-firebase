// package for interacting with Firebase Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';

// defines a class called DatabaseService with a nullable uid parameter in the constructor.
class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // reference for our collections
  /*
  creates references to the Firestore collections: userCollection refers to the "users" collection, and groupCollection refers to the "groups" collection.
  */
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection("users");
  final CollectionReference groupCollection =
      FirebaseFirestore.instance.collection("groups");

  // saving the userdata

  //a function savingUserData that saves user data to the Firestore database. It sets the document with the uid as the document ID and saves the provided fullName, email, an empty list for groups, an empty string for profilePic, and the uid.
  Future savingUserData(String fullName, String email) async {
    return await userCollection.doc(uid).set({
      "fullName": fullName,
      "email": email,
      "groups": [],
      "profilePic": "",
      "uid": uid,
    });
  }

  // getting user data
  // code defines a function gettingUserData that retrieves user data from the Firestore database based on the provided email. It queries the userCollection for documents where the "email" field is equal to the provided email and returns the resulting snapshot.
  Future gettingUserData(String email) async {
    QuerySnapshot snapshot =
        await userCollection.where("email", isEqualTo: email).get();
    return snapshot;
  }

  // get user groups
  // The code defines a function getUserGroups that returns a stream of snapshots for the document in the userCollection with the uid.
  getUserGroups() async {
    return userCollection.doc(uid).snapshots();
  }

  // defines a function createGroup that creates a new group in the Firestore database. It adds a document to the groupCollection with various fields such as the provided groupName, a lowercase version of the group name, group icon, admin, members (initially an empty array), groupId, recentMessage, and recentMessageSender. It then updates the members and groupId fields of the group document and updates the groups field of the user document.
  Future createGroup(String userName, String id, String groupName) async {
    DocumentReference groupDocumentReference = await groupCollection.add({
      "groupName": groupName.trim(),
      "groupNameLowerCase": groupName
          .trim()
          .toLowerCase(), // add lowercase version of the group name
      "groupIcon": "",
      "admin": "${id}_$userName",
      "members": [],
      "groupId": "",
      "recentMessage": "",
      "recentMessageSender": "",
    });
    // update the members
    await groupDocumentReference.update({
      "members": FieldValue.arrayUnion(["${uid}_$userName"]),
      "groupId": groupDocumentReference.id,
    });

    // update the groups field for that user
    DocumentReference userDocumentReference = userCollection.doc(uid);
    return await userDocumentReference.update({
      "groups":
          FieldValue.arrayUnion(["${groupDocumentReference.id}_$groupName"])
    });
  }

  // getting the chats
  // code defines a function getChats that returns a stream of snapshots for the messages collection within a specific group in the Firestore database. The messages are ordered by the "time" field.
  getChats(String groupId) async {
    return groupCollection
        .doc(groupId)
        .collection("messages")
        .orderBy("time")
        .snapshots();
  }

  // code defines a function getGroupAdmin that retrieves the admin of a group from the Firestore database based on the provided groupId. It fetches the group document and returns the value of the "admin" field.
  Future getGroupAdmin(String groupId) async {
    DocumentReference d = groupCollection.doc(groupId);
    DocumentSnapshot documentSnapshot = await d.get();
    return documentSnapshot['admin'];
  }

  // get group members
  // code defines a function getGroupMembers that returns a stream of snapshots for a specific group document in the Firestore database based on the provided groupId.
  getGroupMembers(groupId) async {
    return groupCollection.doc(groupId).snapshots();
  }

  //code defines a function searchByName that searches for groups in the Firestore database based on the provided groupName. It constructs a query that filters documents where the "groupNameLowerCase" field is greater than or equal to the lowercase searchInput and less than the searchInput + 'z'.
  searchByName(String groupName) {
    // Convert the search input to lowercase
    String searchInput = groupName.toLowerCase();
    // Construct a query that filters documents where the "groupName" field starts with the search input
    return groupCollection
        // to let the groupName in valid range, we need this
        .where("groupNameLowerCase", isGreaterThanOrEqualTo: searchInput)
        .where("groupNameLowerCase", isLessThan: searchInput + 'z')
        .get();
  }

  // function -> bool
  // code defines a function isUserJoined that checks if a user has joined a specific group. It retrieves the user document using the uid, fetches the value of the "groups" field, and checks if it contains a specific group based on the groupId and groupName. It returns true if the user has joined the group, and false otherwise.
  Future<bool> isUserJoined(
      String groupName, String groupId, String userName) async {
    DocumentReference userDocumentReference = userCollection.doc(uid);
    DocumentSnapshot documentSnapshot = await userDocumentReference.get();

    List<dynamic> groups = await documentSnapshot['groups'];
    if (groups.contains("${groupId}_$groupName")) {
      return true;
    } else {
      return false;
    }
  }

  // toggling the group join/exit
  // code defines a function toggleGroupJoin that allows a user to join or exit a group. It fetches the user and group documents using the uid and groupId respectively. It checks if the user is already a member of the group, and if so, removes them from the group and updates the respective fields. If the user is not a member, it adds them to the group and updates the fields accordingly.
  Future toggleGroupJoin(
      String groupId, String userName, String groupName) async {
    // doc reference
    DocumentReference userDocumentReference = userCollection.doc(uid);
    DocumentReference groupDocumentReference = groupCollection.doc(groupId);

    DocumentSnapshot documentSnapshot = await userDocumentReference.get();
    List<dynamic> groups = await documentSnapshot['groups'];

    // if user has our groups -> then remove them or also in other part re join
    if (groups.contains("${groupId}_$groupName")) {
      await userDocumentReference.update({
        "groups": FieldValue.arrayRemove(["${groupId}_$groupName"])
      });
      await groupDocumentReference.update({
        "members": FieldValue.arrayRemove(["${uid}_$userName"])
      });
    } else {
      await userDocumentReference.update({
        "groups": FieldValue.arrayUnion(["${groupId}_$groupName"])
      });
      await groupDocumentReference.update({
        "members": FieldValue.arrayUnion(["${uid}_$userName"])
      });
    }
  }

  // send message
  // code defines a function sendMessage that sends a message to a specific group in the Firestore database. It adds the chatMessageData to the "messages" collection within the group document. It also updates the "recentMessage", "recentMessageSender", and "recentMessageTime" fields of the group document with the corresponding values from the chatMessageData
  sendMessage(String groupId, Map<String, dynamic> chatMessageData) async {
    // loads the previously saved chatMessages
    groupCollection.doc(groupId).collection("messages").add(chatMessageData);
    // update the message parameters
    groupCollection.doc(groupId).update({
      "recentMessage": chatMessageData['message'],
      "recentMessageSender": chatMessageData['sender'],
      "recentMessageTime": chatMessageData['time'].toString(),
    });
  }
}
