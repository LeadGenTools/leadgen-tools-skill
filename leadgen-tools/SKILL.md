---
name: leadgen-tools
description: Find B2B customers and run cold email outreach end to end with LeadGen.tools. Use when the user wants to find businesses in a niche and area (dentists in Austin, agencies in Madrid), get company emails or decision makers with verified emails, research a company before a call, verify an email list, enrich CRM records, write cold email sequences, launch campaigns with automatic follow-ups from their own Gmail/SMTP inboxes, triage replies (interested, wants a meeting, question), or automate weekly prospecting and reply briefings. Requires a LeadGen.tools API key.
homepage: https://leadgen.tools
metadata: {"openclaw":{"emoji":"🎯","homepage":"https://leadgen.tools","primaryEnv":"LEADGEN_API_KEY","requires":{"env":["LEADGEN_API_KEY"],"bins":["curl"]}}}
---

# LeadGen.tools — find customers and contact them, on autopilot

LeadGen.tools gives you the whole outbound pipeline behind one JSON API: real businesses from maps data,
their emails, the people who decide (AI-ranked for what the user sells, verified emails), email
verification, AI-written sequences, and campaigns that send from the user's own inboxes with human pacing,
follow-ups in the same thread that stop on reply, and every reply classified by AI.

You bring the judgment and the schedule; LeadGen.tools does the data and the sending.

## What you can do

| Goal | How |
|---|---|
| **Find companies** in any niche + city/region, with phone, address, rating, reviews, hours | `companies` |
| **Get their emails** (from their website, or verified by our data partners) | `companies` with `with_emails=true` |
| **Find the decision maker** (owner, CEO, marketing head…) with a verified email, picked by AI for the user's offer | `people` |
| **Research one company** (emails, phones, socials, what they do) | `crawl`, `people?lookup=false` |
| **Find companies spending on ads** for a keyword | `ads` |
| **Read Google reviews** for a sales angle | `places/reviews` |
| **Search the web** with operators for non-local niches | `search` |
| **Verify emails** (syntax, domain, MX, SPF/DKIM/DMARC, disposable, mailbox) | `verify` — free |
| **Store prospects** in projects in the user's account | `projects`, `leads` — free |
| **Write a cold email sequence** (1 email + up to 5 follow-ups, merge fields, variations) | `campaigns/generate` |
| **Launch campaigns** from the user's connected Gmail/SMTP inboxes, rotated, business hours, daily limits | `campaigns`, `campaigns/launch` |
| **Follow up automatically** in the same thread until they reply | built into every campaign |
| **Know who's interested**: replies classified interested / meeting / question / not interested / out of office… with summary and text | `campaigns/recipients?category=hot` |
| **Pause, resume, cancel, edit** campaigns; track sent, replies, bounces | `campaigns/control`, `campaigns/steps`, `campaigns/status` |

Ready-made automations (weekly prospecting, morning reply briefing, account-based lists, city-by-city
expansion, advertisers, review angles, CRM enrichment, pre-meeting briefs, agencies, second-chance
campaigns, performance tuning, inbound lead research): [references/playbooks.md](references/playbooks.md).

## Setup

1. **API key**: the user gets it at LeadGen.tools → **API & Agents** (sidebar, under Advanced tools) or
   https://leadgen.tools/members/softsale/license. It spends the account's credits — treat it like a
   password: never print it, log it, put it in files or share it in chat.
2. OpenClaw: set it once in `~/.openclaw/openclaw.json`:
   ```json5
   { skills: { entries: { "leadgen-tools": { enabled: true, apiKey: "THE_KEY" } } } }
   ```
   (or `env: { LEADGEN_API_KEY: "THE_KEY" }`, or export `LEADGEN_API_KEY` in the environment).
