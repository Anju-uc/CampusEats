const userService = require("./user.service");

async function getMe(req, res, next) {
  try {
    const user = await userService.getUserByUid(req.user.uid);

    res.status(200).json({
      status: "success",
      data: user,
    });
  } catch (error) {
    next(error);
  }
}

async function updateMe(req, res, next) {
  try {
    const user = await userService.updateUserProfile(
      req.user.uid,
      req.body
    );

    res.status(200).json({
      status: "success",
      message: "Profile updated successfully",
      data: user,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getMe,
  updateMe,
};