const assert = require("node:assert/strict");
const test = require("node:test");
const { ObjectId } = require("mongodb");
const {
  ORDER_STATUS,
  canTransition,
  validateTransition,
} = require("../src/modules/orders/orderStateMachine");
const { requireRole } = require("../src/middleware/role.middleware");
const { ROLES } = require("../src/common/constants/roles");
const orderService = require("../src/modules/orders/order.service");
const mongodbPath = require.resolve("../src/config/mongodb");
const orderServicePath = require.resolve("../src/modules/orders/order.service");

function makeResponse() {
  return {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(value) {
      this.body = value;
      return this;
    },
  };
}

test("order state machine validates normal kitchen flow PENDING -> CONFIRMED -> PREPARING -> READY -> COMPLETED", () => {
  assert.equal(canTransition("PENDING", "CONFIRMED"), true);
  assert.equal(canTransition("CONFIRMED", "PREPARING"), true);
  assert.equal(canTransition("PREPARING", "READY"), true);
  assert.equal(canTransition("READY", "COMPLETED"), true);

  // Completed cannot transition further
  assert.equal(canTransition("COMPLETED", "READY"), false);
  assert.equal(canTransition("COMPLETED", "CANCELLED"), false);
});

test("invalid order status transitions throw 400 error", () => {
  assert.throws(
    () => validateTransition("PENDING", "COMPLETED"),
    (err) => err.statusCode === 400 && err.message.includes("Invalid order status transition")
  );
  assert.throws(
    () => validateTransition("CONFIRMED", "READY"),
    (err) => err.statusCode === 400
  );
  assert.throws(
    () => validateTransition("PREPARING", "COMPLETED"),
    (err) => err.statusCode === 400
  );
  assert.throws(
    () => validateTransition("COMPLETED", "PREPARING"),
    (err) => err.statusCode === 400
  );
  assert.throws(
    () => validateTransition("CONFIRMED", "Accepted"),
    (err) => err.statusCode === 400
  );
});

test("student cannot access /api/orders/all staff endpoint", () => {
  const staffOnly = requireRole(ROLES.ADMIN, ROLES.KITCHEN, ROLES.FACULTY);
  const response = makeResponse();
  let nextCalled = false;

  staffOnly(
    { user: { uid: "student-1", role: ROLES.STUDENT, status: "ACTIVE" } },
    response,
    () => {
      nextCalled = true;
    }
  );

  assert.equal(response.statusCode, 403);
  assert.equal(nextCalled, false);
});

test("authenticated Admin and Kitchen can access staff orders endpoint", () => {
  const staffOnly = requireRole(ROLES.ADMIN, ROLES.KITCHEN, ROLES.FACULTY);

  for (const role of [ROLES.ADMIN, ROLES.KITCHEN]) {
    const response = makeResponse();
    let nextCalled = false;

    staffOnly(
      { user: { uid: "staff-1", role, status: "ACTIVE" } },
      response,
      () => {
        nextCalled = true;
      }
    );

    assert.equal(response.statusCode, 200);
    assert.equal(nextCalled, true);
  }
});

test("order status update preserves MongoDB ObjectId as string and executes allowed transitions", async () => {
  const testOrderId = new ObjectId();
  let storedStatus = "CONFIRMED";
  let updatedDoc = null;

  const mockOrdersCollection = {
    findOne: async ({ _id }) => {
      if (_id.equals(testOrderId)) {
        return {
          _id: testOrderId,
          userId: "student-uid-123",
          status: storedStatus,
          items: [{ name: "Dosa", price: 60, quantity: 1 }],
          total: 60,
        };
      }
      return null;
    },
    findOneAndUpdate: async ({ _id }, { $set }) => {
      if (_id.equals(testOrderId)) {
        storedStatus = $set.status;
        updatedDoc = {
          _id: testOrderId,
          userId: "student-uid-123",
          status: storedStatus,
          updatedAt: $set.updatedAt,
        };
        return updatedDoc;
      }
      return null;
    },
  };

  require.cache[mongodbPath] = {
    exports: {
      getDb: () => ({
        collection: (name) => {
          if (name === "orders") return mockOrdersCollection;
          return {};
        },
      }),
    },
  };
  delete require.cache[orderServicePath];
  const service = require(orderServicePath);

  // Transition CONFIRMED -> PREPARING
  const result = await service.updateOrderStatus(testOrderId.toString(), "PREPARING");
  assert.equal(result.status, "PREPARING");
  assert.equal(result._id.toString(), testOrderId.toString());

  // Transition PREPARING -> READY
  const result2 = await service.updateOrderStatus(testOrderId.toString(), "READY");
  assert.equal(result2.status, "READY");

  // Invalid transition READY -> PREPARING must reject
  await assert.rejects(
    service.updateOrderStatus(testOrderId.toString(), "PREPARING"),
    (err) => err.statusCode === 400
  );
});
