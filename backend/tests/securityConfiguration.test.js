const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const {
  createRateLimiter,
  clearRateLimitBuckets,
} = require("../src/middleware/rateLimit.middleware");
const { isAllowedOrigin } = require("../src/middleware/cors.middleware");

function makeResponse() {
  return {
    statusCode: 200,
    headers: {},
    body: null,
    set(name, value) {
      this.headers[name] = value;
    },
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

test("authentication rate limiter rejects requests after the configured limit", () => {
  clearRateLimitBuckets();
  const limiter = createRateLimiter({
    windowMs: 60_000,
    max: 2,
    message: "limited",
  });
  const request = { ip: "198.51.100.10" };
  let nextCalls = 0;

  limiter(request, makeResponse(), () => {
    nextCalls += 1;
  });
  limiter(request, makeResponse(), () => {
    nextCalls += 1;
  });
  const blocked = makeResponse();
  limiter(request, blocked, () => {
    nextCalls += 1;
  });

  assert.equal(nextCalls, 2);
  assert.equal(blocked.statusCode, 429);
  assert.equal(blocked.headers["Retry-After"] !== undefined, true);
});

test("CORS allows configured localhost origins and rejects unknown origins", () => {
  assert.equal(isAllowedOrigin("http://localhost:3000"), true);
  assert.equal(isAllowedOrigin("http://127.0.0.1:5000"), true);
  assert.equal(isAllowedOrigin("https://untrusted.example"), false);
  assert.equal(isAllowedOrigin(undefined), true);
});

test("src/server.js is the only active backend deployment entry point", () => {
  const packageJson = require("../package.json");
  assert.equal(packageJson.scripts.start, "node src/server.js");
  assert.equal(packageJson.scripts.dev, "nodemon src/server.js");
  assert.equal(
    fs.existsSync(path.join(__dirname, "..", "server.js")),
    false
  );
});