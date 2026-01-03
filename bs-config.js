const fs = require("fs");
const path = require("path");

const rootDir = __dirname;

function hasFile(filePath) {
  try {
    return fs.statSync(filePath).isFile();
  } catch {
    return false;
  }
}

function resolveRequestPath(urlPath) {
  const cleaned = decodeURIComponent(urlPath.split("?")[0].split("#")[0]);
  const normalized = cleaned.startsWith("/") ? cleaned.slice(1) : cleaned;
  const directPath = path.join(rootDir, normalized);
  if (hasFile(directPath)) {
    return directPath;
  }

  if (cleaned.endsWith("/")) {
    const indexPath = path.join(directPath, "index.html");
    if (hasFile(indexPath)) {
      return indexPath;
    }
  } else if (!path.extname(cleaned)) {
    const indexPath = path.join(directPath, "index.html");
    if (hasFile(indexPath)) {
      return indexPath;
    }
  }

  return null;
}

module.exports = {
  notify: false,
  open: false,
  host: "localhost",
  online: false,
  port: 8080,
  ui: false,
  server: {
    baseDir: ".",
    middleware: [
      function handleNotFound(req, res, next) {
        if (req.method !== "GET" && req.method !== "HEAD") {
          return next();
        }

        if (resolveRequestPath(req.url)) {
          return next();
        }

        const notFoundPath = path.join(rootDir, "404.html");
        if (!hasFile(notFoundPath) || req.url === "/404.html") {
          return next();
        }

        res.statusCode = 404;
        req.url = "/404.html";
        return next();
      }
    ]
  },
  files: ["index.html", "help/**/*.html", "404.html", "assets/css/*.css", "assets/js/*.js"]
};
