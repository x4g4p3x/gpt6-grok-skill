# GPT-6 / Grok handoff

A Codex skill for giving a bounded coding or investigation task to Grok through the Cursor CLI. The GPT-6 lead plans the work, reviews the worker's changes and transcript, runs remaining checks, and owns the final result.

This is a Windows/PowerShell launcher. It requires PowerShell 7, Git for implementation tasks, and an installed, authenticated Cursor CLI (`agent`) with access to the selected Grok model. The default worker model is `grok-4.7-high`; availability depends on the user's Cursor account.

## Install

Copy the entire [`gpt6-grok/`](gpt6-grok/) directory into your Codex skills directory, so that the skill entrypoint is at `%USERPROFILE%\.codex\skills\gpt6-grok\SKILL.md`. Start a new Codex chat, then ask for `$gpt6-grok` on a substantive coding task.

The launcher also supports a `-DryRun` setup check. `Explore` asks the worker to investigate without edits; `Implement` allows scoped edits in a clean Git checkout. Read the skill's [workflow instructions](gpt6-grok/SKILL.md) before use.

## Data and usage

The delegated brief and any workspace content the Cursor CLI reads are sent to Cursor. Use only a workspace you are authorized to share. Worker transcripts are written to the operating system's temporary directory under `gpt6-grok-workers`; they may contain source code or other sensitive context. Review them before sharing logs or screenshots.

The launcher does not impose a token or spending limit. A dry run makes no model call; a real run can consume Cursor usage. The lead should inspect the exit code, transcript, diff, and completed checks rather than treating the worker's summary as proof.

This snapshot contains only the public skill package and its publication files. It contains no project-specific prompts, transcripts, credentials, or workspace history.

License: [0BSD](LICENSE), which permits reuse without requiring attribution.
