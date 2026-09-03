function errorMiddleware(err, req, res, next) {
    const statusCode =
      Number.isInteger(err.statusCode) &&
      err.statusCode >= 400 &&
      err.statusCode < 600
        ? err.statusCode
        : 500;
  
    const code =
      err.code ||
      (statusCode === 404
        ? "NOT_FOUND"
        : statusCode === 400
          ? "BAD_REQUEST"
          : statusCode === 401
            ? "UNAUTHORIZED"
            : statusCode === 403
              ? "FORBIDDEN"
              : "INTERNAL_SERVER_ERROR");
  
    if (statusCode >= 500) {
      console.error("Server error:", err);
    }
  
    return res.status(statusCode).json({
      status: "error",
      code,
      message:
        err.isOperational || statusCode < 500
          ? err.message
          : "Internal server error",
    });
  }
  
  module.exports = {
    errorMiddleware,
  };