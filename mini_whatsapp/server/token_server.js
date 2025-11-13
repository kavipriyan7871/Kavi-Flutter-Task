// server/token_server.js

const express = require("express");
const crypto = require("crypto");
const bodyParser = require("body-parser");
const multer = require("multer");
const cloudinary = require("cloudinary").v2;
const cors = require("cors");

const app = express();
app.use(cors());
app.use(bodyParser.json());

// ------------------------------------------------------
// 🔐 HARDCODED CONFIG (NO .env USED)
// ------------------------------------------------------

// 🔹 ZegoCloud Credentials
const ZEGO_APPID = 294033442;  // MUST MATCH AppConfig.zegoAppID
const ZEGO_SERVER_SECRET =
  "910d7105cab0923adbf60f12c760e10f177935b3834e56d11ef007d988f1f106";

// 🔹 Cloudinary Credentials
cloudinary.config({
  cloud_name: "dhe0pkz7a",
  api_key: "571361735266774",
  api_secret: "Lji13W2tXXzayh0gpBaLT0w22WE",
});

// 🔹 Multer (Store file in memory, no actual file creation)
const upload = multer({ storage: multer.memoryStorage() });


// ==========================================================
// 1️⃣ Generate Zego Token (Signature Mode)
// ==========================================================
function generateZegoToken(uid, effectSeconds = 3600) {
  const now = Math.floor(Date.now() / 1000);
  const expire = now + effectSeconds;
  const nonce = Math.floor(Math.random() * 1000000);

  // String to hash => appID + userID + expire + nonce
  const plain = `${ZEGO_APPID}${uid}${expire}${nonce}`;

  const signature = crypto
    .createHmac("sha256", ZEGO_SERVER_SECRET)
    .update(plain)
    .digest("hex");

  return {
    appID: ZEGO_APPID,
    uid,
    nonce,
    expired: expire,
    signature,
  };
}

app.post(["/token", "/zego/token"], (req, res) => {
  const { uid } = req.body;

  if (!uid) {
    return res.status(400).json({ error: "Missing uid" });
  }

  try {
    const token = generateZegoToken(uid);
    return res.json(token);
  } catch (err) {
    console.error("Token generation error:", err);
    return res.status(500).json({ error: err.message });
  }
});


// ==========================================================
// 2️⃣ Cloudinary Audio Upload Endpoint
// ==========================================================
app.post("/cloudinary/upload", upload.single("file"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No file sent" });
    }

    const chatId = req.body.chatId || "default_chat";

    const uploadStream = cloudinary.uploader.upload_stream(
      {
        resource_type: "video", // audio uploads must use "video"
        folder: `mini_whatsapp/${chatId}`,
        public_id: `voice_${Date.now()}`,
        overwrite: false,
      },
      (error, result) => {
        if (error) {
          console.error("Cloudinary upload error:", error);
          return res.status(500).json({ error: error.message });
        }
        return res.json({ url: result.secure_url });
      }
    );

    // Push file buffer → Cloudinary
    uploadStream.end(req.file.buffer);

  } catch (err) {
    console.error("Upload error:", err);
    return res.status(500).json({ error: err.message });
  }
});


// ==========================================================
// 3️⃣ Health Check
// ==========================================================
app.get("/", (_, res) => {
  res.send("✅ Token & Upload Server Running Successfully!");
});


// ==========================================================
// 4️⃣ Start Server
// ==========================================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
