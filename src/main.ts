import './style.css';
import { splitEvenly, totalWithTip } from './split';

const TIP_OPTIONS = [15, 18, 20, 25];
const MIN_PEOPLE = 1;
const MAX_PEOPLE = 20;
const MAX_BILL_DOLLARS = 100000;

const currency = new Intl.NumberFormat('en-US', {
  style: 'currency',
  currency: 'USD',
});

const state = {
  bill: '84.50',
  tip: 18,
  people: 3,
};

const env = import.meta.env.VITE_TABBY_ENV || 'not set';
const lane = import.meta.env.VITE_TABBY_LANE || '';

const app = document.querySelector<HTMLDivElement>('#app')!;

app.innerHTML = `
  <div class="shell">
    <header class="header">
      <h1 class="brand">Tabby</h1>
      <p class="tagline">Split the bill, not hairs.</p>
    </header>

    <main class="main">
      <section class="card form" aria-label="Bill details">
        <div class="field">
          <label class="label" for="bill">Bill amount</label>
          <div class="money">
            <span class="money-symbol" aria-hidden="true">$</span>
            <input id="bill" class="input money-input" type="number" inputmode="decimal"
              min="0" max="${MAX_BILL_DOLLARS}" step="0.01" value="${state.bill}" />
          </div>
        </div>

        <div class="field">
          <span class="label" id="tip-label">Tip</span>
          <div class="segmented" role="group" aria-labelledby="tip-label">
            ${TIP_OPTIONS.map(
              (t) =>
                `<button type="button" class="segment" data-tip="${t}" aria-pressed="${t === state.tip}">${t}%</button>`,
            ).join('')}
          </div>
        </div>

        <div class="field">
          <label class="label" for="people">People</label>
          <div class="stepper">
            <button type="button" class="step" id="minus" aria-label="Remove a person">&minus;</button>
            <input id="people" class="input people-input" type="number" inputmode="numeric"
              min="${MIN_PEOPLE}" max="${MAX_PEOPLE}" step="1" value="${state.people}" />
            <button type="button" class="step" id="plus" aria-label="Add a person">+</button>
          </div>
        </div>
      </section>

      <section class="card result" aria-label="Result">
        <div role="status" aria-atomic="true">
          <p class="result-label">Each person pays</p>
          <p class="amount" id="amount"></p>
          <p class="total">Total with tip <span id="total"></span></p>
        </div>
      </section>
    </main>

    <footer class="footer">Environment: <span class="env" id="env"></span><span class="lane" id="lane-wrap" hidden> · Lane: <span class="env" id="lane"></span></span></footer>
  </div>
`;

const billInput = app.querySelector<HTMLInputElement>('#bill')!;
const peopleInput = app.querySelector<HTMLInputElement>('#people')!;
const minusButton = app.querySelector<HTMLButtonElement>('#minus')!;
const plusButton = app.querySelector<HTMLButtonElement>('#plus')!;
const segments = app.querySelectorAll<HTMLButtonElement>('.segment');
const amountEl = app.querySelector<HTMLElement>('#amount')!;
const totalEl = app.querySelector<HTMLElement>('#total')!;
app.querySelector<HTMLElement>('#env')!.textContent = env;
if (lane) {
  app.querySelector<HTMLElement>('#lane')!.textContent = lane;
  app.querySelector<HTMLElement>('#lane-wrap')!.hidden = false;
}

function billCents(): number {
  const parsed = Number.parseFloat(state.bill);
  if (!Number.isFinite(parsed)) return 0;
  const dollars = Math.min(MAX_BILL_DOLLARS, Math.max(0, parsed));
  return Math.round(Number(dollars.toFixed(2)) * 100);
}

function clampPeople(value: number): number {
  if (!Number.isFinite(value)) return MIN_PEOPLE;
  return Math.min(MAX_PEOPLE, Math.max(MIN_PEOPLE, Math.round(value)));
}

function render(): void {
  const subtotal = billCents();
  const shares = splitEvenly(subtotal, state.tip, state.people);
  amountEl.textContent = currency.format(shares[0] / 100);
  totalEl.textContent = currency.format(totalWithTip(subtotal, state.tip) / 100);

  segments.forEach((button) => {
    button.setAttribute('aria-pressed', String(Number(button.dataset.tip) === state.tip));
  });
  minusButton.disabled = state.people <= MIN_PEOPLE;
  plusButton.disabled = state.people >= MAX_PEOPLE;
}

billInput.addEventListener('input', () => {
  state.bill = billInput.value;
  render();
});

segments.forEach((button) => {
  button.addEventListener('click', () => {
    state.tip = Number(button.dataset.tip);
    render();
  });
});

peopleInput.addEventListener('input', () => {
  if (peopleInput.value === '') return;
  state.people = clampPeople(Number(peopleInput.value));
  if (Number(peopleInput.value) !== state.people) {
    peopleInput.value = String(state.people);
  }
  render();
});

peopleInput.addEventListener('change', () => {
  state.people = clampPeople(Number(peopleInput.value));
  peopleInput.value = String(state.people);
  render();
});

function setPeople(next: number): void {
  state.people = clampPeople(next);
  peopleInput.value = String(state.people);
  render();
}

minusButton.addEventListener('click', () => setPeople(state.people - 1));
plusButton.addEventListener('click', () => setPeople(state.people + 1));

render();
