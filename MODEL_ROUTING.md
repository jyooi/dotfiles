# Model Routing

How to route work across models when running workflows and subagents.
The principle: match model cost to the cognitive demand of the sub-task.

## The two roles

Every non-trivial task splits into two kinds of work.
Route each kind to the role that fits it, not to a fixed model.

- **Planner** - owns judgment, decomposition, synthesis, and review.
  Stays context-thrifty: it reasons about the work and directs it, but does not pull the token-heavy raw material through its own context.
  This is the frontier tier.
- **Executor** - owns bulk, well-specified, token-heavy, mechanical work.
  Reads the large inputs, does the clear-spec implementation, and reports back distilled results in its own context.
  This is the cheap, high-availability tier.

The split pays because the Planner's value is judgment, not doing.
Keeping megabytes of raw material out of the Planner's context is the entire cost story.

## Capability table

Rankings, higher = better.
Cost reflects what I actually pay (my Codex allotment makes gpt-5.5 effectively free), not list price.
Intelligence is how hard a problem you can hand the model unsupervised.
Taste covers UI/UX, code quality, API design, and copy.

| model    | cost | intelligence | taste | default role |
|----------|------|--------------|-------|--------------|
| gpt-5.5  | 9    | 8            | 5     | Executor     |
| sonnet-5 | 5    | 5            | 7     | Executor     |
| opus-4.8 | 4    | 7            | 8     | Planner      |
| fable-5  | 2    | 9            | 9     | Planner      |

The role column is the default instance, not a limit.
A model can play either role when the task calls for it: fable-5 can execute a delicate one-off, sonnet-5 can plan a small task.

## Routing rules

- These are defaults, not limits.
  You have standing permission to override them: if a cheaper model's output does not meet the bar, rerun or redo the work with a smarter model without asking.
  Judge the output, not the price tag.
  Escalating costs less than shipping mediocre work.
- Don't let cost prevent you from using the right model for the job.
  Instead, take advantage of cheaper options to get more information and try things before moving the work to a more expensive option.
- Bulk/mechanical work (clear-spec implementation, data analysis, migrations, log-digging): gpt-5.5 - it's effectively free.
  Give it a tight, self-contained spec; check a sample of its output and escalate the batch to a Planner-tier model if the sample misses the bar.
- Anything user-facing (UI, copy, API design) needs taste >= 7: sonnet-5 is the floor, opus-4.8 or fable-5 when quality matters.
- Reviews of plans/implementations: fable-5 or opus-4.8, optionally gpt-5.5 as an extra independent perspective.
  For a real second opinion, spawn a second reviewer with a different lens (adversarial, security, requirements-conformance) rather than the same prompt twice - same model, same prompt is not a second opinion.
- The hardest unsupervised problems (architecture, gnarly debugging, orchestrating other agents) go to fable-5.
- Never use Haiku.

## Choosing the executor: auto-route, confirm the consequential

Route automatically; do not ask which executor to use on every task.
The table and rules above are enough to pick one, and a prompt on each delegation defeats the point and breaks parallel fan-out.

- Pick the executor from task-shape without asking, and state which model you chose so the choice is visible.
- No prompt for read-only work: analysis, investigation, or a `codex exec -s read-only` run has no side effects.
- Confirm first before a consequential executor call: a write-capable codex run (`-s workspace-write` or `danger-full-access`) or a large/expensive batch.
  This is the same bar as any outward-facing or hard-to-reverse action.
- Escalating to a smarter model needs no prompt; that permission is standing.

## When the split pays, and when it does not

The Planner/Executor split is an arbitrage on read-heavy work.
It only pays when there is a heavy mechanical leg to move to the cheap tier.

- Pays: coverage tasks, document review, log analysis, codebase sweeps, verifying many facts against sources.
  The reading is mandatory and large, so running it at the Executor rate in parallel is a real win (roughly 2.5x cheaper and 3x faster on read-heavy research).
- Does not pay: narrow questions with little reading to arbitrage.
  If the Planner can answer from its own knowledge, delegating just adds a round-trip; if you delegate anyway, you paid a frontier round-trip for nothing.
- Watch for lost subtlety: a cheap Executor can summarize away exactly the nuance that mattered.
  When the task needs frontier judgment on the raw material itself (subtle analysis, not fact-finding), keep it with the Planner.
- Delegation has a floor cost: each Executor call pays fixed setup overhead.
  Splitting the same work into more, narrower briefs can raise the bill, not lower it - brief granularity has an optimum.

## Executor security boundary

An Executor that reads untrusted input (arbitrary web pages, unknown files) is the blast radius for that input.
Scope it to the minimum toolset the job needs.
A worker that can only search, fetch, and report back is a safe boundary; a Planner that only reads distilled reports and holds no tools is safer still.

## Cross-provider mechanics

Claude tiers (sonnet-5, opus-4.8, fable-5) run via the Agent/Workflow `model` parameter ('sonnet', 'opus', 'fable'), with `effort` where supported.
gpt-5.5 is only reachable through the Codex CLI: `codex exec` and `codex review` (my `~/.codex/config.toml` defaults to gpt-5.5 at xhigh reasoning).

Direct one-shot use, for work not covered by a Codex skill (investigation, data analysis):

```sh
codex exec -s read-only "<self-contained prompt>"
```

- `-s read-only | workspace-write | danger-full-access` sets the sandbox; use the least privilege the task needs.
- `-o <file>` writes the agent's final message to a file the Planner reads back; `--output-schema <file.json>` forces a structured JSON return.
- `-C <dir>` sets the working root; `--full-auto` runs sandboxed with low-friction auto-execution.

Using gpt-5.5 inside workflows and subagents (the model parameter only takes Claude models, so use a wrapper):

- Spawn a thin Claude wrapper agent with `model: 'sonnet', effort: 'low'` whose prompt instructs it to write a self-contained codex prompt, run `codex exec` via Bash, and return the report (use `schema` on the wrapper for structured output).
- Always label these agents with a `gpt-5.5:` prefix, e.g. `{label: 'gpt-5.5:review-auth'}` - the workflow UI shows the wrapper's Claude model, so the label is the only sign the real worker is gpt-5.5.
- Codex runs can exceed Bash's 10-minute timeout: pass an explicit timeout, or run in the background and poll for the report file.
- Parallel gpt-5.5 implementation agents must use `isolation: 'worktree'` so codex edits don't collide in the shared checkout.
- Workflow token budgets only count Claude tokens; codex work is invisible to `budget.spent()`.
