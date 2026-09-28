# LeadGen.tools skill for OpenClaw and AI agents 🎯

Give your AI agent the power to **find customers and contact them**: real businesses in any niche and
city, their emails, the decision makers with verified emails, AI-written cold email sequences, campaigns
that send from your own inboxes with automatic follow-ups, and every reply classified so you only read the
ones that matter.

Works with [OpenClaw](https://openclaw.ai) and any agent that reads `SKILL.md` files
([AgentSkills](https://agentskills.io) format), including Claude Code.

## What your agent can do with it

- "Find 50 dental clinics in Austin with the owner's email."
- "Every Monday, find 40 new real estate agencies in Madrid, write the emails and ask me before sending."
- "Who answered my campaigns? Draft replies for the interested ones."
- "Here are 30 target accounts — find the marketing head at each and start a 3-email sequence."
- "Which plumbers are running Google ads in Miami this week? Contact them."
- "Enrich these CRM records with decision makers and verified emails."
- "Brief me on this company before my 3 pm call."
- "Pause the campaign with the lowest reply rate and suggest a better first email."

Twelve ready-made automations are in [`leadgen-tools/references/playbooks.md`](leadgen-tools/references/playbooks.md).

## Install

### OpenClaw (ClawHub)

```bash
openclaw skills install @leadgen/leadgen-tools
```

### OpenClaw (from GitHub)

```bash
openclaw skills install git:leadgentools/leadgen-tools-skill@main
```

### Manual (any agent)

Copy the `leadgen-tools` folder into your agent's skills folder:

| Agent | Folder |
|---|---|
| OpenClaw (all agents) | `~/.openclaw/skills/leadgen-tools` |
| OpenClaw (one workspace) | `<workspace>/skills/leadgen-tools` |
| Claude Code | `~/.claude/skills/leadgen-tools` or `<project>/.claude/skills/leadgen-tools` |
| Other AgentSkills agents | their skills directory |

## Connect your account

1. Create an account at [leadgen.tools](https://leadgen.tools) (free to start).
2. In the app: **API & Agents** → copy your API key.
3. Give it to the skill.

   OpenClaw — `~/.openclaw/openclaw.json`:

   ```json5
   {
     skills: {
       entries: {
         "leadgen-tools": { enabled: true, apiKey: "YOUR_LEADGEN_API_KEY" }
       }
     }
   }
   ```

   Any other agent — environment variable:

   ```bash
   export LEADGEN_API_KEY="YOUR_LEADGEN_API_KEY"
   ```

4. To send campaigns from LeadGen.tools, connect at least one Gmail or SMTP inbox in the app
   (**My email**). Not needed if you only want data or send with your own tool.

Try it: *"Use LeadGen.tools to find 10 coffee shops in Denver with emails."*

## Pricing

The skill is free. Calls use your LeadGen.tools credits: finding companies costs 2 credits per page of
~20, an email 1–2, a decision maker with a verified email 2, contacting a prospect 1 (all follow-ups
included), and verifying, storing and managing campaigns is free. Every response says exactly what it
cost. Details: [API docs](https://leadgen.tools/v2/api/v1/).

## What's inside

```
leadgen-tools/
├── SKILL.md                 what the agent reads first: capabilities, rules, pipeline, credits, errors
├── references/
│   ├── api.md               every endpoint, parameter and response field
│   ├── workflows.md         step-by-step recipes with exact calls
│   └── playbooks.md         12 business automations
└── scripts/
    └── leadgen.sh           tiny curl client (keeps your key out of the process list)
```

Requirements: `curl` and `bash` (macOS, Linux, or Git Bash on Windows). The agent can also call the API
with its own HTTP tools.

## Security

- The key only goes to `leadgen.tools` over HTTPS. The script passes it to curl through stdin, so it never
  shows in the process list or shell history.
- The skill tells the agent to ask before spending many credits and to never launch a campaign or send
  email without your approval (unless you set a standing rule with a cap).
- Leaked key? Contact support to regenerate it; your credits are only spent through it.

## Links

- Website: https://leadgen.tools
- API documentation: https://leadgen.tools/v2/api/v1/
- Changelog: [CHANGELOG.md](CHANGELOG.md)

## License

MIT — see [LICENSE](LICENSE).
