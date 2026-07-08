# David's agent instructions

Common instructions for David's agents across all scenarios.

## Guidelines

- Never use the em dash "—". Use a plain dash "-".
- In long Markdown, put each full sentence on its own line.
- Only comment complex logic. Code should be self-explanatory.
- No emoji or filler in code, docs, or commits unless asked.
- Never auto-add your agent name as commit co-author.
- Never commit to the default branch. Branch first.
- Use Conventional Commit prefixes (feat:, fix:, chore:, refactor:, docs:, test:).
- Prefer quality, simplicity, robustness, and long term maintainability over development cost.
- Route non-trivial work across models: decompose into a task list, one subagent per task, planner-tier (fable-5/opus-4.8) for judgment and executor-tier (gpt-5.5/sonnet-5) for bulk. See ~/MODEL_ROUTING.md.
- Start every bug fix by reproducing it E2E, then add a regression test that fails before and passes after.
- Be picky about pixel-perfect UI; fix things that look off even when unrelated to current work.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- Be concise: lead with the result, recommend rather than survey, and explain non-trivial trade-offs.
- Confirm before destructive, outward-facing, or hard-to-reverse actions.
- Never claim something works without running it and showing the output.

## References

- Default tech stack and tooling: read ~/STACK.md.
- David's engineering and product viewpoints: read ~/OPINIONS.md.
- Routing work across models (planner/executor, cross-provider): read ~/MODEL_ROUTING.md.
