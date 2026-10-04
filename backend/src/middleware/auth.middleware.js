const { auth } = require("../config/firebase");
const { getDb } = require("../config/mongodb");

async function authenticate(req, res, next) {
  try {
    const authorization = req.headers.authorization;

    if (!authorization || !authorization.startsWith("Bearer ")) {
      return res.status(401).json({
        status: "error",
        message: "Authorization token is required",
      });
    }

    const idToken = authorization.split("Bearer ")[1].trim();

    if (!idToken) {
      return res.status(401).json({
        status: "error",
        message: "Authorization token is required",
      });
    }

    const decodedToken = await auth.verifyIdToken(idToken);

    const user = await getDb().collection("users").findOne({
      uid: decodedToken.uid,
    });

    if (!user) {
      return res.status(401).json({
        status: "error",
        message: "Authenticated user is not provisioned",
      });
    }

    req.user = {
      ...decodedToken,
      uid: user.uid,
      studentId: user.studentId,
      staffId: user.staffId,
      rollNumber: user.rollNumber,
      name: user.name,
      program: user.program,
      role: user.role,
      status: user.status,
      cafeteria: user.cafeteria,
      cafeteriaId: user.cafeteriaId,
    };

    next();
  } catch (error) {
    return res.status(401).json({
      status: "error",
      message: "Invalid or expired authentication token",
    });
  }
}

module.exports = {
  authenticate,
};