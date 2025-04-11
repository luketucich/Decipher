require("dotenv").config();
const express = require("express");
const { getRandomTopic } = require("./controllers/wikiFetcher");

const app = express();
const PORT = process.env.PORT || 3000;

app.get("/decipher", async (req, res) => {
  const result = await getRandomTopic();
  console.log(result);

  // Create HTML response
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <title>Decipher Result</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h2 { color: #333; }
        ul { margin-bottom: 20px; }
      </style>
    </head>
    <body>
      <h2>Topic: ${result.keyword}</h2>
      
      <h3>Variations:</h3>
      <ul>
        ${result.variations
          .map((variation) => `<li>${variation}</li>`)
          .join("")}
      </ul>
      
      <h3>Hints:</h3>
      <ul>
        ${result.hints.map((hint) => `<li>${hint}</li>`).join("")}
      </ul>
    </body>
    </html>
  `;

  res.send(html);
});

app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});
