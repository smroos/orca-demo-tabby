# Tabby

Tabby is a small bill splitter. Enter a bill amount, pick a tip, set the number of people, and it shows what each person pays. It is built with Vite, vanilla TypeScript, and Vitest, with no UI framework.

## Commands

- `npm run dev`: start the dev server
- `npm test`: run the unit tests
- `npm run typecheck`: run the TypeScript compiler without emitting

## Conventions

- Money is always integer cents. Convert to dollars only when formatting for display.
- `src/split.ts` stays pure: no DOM access, no side effects, no formatting.
- Unit tests live in `tests/` (Vitest only runs tests from there).
- UI wiring lives in `src/main.ts` and styles in `src/style.css`.
- Run `npm test` and `npm run typecheck` before finishing any change.
