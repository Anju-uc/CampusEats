function normalizeStudentId(studentId) {
  if (typeof studentId !== "string") {
    return "";
  }

  return studentId.trim().toUpperCase().replace(/\s+/g, "");
}

function validateRegister(req, res, next) {
  const { studentId, password } = req.body;

  if (!studentId || !password) {
    return res.status(400).json({
      status: "error",
      message: "studentId and password are required",
    });
  }

  if (typeof studentId !== "string" || !studentId.trim()) {
    return res.status(400).json({
      status: "error",
      message: "A valid student ID is required",
    });
  }

  if (typeof password !== "string" || password.length < 4) {
    return res.status(400).json({
      status: "error",
      message: "Password must be at least 4 characters",
    });
  }

  req.body.studentId = normalizeStudentId(studentId);
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

  if (typeof studentId !== "string" || !studentId.trim()) {
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

  req.body.studentId = normalizeStudentId(studentId);
  next();
}

function validateStudentStatus(req, res, next) {
  const { status } = req.body;

  if (!["ACTIVE", "GRADUATED", "SUSPENDED"].includes(status)) {
    return res.status(400).json({
      status: "error",
      message: "status must be ACTIVE, GRADUATED or SUSPENDED",
    });
  }

  next();
}

function validateStaffLogin(req, res, next) {
  const { identifier, email, staffId, rollNumber, facultyId, password } = req.body;
  const loginId = identifier || email || staffId || rollNumber || facultyId;

  if (!loginId || !password) {
    return res.status(400).json({
      status: "error",
      message: "Staff identifier and password are required",
    });
  }

  if (typeof loginId !== "string" || !loginId.trim()) {
    return res.status(400).json({
      status: "error",
      message: "A valid staff identifier is required",
    });
  }

  if (typeof password !== "string" || !password.trim()) {
    return res.status(400).json({
      status: "error",
      message: "Password must be a non-empty string",
    });
  }

  req.body.identifier = loginId.trim();
  next();
}

module.exports = {
  normalizeStudentId,
  validateRegister,
  validateLogin,
  validateStudentStatus,
  validateStaffLogin,
};