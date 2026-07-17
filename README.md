# cpa-model-prices

Merged model pricing feed for the CLIProxyAPI `codex-token-usage` plugin.

The plugin refreshes `model_prices.json` from a single URL every few hours and
replaces the whole file, so any hand-added model entries are wiped on each
update. This repo solves that by serving a feed that already contains the
custom entries:

1. `scripts/merge.sh` downloads the upstream LiteLLM pricing file.
2. Entries from `custom_prices.json` are added only when the key does **not**
   exist upstream. If upstream later adds the same model, upstream wins.
3. The merged result is committed to `model_prices.json` by a GitHub Action
   (hourly cron, plus on every change to `custom_prices.json`).
4. The plugin's `model_price_update_url` points at the raw URL of
   `model_prices.json` in this repo, so every plugin refresh keeps custom
   entries while staying current with upstream.

Raw feed URL:

```
https://raw.githubusercontent.com/MrZhihao/cpa-model-prices/main/model_prices.json
```

## Adding or changing a custom model

Edit `custom_prices.json` and push. The Action runs on push and updates the
feed within a minute. Use LiteLLM field names (`input_cost_per_token`,
`output_cost_per_token`, `cache_read_input_token_cost`, `mode`, ...).

## Notes

- `codex-auto-review` has no dedicated public API SKU; it is approximated with
  `gpt-5.4-mini` public pricing.
- GitHub may pause scheduled workflows after long periods of repository
  inactivity; the hourly merge usually produces enough activity, and you can
  always re-run it manually from the Actions tab.
