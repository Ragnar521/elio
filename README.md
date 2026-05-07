# Elio

Elio is a Flutter mood and clarity app for iOS and Android. It helps users check in with their mood, set a daily intention, connect the day to goals or life directions, and reflect without turning personal growth into a checklist.

## Current Product Loop

1. Capture mood with a simple slider and mood word.
2. Write one intention.
3. Select any goals or life directions that were present today.
4. Optionally add per-goal notes: one small step, what blocked or scared you, and what might help.
5. Choose whether selected goals should get goal-specific reflection prompts.
6. Save the check-in and review patterns over time.

Directions separate presence from progress. A goal can matter today even if no step happened; progress is counted only when the user writes a small step.

## Product Principles

- Local-first and private.
- Warm, non-clinical language.
- No streak shame or completion pressure.
- Useful patterns over heavy dashboards.
- Goals as gentle directions, not hard tasks.

## Development

Run checks before opening a PR:

```sh
flutter analyze
flutter test
```
