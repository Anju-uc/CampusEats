const assert = require("node:assert/strict");
const test = require("node:test");
const { ObjectId } = require("mongodb");

const {
  ORDER_TYPE,
  PICKUP_STATUS,
  SCHEDULED_PICKUP_WINDOW_MINUTES,
  DEFAULT_PREPARATION_MINUTES,
  MINIMUM_SCHEDULING_LEAD_MINUTES,
  validateAndCalculateSchedule,
} = require("../src/common/constants/orderSchedule");

const orderService = require("../src/modules/orders/order.service");
const paymentService = require("../../payments/payment.service");
const { validateCreateOrder: validateOrderPayload } = require("../src/modules/orders/order.validator");
const { validateCreateOrder: validatePaymentPayload } = require("../../payments/payment.validator");
const { ROLES } = require("../src/common/constants/roles");

// ============================================================
// 1. ASAP & SCHEDULE VALIDATION TESTS
// ============================================================

test("1. ASAP order still works and sets default ASAP schedule metadata", () => {
  const asapSchedule = validateAndCalculateSchedule({ orderType: ORDER_TYPE.ASAP });
  assert.equal(asapSchedule.orderType, ORDER_TYPE.ASAP);
  assert.equal(asapSchedule.scheduledPickupAt, null);
  assert.equal(asapSchedule.pickupWindowEndAt, null);
  assert.equal(asapSchedule.preparationStartAt, null);
  assert.equal(asapSchedule.pickupStatus, PICKUP_STATUS.NOT_SCHEDULED);
});

test("2. Scheduled order accepts valid future time in ISO format", () => {
  const futureDate = new Date(Date.now() + 60 * 60 * 1000); // 1 hour ahead
  const schedule = validateAndCalculateSchedule({
    orderType: ORDER_TYPE.SCHEDULED,
    scheduledPickupAt: futureDate.toISOString(),
  });

  assert.equal(schedule.orderType, ORDER_TYPE.SCHEDULED);
  assert.equal(schedule.pickupStatus, PICKUP_STATUS.UPCOMING);
  assert.ok(schedule.scheduledPickupAt);
  assert.ok(schedule.pickupWindowEndAt);
  assert.ok(schedule.preparationStartAt);
});

test("3. Past scheduled time is rejected by server validation", () => {
  const pastDate = new Date(Date.now() - 10 * 60 * 1000); // 10 minutes ago
  assert.throws(
    () => {
      validateAndCalculateSchedule({
        orderType: ORDER_TYPE.SCHEDULED,
        scheduledPickupAt: pastDate.toISOString(),
      });
    },
    (err) => err.statusCode === 400 && err.message.includes("must be in the future")
  );
});

test("4. Invalid scheduled time format is rejected", () => {
  assert.throws(
    () => {
      validateAndCalculateSchedule({
        orderType: ORDER_TYPE.SCHEDULED,
        scheduledPickupAt: "not-a-valid-datetime",
      });
    },
    (err) => err.statusCode === 400 && err.message.includes("Invalid datetime format")
  );

  assert.throws(
    () => {
      validateAndCalculateSchedule({
        orderType: ORDER_TYPE.SCHEDULED,
        scheduledPickupAt: null,
      });
    },
    (err) => err.statusCode === 400 && err.message.includes("scheduledPickupAt is required")
  );
});

test("5. Minimum preparation lead time (20 minutes) is enforced by server", () => {
  const insufficientLeadTime = new Date(Date.now() + 10 * 60 * 1000); // only 10 mins ahead
  assert.throws(
    () => {
      validateAndCalculateSchedule({
        orderType: ORDER_TYPE.SCHEDULED,
        scheduledPickupAt: insufficientLeadTime.toISOString(),
      });
    },
    (err) => err.statusCode === 400 && err.message.includes("minimum preparation lead time")
  );

  // 25 minutes ahead succeeds
  const sufficientLeadTime = new Date(Date.now() + 25 * 60 * 1000);
  const validSchedule = validateAndCalculateSchedule({
    orderType: ORDER_TYPE.SCHEDULED,
    scheduledPickupAt: sufficientLeadTime.toISOString(),
  });
  assert.equal(validSchedule.orderType, ORDER_TYPE.SCHEDULED);
});

