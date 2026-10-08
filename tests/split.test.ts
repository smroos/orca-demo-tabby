import { describe, expect, it } from 'vitest';
import { splitEvenly, totalWithTip } from '../src/split';

describe('totalWithTip', () => {
  it('adds a 20 percent tip', () => {
    expect(totalWithTip(10000, 20)).toBe(12000);
  });

  it('adds a 15 percent tip', () => {
    expect(totalWithTip(5000, 15)).toBe(5750);
  });
});

describe('splitEvenly', () => {
  it('splits a bill among four people', () => {
    expect(splitEvenly(10000, 20, 4)).toEqual([3000, 3000, 3000, 3000]);
  });

  it('splits a bill among two people', () => {
    expect(splitEvenly(5000, 15, 2)).toEqual([2875, 2875]);
  });

  it('gives one person the whole total', () => {
    expect(splitEvenly(10000, 20, 1)).toEqual([12000]);
  });
});
