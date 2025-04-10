require("dotenv").config();
const express = require("express");
const { hintExtractor } = require("./controllers/wikiFetcher");

const app = express();
const PORT = process.env.PORT || 3000;

app.get("/:keyword", async (req, res) => {
  const keyword = decodeURIComponent(req.params.keyword);
  const result = await hintExtractor(keyword);

  // Create HTML with unordered list
  let html = "<html><body><ul>";

  // Add each result as a list item
  result.forEach((item) => {
    html += `<li>${item}</li>`;
  });

  html += "</ul></body></html>";

  // Set Content-Type header to HTML and send the response
  res.setHeader("Content-Type", "text/html");
  res.send(html);
});

app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});
