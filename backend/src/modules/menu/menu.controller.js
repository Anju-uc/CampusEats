const menuService = require("./menu.service");

async function getAllMenuItems(req, res, next) {
  try {
    const items = await menuService.getAllMenuItems();

    res.status(200).json({
      status: "success",
      data: items,
    });
  } catch (error) {
    next(error);
  }
}

async function getAvailableMenuItems(req, res, next) {
  try {
    const items = await menuService.getAvailableMenuItems();

    res.status(200).json({
      status: "success",
      data: items,
    });
  } catch (error) {
    next(error);
  }
}

async function getMenuItemById(req, res, next) {
  try {
    const item = await menuService.getMenuItemById(req.params.id);

    res.status(200).json({
      status: "success",
      data: item,
    });
  } catch (error) {
    next(error);
  }
}

async function createMenuItem(req, res, next) {
  try {
    const item = await menuService.createMenuItem(req.body);

    res.status(201).json({
      status: "success",
      message: "Menu item created successfully",
      data: item,
    });
  } catch (error) {
    next(error);
  }
}

async function updateMenuItem(req, res, next) {
  try {
    const item = await menuService.updateMenuItem(
      req.params.id,
      req.body
    );

    res.status(200).json({
      status: "success",
      message: "Menu item updated successfully",
      data: item,
    });
  } catch (error) {
    next(error);
  }
}

async function deleteMenuItem(req, res, next) {
  try {
    const result = await menuService.deleteMenuItem(req.params.id);

    res.status(200).json({
      status: "success",
      message: "Menu item deleted successfully",
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllMenuItems,
  getAvailableMenuItems,
  getMenuItemById,
  createMenuItem,
  updateMenuItem,
  deleteMenuItem,
};