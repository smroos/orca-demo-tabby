# Tabby

Split the bill, not hairs.

Tabby is a small bill splitter. Enter the bill amount, choose a tip, set how many people are at the table, and Tabby shows what each person pays. It is built with Vite, vanilla TypeScript, and Vitest.

## Quick start

```sh
npm install
npm run dev
```

Then open the URL that Vite prints, usually http://localhost:5173.

To show a value in the page footer, copy `.env.example` to `.env.local`. Without it the footer reads "not set".

## Scripts

| Script | What it does |
|---|---|
| `npm run dev` | Start the Vite dev server |
| `npm run build` | Typecheck, then build to `dist` |
| `npm run typecheck` | Run the TypeScript compiler without emitting |
| `npm test` | Run the unit tests once |

## Project layout

- `src/split.ts`: pure money logic, all amounts in integer cents
- `src/main.ts`: UI wiring
- `src/style.css`: styles
- `tests/`: unit tests

## License

MIT
