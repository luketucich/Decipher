const nlp = require("compromise");
const natural = require("natural");

const fetchWikipediaText = async (keyword) => {
  try {
    const wikiEndpoint = "https://simple.wikipedia.org/w/api.php";
    const wikiParams =
      "?action=query" +
      "&prop=extracts" +
      "&titles=" +
      encodeURIComponent(keyword) +
      "&explaintext=1" +
      "&format=json" +
      "&formatversion=2" +
      "&origin=*";

    const wikiUrl = wikiEndpoint + wikiParams;
    const response = await fetch(wikiUrl);
    const data = await response.json();
    const page = data.query.pages[0];

    if (page.extract) {
      return page.extract;
    } else {
      console.error("No extract found for the given keyword.");
      return "";
    }
  } catch (error) {
    console.error("Error fetching Wikipedia content:", error);
    return "";
  }
};

const getKeywordVariations = (keyword) => {
  const doc = nlp(keyword);
  const lowercaseKeyword = keyword.toLowerCase();
  const variations = new Set();

  // Add original forms
  variations.add(keyword);
  variations.add(lowercaseKeyword);

  // Add compromise forms
  const singular = doc.nouns().toSingular().text();
  const plural = doc.nouns().toPlural().text();
  variations.add(singular);
  variations.add(singular.toLowerCase());
  variations.add(plural);
  variations.add(plural.toLowerCase());

  // Add abbreviations if available
  const abbr = doc.abbreviations().text();
  if (abbr) variations.add(abbr);

  // Add natural.js forms
  const nounInflector = new natural.NounInflector();
  variations.add(nounInflector.pluralize(lowercaseKeyword));
  variations.add(nounInflector.singularize(lowercaseKeyword));

  // Add stemmed forms
  variations.add(natural.PorterStemmer.stem(lowercaseKeyword));
  variations.add(natural.LancasterStemmer.stem(lowercaseKeyword));

  // Filter out empty values and duplicates
  return [...variations].filter(Boolean);
};

const cleanText = (text, keyword) => {
  // Get all variations of the keyword
  const variations = getKeywordVariations(keyword);
  console.log("Variations:", variations);

  // Replace each variation with blanks
  for (const variation of variations) {
    text = text.replace(new RegExp(`\\b${variation}\\w*\\b`, "gi"), "_____");
  }

  // Remove content within parentheses and brackets
  text = text.replace(/\([^()]*\)/g, "");
  text = text.replace(/\[[^\[\]]*\]/g, "");

  // Remove quotes but keep their content
  text = text.replace(/"([^"]*)"/g, "$1");
  text = text.replace(/'([^']*)'/g, "$1");

  // Remove spaces before commas
  text = text.replace(/ ,/g, ",");

  return text;
};

const textExtractor = async (keyword) => {
  try {
    const rawText = await fetchWikipediaText(keyword);
    if (!rawText) return [];

    // Clean text first, then split into sentences
    const cleanedText = cleanText(rawText, keyword);
    const doc = nlp(cleanedText);
    return doc.sentences().out("array");
  } catch (error) {
    console.error("Error processing text:", error);
    return [];
  }
};

const passesGrammarCheck = (hint) => {
  // Check if the hint contains the placeholder, has more than 7 words, and ends with "."
  if (
    !hint.includes("_____") ||
    hint.split(/\s+/).length <= 10 ||
    hint[hint.length - 1] !== "."
  )
    return false;

  const doc = nlp(hint);
  const hasNoun = doc.nouns().out("array").length > 0;
  const hasVerb = doc.verbs().out("array").length > 0;

  return hasNoun && hasVerb;
};

const isValidHint = (hint) => {
  return passesGrammarCheck(hint);
};

const hintExtractor = async (keyword) => {
  const sentences = await textExtractor(keyword);
  const hints = [];

  sentences.forEach((sentence) => {
    if (isValidHint(sentence)) {
      hints.push(sentence);
    }
  });

  return hints;
};

module.exports = {
  hintExtractor,
};
