function validateRegister(req, res, next) {
  const {
    studentId,
    name,
    email,
    password,
  } = req.body;

  if (!studentId || !name || !email || !password) {
    return res.status(400).json({
      status: "error",
      message:
        "studentId, name, email and password are required",
    });
  }

  if (typeof studentId !== "string") {
    return res.status(400).json({
      status: "error",
      message: "Student ID must be a string",
    });
  }

  if (typeof name !== "string" || name.trim().length < 2) {
    return res.status(400).json({
      status: "error",
      message: "A valid name is required",
    });
  }

  if (
    typeof email !== "string" ||
    !email.includes("@")
  ) {
    return res.status(400).json({
      status: "error",
      message: "A valid email is required",
    });
  }

  if (
    typeof password !== "string" ||
    password.length < 6
  ) {
    return res.status(400).json({
      status: "error",
      message: "Password must be at least 6 characters",
    });
  }

  next();
}

function validateLogin(req, res, next) {
  const { studentId, password } = req.body;

  if (!studentId || !password) {
    return res.status(400).json({
      status: "error",
      message: "Student ID and password are required",
    });
  }

  if (typeof studentId !== "string") {
    return res.status(400).json({
      status: "error",
      message: "Student ID must be a string",
    });
  }

  if (typeof password !== "string") {
    return res.status(400).json({
      status: "error",
      message: "Password must be a string",
    });
  }

  next();
}

module.exports = {
  validateRegister,
  validateLogin,
};