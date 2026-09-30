# LeadGen.tools — Workflows

Recipes for common requests. Parameters and responses: [api.md](api.md). Longer automations:
[playbooks.md](playbooks.md).

Every example is shown with plain `curl` (`$K` = the API key, `$B` = the base URL). The bundled client
does the same with less typing and keeps the key out of the process list:

```bash
K="$LEADGEN_API_KEY"; B="${LEADGEN_BASE_URL:-https://leadgen.tools/v2/api/v1}"
LG="{baseDir}/scripts/leadgen.sh"
$LG GET companies query="dental clinics" location="Austin, TX" limit=50 with_emails=true
$LG POST verify '{"emails":["info@acme.com"]}'
```

## Contents

1. [Find 50 dental clinics in Austin with emails](#1-find-50-dental-clinics-in-austin-with-emails)
2. [Find decision makers for a list of domains](#2-find-decision-makers-for-a-list-of-domains)
3. [Verify a list of emails](#3-verify-a-list-of-emails)
4. [Build and launch a campaign on LeadGen.tools](#4-build-and-launch-a-campaign-on-leadgentools)
5. [Export leads to the user's own mailer or CRM](#5-export-leads-to-the-users-own-mailer-or-crm)
6. [Poll campaign status and replies](#6-poll-campaign-status-and-replies)
7. [Other sources: search, ads, one website](#7-other-sources-search-ads-one-website)
8. [LinkedIn and WhatsApp after the email](#8-linkedin-and-whatsapp-after-the-email)

---

## 1. Find 50 dental clinics in Austin with emails

Estimate first: 3 Maps pages (6 credits) + up to ~50 emails (1 each, 2 when verified by data partners)
≈ 40–80 credits. Confirm with the user if they didn't already agree to spend.

```bash
curl -s --max-time 240 "$B/companies.php?api_key=$K&query=dental+clinics&location=Austin,+TX&limit=50&with_emails=true"
```

Then:

1. Keep companies with `email`. Count them (`emails_found`).
2. Fewer than 50 with email and `next_page_token` not null → call again with only
   `page_token=<next_page_token>&with_emails=true&limit=<missing × 1.5>` until you have enough or the token
   is `null`.
3. Token `null` and still short → widen the area: nearby cities (`Round Rock, TX`, `Cedar Park, TX`…) or
   related wording (`dentist`, `family dentistry`, `orthodontist`). Tell the user you widened it.
4. Deduplicate by `domain` (chains appear several times).
5. Report: how many found, how many with emails, how many verified (`email_grade` `A`/`A-`), credits used.
   Show a table (name, website, email, grade, phone, rating/reviews).

Only need names/phones/addresses (e.g. for calling)? Omit `with_emails`: 2 credits per 20 companies.

## 2. Find decision makers for a list of domains

Input: domains (from step 1 or from the user) and what the user sells.

```bash
for d in lakesidefamilydental.com smilesaustin.com; do
  curl -s --max-time 120 "$B/people.php?api_key=$K&domain=$d&want=1&offer=Online+booking+software+for+dental+clinics"
  sleep 1
done
```

- One domain per call, sequentially. Estimate 2 credits per person found; nobody found = 0.
- Pass `company=<name>` when you have it and always pass `offer` — the ranking depends on it.
- `people: []` → keep the company's general email from `companies` as the contact.
- Only research (names/titles for LinkedIn or calls)? Use `lookup=false` (1 credit per person, no emails
  bought).
- Merge results: one row per person with the company fields; set `firstname`/`lastname` from the person.

## 3. Verify a list of emails

Skip emails already graded `A` / `A-`. For the rest (grade `null`, or a user-supplied list):

```bash
curl -s --max-time 180 -X POST "$B/verify.php?api_key=$K" -H "Content-Type: application/json" \
  -d '{"emails": ["hello@lakesidefamilydental.com", "info@smilesaustin.com"]}'
```

- Max 20 emails per call; run batches sequentially (~2–5 s per email). Free.
- Keep `verdict: "valid"`; drop `invalid`; drop `disposable: true`.
- If the leads are already in a project, pass `lead_ids` in the same order as `emails` so each lead's
  `verified` flag is stored.
- Report valid / invalid counts.

## 4. Build and launch a campaign on LeadGen.tools

Use this when the user wants LeadGen.tools to send (see "Send here or export?" in SKILL.md).

**a. Check sending accounts first.**

```bash
curl -s "$B/accounts.php?api_key=$K"
```

Empty → stop and ask the user to connect Gmail or an SMTP mailbox in LeadGen.tools → "My email". Note the
`type` + `id` of each account to use. Suggested `daily_limit`: 20–30 per inbox for new domains, up to
50 per inbox once warmed up.

**b. Put the prospects in a project.**

```bash
curl -s "$B/projects.php?api_key=$K&search=Austin+dentists"
curl -s -X POST "$B/projects.php?api_key=$K" -H "Content-Type: application/json" \
  -d '{"name": "Austin dentists — Sep 2026"}'
curl -s -X POST "$B/leads.php?api_key=$K" -H "Content-Type: application/json" -d '{
  "project_id": 42,
  "leads": [
    {"email": "maria@lakesidefamilydental.com", "firstname": "Maria", "lastname": "Gomez",
     "company": "Lakeside Family Dental", "website": "https://lakesidefamilydental.com",
     "phones": "(512) 555-0142", "description": "Owner & Lead Dentist. 4.8 stars, 212 reviews"}
  ]}'
```

Only add verified or `valid` emails. ≤500 leads per call. `description` feeds the automatic
personal first line, so put useful facts there (title, rating, specialty).

**c. Write the sequence.** Give the generator a concrete brief:

```bash
curl -s -X POST "$B/campaigns/generate.php?api_key=$K" -H "Content-Type: application/json" -d '{
  "prompt": "We sell online booking software for dental clinics (Calendly-like, integrates with Dentrix). Audience: independent dental clinics in Austin, TX, owners. Proof: clinics cut no-shows 30%. CTA: 15-minute demo this week. Tone: friendly, short, no hype. Language: English.",
  "num_followups": 2
}'
```

Cost: 1 credit per email (3 here). Show the subjects and bodies to the user and apply their edits.
Check that the first email contains `<p>{icebreaker}</p>` after the greeting (add it if missing) and that
follow-ups have `delay_days` (e.g. 3 and 4). If many leads are generic mailboxes (info@…), replace
`{firstname}` in greetings with something neutral like `{Hi|Hello} {company} team`.

**d. Create the draft.** Get explicit approval of: the emails, the sending accounts, the daily limit and the
number of prospects (each costs 1 credit when contacted).

```bash
curl -s -X POST "$B/campaigns.php?api_key=$K" -H "Content-Type: application/json" -d '{
  "name": "Austin dentists — booking software",
  "project_id": 42,
  "daily_limit": 30,
  "sending_accounts": [{"type": "gmail", "id": 5}],
  "steps": [ ...steps from generate, edited... ]
}'
```

**e. Launch.**

```bash
curl -s -X POST "$B/campaigns/launch.php?api_key=$K" -H "Content-Type: application/json" -d '{"campaign_id": 8}'
```

Tell the user: `recipients_loaded` prospects queued; sending runs on weekdays during business hours with
human-like pacing, so the first emails can take a few hours to go out; follow-ups stop automatically when
someone replies. To change emails later: pause → `PUT campaigns/steps.php` → resume.

## 5. Export leads to the user's own mailer or CRM

Use this when the user already has sending infrastructure (Instantly, Smartlead, lemlist, Apollo, HubSpot,
their own SMTP/ESP) or only wants data.

1. Collect companies (workflow 1) and, if asked, people (workflow 2).
2. Verify `null`-grade emails (workflow 3); drop invalid ones.
3. Write a CSV (UTF-8, header row) or push through the user's tool's API:

```
company,website,domain,first_name,last_name,title,email,email_grade,phone,address,rating,reviews,maps_url,icebreaker
```

   Leave `icebreaker` empty or write one short, factual line per lead from the company data; never invent facts.
4. Optionally also save them in a LeadGen.tools project (`POST leads.php`, free) so they aren't bought or
   contacted twice.
5. Remind the user: warm up new domains, keep volume per inbox low (≈30/day), include an opt-out, and
   stop following up with people who reply.

## 6. Poll campaign status and replies

```bash
curl -s "$B/campaigns/status.php?api_key=$K&campaign_id=8"
curl -s "$B/campaigns/recipients.php?api_key=$K&campaign_id=8&category=hot&limit=100"
```

- Poll at most every 15 minutes (sending runs every 5 minutes, reply checks every 15); once or twice a
  day is enough for a summary. Don't loop tightly.
- Report: sent, replied, bounced, unsubscribed, still pending.
- **Hot replies first** (`category=hot` → interested, meeting, question): for each, show name, company,
  `reply_summary` and `reply_text`, and suggest the next step (propose times for `meeting`, answer the
  question, send the resource). Offer a draft answer; the user sends it from their own inbox (or you do,
  only if they ask and you have a mail tool for their mailbox). Never answer `not_interested` or
  `unsubscribe` replies — they are already suppressed.
- `out_of_office` isn't a reply: the sequence resumes after their return date by itself.
- `wrong_person`: suggest `people.php` on that domain to find the right contact for a new campaign.
- Bounce rate (`total_bounced / total_sent`) above 5% → the server pauses the campaign automatically;
  suggest verifying the remaining leads before resuming (`campaigns/control.php` `resume`).
- Finished when `recipient_stats.pending + recipient_stats.in_progress = 0` (status `completed`).
- Pause / resume / cancel:

```bash
curl -s -X POST "$B/campaigns/control.php?api_key=$K" -H "Content-Type: application/json"   -d '{"campaign_id": 8, "action": "pause"}'
```

## 7. Other sources: search, ads, one website

- **Non-local niches** (SaaS companies, agencies, e-commerce brands): `search.php` with operators, e.g.
  `query="shopify store" "contact us" skincare` or `site:linkedin.com/company "marketing agency" miami`,
  then `crawl.php` or `people.php` on the domains found.
- **Companies spending on ads** (they have budget): `ads.php?query=emergency+plumber&se=google`, then
  `people.php` on the advertisers' domains.
- **One website** the user names: `crawl.php?domain=example.com` for emails/phones/socials, or
  `people.php?domain=example.com&offer=…` for the right person.
- **Reputation angle** for emails: `places/reviews.php?place_id=<companies[].id>` to reference recent reviews
  (1 credit each; use sparingly).

## 8. LinkedIn and WhatsApp after the email

Only when the user asks, and only with their own signed-in browser (Claude in Chrome, OpenClaw with browser control,
any browser agent). The API keeps the state; you do the clicks.

**LinkedIn daily routine** (once a day, weekdays):
1. `GET campaigns/linkedin` → campaigns with LinkedIn work (`next` counts). Show the user; for a first run show one
   example `note` and `message` and wait for their OK.
2. For the chosen campaign: `GET campaigns/linkedin campaign_id=8 next=all`.
3. **Check** (`next=check`): open each profile; connected now → `POST … "state": "accepted"`.
4. **Replies**: open linkedin.com/messaging; anyone from the lists who wrote back → `POST … "state": "replied",
   "text": "<their message>"` — don't answer for the user; tell them (hot replies first).
5. **Message** (`next=message`, max `limits.messages_per_day`): profile → Message → paste `message` → Send →
   `POST … "state": "messaged"`.
6. **Invite** (`next=invite`, max `limits.invites_per_day`): profile → wrong person → `not_found`; already
   connected → `accepted`; else Connect → Add a note → paste `note` → Send → `POST … "state": "invited"`.
7. 30–90 s between actions. Stop on any warning, limit, verification or CAPTCHA and tell the user.
8. Report: accepted, replied (with category), messages sent, invitations sent, skipped and why.

**WhatsApp**, a few days after the email and only for people who haven't replied:
`GET campaigns/whatsapp campaign_id=8 only=likely` → open `whatsapp_web_link` → check the typed message →
send → `POST … "state": "sent"` (or `no_whatsapp`). 10–15 a day at most, 1–3 min apart.