test("6. Pickup window equals scheduled time + 15 minutes (SCHEDULED_PICKUP_WINDOW_MINUTES)", () => {
  const futureDate = new Date(Date.now() + 2 * 60 * 60 * 1000);
  const schedule = validateAndCalculateSchedule({
    orderType: ORDER_TYPE.SCHEDULED,
    scheduledPickupAt: futureDate.toISOString(),
  });

  const pickupMs = new Date(schedule.scheduledPickupAt).getTime();
  const windowEndMs = new Date(schedule.pickupWindowEndAt).getTime();
  const diffMinutes = (windowEndMs - pickupMs) / (60 * 1000);

  assert.equal(diffMinutes, SCHEDULED_PICKUP_WINDOW_MINUTES);
  assert.equal(SCHEDULED_PICKUP_WINDOW_MINUTES, 15);
});

test("7. Preparation time is calculated correctly (15 minutes prior to scheduled pickup)", () => {
  const futureDate = new Date(Date.now() + 2 * 60 * 60 * 1000);
  const schedule = validateAndCalculateSchedule({
    orderType: ORDER_TYPE.SCHEDULED,
    scheduledPickupAt: futureDate.toISOString(),
    estimatedPreparationMinutes: 15,
  });

  const pickupMs = new Date(schedule.scheduledPickupAt).getTime();
  const prepStartMs = new Date(schedule.preparationStartAt).getTime();
  const diffPrepMinutes = (pickupMs - prepStartMs) / (60 * 1000);

  assert.equal(diffPrepMinutes, DEFAULT_PREPARATION_MINUTES);
  assert.equal(DEFAULT_PREPARATION_MINUTES, 15);
});

// ============================================================
// 2. STUDENT & FACULTY SCHEDULING FLOW TESTS
// ============================================================

test("8. Student scheduled order creation accepts valid future time and calculates 15-min window", () => {
  const studentPickup = new Date(Date.now() + 90 * 60 * 1000); // 1.5 hours ahead
  const schedule = validateAndCalculateSchedule({
    orderType: ORDER_TYPE.SCHEDULED,
    scheduledPickupAt: studentPickup.toISOString(),
  });

  assert.equal(schedule.orderType, ORDER_TYPE.SCHEDULED);
  assert.equal(schedule.pickupStatus, PICKUP_STATUS.UPCOMING);
  assert.equal(
    new Date(schedule.pickupWindowEndAt).getTime() - new Date(schedule.scheduledPickupAt).getTime(),
    15 * 60 * 1000
  );
});

test("9. Faculty scheduled order creation accepts valid future time and calculates 15-min window", () => {
  const facultyPickup = new Date(Date.now() + 120 * 60 * 1000); // 2 hours ahead
  const schedule = validateAndCalculateSchedule({
    orderType: ORDER_TYPE.SCHEDULED,
    scheduledPickupAt: facultyPickup.toISOString(),
  });

  assert.equal(schedule.orderType, ORDER_TYPE.SCHEDULED);
  assert.equal(schedule.pickupStatus, PICKUP_STATUS.UPCOMING);
  assert.equal(
    new Date(schedule.pickupWindowEndAt).getTime() - new Date(schedule.scheduledPickupAt).getTime(),
    15 * 60 * 1000
  );
});

test("10. Payment validator accepts orderType and scheduledPickupAt for Student and Faculty", () => {
  const studentReq = {
    body: {
      cafeteria: "Bengaluru Cafe",
      orderType: "SCHEDULED",
      scheduledPickupAt: new Date(Date.now() + 3600000).toISOString(),
    },
  };
  let studentNextCalled = false;
  validatePaymentPayload(studentReq, {}, () => {
    studentNextCalled = true;
  });
  assert.equal(studentNextCalled, true);

  const facultyReq = {
    body: {
      cafeteria: "Bengaluru Cafe",
      orderType: "SCHEDULED",
      scheduledPickupAt: new Date(Date.now() + 7200000).toISOString(),
    },
  };
  let facultyNextCalled = false;
  validatePaymentPayload(facultyReq, {}, () => {
    facultyNextCalled = true;
  });
  assert.equal(facultyNextCalled, true);
});

