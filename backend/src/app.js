const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const { corsOrigin } = require("./middleware/cors.middleware");

const routes = require("./routes");
const {
  errorMiddleware,
} = require("./middleware/error.middleware");

const app = express();

app.use(helmet());

app.use(cors({ origin: corsOrigin }));

app.use(
  express.json({
    limit: "1mb",
    verify: (req, res, buf) => {
      req.rawBody = buf;
    },
  })
);

app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    service: "CampusEATS Backend",
  });
});

const { renderKioskPage } = require("./modules/kiosk/kiosk.controller");
app.get("/kiosk", renderKioskPage);

app.use("/api", routes);

app.use((req, res) => {
  res.status(404).json({
    status: "error",
    code: "NOT_FOUND",
    message: "Route not found",
  });
});

app.use(errorMiddleware);

module.exports = app;