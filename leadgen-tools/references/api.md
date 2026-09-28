# LeadGen.tools API v1 — Reference

Base URL: `https://leadgen.tools/v2/api/v1/` (override with `LEADGEN_BASE_URL`). Human-friendly docs:
https://leadgen.tools/v2/api/v1/. With the bundled client: `{baseDir}/scripts/leadgen.sh GET <endpoint> name=value …`.

## Contents

- [Conventions](#conventions) — auth, responses, errors, credits, caching, limits
- Find prospects: [companies](#companies) · [people](#people) · [crawl](#crawl) · [search](#search) · [ads](#ads) · [places/search](#placessearch) · [places/reviews](#placesreviews)
- Organize and clean: [projects](#projects) · [leads](#leads) · [verify](#verify)
- Send: [accounts](#accounts) · [campaigns](#campaigns) · [campaigns/generate](#campaignsgenerate) · [campaigns/steps](#campaignssteps) · [campaigns/launch](#campaignslaunch) · [campaigns/control](#campaignscontrol) · [campaigns/status](#campaignsstatus) · [campaigns/recipients](#campaignsrecipients)

---

## Conventions

### Authentication

Every request carries the API key in the query string:

```
https://leadgen.tools/v2/api/v1/<endpoint>.php?api_key=YOUR_KEY&...
```

The account (and its credit balance) is resolved from the key. `user_id` is accepted for backwards
compatibility but ignored. Every call first checks the key and that the balance is at least 1 credit
(otherwise `402 insufficient_credits`).

### Request bodies

POST/PUT endpoints take JSON (`Content-Type: application/json`). `companies.php` and `people.php` accept
their parameters either in the query string (GET) or as a JSON body (POST); `api_key` always goes in the
query string.

### Responses

```json
{"status": "success", "credits_used": 0, "data": { ... }}
```

```json
{"status": "error", "code": "missing_param", "message": "Human-readable description."}
```

`credits_used` is what that call cost. Credits are never charged on errors.

### Error codes

| HTTP | code | Meaning |
|---|---|---|
| 400 | `missing_param` | Required parameter missing |
| 400 | `invalid_param` | Parameter value invalid (bad engine, bad page token, too many items…) |
| 400 | `invalid_body` / `invalid_json` | Body missing or not valid JSON |
| 400 | `invalid_code` | Recipe code not found (search) |
| 400 | `invalid_state` | Campaign in the wrong status for the operation |
| 400 | `campaign_error` / `launch_error` | Campaign create/update/launch failed (see `message`) |
| 401 | `missing_api_key` / `invalid_api_key` | No key, or key invalid/expired |
| 402 | `insufficient_credits` | Balance too low (`message` states the balance) |
| 404 | `not_found` | Resource doesn't exist or isn't this account's |
| 405 | `method_not_allowed` | Wrong HTTP method |
| 409 | `duplicate_project` | A project with that name already exists |
| 500 | `db_error` / `config_error` | Server problem |
| 502 | `provider_error` / `api_error` / `search_error` / `crawl_error` / `ai_error` | Upstream source failed; nothing charged — retry later |
| 503 | `auth_error` | License service unavailable — retry later |
| 503 | `not_available` | Decision-maker search unavailable — retry later |

### Credits

| Endpoint | Credits |
|---|---|
| companies | 2 per page of ~20 companies delivered + 1 per company email found on its website + 2 per verified email from data partners |
| people | 2 per person with a verified email; 1 per person without an email (`lookup=false`); 0 when nobody is found |
| search | 10 if more than 7 results, else 1 per email found; 0 if cached |
| crawl | 1 per valid email found (minimum 1 if any data); 0 if cached |
| ads | 10 if more than 7 fresh ads, else 1 per ad with an email |
| places/search | 2 per page of ~20 places |
| places/reviews | 1, or 0 if cached (7 days) |
| campaigns/generate | 1 per email generated (min 2, max 10) |
| Campaign sending (server-side) | 1 per prospect contacted, follow-ups included |
| projects, leads, verify, accounts, campaigns, steps, launch, control, status, recipients | 0 |

`companies` and `people` charge each item (a page, a company email, a person) once per account for 30
days: repeating a call or paging back is free. If the balance runs out mid-call they stop or withhold the
rest (`warning` in the response) and never charge beyond the balance. Prices can change; `credits_used` in each
response is always the truth.

### Caching

| Endpoint | Cache |
|---|---|
| search | 7 days (same query, engine, page) |
| crawl | 14 days (same URL) |
| ads | ads stored permanently, landing-page data 7 days |
| places/search | live |
| places/reviews | 7 days |
| companies | Maps pages 7 days, website emails 14 days |
| people | 30 days (same domain, company, want, offer, ideal, lang, lookup) |

### Rate limits and timeouts

No per-minute limit is enforced; per-request caps apply (companies ≤60, verify ≤20 emails, leads ≤500,
people 1 domain). Recommended: at most 5 concurrent requests overall and **one at a time** for
`companies` with emails (30–120 s), `people` (up to ~60 s), `crawl` (up to 2 min), `ads` (30–60 s on first
call) and `verify` (~2–5 s per email). Use an HTTP timeout of 180 s or more.

---

## Find prospects

### companies

`GET|POST /companies.php` — real businesses for a niche + place (Google Maps data), optionally with emails.

| Param | Type | Default | Notes |
|---|---|---|---|
| `query` | string | — | Required unless `page_token`. What businesses: `dental clinics`, `roofing contractors`. Max 150 chars. |
| `location` | string | — | `Austin, TX`, `Madrid, Spain`. Searched as "query in location". Max 150 chars. |
| `limit` | int | 20 | 1–60 companies. |
| `with_emails` | bool | false | Read each company's website for emails. |
| `fill_missing` | bool | true | With `with_emails`: when the website shows none, get a verified email from our data partners (max 30 per call). |
| `page_token` | string | — | `next_page_token` from the previous response; continues exactly where it stopped. |

```bash
curl -s "https://leadgen.tools/v2/api/v1/companies.php?api_key=$LEADGEN_API_KEY&query=dental+clinics&location=Austin,+TX&limit=50&with_emails=true"
```

```json
{
  "status": "success",
  "credits_used": 47,
  "data": {
    "query": "dental clinics",
    "location": "Austin, TX",
    "search": "dental clinics in Austin, TX",
    "results_count": 50,
    "with_emails": true,
    "emails_found": 33,
    "next_page_token": "c:eyJxIjoiZGVudGFs...",
    "credits_breakdown": {"pages": 6, "emails": 27, "verified_emails": 14},
    "companies": [
      {
        "id": "ChIJ...",
        "name": "Lakeside Family Dental",
        "website": "https://lakesidefamilydental.com/",
        "phone": "(512) 555-0142",
        "address": "1201 S Lamar Blvd, Austin, TX 78704",
        "rating": 4.8,
        "reviews": 212,
        "lat": 30.2549,
        "lng": -97.7644,
        "categories": ["Dentist"],
        "hours": ["Monday: 8 AM–5 PM", "..."],
        "maps_url": "https://maps.google.com/?cid=...",
        "domain": "lakesidefamilydental.com",
        "email": "hello@lakesidefamilydental.com",
        "email_verified": false,
        "email_grade": null,
        "emails": ["hello@lakesidefamilydental.com"],
        "socials": ["https://www.facebook.com/lakesidefamilydental"],
        "description": "Lakeside Family Dental — Gentle dentistry in South Austin"
      }
    ]
  }
}
```

- `email_grade`: `A` verified · `A-` very likely deliverable · `null` published on the company's own
  website, not verified (verify before sending). `email_verified` is true only for `A`.
- `email`, `email_verified`, `email_grade`, `emails`, `socials`, `description` appear only with `with_emails=true`.
- `email_withheld: true` on a company + `warning` on the response = found but not delivered (balance ran out).
- Companies whose website is a social page or directory get no email.
- `next_page_token: null` = the area is exhausted (Maps shows up to ~200 places per search); try nearby
  cities or other wording for more.
- `id` is a Google Place ID, usable with `places/reviews`.

### people

`GET|POST /people.php` — decision makers at one company, ranked by AI for what the caller sells.

| Param | Type | Default | Notes |
|---|---|---|---|
| `domain` | string | — | Required. `acme.com` or a website URL. |
| `company` | string | — | Company name; improves ranking. |
| `want` | int | 1 | 1–3 people. |
| `offer` | string | — | What the user sells (≤300 chars). Strongly recommended — ranking depends on it. |
| `ideal` | string | — | Ideal customer (≤200 chars). |
| `lang` | string | `en` | `en` or `es`, language of `reason`. |
| `lookup` | bool | true | true: only people with a verified email, looked up when needed. false: names and titles (email only if already known), no lookups. |

```bash
curl -s "https://leadgen.tools/v2/api/v1/people.php?api_key=$LEADGEN_API_KEY&domain=lakesidefamilydental.com&want=1&offer=Online+booking+software+for+dental+clinics"
```

```json
{
  "status": "success",
  "credits_used": 2,
  "data": {
    "domain": "lakesidefamilydental.com",
    "company": null,
    "lookup": true,
    "candidates": 7,
    "people_count": 1,
    "people": [
      {
        "rank": 1,
        "name": "Maria Gomez",
        "first_name": "Maria",
        "last_name": "Gomez",
        "title": "Owner & Lead Dentist",
        "email": "maria@lakesidefamilydental.com",
        "email_verified": true,
        "grade": "A",
        "linkedin": "https://www.linkedin.com/in/...",
        "reason": "Owner decides on clinic software"
      }
    ]
  }
}
```

- Only `A` / `A-` emails are returned. Nobody found → `people: []` + `message`, 0 credits.
- Small businesses often have no findable person: fall back to the company email from `companies`.

### crawl

`GET /crawl.php?domain=<url or domain>` — reads up to 15 pages of one website.

```json
{"status": "success", "credits_used": 1, "data": {
  "domain": "https://ccocoa.com", "pages_crawled": 15,
  "metadata": {"title": "...", "description": "...", "keywords": "", "image": "..."},
  "emails": ["info@ccocoa.com"], "all_emails": ["info@ccocoa.com"],
  "phones": ["..."], "social_links": ["https://www.facebook.com/..."]
}}
```

`emails` = addresses on the site's own domain (filtered); `all_emails` = everything found.

### search

`GET /search.php` — search-engine results with emails/phones extracted from the snippets.

| Param | Default | Notes |
|---|---|---|
| `query` | — | Required unless `code`. Keywords or operators, e.g. `"marketing agency" miami "@gmail.com"`. |
| `code` | — | A LeadGen.tools recipe code instead of `query`. |
| `se` | `google` | `google`, `bing`, `yahoo`, `duckduckgo`. |
| `page` | 0 | Pagination offset. |
| `results_per_page` | 10 | |

```json
{"status": "success", "credits_used": 10, "data": {
  "query": "marketing agency miami", "search_engine": "google", "page": 0, "results_count": 9,
  "results": [{"title": "...", "link": "https://...", "description": "...", "emails": [], "phones": ["(786) 269-3783"]}]
}}
```

### ads

`GET /ads.php` — advertisers on a keyword, with landing-page contact data.

| Param | Default | Notes |
|---|---|---|
| `query` | — | Required. |
| `se` | `google` | `google` or `bing`. |
| `page` | 0 | |
| `include_history` | true | Include ads seen in earlier searches for the same query. |

Each result: `position`, `title`, `url`, `ad_text`, `search_engine`, `first_seen`, `last_seen`,
`is_active`, `contact_data` (`emails`, `phones`, `social_links`, `metadata`).

### places/search

`GET /places/search.php?keyword=<text>&pagetoken=<token>` — raw Google Maps listings (~20 per page):
`name`, `address`, `phone`, `website`, `rating`, `rating_total`, `types`, `weekday_text`, `place_id`,
`lat`, `long`, `url`; `next_page_token`. Prefer `companies`.

### places/reviews

`GET /places/reviews.php?place_id=<id>` → `reviews[]` with `author_name`, `rating`, `text`,
`relative_time_description`, `time`; `cached`.

---

## Organize and clean

### projects

- `GET /projects.php[?search=name]` → `projects[]`: `id`, `name`, `type`, `campaigns[]` (`id`, `name`, `status`).
- `POST /projects.php` body `{"name": "Austin dentists — Sep 2026"}` → `{"project_id": 42, "name": "..."}`.
  `409 duplicate_project` if the name exists: search and reuse it.

### leads

- `GET /leads.php?project_id=42&limit=100&offset=0` (limit ≤500) → `total`, `leads[]`: `id`, `email`,
  `firstname`, `lastname`, `company`, `website`, `phones`, `description`, `verified` (1 valid, -1 invalid, 0 unknown),
  `keyword`, `social_media`.
- `POST /leads.php` body:

```json
{"project_id": 42, "leads": [
  {"email": "maria@lakesidefamilydental.com", "firstname": "Maria", "lastname": "Gomez",
   "company": "Lakeside Family Dental", "website": "https://lakesidefamilydental.com",
   "phones": "(512) 555-0142", "description": "Owner & Lead Dentist · 4.8★ (212 reviews)"}
]}
```

  → `{"imported": 1, "duplicates": 0, "errors": 0, "details": []}`. ≤500 per call; `email` required; duplicates
  (same project + email) skipped. Aliases: `title`=`company`, `url`=`website`, `phone`=`phones`. When both
  names are empty they are guessed from the email (`john.doe@` → John Doe, `info@` → "Info"), so for
  generic mailboxes write emails that don't depend on `{firstname}`.

### verify

`POST /verify.php` body `{"emails": ["a@acme.com", "b@acme.com"], "lead_ids": [1234, 1235]}` (≤20 emails;
`lead_ids[i]` matches `emails[i]` and updates the lead's `verified`).

```json
{"status": "success", "credits_used": 0, "data": {"verified": 2, "valid": 1, "invalid": 1, "results": [
  {"email": "a@acme.com", "valid": true, "verdict": "valid", "details": {"domain_exists": true, "valid_mx": true,
   "disposable": false, "has_a": true, "has_spf": true, "has_dkim": true, "has_dmarc": true, "deliverable": true}}
]}}
```

Checks: format, domain/MX, SPF/DKIM/DMARC, disposable list, SMTP mailbox check.

---

## Send

### accounts

`GET /accounts.php[?type=gmail|smtp]` → `accounts[]`: `type`, `id`, `email`, `name`/`label`,
`daily_send_limit`, `sent_today`, `status` (+ SMTP `smtp_host`, `smtp_port`, `has_imap`, `is_verified`).
Accounts are connected in the web app only (LeadGen.tools → My email). No accounts = can't send from LeadGen.tools.

### campaigns

- `GET /campaigns.php` → `campaigns[]`: `id`, `name`, `status` (`draft|active|paused|completed|cancelled`),
  `project_id`, `project_name`, `accounts_display`, `daily_limit`, `total_sent`, `total_replied`,
  `total_bounced`, `total_recipients`, `created_at`, `launched_at`.
- `GET /campaigns.php?id=8` → `campaign` with `steps[]`, `recipient_stats`, `sending_accounts[]`.
- `POST /campaigns.php` creates a **draft**:

```json
{
  "name": "Austin dentists — booking software",
  "project_id": 42,
  "daily_limit": 30,
  "batch_size": 5,
  "sending_accounts": [{"type": "gmail", "id": 5}, {"type": "smtp", "id": 1}],
  "steps": [
    {"step_order": 0, "delay_days": 0, "subject": "{Quick question|Idea} for {company}",
     "body_html": "<p>{Hi|Hello} {firstname},</p><p>{icebreaker}</p><p>...</p>"},
    {"step_order": 1, "delay_days": 3, "subject": "Re: {Quick question|Idea} for {company}",
     "body_html": "<p>{Just following up|Circling back} ...</p>"}
  ]
}
```

  → `{"campaign_id": 8, "name": "...", "status": "draft"}`. Defaults: `daily_limit` 50, `batch_size` 5.
  Accounts must belong to the account owning the key.

**Email content.** Merge fields: `{firstname}`, `{lastname}`, `{email}`, `{company}`, `{website}`,
`{icebreaker}` (a personal first line the server writes per prospect from their website; its paragraph is
removed when none can be written). Spintax `{a|b|c}` picks one option per email. Keep HTML simple
(`<p>`, `<br>`, `<strong>`). Follow-ups are sent in the same thread and stop when the prospect replies.
An opt-out line and a `List-Unsubscribe` header are added automatically.

### campaigns/generate

`POST /campaigns/generate.php` body `{"prompt": "<brief>", "num_followups": 2}` (`num_followups` 1–5;
optional `custom_system_prompt`, `custom_user_prompt_template` with `{num_followups}` / `{prompt}`
placeholders) → `{"steps": [{"step_order", "subject", "body_html", "delay_days"}]}` ready for `campaigns.php`.
Costs 1 credit per email (min 2, max 10), checked up front.

### campaigns/steps

`PUT /campaigns/steps.php` body `{"campaign_id": 8, "steps": [...]}` — replaces all steps; only `draft` or
`paused` campaigns → `{"campaign_id", "steps_count", "message"}`.

### campaigns/launch

`POST /campaigns/launch.php` body `{"campaign_id": 8}` — draft only; needs ≥1 step and valid sending
accounts. Loads every project lead with an email (first one if several), skipping the account's
suppression list (past unsubscribes / not interested) → `{"campaign_id", "status": "active", "recipients_loaded"}`.
The server then sends every 5 minutes during business hours on weekdays, with random pacing and
per-account daily limits; the first email to each prospect costs 1 credit.

### campaigns/control

`POST /campaigns/control.php` body `{"campaign_id": 8, "action": "pause|resume|cancel"}`.
pause: active→paused · resume: paused→active · cancel: active/paused→cancelled.
→ `{"campaign_id", "previous_status", "status", "message"}`.

### campaigns/status

`GET /campaigns/status.php?campaign_id=8` → `status`, `daily_limit`, `total_sent`, `total_replied`,
`total_bounced`, `sent_today`, `steps_count`, `recipient_stats` (`total`, `pending`, `in_progress`,
`completed`, `replied`, `bounced`, `unsubscribed`), `launched_at`, `updated_at`.
Done when `pending + in_progress = 0`.

### campaigns/recipients

`GET /campaigns/recipients.php?campaign_id=8[&status=replied][&category=hot][&limit=100&offset=0]`

| Param | Notes |
|---|---|
| `status` | `pending`, `in_progress`, `completed`, `replied`, `bounced`, `unsubscribed` |
| `category` | `hot` (= interested + meeting + question) or a comma list of `interested`, `meeting`, `question`, `not_interested`, `unsubscribe`, `out_of_office`, `wrong_person`, `other` |
| `limit` / `offset` | limit ≤ 500 (default 100) |

→ `total`, `recipients[]`: `id`, `email`, `firstname`, `lastname`, `status`, `current_step`,
`last_sent_at`, `replied_at`, `sent_via_type`, `sent_via_account_id`, and once they answered:
`reply_category`, `reply_summary` (one line, written by AI), `reply_text` (first ~600 characters, quoted
history removed).

```json
{"status": "success", "credits_used": 0, "data": {"campaign_id": 8, "total": 3, "category_filter": "hot",
 "recipients": [{"id": 311, "email": "maria@lakesidefamilydental.com", "firstname": "Maria", "status": "replied",
   "current_step": 1, "replied_at": "2026-09-24 10:12:03", "reply_category": "meeting",
   "reply_summary": "Wants a demo next Tuesday afternoon",
   "reply_text": "Hi! Sounds interesting. Could we do Tuesday after 3pm?"}]}}
```

Categories: `interested`, `meeting` (wants to talk), `question`, `not_interested` (never emailed again),
`unsubscribe` (never emailed again), `out_of_office` (the sequence waits until they're back, it isn't a
reply), `wrong_person`, `other`. `503 not_available` when `category` is used on a server without reply
classification. Replies are checked every 15 minutes.
