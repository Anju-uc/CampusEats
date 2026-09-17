const assert = require("node:assert/strict");
const test = require("node:test");

const firebasePath = require.resolve("../src/config/firebase");
const mongodbPath = require.resolve("../src/config/mongodb");
const authServicePath = require.resolve("../src/modules/auth/auth.service");
const { upsertRegistryRecord } = require("../seed-student-registry.js");

function loadAuthService({ registryStudent, user, createUser } = {}) {
  const auth = {
    createUser: createUser || (async () => ({ uid: "new-uid" })),
    deleteUser: async () => undefined,
    updateUser: async () => undefined,
    revokeRefreshTokens: async () => undefined,
  };
  const registry = {
    findOne: async () => registryStudent || null,
    updateOne: async () => ({ acknowledged: true }),
  };
  const users = {
    findOne: async () => user || null,
    insertOne: async () => ({ acknowledged: true }),
    updateOne: async () => ({ acknowledged: true }),
  };

  require.cache[firebasePath] = { exports: { auth } };
  require.cache[mongodbPath] = {
    exports: {
      getDb: () => ({
        collection: (name) =>
          name === "studentRegistry" ? registry : users,
      }),
    },
  };
  delete require.cache[authServicePath];

  return require(authServicePath);
}

function middlewareRequest(body) {
  const response = {
    statusCode: 200,
    body: null,
    status(code) {
      response.statusCode = code;
      return response;
    },
    json(value) {
      response.body = value;
      return response;
    },
  };
  const request = { body };
  let called = false;

  return {
    request,
    response,
    next: () => {
      called = true;
    },
    wasNextCalled: () => called,
  };
}

const activeRegistryStudent = {
  _id: "registry-id",
  studentId: "PES1UG23CA001",
  name: "Official Student",
  program: "BCA",
  status: "ACTIVE",
  graduationYear: 2027,
};

test("registration validation requires only SRN and password", () => {
  const { validateRegister } = require("../src/modules/auth/auth.validator");
  const context = middlewareRequest({
    studentId: " pes 1ug23ca001 ",
    password: "strong-password",
  });

  validateRegister(context.request, context.response, context.next);

  assert.equal(context.wasNextCalled(), true);
  assert.equal(context.request.body.studentId, "PES1UG23CA001");
  assert.equal(context.request.body.name, undefined);
  assert.equal(context.request.body.program, undefined);
});

test("valid ACTIVE registry student can register using official data", async () => {
  let firebaseInput;
  const service = loadAuthService({
    registryStudent: activeRegistryStudent,
    createUser: async (input) => {
      firebaseInput = input;
      return { uid: "new-uid" };
    },
  });

  const result = await service.registerUser({
    studentId: " pes 1ug23ca001 ",
    name: "Client Forged Name",
    program: "MBA",
    password: "strong-password",
  });

  assert.equal(firebaseInput.displayName, "Official Student");
  assert.equal(result.name, "Official Student");
  assert.equal(result.program, "BCA");
  assert.equal(result.status, "ACTIVE");
  assert.equal(result.role, "Student");
});

test("unknown SRN cannot register", async () => {
  const service = loadAuthService();

  await assert.rejects(
    service.registerUser({ studentId: "PES-UNKNOWN", password: "password" }),
    (error) => error.statusCode === 403
  );
});

for (const status of ["GRADUATED", "SUSPENDED"]) {
  test(`${status} registry student cannot register`, async () => {
    const service = loadAuthService({
      registryStudent: { ...activeRegistryStudent, status },
    });

    await assert.rejects(
      service.registerUser({ studentId: "PES1UG23CA001", password: "password" }),
      (error) => error.statusCode === 403
    );
  });
}

test("duplicate SRN cannot register", async () => {
  let createCalls = 0;
  const service = loadAuthService({
    registryStudent: activeRegistryStudent,
    user: { uid: "existing", studentId: "PES1UG23CA001", role: "Student" },
    createUser: async () => {
      createCalls += 1;
      return { uid: "unexpected" };
    },
  });

  await assert.rejects(
    service.registerUser({ studentId: "PES1UG23CA001", password: "password" }),
    (error) => error.statusCode === 409
  );
  assert.equal(createCalls, 0);
});

