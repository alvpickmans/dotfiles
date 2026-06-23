# Claim an Azure Boards task with az

Use this workflow to claim a task and move it to active work.

## Claim command

```bash
az boards work-item update --id <task-id> --state "In Development" --assigned-to "<assignee-email>"
```

## Optional: auto-fill current signed-in user

```bash
az boards work-item update --id <task-id> --state "In Development" --assigned-to "$(az account show --query user.name -o tsv)"
```

## Optional: check current signed-in user

```bash
az account show --query user.name -o tsv
```

## Verify task assignment and state

```bash
az boards work-item show --id <task-id> --query "{id:id,state:fields.'System.State',assignedTo:fields.'System.AssignedTo'.uniqueName}" -o table
```

## Branch decision after claiming

When claiming a work item, always ask the user whether to create a branch before continuing. Use the `question` tool and present these options in this exact order:
- `Create branch with default` (Recommended)
- `Skip`
- `Type your own branch name`

Derive the default branch name from work item type, id, and a short title:

`<work_item-type>/<work_item_id>-<short-title-snake-cased>`

Examples:
- `task/12345-create-api`
- `bug/67890-fix-serialisation`

Recommended derivation rules:
- `work_item-type`: lower-case the Azure Boards type (for example `Task` -> `task`, `Bug` -> `bug`).
- `short-title-snake-cased`: lower-case title, keep only letters/numbers/spaces/hyphens, convert spaces and separators to single `-`, trim to a short slug.

If the user picks `Create branch with default`, create `"<derived-default>"`:

```bash
git checkout -b "<derived-default>"
```

If the user picks `Type your own branch name`, ask for the exact branch name and run `git checkout -b "<custom-branch>"`.

If the user picks `Skip`, do not create a branch and continue the workflow.

Important:
- Do not skip this prompt during a claim flow.
- The branch creation itself is optional, but the `question` prompt is required.

## Link remote branch to the work item

Always run this section during a claim flow.

If the user created a branch (`Create branch with default` or `Type your own branch name`), always link that newly created branch to the work item (no extra confirmation prompt).

If the user picked `Skip` (no new branch created), ask whether to link the current checked-out branch. Use the `question` tool with these options in this exact order:
- `Link current branch now` (Recommended)
- `Skip`

If the user picks `Link current branch now`, add a `Branch` artifact link through the WIT REST API.

1) Capture IDs and branch name:

```bash
branch_name="$(git branch --show-current)"
project_id="$(az devops project show --project <project> --query id -o tsv)"
repo_id="$(az repos show --repository <repo> --query id -o tsv)"
```

2) Build artifact URL (encode branch path separators once as `%2F`):

```bash
artifact_url="vstfs:///Git/Ref/${project_id}%2F${repo_id}%2FGB${branch_name//\//%2F}"
```

3) Add relation (known working approach):

```bash
az rest --method patch \
  --resource 499b84ac-1321-427f-aa17-267ca6975798 \
  --url "https://dev.azure.com/<org>/<project>/_apis/wit/workitems/<task-id>?api-version=7.1" \
  --headers "Content-Type=application/json-patch+json" \
  --body "[{\"op\":\"add\",\"path\":\"/relations/-\",\"value\":{\"rel\":\"ArtifactLink\",\"url\":\"${artifact_url}\",\"attributes\":{\"name\":\"Branch\"}}}]"
```

4) Verify link:

```bash
az boards work-item show --id <task-id> --expand relations --query "relations[?rel=='ArtifactLink'].{name:attributes.name,url:url}" -o table
```

Notes:
- Use `Branch` artifact relation (`rel: ArtifactLink`, `attributes.name: Branch`), not a plain `Hyperlink`.
- Do not double-encode branch separators (`%252F` is invalid).
- If the user created a branch in this flow, do not ask to skip linking; link it automatically.
- If no branch was created and the user picks `Skip`, do not create any relation.
- If relation add returns `400`, treat it as non-blocking for claim completion: report failure details, continue implementation work, and suggest targeted troubleshooting (validate org/project/repo IDs, repo name resolution, and artifact URL format for that org).

## Update work item description

Azure Boards stores description as HTML. Prefer sending HTML content to `--description` so section headings and bullet lists render correctly.

### Inline HTML (quick edits)

```bash
az boards work-item update --id <task-id> --description "<h2>Scope</h2><ul><li>Item one</li><li>Item two</li></ul><h2>Acceptance Criteria</h2><ul><li>Criterion one</li></ul>"
```

Tips:
- Use double quotes around the full `--description` value.
- Escape double quotes inside HTML attributes if needed.
- Use `&gt;` for literal `>` when documenting arrow flows.

### Large descriptions (recommended)

For longer content, avoid heavy shell escaping by reading the description from a file.

```bash
az boards work-item update --id <task-id> --description "$(cat ./work-item-description.html)"
```

This is safer for multi-section descriptions (Scope, Out of Scope, Acceptance Criteria, Notes).

### Verify description update

```bash
az boards work-item show --id <task-id> --query "{id:id,rev:rev,state:fields['System.State'],description:fields['System.Description']}"
```

If a query fails due to quoting rules, rerun without `--query` and inspect the `fields.System.Description` value.

## State validation

- Allowed state values: `New`, `In Planning`, `In Development`, `In Testing`, `Closed`, `Removed`.
- If the user does not provide a state, ask the user to choose one from the allowed values before running an update.
- If the user provides any other state value, do not update; ask the user to choose a valid state from the allowed values.
