const assert = require("node:assert/strict");
const test = require("node:test");

const firebasePath = require.resolve("../src/config/firebase");
const mongodbPath = require.resolve("../src/config/mongodb");
const authServicePath = require.resolve("../src/modules/auth/auth.service");
const { ROLES } = require("../src/common/constants/roles");

function loadAuthServiceWithUsers({ usersList = [], createUser } = {}) {
  const usersCollection = {
    findOne: async (query) => {
      if (query.$or) {
        return (
          usersList.find((u) =>
            query.$or.some((clause) => {
              const [k, v] = Object.entries(clause)[0];
              return (
                u[k] &&
                String(u[k]).toLowerCase() === String(v).toLowerCase()
              );
            })
          ) || null
        );
      }
      const [k, v] = Object.entries(query)[0];
      return (
        usersList.find(
          (u) =>
            u[k] && String(u[k]).toLowerCase() === String(v).toLowerCase()
        ) || null
      );
    },
    insertOne: async (doc) => {
      usersList.push(doc);
      return { acknowledged: true };
    },
    updateOne: async () => ({ acknowledged: true }),
  };

  const auth = {
    createUser: createUser || (async () => ({ uid: "new-staff-uid" })),
    getUserByEmail: async (email) => ({ uid: "existing-staff-uid", email }),
    deleteUser: async () => undefined,
    updateUser: async () => undefined,
    revokeRefreshTokens: async () => undefined,
  };

  require.cache[firebasePath] = { exports: { auth } };
  require.cache[mongodbPath] = {
    exports: {
      getDb: () => ({
        collection: () => usersCollection,
      }),
    },
  };
  delete require.cache[authServicePath];
  return require(authServicePath);
}

test("staff login with valid Admin credentials returns real authenticated session with Admin role", async () => {
  process.env.FIREBASE_WEB_API_KEY = "test-api-key";

  const adminUser = {
    uid: "admin-uid-100",
    staffId: "admin.bengaluru",
    email: "admin@bengaluru.campuseats.com",
    name: "Bengaluru Admin",
    role: ROLES.ADMIN,
    status: "ACTIVE",
    cafeteria: "Bengaluru Cafe",
    cafeteriaId: "bengaluru",
  };

  const service = loadAuthServiceWithUsers({ usersList: [adminUser] });

  // Mock global fetch for Firebase Auth REST API
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, options) => {
    return {
      ok: true,
      json: async () => ({
        idToken: "real-firebase-admin-jwt-token",
        refreshToken: "refresh-token-admin",
        expiresIn: "3600",
      }),
    };
  };

  try {
    const result = await service.loginStaff({
      identifier: "admin.bengaluru",
      password: "secure-password-123",
    });

    assert.equal(result.uid, "admin-uid-100");
    assert.equal(result.role, ROLES.ADMIN);
    assert.equal(result.idToken, "real-firebase-admin-jwt-token");
    assert.equal(result.cafeteria, "Bengaluru Cafe");
    assert.equal(result.status, "ACTIVE");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("staff login with valid Kitchen credentials returns real authenticated session with Kitchen role", async () => {
  process.env.FIREBASE_WEB_API_KEY = "test-api-key";

  const kitchenUser = {
    uid: "kitchen-uid-200",
    staffId: "kitchen.pesu",
    email: "kitchen@pesu.campuseats.com",
    name: "Cafe PESU Kitchen Staff",
    role: ROLES.KITCHEN,
    status: "ACTIVE",
    cafeteria: "Cafe PESU",
    cafeteriaId: "pesu",
  };

  const service = loadAuthServiceWithUsers({ usersList: [kitchenUser] });

  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => ({
    ok: true,
    json: async () => ({
      idToken: "real-firebase-kitchen-jwt-token",
      refreshToken: "refresh-token-kitchen",
      expiresIn: "3600",
    }),
  });

  try {
    const result = await service.loginStaff({
      identifier: "kitchen@pesu.campuseats.com",
      password: "kitchen-password-456",
    });

    assert.equal(result.uid, "kitchen-uid-200");
    assert.equal(result.role, ROLES.KITCHEN);
    assert.equal(result.idToken, "real-firebase-kitchen-jwt-token");
    assert.equal(result.cafeteria, "Cafe PESU");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("student cannot authenticate as Admin or Kitchen by supplying a client role parameter", async () => {
  const studentUser = {
    uid: "student-uid-300",
    studentId: "PES1UG23CS001",
    email: "student@pes.edu",
    name: "Student Tester",
    role: ROLES.STUDENT,
    status: "ACTIVE",
  };

  const service = loadAuthServiceWithUsers({ usersList: [studentUser] });

  await assert.rejects(
    async () => {
      await service.loginStaff({
        identifier: "PES1UG23CS001",
        password: "student-pass",
        role: "Admin", // client attempts to spoof role
      });
    },
    (err) => {
      assert.equal(err.statusCode, 401);
      assert.equal(err.message, "Invalid staff credentials");
      return true;
    }
  );
});

test("wrong staff password is rejected", async () => {
  process.env.FIREBASE_WEB_API_KEY = "test-api-key";

  const adminUser = {
    uid: "admin-uid-100",
    staffId: "admin.bengaluru",
    role: ROLES.ADMIN,
    status: "ACTIVE",
  };

  const service = loadAuthServiceWithUsers({ usersList: [adminUser] });

  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => ({
    ok: false,
    json: async () => ({
      error: { message: "INVALID_PASSWORD" },
    }),
  });

  try {
    await assert.rejects(
      async () => {
        await service.loginStaff({
          identifier: "admin.bengaluru",
          password: "wrong-password",
        });
      },
      (err) => {
        assert.equal(err.statusCode, 401);
        assert.equal(err.message, "Invalid staff credentials");
        return true;
      }
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("inactive staff account is rejected", async () => {
  const inactiveAdmin = {
    uid: "admin-uid-suspended",
    staffId: "admin.suspended",
    role: ROLES.ADMIN,
    status: "SUSPENDED",
  };

  const service = loadAuthServiceWithUsers({ usersList: [inactiveAdmin] });

  await assert.rejects(
    async () => {
      await service.loginStaff({
        identifier: "admin.suspended",
        password: "any-password",
      });
    },
    (err) => {
      assert.equal(err.statusCode, 403);
      assert.equal(err.message, "Staff account is not active");
      return true;
    }
  );
});

test("provisionStaffUser creates verified staff record with assigned role", async () => {
  const usersList = [];
  const service = loadAuthServiceWithUsers({ usersList });

  const result = await service.provisionStaffUser({
    email: "newadmin@campuseats.com",
    staffId: "newadmin",
    password: "secure-admin-pass-123",
    name: "New Admin",
    role: ROLES.ADMIN,
    cafeteria: "Bengaluru Cafe",
  });

  assert.equal(result.email, "newadmin@campuseats.com");
  assert.equal(result.role, ROLES.ADMIN);
  assert.equal(result.status, "ACTIVE");
  assert.equal(usersList.length, 1);
  assert.equal(usersList[0].role, ROLES.ADMIN);
});
