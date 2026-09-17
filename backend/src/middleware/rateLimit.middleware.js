const buckets = new Map();

function getClientKey(req) {
  return req.ip || req.socket?.remoteAddress || "unknown";
}

function createRateLimiter({ windowMs, max, message }) {
  return (req, res, next) => {
    const now = Date.now();
    const key = getClientKey(req);
    const current = buckets.get(key);

    if (!current || current.resetAt <= now) {
      buckets.set(key, { count: 1, resetAt: now + windowMs });
      return next();
    }

    current.count += 1;

    if (current.count > max) {
      res.set("Retry-After", Math.ceil((current.resetAt - now) / 1000));
      return res.status(429).json({
        status: "error",
        code: "RATE_LIMITED",
        message,
      });
    }

    next();
  };
}

const authRateLimit = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: "Too many authentication attempts. Please try again later.",
});

function clearRateLimitBuckets() {
  buckets.clear();
}

module.exports = {
  createRateLimiter,
  authRateLimit,
  clearRateLimitBuckets,
};
