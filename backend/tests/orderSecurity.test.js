const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const test = require("node:test");
const { ObjectId } = require("mongodb");

const mongodbPath = require.resolve("../src/config/mongodb");
const campusMiddlewarePath = require.resolve(
  "../src/middleware/campusAccess.middleware"
);
const orderServicePath = require.resolve(
  "../src/modules/orders/order.service"
);
const roleMiddlewarePath = require.resolve(
  "../src/middleware/role.middleware"
);

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

function makeProof({ campusId = "pes-bangalore", uid, iat, exp, jti }) {
  const payload = Buffer.from(
    JSON.stringify({ campusId, uid, iat, exp, jti }),
    "utf8"
  ).toString("base64url");
  const signature = crypto
    .createHmac("sha256", process.env.CAMPUS_ACCESS_SECRET)
    .update(payload)
    .digest("base64url");

  return `${payload}.${signature}`;
}

function loadCampusMiddleware({ insertOne }) {
  require.cache[mongodbPath] = {
    exports: {
      getDb: () => ({
        collection: () => ({ insertOne }),
      }),
    },
  };
  delete require.cache[campusMiddlewarePath];
  return require(campusMiddlewarePath).requireCampusAccess;
}

function loadOrderService(user) {
  const menuItemId = new ObjectId();
  const collections = {
    users: {
      findOne: async () => user,
    },
    carts: {
      findOne: async () => ({
        userId: user.uid,
        items: [{ menuItemId, quantity: 1 }],
      }),
      updateOne: async () => ({ acknowledged: true }),
    },
    menu: {
      findOne: async () => ({
        _id: menuItemId,
        name: "Meal",
        price: 100,
        available: true,
      }),
    },
    orders: {
      insertOne: async (order) => ({
        insertedId: new ObjectId(),
        order,
      }),
    },
  };

  require.cache[mongodbPath] = {
    exports: {
      getDb: () => ({
        collection: (name) => collections[name],
      }),
    },
  };
  delete require.cache[orderServicePath];
  return require(orderServicePath);
}

test("active student with a valid campus proof can create an order", async () => {
  process.env.CAMPUS_ACCESS_SECRET = "test-campus-secret";
  process.env.CAMPUS_ID = "pes-bangalore";
  const now = Math.floor(Date.now() / 1000);
  let consumed = 0;
  const requireCampusAccess = loadCampusMiddleware({
    insertOne: async () => {
      consumed += 1;
    },
  });
  const request = {
    user: { uid: "active-student", role: "Student", status: "ACTIVE" },
    headers: {
      "x-campus-access-proof": makeProof({
          uid: "active-student",
        iat: now,
        exp: now + 60,
        jti: "proof-active-123456",
      }),
    },
  };
  const response = makeResponse();
  let nextCalled = false;

  await requireCampusAccess(request, response, () => {
    nextCalled = true;
  });
  const order = await loadOrderService(request.user).createOrder(
    request.user.uid
  );

  assert.equal(nextCalled, true);
  assert.equal(consumed, 1);
  assert.equal(order.userId, "active-student");
});

test("missing, invalid, expired, and replayed proofs are rejected", async () => {
  process.env.CAMPUS_ACCESS_SECRET = "test-campus-secret";
  process.env.CAMPUS_ID = "pes-bangalore";
  const now = Math.floor(Date.now() / 1000);
  const usedJtis = new Set();
  const requireCampusAccess = loadCampusMiddleware({
    insertOne: async ({ jti }) => {
      if (usedJtis.has(jti)) {
        const error = new Error("duplicate");
        error.code = 11000;
        throw error;
      }
      usedJtis.add(jti);
    },
  });

  for (const proof of [
    undefined,
    "invalid-proof",
    makeProof({ uid: "active", iat: now - 120, exp: now - 60, jti: "proof-expired-123456" }),
  ]) {
    const response = makeResponse();
    await requireCampusAccess(
      {
        user: { uid: "active", role: "Student", status: "ACTIVE" },
        headers: proof ? { "x-campus-access-proof": proof } : {},
      },
      response,
      () => assert.fail("invalid proof must not call next")
    );
    assert.equal(response.statusCode, 403);
  }

  const validProof = makeProof({
    uid: "active",
    iat: now,
    exp: now + 60,
    jti: "proof-replay-123456",
  });
  const request = {
    user: { uid: "active", role: "Student", status: "ACTIVE" },
    headers: { "x-campus-access-proof": validProof },
  };
  await requireCampusAccess(request, makeResponse(), () => {});
  const replayResponse = makeResponse();
  await requireCampusAccess(request, replayResponse, () => {
    assert.fail("replayed proof must not call next");
  });
  assert.equal(replayResponse.statusCode, 403);
});

test("a campus proof for student A cannot be used by student B", async () => {
  process.env.CAMPUS_ACCESS_SECRET = "test-campus-secret";
  process.env.CAMPUS_ID = "pes-bangalore";
  const now = Math.floor(Date.now() / 1000);
  const requireCampusAccess = loadCampusMiddleware({
    insertOne: async () => {},
  });
  const response = makeResponse();

  await requireCampusAccess(
    {
      user: { uid: "student-b", role: "Student", status: "ACTIVE" },
      headers: {
        "x-campus-access-proof": makeProof({
          uid: "student-a",
          iat: now,
          exp: now + 60,
          jti: "proof-student-a-123456",
        }),
      },
    },
    response,
    () => assert.fail("a proof for another student must be rejected")
  );

  assert.equal(response.statusCode, 403);
});

for (const status of ["GRADUATED", "SUSPENDED"]) {
  test(`${status.toLowerCase()} student cannot create an order`, async () => {
    const service = loadOrderService({
      uid: `student-${status.toLowerCase()}`,
      role: "Student",
      status,
    });

    await assert.rejects(
      service.createOrder(`student-${status.toLowerCase()}`),
      (error) => error.statusCode === 403
    );
  });
}

test("students cannot update order status but authorized staff can", () => {
  const requireRole = require(roleMiddlewarePath).requireRole;
  const staffOnly = requireRole(
    "Admin",
    "Kitchen",
    "Faculty",
    "admin",
    "kitchen",
    "faculty"
  );

  for (const role of ["Student", "student"]) {
    const response = makeResponse();
    let nextCalled = false;
    staffOnly({ user: { role } }, response, () => {
      nextCalled = true;
    });
    assert.equal(response.statusCode, 403);
    assert.equal(nextCalled, false);
  }

  for (const role of ["admin", "kitchen", "faculty"]) {
    const response = makeResponse();
    let nextCalled = false;
    staffOnly({ user: { role } }, response, () => {
      nextCalled = true;
    });
    assert.equal(response.statusCode, 403);
    assert.equal(nextCalled, false);
  }

  for (const role of ["Admin", "Kitchen", "Faculty"]) {
    const response = makeResponse();
    let nextCalled = false;
    staffOnly({ user: { role } }, response, () => {
      nextCalled = true;
    });
    assert.equal(response.statusCode, 200);
    assert.equal(nextCalled, true);
  }

  const spoofedClaimsResponse = makeResponse();
  let spoofedClaimsNext = false;
  staffOnly(
    { user: { customClaims: { role: "Admin" } } },
    spoofedClaimsResponse,
    () => {
      spoofedClaimsNext = true;
    }
  );
  assert.equal(spoofedClaimsResponse.statusCode, 403);
  assert.equal(spoofedClaimsNext, false);
});
