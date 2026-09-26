---
name: gpt6-grok
description: Pair a GPT-6 Codex lead with a scoped Grok worker in Cursor CLI for substantive coding or debugging across repositories when that handoff would help. Skip trivial and Git-only tasks.
---

# GPT-6 / Grok handoff

Use this workflow across projects. The active GPT-6 model owns the plan, integration, validation, and final answer; Grok handles a bounded investigation or implementation in its own Cursor CLI context. This skill does not select or switch the lead model. Name the actual active model accurately.

1. Read the project's `AGENTS.md` and relevant validation guidance, and inspect Git state. Choose a self-contained task for Grok with clear boundaries and acceptance criteria. Keep secrets and unrelated context out of the brief; Cursor can read files in the workspace.
2. Run [scripts/invoke_grok_worker.ps1](scripts/invoke_grok_worker.ps1) with `-Workspace <repository-root> -BriefPath <brief-file> -Mode Explore` for read-only work or `-Mode Implement` for scoped edits. The default worker model is `grok-4.7-high`; use `-Model` when the user specifies another available Grok model. Pass `-TrustWorkspace` only after inspecting the repository and deciding to trust it. The launcher records a transcript. Use `-DryRun` to check the setup without a model call.
3. Before implementation, use a clean checkout or an isolated worktree if other work is present. Pass `-AllowDirty` only after reviewing existing edits and deciding the worker must share that checkout. Scope the workspace and brief to the files and checks the worker needs. Make one bounded call, inspect its result, then decide whether another call is warranted. Cursor usage is separate and can be substantial; the launcher does not impose a token cap.
4. Check the worker exit code, transcript, actual diff, and completed validation. Fix or redispatch scoped work as needed, then run remaining project checks yourself. The worker's summary is not proof that a check passed. Do not infer contribution or cost from token counts alone.
5. Commit, push, merge, or publish only within the user's authorization. Keep those actions with the lead, outside the worker brief.

If Cursor CLI is unavailable or the handoff fails, continue in Codex and report that Grok did not complete the delegated work. Honor later requests to avoid external model calls, keep work local, or use a different model.
