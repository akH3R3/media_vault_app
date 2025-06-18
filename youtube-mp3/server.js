const express = require("express");
const bodyParser = require("body-parser");
const { spawn } = require("child_process");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.post("/download", (req, res) => {
  const videoUrl = req.body.url;
  if (!videoUrl) return res.status(400).json({ error: "Missing URL" });

  console.log("🎬 Received YouTube URL:", videoUrl);

  // Tell Flutter this is an audio stream
  res.setHeader("Content-Type", "audio/mpeg");
  res.setHeader("Content-Disposition", "attachment; filename=audio.mp3");

  const ytdlp = spawn("yt-dlp", [
    "-f", "bestaudio",
    "-x", "--audio-format", "mp3",
    "-o", "-", // Output to stdout (stream, not file)
    videoUrl,
  ]);

  // Pipe to response (to Flutter)
  ytdlp.stdout.pipe(res);

  ytdlp.stderr.on("data", (data) => {
    console.error(`yt-dlp stderr: ${data}`);
  });

  ytdlp.on("error", (err) => {
    console.error("❌ yt-dlp failed:", err);
    res.status(500).end();
  });

  ytdlp.on("close", (code) => {
    if (code !== 0) {
      console.error(`yt-dlp exited with code ${code}`);
      if (!res.headersSent) {
        res.status(500).send("yt-dlp failed to process this video.");
      }
    }
  });
});

app.listen(3000, () => {
  console.log("✅ Server running at http://localhost:3000");
});
