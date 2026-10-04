const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const test = require("node:test");

process.env.CAMPUS_ACCESS_SECRET = "test-campus-checkin-secret-value-32chars";
process.env.CAMPUS_ID = "pes-bangalore";

const mongodbPath = require.resolve("../src/config/mongodb");
const authServicePath = require.resolve("../src/modules/auth/auth.service");
const campusMiddlewarePath = require.resolve("../src/middleware/campusAccess.middleware");

// Mock response object
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

// In-memory collection simulation
function createMockDb() {
  const challenges = new Map();
  const proofs = new Map();

  return {
    collection(name) {
      if (name === "campusCheckinChallenges") {
        return {
          async insertOne(doc) {
            if (challenges.has(doc.jti)) {
              const err = new Error("Duplicate key");
              err.code = 11000;
              throw err;
            }
            challenges.set(doc.jti, doc);
            return { acknowledged: true };
          },
        };
      }
      if (name === "campusAccessProofs") {
        return {
          async insertOne(doc) {
            if (proofs.has(doc.jti)) {
              const err = new Error("Duplicate key");
              err.code = 11000;
              throw err;
            }
            proofs.set(doc.jti, doc);
            return { acknowledged: true };
          },
        };
      }
      return {
        async insertOne() { return { acknowledged: true }; },
        async findOne() { return null; },
      };
    },
  };
}

function loadModules(mockDb) {
  require.cache[mongodbPath] = {
    exports: {
      getDb: () => mockDb,
      connectMongoDB: async () => {},
      closeMongoDB: async () => {},
    },
  };
  delete require.cache[authServicePath];
  delete require.cache[campusMiddlewarePath];

  return {
    authService: require(authServicePath),
    requireCampusAccess: require(campusMiddlewarePath).requireCampusAccess,
  };
}

test("1. Campus Check-in: Missing or empty challenge is rejected with 400", async () => {
  const mockDb = createMockDb();
  const { authService } = loadModules(mockDb);

  await assert.rejects(
    authService.verifyCampusCheckinAndIssueProof({
      uid: "student-123",
      checkinChallenge: "",
    }),
    (err) => err.statusCode === 400
  );
});

test("2. Campus Check-in: Valid campus check-in challenge issues a valid student-bound proof", async () => {
  const mockDb = createMockDb();
  const { authService, requireCampusAccess } = loadModules(mockDb);

  const validChallenge = authService.createCampusCheckinChallenge({ expiresIn: 120 });
  const result = await authService.verifyCampusCheckinAndIssueProof({
    uid: "student-123",
    checkinChallenge: validChallenge,
  });

  assert.ok(result.campusProof, "Must return campusProof string");
  assert.equal(result.campusId, "pes-bangalore");
  assert.equal(result.expiresInSeconds, 60);

  // Verify the issued proof is accepted by requireCampusAccess for student-123
  const req = {
    user: { uid: "student-123", role: "Student", status: "ACTIVE" },
    headers: { "x-campus-access-proof": result.campusProof },
  };
  let nextCalled = false;
  await requireCampusAccess(req, makeResponse(), () => {
    nextCalled = true;
  });

  assert.equal(nextCalled, true, "requireCampusAccess must accept valid issued proof");
});

test("3. Campus Check-in: Expired check-in challenge is rejected with 403", async () => {
  const mockDb = createMockDb();
  const { authService } = loadModules(mockDb);

  const past = Math.floor(Date.now() / 1000) - 200;
  const payload = Buffer.from(
    JSON.stringify({
      type: "CAMPUS_CHECKIN_CHALLENGE",
      campusId: "pes-bangalore",
      iat: past - 120,
      exp: past,
      jti: crypto.randomUUID(),
    })
  ).toString("base64url");
  const signature = crypto
    .createHmac("sha256", process.env.CAMPUS_ACCESS_SECRET)
    .update(payload)
    .digest("base64url");
  const expiredChallenge = `${payload}.${signature}`;

  await assert.rejects(
    authService.verifyCampusCheckinAndIssueProof({
      uid: "student-123",
      checkinChallenge: expiredChallenge,
    }),
    (err) => err.statusCode === 403
  );
});

test("4. Campus Check-in: Replayed check-in challenge is rejected with 403", async () => {
  const mockDb = createMockDb();
  const { authService } = loadModules(mockDb);

  const challenge = authService.createCampusCheckinChallenge({ expiresIn: 120 });

  // First check-in succeeds
  const firstResult = await authService.verifyCampusCheckinAndIssueProof({
    uid: "student-123",
    checkinChallenge: challenge,
  });
  assert.ok(firstResult.campusProof);

  // Second check-in with same challenge must be rejected
  await assert.rejects(
    authService.verifyCampusCheckinAndIssueProof({
      uid: "student-123",
      checkinChallenge: challenge,
    }),
    (err) => err.statusCode === 403
  );
});

test("5. Campus Access: Proof issued for Student A is rejected when used by Student B", async () => {
  const mockDb = createMockDb();
  const { authService, requireCampusAccess } = loadModules(mockDb);

  const challenge = authService.createCampusCheckinChallenge({ expiresIn: 120 });
  const resultA = await authService.verifyCampusCheckinAndIssueProof({
    uid: "student-A",
    checkinChallenge: challenge,
  });

  const reqB = {
    user: { uid: "student-B", role: "Student", status: "ACTIVE" },
    headers: { "x-campus-access-proof": resultA.campusProof },
  };
  const resB = makeResponse();
  let nextCalled = false;

  await requireCampusAccess(reqB, resB, () => {
    nextCalled = true;
  });

  assert.equal(nextCalled, false, "Proof for student A must not authenticate student B");
  assert.equal(resB.statusCode, 403);
});

test("6. Campus Access: Missing campus configuration returns 503", async () => {
  const originalSecret = process.env.CAMPUS_ACCESS_SECRET;
  delete process.env.CAMPUS_ACCESS_SECRET;

  const mockDb = createMockDb();
  const { authService } = loadModules(mockDb);

  await assert.rejects(
    authService.verifyCampusCheckinAndIssueProof({
      uid: "student-123",
      checkinChallenge: "dummy.challenge",
    }),
    (err) => err.statusCode === 503
  );

  process.env.CAMPUS_ACCESS_SECRET = originalSecret;
});
