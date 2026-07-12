# Decipher

Decipher is a daily iOS puzzle game built around progressively revealing hints. Players get five attempts to identify the topic, then compare their result with the community.

[Download Decipher on the App Store](https://apps.apple.com/us/app/decipher-daily-puzzle-game/id6755046200)

## How it works

- Each day has one shared topic and five hints, from broad to specific.
- Answer matching accepts aliases, minor typos, and common variations.
- Local progress tracks streaks, solve times, and play history.
- Community results show completion and guess statistics after each game.

## Architecture

The SwiftUI client owns gameplay and local progress. Three Supabase Edge Functions provide the daily topic, record completed games, and return aggregate statistics. A small prompt workflow helps create new topics while checking previous answers for repeats.

```text
mobile/Decipher/          SwiftUI app
supabase/functions/      Daily topic, submission, and statistics endpoints
supabase/migrations/     Database permissions and topic alias support
build_topic_prompt.sh    Prompt builder for new daily topics
```

## Run locally

1. Open `mobile/Decipher.xcodeproj` in Xcode.
2. Select an iOS 17 or newer simulator or device.
3. Build and run the `Decipher` target.

The client uses a Supabase publishable key. Administrative credentials are not required to build or run the app.

## Privacy

See the [privacy policy](PRIVACY_POLICY.md) for the gameplay data the app collects.
