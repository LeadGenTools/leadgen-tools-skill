# LeadGen.tools — Automation playbooks

Ready-made business automations built on the API. Each lists its trigger, the steps, what it costs and
where to stop for the user's approval. Endpoint details: [api.md](api.md). Step-by-step calls:
[workflows.md](workflows.md).

**Before automating anything, agree with the user on:** a credit budget per run and per month, what may
run unattended (finding, enriching, verifying, drafting) and what always needs a "yes" (launching a
campaign, contacting a new list, sending replies). Save those rules in your memory and follow them on
every scheduled run. When a run would go over budget, stop and ask.

## Contents

1. [Weekly prospecting machine](#1-weekly-prospecting-machine)
2. [Morning reply briefing](#2-morning-reply-briefing)
3. [Account-based outreach (a named list of companies)](#3-account-based-outreach)
4. [City-by-city expansion](#4-city-by-city-expansion)
5. [Companies with ad budget](#5-companies-with-ad-budget)
6. [Reputation angle from Google reviews](#6-reputation-angle-from-google-reviews)
7. [CRM enrichment](#7-crm-enrichment)
8. [Pre-meeting research brief](#8-pre-meeting-research-brief)
9. [Agency: many clients, one account](#9-agency-many-clients-one-account)
10. [Second-chance campaign for non-responders](#10-second-chance-campaign-for-non-responders)
11. [Weekly performance report and tuning](#11-weekly-performance-report-and-tuning)
12. [Instant research on inbound leads](#12-instant-research-on-inbound-leads)

---

## 1. Weekly prospecting machine

**Trigger:** schedule (e.g. every Monday 8:00). **Goal:** a fresh batch of qualified prospects contacted
every week without the user doing anything but approving.

1. Read from memory: the offer, the ideal customer (niche + area), the approved email sequence, the
   weekly volume (e.g. 50), the areas already covered, and the domains already contacted.
2. `companies.php?with_emails=true` for the next niche/area, paging with `page_token` until you have the
   volume. Skip domains already contacted.
3. Optional: `people.php` for the best-rated companies (owners/decision makers), `want=1`.
4. `verify.php` for `null`-grade emails.
5. New project `"<niche> — <area> — <week>"` → `leads.php`.
6. New draft campaign with the approved steps (`GET campaigns.php?id=<last campaign>` → copy `steps`).
   A launched campaign doesn't take new leads, so each batch is its own campaign.
7. **Approval gate:** send the user a short summary (N companies, M decision makers, sample of 5, credits
   so far, credits to contact them = number of prospects). Launch only on "yes" — or automatically if the
   user explicitly allowed unattended launches within a weekly cap.
8. Record the area, the domains and the campaign id in memory.

**Cost:** ~2 credits per 20 companies + ~1–2 per email + 2 per decision maker + 1 per prospect contacted.
50 prospects/week with emails only ≈ 130–160 credits including contacting them.

Hands-off alternative inside the web app: **Autopilot** (LeadGen.tools → Autopilot) finds and adds
prospects to one running campaign every day. Suggest it when the user doesn't need an agent in the loop.

## 2. Morning reply briefing

**Trigger:** schedule (weekdays 8:30) or on request ("who answered?"). **Goal:** the user starts the day
with the replies that matter and a draft answer for each.

1. `GET campaigns.php` → campaigns with status `active`, `paused` or `completed` in the last 30 days.
2. For each: `recipients.php?campaign_id=<id>&category=hot` (interested, meeting, question). Keep only
   those with `replied_at` after your last briefing (store the timestamp in memory).
3. For each hot reply: name, company, `reply_summary`, the key sentence of `reply_text`, and a 2–4
   sentence draft answer in the prospect's language (propose two time slots for `meeting`, answer the
   question directly, confirm next step for `interested`).
4. Totals line: sent yesterday, new replies by category, bounces. Flag campaigns that got paused.
5. Only send the answers yourself if the user asked you to and you have a mail tool for their mailbox;
   otherwise hand over the drafts.

**Cost:** 0 credits.

## 3. Account-based outreach

**Trigger:** the user gives a list of target companies (names or domains, a spreadsheet, a CRM view).
**Goal:** reach the right 1–3 people at each, with emails that show you know the company.

1. Normalize to domains (ask or `search.php` for names without a website).
2. `people.php?domain=…&offer=…&want=2` one domain at a time.
3. `crawl.php?domain=…` for the site's description/metadata when you need material for personalization.
4. Put what you learned in each lead's `description` (title, what the company does, a recent fact) — the
   server writes each prospect's `{icebreaker}` from it.
5. Generate the sequence with the account list's common angle; two contacts at a company get separate
   emails, never CC.
6. Approval gate → campaign → launch.

**Cost:** 2 per person with a verified email (+1 per crawl with emails found).

## 4. City-by-city expansion

**Trigger:** "sell to <niche> across <state/country>". **Goal:** cover a large area in the order that
brings results fastest.

1. List the area's cities biggest first (your own knowledge is fine; confirm with the user).
2. Round-robin: one `companies.php` page per city per run, keeping each city's `page_token` in memory;
   a city is done when its token comes back `null`.
3. Write the sequence in the language businesses in that city use (e.g. Spanish for Mexico, French for
   Québec). One campaign per language.
4. Continue as in playbook 1.

## 5. Companies with ad budget

**Trigger:** schedule (weekly) with keywords the user's customers advertise on (e.g. "emergency plumber",
"teeth whitening"). **Goal:** contact businesses that already spend on marketing.

1. `ads.php?query=<keyword>&se=google` (and `bing`). `is_active: true` = advertising right now.
2. New advertisers since last week (compare domains in memory).
3. `people.php` on their domains; mention the ad angle in the brief ("saw you're running ads for …").

**Cost:** 10 credits per search with >7 fresh ads (else 1 per ad with an email) + people.

## 6. Reputation angle from Google reviews

**Trigger:** the user sells reviews, reputation, customer-experience or local-SEO services.

1. `companies.php` for the niche + area (no emails yet).
2. Keep companies with a low `rating` or few `reviews`; `places/reviews.php?place_id=<id>` for the
   candidates (1 credit each, 0 if cached) to read recent complaints.
3. Emails for the shortlist (`companies.php` again with `with_emails=true` or `crawl.php`), people if
   needed; reference the pattern in the reviews respectfully — never quote a customer's name.

## 7. CRM enrichment

**Trigger:** the user shares CRM records missing emails or decision makers. **Goal:** complete them.

1. For each record's domain: `people.php?lookup=true` (verified email) or `lookup=false` (names and
   titles only, 1 credit) when they only need who to call.
2. Company-level email/phone/socials: `crawl.php`.
3. `verify.php` existing emails that were never checked.
4. Write back through the user's CRM tool, or return a CSV. Mark what changed.

## 8. Pre-meeting research brief

**Trigger:** a meeting with a prospect is booked (from the user's calendar or a hot reply of type
`meeting`). **Goal:** a one-page brief 30 minutes before the call.

1. `crawl.php` the company's site: what they do, services, locations, socials.
2. `people.php?lookup=false` for the team around the person (titles).
3. `places/reviews.php` if they're a local business: rating, recurring praise/complaints.
4. The thread: `recipients.php` → their `reply_text`, and the campaign's steps (what they were told).
5. Brief: who they are, likely needs, 3 questions to ask, objections to expect.

**Cost:** 1–5 credits.

## 9. Agency: many clients, one account

**Goal:** run prospecting for several clients without mixing them.

- Naming: projects and campaigns start with the client (`ACME — Austin dentists — W39`).
- Each client's offer, ideal customer, approved sequence and budget live in your memory per client.
- Sending mailboxes: the user assigns each client's inboxes in the web app (brands and "My email");
  `accounts.php` shows them — only use the ones the user named for that client.
- Report per client (playbook 11) and track credits per client from each response's `credits_used`.
- Collaborators (the client's team) can be invited in the web app (Team) on plans that include them.

## 10. Second-chance campaign for non-responders

**Trigger:** a campaign finished (`completed`) 60–90 days ago. **Goal:** a new angle for people who never
answered.

1. `recipients.php?campaign_id=<id>&status=completed` → people who got the whole sequence without
   replying (unsubscribes, not-interested and bounces are excluded by their status and the suppression
   list). Drop anyone whose company domain also appears among the `replied` recipients: when one person
   at a company answers, their colleagues are marked `completed` too.
2. New project + `leads.php` with them, a genuinely different angle (new offer, case study, season),
   shorter sequence (1 email + 1 follow-up).
3. Approval gate → launch. The server skips anyone who opted out since.

## 11. Weekly performance report and tuning

1. `campaigns.php` + `campaigns/status.php` per active campaign: sent, reply rate
   (`total_replied / total_sent`), hot replies, bounce rate, what's pending.
2. Compare campaigns: which niche/area/subject performs best. Reply rate under ~1% after 100+ sends →
   propose a new first email; bounce rate over 3% → verify before sending more.
3. To change emails: `control.php pause` → `PUT campaigns/steps.php` → `control.php resume` (only after
   the user approves the new copy). Already-sent emails don't change.

## 12. Instant research on inbound leads

**Trigger:** a new lead arrives from the user's website form, inbox or CRM (through another skill or a
webhook your agent receives).

1. Domain from the lead's email (skip free mailboxes like gmail.com).
2. `crawl.php` + `people.php?lookup=false` → who they are, company size signals, their role.
3. Draft a personal reply for the user within minutes, and a note on fit (hot / maybe / not a fit).

**Cost:** 1–3 credits.