3. Base URL `https://leadgen.tools/v2/api/v1/` (override with `LEADGEN_BASE_URL`).
4. Check the connection with a free call: `GET accounts` (lists the user's sending inboxes).

## How to call the API

Use the bundled client — it URL-encodes parameters, sends JSON bodies and keeps the key out of the process
list:

```bash
{baseDir}/scripts/leadgen.sh GET companies query="dental clinics" location="Austin, TX" limit=20 with_emails=true
{baseDir}/scripts/leadgen.sh GET people domain=acme.com want=1 offer="Online booking software for clinics"
{baseDir}/scripts/leadgen.sh POST verify '{"emails":["info@acme.com","ana@acme.com"]}'
{baseDir}/scripts/leadgen.sh POST campaigns/launch '{"campaign_id": 8}'
```

Or any HTTP tool: `api_key` always goes in the **query string**; POST/PUT bodies are JSON
(`Content-Type: application/json`); `companies` and `people` also accept everything as GET parameters.
Use a timeout of at least 180 s.

Every response:

```json
{"status": "success", "credits_used": 4, "data": { ... }}
{"status": "error", "code": "insufficient_credits", "message": "..."}
```

Read `credits_used` on every call and keep a running total to report.

## Golden rules

1. **Ask before spending big.** Estimate first (see Credits). Over ~100 credits, or emails/people the user
   didn't ask for → state the estimate and wait for a yes. Respect any budget the user set.
2. **Launching is sending real email to real people.** Never launch a campaign, add prospects to a
   running flow, or send a reply without the user's explicit approval of the emails, the inboxes, the
   daily limit and the number of prospects — unless they gave you a standing rule with a cap.
3. **Quality over volume.** One contact per company by default (`want=1`). Verify emails with a `null`
   grade before sending. Drop duplicates by domain. 20–30 emails per inbox per day on new domains.
4. **Relevant B2B only.** Contact businesses about something that fits them. Campaigns add an opt-out line
   and honor unsubscribes automatically; if the user sends with another tool, remind them to do the same.
5. **Never invent data.** Report only companies, people, emails and numbers the API returned. No fake
   personalization, no made-up case studies in emails.
6. **Go slow on slow endpoints.** One call at a time for `companies` with emails (30–120 s), `people`
   (up to ~60 s), `crawl` (up to 2 min), `verify` (~2–5 s per email). Max 5 concurrent calls otherwise.
7. **Page with tokens.** Pass `next_page_token` back as `page_token` unchanged; stop at `null` or when you
   have enough. Repeating a `companies`/`people` call within 30 days doesn't charge again, so retrying
   after a timeout is safe.
8. **Don't name the data sources.** Say "LeadGen.tools" or "its data partners".

## Send with LeadGen.tools or export?

Ask how the user sends email today if you don't know.

- **Send here** when they have no cold-email tool or want one place for everything: rotation across
  several Gmail/SMTP inboxes, business-hours sending with human pacing, per-inbox daily limits, a bounce
  guard that pauses the campaign, follow-ups that stop on reply, AI reply classification, per-prospect
  first lines (`{icebreaker}`). Needs at least one inbox connected in the web app (LeadGen.tools → My
  email — inboxes can't be connected through the API). Costs 1 credit per prospect contacted,
  follow-ups included.
- **Export** when they already use Instantly, Smartlead, lemlist, Apollo, HubSpot, Outreach, their own
  SMTP/ESP or a CRM, only need data, or need Outlook/Microsoft 365. Return CSV/JSON with
  `company, website, domain, first_name, last_name, title, email, email_grade, phone, address, rating,
  reviews` (verified emails only), or push it with the user's other tools. Saving them in a project too
  (`leads`, free) avoids buying or contacting them twice.

## The core pipeline

1. **Brief** — who (niche + area), how many, what the user sells and the proof, emails only or decision
   makers, send here or export, budget.
2. **Find** — `companies?with_emails=true`, page until enough.
3. **Decision makers** (optional) — `people?domain=…&offer=…` one company at a time; keep the company
   email when nobody is found.
4. **Clean** — `verify` for `null`-grade emails (20 per call); drop invalid, disposable, duplicates.
5. **Store** — `projects` (find or create) → `leads` (≤500 per call). Put useful facts (title, specialty,
   rating) in `description`: the server writes each prospect's personal first line from it.
6. **Write** — `campaigns/generate` with a concrete brief (offer, audience, proof, call to action, tone,
   language, number of follow-ups). Show the emails; apply the user's edits. Keep `<p>{icebreaker}</p>`
   after the greeting of the first email; greet generic mailboxes (info@) without `{firstname}`.
7. **Launch** — `accounts` → `campaigns` (draft) → user approves → `campaigns/launch`.
8. **Watch** — `campaigns/status` and `campaigns/recipients?category=hot`; bring hot replies to the user
   with a suggested answer.

Exact calls and bodies: [references/workflows.md](references/workflows.md). Every parameter and field:
[references/api.md](references/api.md).

## Writing emails that get answers

- 50–120 words, one idea, one clear ask (a 15-minute call, "worth a look?"), no attachments or images.
- Personal first line (`{icebreaker}`), then the problem they likely have, the result you bring with proof,
  the ask. Follow-ups add a new angle each (a case, a question, a resource), 2–4 days apart.
- Merge fields: `{firstname}`, `{lastname}`, `{company}`, `{website}`, `{email}`, `{icebreaker}`;
  fallback for a missing name: `{firstname|team}`. Variations: `{Hi|Hello|Hey}` picks one per email.
- The user's language and the prospect's language: write each campaign in the language the prospects use.
- Subjects: short, lowercase-friendly, specific ("quick idea for {company}"). Follow-ups reply in the same
  thread automatically.

## Credits

| Action | Credits |
|---|---|
| `companies` | 2 per page of ~20 companies + 1 per email found on a website + 2 per verified email from data partners |
| `people` | 2 per person with a verified email · 1 per person without (`lookup=false`) · 0 if nobody |
| `crawl` | 1 per valid email found (min 1 if any data) · 0 if cached |
| `search` | 10 if more than 7 results, else 1 per email found · 0 if cached |
| `ads` | 10 if more than 7 fresh ads, else 1 per ad with an email |
| `places/search` · `places/reviews` | 2 per page · 1 per lookup (0 if cached) |
| `campaigns/generate` | 1 per email written (min 2, max 10) |
| Campaign sending | 1 per prospect contacted, all follow-ups included |
| `verify`, `projects`, `leads`, `accounts`, `campaigns`, `steps`, `launch`, `control`, `status`, `recipients` | 0 |

`companies` and `people` charge each delivered item once per 30 days. If the balance runs out mid-call you
get what the balance covers plus a `warning` — never a charge beyond the balance.

Quick estimates: 50 companies with emails ≈ 6 + 35–70 credits · their 50 decision makers ≈ +100 ·
contacting 50 prospects = 50 · a 3-email sequence = 3.

## Errors

| HTTP | code | Do this |
|---|---|---|
| 401 | `missing_api_key`, `invalid_api_key` | Ask the user for a valid key (API & Agents page). Stop. |
| 402 | `insufficient_credits` | Tell the user the balance (`message`); they can top up in the app. Don't retry. |
| 400 | `missing_param`, `invalid_param`, `invalid_json`, `invalid_body` | Fix the request, retry once. |
| 400 | `invalid_state`, `launch_error`, `campaign_error` | Read `message` (wrong status, no steps, no inbox, no valid recipients) and fix. |
| 404 | `not_found` | Wrong id or not this account's; list again. |
| 409 | `duplicate_project` | Reuse it (`projects?search=`). |
| 405 | `method_not_allowed` | Use the documented method. |
| 502 | `provider_error`, `api_error`, `search_error`, `crawl_error`, `ai_error` | Temporary, nothing charged. Retry once after ~10 s, then report. |
| 503 | `auth_error`, `not_available` | Service temporarily unavailable; try later. |
| 500 | `db_error`, `config_error` | Report to the user; don't loop. |

A success may carry `warning` (items withheld for lack of credits) or `message` (nothing found, 0 credits):
always pass them on.

## Reporting back

After each job, tell the user in a few lines: what you found (counts), a small table (company, contact,
email + grade, city), what it cost (`credits_used` total), what's waiting for their approval, and the next
step you suggest. For campaigns: sent, replies by category, bounces, what's pending.

## Limits (be upfront about them)

- Inboxes are connected in the web app, not through the API; Outlook/Microsoft 365 isn't supported for
  sending yet (export instead).
- The API reads replies' category, summary and first ~600 characters; answering happens from the user's
  inbox (or your own mail tool, only if the user asks).
- A launched campaign doesn't accept new leads: each new batch is a new campaign (copy the approved steps).
- Brands, team members, autopilot and mailbox-to-brand assignment are managed in the web app.
- No LinkedIn automation, no phone dialing, no SMS.
