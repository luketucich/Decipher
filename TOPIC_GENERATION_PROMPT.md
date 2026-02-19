# Decipher Topic Generation Prompt

Use this prompt with Codex/Copilot/any AI when you want a new Decipher topic.

Quick auto-fill (recommended):

- Export `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in your shell.
- Run `./build_topic_prompt.sh --copy` (or pass `YYYY-MM-DD` if you want a specific date)
- Paste the copied prompt into Codex/Copilot.

Replace:

- `{{DATE}}` with the target date in `YYYY-MM-DD`
- `{{PAST_ANSWERS}}` with a comma-separated list of previous answers (or `None`)

---

Generate a daily puzzle topic for my guessing game Decipher.
The goal is to guess the daily topic based on a series of hints.

There are seven topics per week, one for each day (Monday to Sunday):

- Monday: Movie
- Tuesday: Book
- Wednesday: History (Person or Event)
- Thursday: Music (Song or Album)
- Friday: TV Show
- Saturday: Public Figure (Celebrity, Politician, etc.)
- Sunday: Miscellaneous (anything fun and interesting)

Today is `{{DATE}}`.
Only use holiday-themed topics if today is exactly a major holiday (for example, spooky for Halloween on October 31 or festive for Christmas on December 25). Do not theme for nearby dates.

You must not use any of these past answers (or very similar ones, including synonyms, sequels, or closely related entries):
`{{PAST_ANSWERS}}`

Generate something new and non-repetitive.

Hint style requirements:

- Hints should start vague and become more specific.
- First 2-3 hints must be subtle and abstract.
- Avoid obvious giveaways early.
- Make hints cumulative so each one adds context.
- Difficulty target: medium-hard to hard (players should usually need 4-5 hints).

Hint structure (exactly 5 hints):

1. Broad Category
2. Emoji only (3-5 emojis, no text)
3. Obscure Quote
4. Trivia fact
5. Definition or direct clue

Topic choices should be recognizable, but not too easy.

Output only valid JSON in this exact shape:

```json
{
  "answer": "string (secret word/phrase)",
  "type": "string",
  "aliases": ["optional alias 1", "optional alias 2"],
  "hints": [
    { "content": "string", "type": "Category", "order": 1 },
    { "content": "string", "type": "Emoji", "order": 2 },
    { "content": "string", "type": "Quote", "order": 3 },
    { "content": "string", "type": "Trivia", "order": 4 },
    { "content": "string", "type": "Definition", "order": 5 }
  ]
}
```

Rules for the top-level `type`:
Must be exactly one of:

- Movie
- Book
- Historical Event
- Historical Figure
- Song
- Album
- Music
- TV Show
- Public Figure
- Miscellaneous

Rules for each hint `type`:
Must be exactly one of:

- Category
- Emoji
- Quote
- Trivia
- Definition

Return JSON only.
