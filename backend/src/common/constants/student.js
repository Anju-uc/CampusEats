const STUDENT_STATUS = Object.freeze({
  ACTIVE: "ACTIVE",
  GRADUATED: "GRADUATED",
  SUSPENDED: "SUSPENDED",
});

const STUDENT_PROGRAMS = Object.freeze([
  "BCA",
  "B.Com",
  "BBA",
  "B.Tech / Engineering",
  "Architecture",
  "MCA",
  "M.Tech",
  "MBA",
  "Other",
]);

const PROGRAM_ALIASES = Object.freeze({
  BCA: "BCA",
  BCOM: "B.Com",
  "B.COM": "B.Com",
  BBA: "BBA",
  BTECH: "B.Tech / Engineering",
  "B.TECH": "B.Tech / Engineering",
  ENGINEERING: "B.Tech / Engineering",
  ARCHITECTURE: "Architecture",
  MCA: "MCA",
  MTECH: "M.Tech",
  "M.TECH": "M.Tech",
  MBA: "MBA",
  OTHER: "Other",
});

function normalizeProgram(program) {
  if (typeof program !== "string") {
    return null;
  }

  return PROGRAM_ALIASES[program.trim().toUpperCase()] || null;
}

module.exports = {
  STUDENT_STATUS,
  STUDENT_PROGRAMS,
  normalizeProgram,
};