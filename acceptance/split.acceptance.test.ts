import { describe, expect, it } from 'vitest';
import { splitByShares, splitEvenly, totalWithTip } from '../src/split';

const sum = (values: number[]): number => values.reduce((a, b) => a + b, 0);

function makeLcg(seed: number): () => number {
  let state = seed >>> 0;
  return () => {
    state = (Math.imul(state, 1664525) + 1013904223) >>> 0;
    return state / 0x100000000;
  };
}

describe('acceptance', () => {
  it('A1: splits by weights and matches the exact total', () => {
    expect(splitByShares(8000, 20, [2, 1, 1])).toEqual([4800, 2400, 2400]);
  });

  it('A2: distributes leftover cents so the sum is exact', () => {
    const result = splitByShares(10000, 0, [1, 1, 1]);
    expect(sum(result)).toBe(10000);
    for (const amount of result) {
      expect([3333, 3334]).toContain(amount);
    }
  });

  it('A3: always sums to the total for 200 seeded cases', () => {
    const next = makeLcg(20260508);
    for (let i = 0; i < 200; i++) {
      const subtotal = 1 + Math.floor(next() * 100000);
      const tip = Math.floor(next() * 31);
      const count = 1 + Math.floor(next() * 8);
      const shares = Array.from({ length: count }, () => 1 + Math.floor(next() * 5));
      const result = splitByShares(subtotal, tip, shares);
      expect(result).toHaveLength(count);
      expect(sum(result)).toBe(totalWithTip(subtotal, tip));
      for (const amount of result) {
        expect(Number.isInteger(amount)).toBe(true);
        expect(amount).toBeGreaterThanOrEqual(0);
      }
    }
  });

  it('A4: even split also sums to the total', () => {
    expect(sum(splitEvenly(10000, 0, 3))).toBe(10000);
  });
});