test("active registry student can log in", async () => {
  const service = loadAuthService({
    registryStudent: activeRegistryStudent,
    user: {
      uid: "active",
      studentId: "PES1UG23CA001",
      name: "Official Student",
      program: "BCA",
      status: "ACTIVE",
      role: "Student",
    },
  });
  const originalApiKey = process.env.FIREBASE_WEB_API_KEY;
  const originalFetch = global.fetch;
  process.env.FIREBASE_WEB_API_KEY = "test-key";
  global.fetch = async () => ({
    ok: true,
    json: async () => ({
      localId: "active",
      idToken: "id-token",
      refreshToken: "refresh-token",
      expiresIn: "3600",
    }),
  });

  try {
    const result = await service.loginUser({
      studentId: "pes 1ug23ca001",
      password: "password",
    });

    assert.equal(result.studentId, "PES1UG23CA001");
    assert.equal(result.name, "Official Student");
    assert.equal(result.program, "BCA");
    assert.equal(result.email, undefined);
  } finally {
    global.fetch = originalFetch;
    if (originalApiKey === undefined) {
      delete process.env.FIREBASE_WEB_API_KEY;
    } else {
      process.env.FIREBASE_WEB_API_KEY = originalApiKey;
    }
  }
});

test("registry upsert synchronizes existing user and enables Firebase", async () => {
  const userUpdates = [];
  const firebaseUpdates = [];
  const db = {
    collection: (name) => {
      if (name === "studentRegistry") {
        return {
          updateOne: async () => ({ acknowledged: true }),
        };
      }

      return {
        findOne: async () => ({ _id: "user-id", uid: "user-uid" }),
        updateOne: async (filter, update) => {
          userUpdates.push({ filter, update });
        },
      };
    },
  };
  const auth = {
    getUser: async () => ({ uid: "user-uid", disabled: true }),
    updateUser: async (uid, update) => firebaseUpdates.push({ uid, update }),
    revokeRefreshTokens: async () => {
      throw new Error("active users must not revoke tokens");
    },
  };
  await upsertRegistryRecord({
    db,
    auth,
    record: activeRegistryStudent,
  });

  assert.deepEqual(userUpdates[0].update.$set, {
    studentId: "PES1UG23CA001",
    name: "Official Student",
    program: "BCA",
    status: "ACTIVE",
    updatedAt: userUpdates[0].update.$set.updatedAt,
  });
  assert.deepEqual(firebaseUpdates, [
    { uid: "user-uid", update: { disabled: false } },
  ]);
});

test("registry upsert synchronizes inactive user and revokes Firebase tokens", async () => {
  const userUpdates = [];
  const firebaseUpdates = [];
  let revokedUid;
  const db = {
    collection: (name) => {
      if (name === "studentRegistry") {
        return {
          updateOne: async () => ({ acknowledged: true }),
        };
      }

      return {
        findOne: async () => ({ _id: "user-id", uid: "user-uid" }),
        updateOne: async (filter, update) => {
          userUpdates.push({ filter, update });
        },
      };
    },
  };
  const auth = {
    getUser: async () => ({ uid: "user-uid", disabled: false }),
    updateUser: async (uid, update) => firebaseUpdates.push({ uid, update }),
    revokeRefreshTokens: async (uid) => {
      revokedUid = uid;
    },
  };
  await upsertRegistryRecord({
    db,
    auth,
    record: { ...activeRegistryStudent, status: "GRADUATED" },
  });

  assert.equal(userUpdates[0].update.$set.status, "GRADUATED");
  assert.deepEqual(firebaseUpdates, [
    { uid: "user-uid", update: { disabled: true } },
  ]);
  assert.equal(revokedUid, "user-uid");
});

for (const status of ["GRADUATED", "SUSPENDED"]) {
  test(`${status} registry student cannot log in`, async () => {
    const service = loadAuthService({
      registryStudent: { ...activeRegistryStudent, status },
      user: {
        uid: "inactive",
        studentId: "PES1UG23CA001",
        status,
        role: "Student",
      },
    });

    await assert.rejects(
      service.loginUser({ studentId: "PES1UG23CA001", password: "password" }),
      (error) => error.statusCode === 401
    );
  });
}
