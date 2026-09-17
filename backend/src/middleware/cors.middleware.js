const config = require("../config/env");

function isAllowedOrigin(origin) {
  return !origin || config.cors.origins.includes(origin);
}

function corsOrigin(origin, callback) {
  if (isAllowedOrigin(origin)) {
    return callback(null, true);
  }

  return callback(new Error("Origin is not allowed"));
}

module.exports = {
  corsOrigin,
  isAllowedOrigin,
};
