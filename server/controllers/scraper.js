const cheerio = require("cheerio");
const nlp = require("compromise");

const cleanData = (text, keyword) => {
  const lowerKeyword = keyword.toLowerCase();

  // Create the base form
  let baseWord = lowerKeyword;

  if (lowerKeyword.endsWith("es")) {
    baseWord = lowerKeyword.slice(0, -2);
  } else if (lowerKeyword.endsWith("s")) {
    baseWord = lowerKeyword.slice(0, -1);
  }

  // Create a pattern that matches words that start with the base word
  const pattern = new RegExp(`\\b${baseWord}\\w*\\b`, "gi");

  return text
    .replace(pattern, "_____")
    .replace(/\[.*?\]/g, "")
    .replace(/\(.*?\)/g, "")
    .replace(/\s+/g, " ")
    .trim();
};

// Checks grammar-based requirements: blank, word count, noun & verb presence
const passesGrammarCheck = (hint) => {
  if (!hint.includes("_____") || hint.split(/\s+/).length <= 5) return false;

  const doc = nlp(hint);
  const hasNoun = doc.nouns().out("array").length > 0;
  const hasVerb = doc.verbs().out("array").length > 0;

  return hasNoun && hasVerb;
};

// Filters out vague or generic phrasing
const passesVaguenessCheck = (hint) => {
  const lowerHint = hint.toLowerCase();

  const vagueStarts = [
    "some people",
    "many people",
    "it is",
    "they are",
    "there is",
    "there are",
    "this is",
    "these are",
    "others say",
    "people say",
    "one of the",
  ];
  if (vagueStarts.some((start) => lowerHint.startsWith(start))) return false;

  const vaguePatterns = [
    "is used",
    "are used",
    "is known",
    "are known",
    "is found",
    "are found",
    "is considered",
    "are considered",
    "is called",
    "are called",
    "is referred",
    "are referred",
    "can be",
    "may be",
    "are made",
  ];
  if (vaguePatterns.some((pattern) => lowerHint.includes(pattern)))
    return false;

  return true;
};

const isValidHint = (hint) => {
  return passesGrammarCheck(hint) && passesVaguenessCheck(hint);
};

const hintExtractor = (data, keyword) => {
  const $ = cheerio.load(data);
  const hints = [];

  $("p").each((index, element) => {
    // Prevents extracting hints whose next element is a list or table
    const nextElement = $(element).next();

    if (
      nextElement.length > 0 &&
      (nextElement.is("p") || nextElement.is("div"))
    ) {
      // Only extract first sentence
      const text = $(element).text();
      const hint = cleanData(text, keyword).split(". ")[0].trim();

      // If valid, push formatted hint
      if (isValidHint(hint)) {
        hints.push(hint.endsWith(".") ? hint : hint + ".");
      }
    }
  });

  return hints;
};

module.exports = {
  hintExtractor,
};
