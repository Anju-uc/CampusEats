function sendSuccess(
    res,
    data = null,
    message = "Request successful",
    statusCode = 200
  ) {
    return res.status(statusCode).json({
      status: "success",
      message,
      data,
    });
  }
  
  function sendError(
    res,
    message = "Something went wrong",
    statusCode = 500,
    code = "INTERNAL_SERVER_ERROR"
  ) {
    return res.status(statusCode).json({
      status: "error",
      code,
      message,
    });
  }
  
  module.exports = {
    sendSuccess,
    sendError,
  };