# Changelog

All notable changes to the LeadGen.tools skill. Versions follow [semver](https://semver.org).

## 1.1.0 — 2026-09-30

- LinkedIn and WhatsApp after the email: `campaigns/linkedin` (profiles + ready connection notes) and
  `campaigns/whatsapp` (international phones, whether they're on WhatsApp, the message and a link that opens
  the chat with it typed), with their safety rules; new workflow 8. The old "no LinkedIn automation" limit
  is replaced by how to do it safely in the user's own browser.

## 1.0.0 — 2026-09-27

First public release.

- `SKILL.md`: capabilities map, setup for OpenClaw and other agents, golden rules (spend, approval before
  sending, quality, compliance), send-here vs export, the core pipeline, email writing guide, credits,
  errors, reporting format and limits.
- `references/api.md`: every API v1 endpoint — companies, people, crawl, search, ads, places, reviews,
  verify, projects, leads, accounts, campaigns, generate, steps, launch, control, status, recipients
  (with reply category, summary and text).
- `references/workflows.md`: step-by-step recipes.
- `references/playbooks.md`: 12 business automations (weekly prospecting, morning reply briefing,
  account-based outreach, city-by-city expansion, advertisers, review angle, CRM enrichment,
  pre-meeting brief, agencies, second-chance campaigns, performance tuning, inbound lead research).
- `scripts/leadgen.sh`: curl client that keeps the key out of the process list.
