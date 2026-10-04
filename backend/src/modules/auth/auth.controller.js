const authService = require("./auth.service");

async function register(req, res, next) {
  try {
    const user = await authService.registerUser(
      req.body
    );

    res.status(201).json({
      status: "success",
      message: "User registered successfully",
      data: user,
    });
  } catch (error) {
    next(error);
  }
}

async function login(req, res, next) {
  try {
    const result = await authService.loginUser(
      req.body
    );

    res.status(200).json({
      status: "success",
      message: "Login successful",
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

async function staffLogin(req, res, next) {
  try {
    const result = await authService.loginStaff(req.body);

    res.status(200).json({
      status: "success",
      message: "Staff login successful",
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

async function updateStudentStatus(req, res, next) {
  try {
    const user = await authService.updateStudentStatus(
      req.params.studentId,
      req.body.status
    );

    res.status(200).json({
      status: "success",
      message: "Student status updated successfully",
      data: {
        uid: user.uid,
        studentId: user.studentId,
        name: user.name,
        program: user.program,
        status: user.status,
        role: user.role,
      },
    });
  } catch (error) {
    next(error);
  }
}

async function campusCheckin(req, res, next) {
  try {
    const user = req.user;
    if (!user || user.role !== "Student" || user.status !== "ACTIVE") {
      return res.status(403).json({
        status: "error",
        message: "An active student account is required",
      });
    }

    const { checkinChallenge } = req.body || {};
    if (!checkinChallenge) {
      return res.status(400).json({
        status: "error",
        message: "Campus check-in challenge is required",
      });
    }

    const result = await authService.verifyCampusCheckinAndIssueProof({
      uid: user.uid,
      checkinChallenge,
    });

    res.status(200).json({
      status: "success",
      message: "Campus check-in verified successfully",
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  register,
  login,
  staffLogin,
  updateStudentStatus,
  campusCheckin,
};