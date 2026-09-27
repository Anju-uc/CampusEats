const config = require("../config/env");

function isDynamicLocalOrigin(origin) {
  if (typeof origin !== "string" || process.env.NODE_ENV === "production") {
    return false;
  }

  try {
    const parsed = new URL(origin);
    const isLocalHost =
      parsed.hostname === "localhost" || parsed.hostname === "127.0.0.1";

    return (
      parsed.protocol === "http:" &&
      isLocalHost &&
      parsed.pathname === "/" &&
      parsed.search === "" &&
      parsed.hash === ""
    );
  } catch (error) {
    return false;
  }
}

function isAllowedOrigin(origin) {
  return (
    !origin ||
    (origin !== "*" && config.cors.origins.includes(origin)) ||
    isDynamicLocalOrigin(origin)
  );
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
