const { auth } = require("../config/firebase");

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

    req.user = decodedToken;

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