import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { auth } from "firebase-functions/v1";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();
setGlobalOptions({ region: "asia-south1" });

const db = getFirestore();

export const createUserProfile = auth.user().onCreate(async (user) => {
  const profile = db.collection("users").doc(user.uid);
  const existing = await profile.get();
  if (existing.exists) return;

  await profile.create({
    uid: user.uid,
    email: user.email ?? "",
    displayName: user.displayName ?? user.email?.split("@")[0] ?? "Citizen",
    role: "citizen",
    authProvider: user.providerData.some(
      (provider) => provider.providerId === "google.com",
    )
      ? "google"
      : "password",
    onboardingComplete: false,
    points: 0,
    weeklyPoints: 0,
    streak: 0,
    longestStreak: 0,
    freezeTokens: 1,
    badges: [],
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
});

export const setUserRole = onCall(async (request) => {
  if (request.auth?.token.admin !== true) {
    throw new HttpsError("permission-denied", "Administrator access required.");
  }

  const uid = request.data?.uid;
  const role = request.data?.role;
  if (
    typeof uid !== "string" ||
    !uid ||
    !["citizen", "captain", "admin"].includes(role)
  ) {
    throw new HttpsError("invalid-argument", "A valid user ID and role are required.");
  }

  const authUser = await getAuth().getUser(uid);
  const claims = { ...(authUser.customClaims ?? {}) };
  if (role === "admin") claims.admin = true;
  else delete claims.admin;
  if (role === "captain") claims.captain = true;
  else delete claims.captain;
  await getAuth().setCustomUserClaims(uid, claims);
  await db.collection("users").doc(uid).set(
    { role, updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  return { uid, role };
});
