export function totalWithTip(subtotalCents: number, tipPercent: number): number {
  return Math.round(subtotalCents * (1 + tipPercent / 100));
}

export function splitEvenly(
  subtotalCents: number,
  tipPercent: number,
  people: number,
): number[] {
  const total = totalWithTip(subtotalCents, tipPercent);
  const per = Math.round(total / people);
  return Array(people).fill(per);
}