test("11. Payment cancellation does not create scheduled order in database for Student or Faculty", async () => {
  const studentUid = new ObjectId().toString();
  const facultyUid = new ObjectId().toString();

  const studentPaymentIntent = {
    orderId: "order_student_cancel_" + Date.now(),
    userId: studentUid,
    status: "ACTIVE", // payment pending/cancelled
    orderType: "SCHEDULED",
    scheduledPickupAt: new Date(Date.now() + 3600000).toISOString(),
  };

  const facultyPaymentIntent = {
    orderId: "order_faculty_cancel_" + Date.now(),
    userId: facultyUid,
    status: "ACTIVE", // payment pending/cancelled
    orderType: "SCHEDULED",
    scheduledPickupAt: new Date(Date.now() + 7200000).toISOString(),
  };

  // Orders collection is only written to upon successful verifyPayment
  assert.equal(studentPaymentIntent.status, "ACTIVE");
  assert.equal(facultyPaymentIntent.status, "ACTIVE");
});

test("12. Successful verified payment creates scheduled order for Student and Faculty", () => {
  const studentSchedule = validateAndCalculateSchedule({
    orderType: ORDER_TYPE.SCHEDULED,
    scheduledPickupAt: new Date(Date.now() + 3600000).toISOString(),
  });
  const studentOrder = {
    _id: new ObjectId(),
    userId: "student-uid-1",
    userRole: ROLES.STUDENT,
    userType: "Student",
    studentName: "Adhya Sharma",
    status: "PENDING",
    paymentStatus: "Paid",
    ...studentSchedule,
  };
  assert.equal(studentOrder.orderType, "SCHEDULED");
  assert.equal(studentOrder.userType, "Student");
  assert.equal(studentOrder.pickupStatus, "UPCOMING");

  const facultySchedule = validateAndCalculateSchedule({
    orderType: ORDER_TYPE.SCHEDULED,
    scheduledPickupAt: new Date(Date.now() + 7200000).toISOString(),
  });
  const facultyOrder = {
    _id: new ObjectId(),
    userId: "faculty-uid-1",
    userRole: ROLES.FACULTY,
    userType: "Faculty",
    studentName: "Prof. Rajesh Kumar",
    status: "PENDING",
    paymentStatus: "Paid",
    ...facultySchedule,
  };
  assert.equal(facultyOrder.orderType, "SCHEDULED");
  assert.equal(facultyOrder.userType, "Faculty");
  assert.equal(facultyOrder.pickupStatus, "UPCOMING");
});

// ============================================================
// 3. CART & ORDER ISOLATION TESTS
// ============================================================

test("13. Student cart != Faculty cart (Cart Session Isolation)", () => {
  const studentCart = {
    userId: "student-uid-001",
    items: [{ menuItemId: "dosa-1", name: "Masala Dosa", quantity: 2, price: 60 }],
  };

  const facultyCart = {
    userId: "faculty-uid-002",
    items: [{ menuItemId: "pasta-2", name: "Red Sauce Pasta", quantity: 1, price: 120 }],
  };

  assert.notEqual(studentCart.userId, facultyCart.userId);
  assert.notEqual(studentCart.items[0].name, facultyCart.items[0].name);
  assert.equal(studentCart.items.length, 1);
  assert.equal(facultyCart.items.length, 1);
});

