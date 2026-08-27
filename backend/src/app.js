const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const routes = require("./routes");
const {
  errorMiddleware,
} = require("./middleware/error.middleware");

const app = express();

app.use(helmet());

app.use(cors());

app.use(express.json());

app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    service: "CampusEATS Backend",
  });
});

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