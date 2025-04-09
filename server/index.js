require("dotenv").config();
const express = require("express");
const https = require("https");
const { hintExtractor } = require("./controllers/scraper");

const app = express();
const PORT = process.env.PORT || 3000;

app.get("/:keyword", (req, res) => {
  const keyword = encodeURIComponent(req.params.keyword);
  const url = `https://simple.wikipedia.org/wiki/${keyword}`;

  https
    .get(url, (response) => {
      let data = "";

      response.on("data", (chunk) => {
        data += chunk;
      });

      response.on("end", () => {
        console.log(hintExtractor(data, keyword));
        res.send(data);
      });
    })
    .on("error", (err) => {
      console.error("Error fetching Wikipedia:", err.message);
      res.status(500).send("Error fetching the Wikipedia page.");
    });
});

app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});
