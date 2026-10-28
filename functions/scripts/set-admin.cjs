const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");

const uid = process.argv[2];
if (!uid) {
  console.error("Usage: npm run set-admin -- <firebase-auth-uid>");
  process.exitCode = 1;
} else {
  initializeApp({ projectId: "green-energy-fb652" });
  const auth = getAuth();
  const db = getFirestore();

  auth
    .getUser(uid)
    .then(async (user) => {
      await auth.setCustomUserClaims(uid, {
        ...(user.customClaims ?? {}),
        admin: true,
      });
      await db.collection("users").doc(uid).set(
        { role: "admin", updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      console.log(`Granted admin role to ${uid}. Ask the user to sign in again.`);
    })
    .catch((error) => {
      console.error("Could not grant admin role:", error.message);
      process.exitCode = 1;
    });
}
