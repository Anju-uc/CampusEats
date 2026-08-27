const {
    initializeApp,
    getApps,
    getApp,
    cert,
  } = require("firebase-admin/app");
  
  const { getAuth } = require("firebase-admin/auth");
  const { getDatabase } = require("firebase-admin/database");
  
  const config = require("./env");
  
  const firebaseApp = getApps().length
    ? getApp()
    : initializeApp({
        credential: cert({
          projectId: config.firebase.projectId,
          clientEmail: config.firebase.clientEmail,
          privateKey: config.firebase.privateKey,
        }),
        databaseURL: config.firebase.databaseURL,
      });
  
  const auth = getAuth(firebaseApp);
  const realtimeDb = getDatabase(firebaseApp);
  
  module.exports = {
    firebaseApp,
    auth,
    realtimeDb,
  };