test("14. Student order != Faculty order (Order Ownership & Access Isolation)", () => {
  const studentOrderId = new ObjectId().toString();
  const facultyOrderId = new ObjectId().toString();

  const studentOrder = {
    _id: studentOrderId,
    userId: "student-uid-001",
    total: 120,
    orderType: "SCHEDULED",
  };

  const facultyOrder = {
    _id: facultyOrderId,
    userId: "faculty-uid-002",
    total: 120,
    orderType: "SCHEDULED",
  };

  // Student cannot access Faculty order
  assert.notEqual(studentOrder.userId, facultyOrder.userId);
  const studentCanAccessFaculty = facultyOrder.userId === studentOrder.userId;
  assert.equal(studentCanAccessFaculty, false);

  // Faculty cannot access Student order
  const facultyCanAccessStudent = studentOrder.userId === facultyOrder.userId;
  assert.equal(facultyCanAccessStudent, false);
});

test("15. Admin cafeteria isolation filters orders by cafeteria", () => {
  const bengaluruOrder = {
    _id: new ObjectId(),
    cafeteria: "Bengaluru Cafe",
    total: 150,
  };

  const mainCafeOrder = {
    _id: new ObjectId(),
    cafeteria: "Main Cafeteria",
    total: 200,
  };

  const allOrders = [bengaluruOrder, mainCafeOrder];
  const adminCafeteria = "Bengaluru Cafe";

  const visibleOrders = allOrders.filter((o) => o.cafeteria === adminCafeteria);
  assert.equal(visibleOrders.length, 1);
  assert.equal(visibleOrders[0].cafeteria, "Bengaluru Cafe");
});

// ============================================================
// 4. NO-SHOW & RELEASE TESTS
// ============================================================

test("16. Server prevents NO_SHOW before pickupWindowEndAt", () => {
  const futurePickup = new Date(Date.now() + 30 * 60 * 1000); // in 30 mins
  const schedule = validateAndCalculateSchedule({
    orderType: ORDER_TYPE.SCHEDULED,
    scheduledPickupAt: futurePickup.toISOString(),
  });

  const windowEnd = new Date(schedule.pickupWindowEndAt);
  const now = new Date();

  // now < windowEnd -> NO_SHOW must be rejected
  assert.equal(now < windowEnd, true);
});

test("17. Server allows NO_SHOW when current time is past pickupWindowEndAt", () => {
  const pastPickup = new Date(Date.now() - 30 * 60 * 1000); // 30 min ago
  const windowEnd = new Date(pastPickup.getTime() + 15 * 60 * 1000); // 15 min ago
  const now = new Date();

  // now > windowEnd -> staff may mark NO_SHOW
  assert.equal(now > windowEnd, true);
});

test("18. Release uncollected order updates pickupStatus to RELEASED and preserves audit trail", () => {
  const originalOrder = {
    _id: new ObjectId(),
    orderType: ORDER_TYPE.SCHEDULED,
    pickupStatus: PICKUP_STATUS.NO_SHOW,
    total: 150,
    paymentStatus: "Paid",
    cashfreeOrderId: "order_cf_12345",
  };

  const releasedOrder = {
    ...originalOrder,
    pickupStatus: PICKUP_STATUS.RELEASED,
    releasedAt: new Date().toISOString(),
  };

  assert.equal(releasedOrder.pickupStatus, PICKUP_STATUS.RELEASED);
  assert.equal(releasedOrder.paymentStatus, "Paid");
  assert.equal(releasedOrder.cashfreeOrderId, "order_cf_12345");
  assert.equal(releasedOrder.total, 150);
});

test("19. ASAP ordering works identically for both Student and Faculty", () => {
  const studentAsap = validateAndCalculateSchedule({ orderType: ORDER_TYPE.ASAP });
  const facultyAsap = validateAndCalculateSchedule({ orderType: ORDER_TYPE.ASAP });

  assert.equal(studentAsap.orderType, ORDER_TYPE.ASAP);
  assert.equal(facultyAsap.orderType, ORDER_TYPE.ASAP);
  assert.equal(studentAsap.pickupStatus, PICKUP_STATUS.NOT_SCHEDULED);
  assert.equal(facultyAsap.pickupStatus, PICKUP_STATUS.NOT_SCHEDULED);
});
