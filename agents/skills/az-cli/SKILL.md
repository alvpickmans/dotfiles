---
name: az-cli
description: Use Azure CLI for Azure and Azure DevOps workflows (authentication, defaults, and day-to-day operations). Use this whenever the user asks to use az cli, Azure DevOps via az, or wants repeatable command workflows with organization/project defaults.
---

# Azure CLI (az)

Use this skill for general Azure CLI and Azure DevOps CLI tasks.

## Global prerequisites

These prerequisites apply to all task guides in this skill.

### 1) Sign in

```bash
az login
```

If needed, verify account context:

```bash
az account show
```

### 2) Install Azure DevOps extension (if missing)

```bash
az extension add --name azure-devops
```

### 3) Set default Azure DevOps organization and project

```bash
az devops configure --defaults organization=https://dev.azure.com/<org> project=<project>
```

Check current defaults:

```bash
az devops configure --list
```

## Usage principles

- Prefer explicit commands first, then compact queries (`--query`) when output is noisy.
- For Azure DevOps REST-style operations, use `az devops invoke` with `--area`, `--resource`, and `--route-parameters`.
- If a command unexpectedly fails with arguments, check `-h` and adapt to the installed extension version.
- For Azure Boards state updates, only use `New`, `In Planning`, `In Development`, `In Testing`, `Closed`, or `Removed`; if state is missing or invalid, ask the user to choose one from this list before updating.
- During Azure Boards claim flows, you must ask a branch-creation decision with the `question` tool (default derived branch, custom branch, or skip) as defined in `backlog.md`.
- For long markdown/HTML payloads (PR descriptions, comments, work item description fields), do not inline text in double quotes; use a heredoc or file-backed payload and then pass that value to the CLI command.
- After write operations (claim, relation add, PR create/update), run an explicit verification command and report the verified outcome.
- If a non-critical Azure DevOps linkage step fails (for example, branch artifact link returns 400) after the primary goal already succeeded, continue the requested workflow and report the failure details plus next troubleshooting step.

## Task guides

- Pull request creation, review, and comment thread workflows: see `pull-requests.md`.
- Claim and move Azure Boards tasks: see `backlog.md`.
