import { defineConfig } from 'vitest/config';

export default defineConfig({
  cacheDir: '.vite',
  test: {
    include: ['.acceptance/**/*.test.ts'],
  },
});
