# Pull Requests (Azure DevOps)

Use these patterns to open and manage Azure DevOps pull requests with `az` CLI.

## Open a new pull request

Use this flow when the user asks to create a PR.

1. Confirm git state and branch context.
2. Ensure the source branch has an upstream (`git rev-parse --abbrev-ref --symbolic-full-name @{u}`).
3. Review what is included in the PR from divergence with main (`git log --oneline main..HEAD` and `git diff --stat main...HEAD`).
4. Run relevant validation/tests when practical.
5. Before creating the PR, the agent MUST ask whether to use the repository template for the PR description.
6. Create PR with `az repos pr create` and link work item(s).

### Required user confirmation for PR description

For PR description content, the agent MUST use the `question` tool and ask the user to choose one option:
- Use template from `@.azuredevops\pull_request_template.md`
- Skip template and use a concise custom description

Recommended behavior:
- Put template usage as the first option and mark it as `(Recommended)`.
- If the user picks template, read `@.azuredevops\pull_request_template.md`, fill sections based on actual changes/tests, and preserve structure.
- If the user skips template, use a compact description with at least: change intent, testing, and work item linkage.

Example `question` call shape:

```json
{
  "questions": [
    {
      "header": "PR Description",
      "question": "How should I prepare the PR description?",
      "options": [
        {
          "label": "Use template (Recommended)",
          "description": "Use @.azuredevops\\pull_request_template.md"
        },
        {
          "label": "Skip template",
          "description": "Write a concise custom description"
        }
      ]
    }
  ]
}
```

### Reliable command pattern

For markdown descriptions, avoid direct inline quoting when the text contains backticks, `$`, or multiple paragraphs.
Use heredoc/file-backed content and pass the resolved string to `--description`.

```bash
pr_desc="$(cat <<'EOF'
## Description
<summary>

## Testing
- <command>
EOF
)"

az repos pr create \
  --source-branch <source-branch> \
  --target-branch <target-branch> \
  --title "<title>" \
  --description "$pr_desc" \
  --work-items <id-or-comma-separated-ids>
```

Notes:
- Defaults from `az devops configure --defaults` are used for organization/project.
- If the branch is not pushed, push first: `git push -u origin <source-branch>`.

### Required verification after create/update

After `az repos pr create` or `az repos pr update`, always verify persisted fields from server output.

```bash
az repos pr show --id <pr-id> --query "{id:pullRequestId,status:status,title:title,url:url}" -o json
az repos pr show --id <pr-id> --query "description" -o tsv
```

Do not assume local command success means description formatting was preserved.

## Review/comment thread workflow

Use these patterns to handle Azure DevOps pull request comment threads with `az` CLI.

### Core workflow

1. Parse PR URL (`organization`, `project`, `repository`, `pullRequestId`).
2. Get PR details to confirm repository GUID.
3. Fetch pull request threads and explicitly identify all open comments (`status == active`).
4. If open comments exist, process threads one at a time in order.
5. For each thread, call the `question` tool once (single question) and use the actual reviewer comment text as the question body.
6. Execute the selected action for that thread (including optional code updates), then move to the next thread.
7. Verify no active threads remain.
8. Only then complete review actions (for example, casting approval vote).

### Mandatory review rule

When the user asks to "review" a PR, this is required:

- Always fetch thread data and check for active threads before finalizing the review.
- If active threads exist, do not treat the review as complete until they are addressed (reply + resolve), unless the user explicitly asks to only report.
- Do not approve a PR while active review threads remain unresolved.
- Never post blanket replies or bulk-resolve all threads without per-thread confirmation.
- Collect one decision per active thread via the `question` tool before taking action.
- Do not use one combined multi-question survey for all comments; ask one `question` per comment thread.

### Required one-question-per-comment flow

When active threads are found, ask the user what to do for each thread using a separate `question` tool call per thread.
The question text should be exactly: `"<thread comment>" @<file_path>`.
Do not include thread ID in the question text.

Recommended options per thread:
- `Apply suggested change (Recommended)`
- `Reply + resolve`
- `Reply only`
- `Do nothing`

Use the auto-added custom input option to let the user provide custom reply text when needed.

Example `question` call shape:

```json
{
  "questions": [
    {
      "header": "Review Comment",
      "question": "\"Some comments would be handy so we have an idea what this does\" @/docker/postgres/init-multi-db.sh",
      "options": [
        {
          "label": "Apply suggested change (Recommended)",
          "description": "Update code based on assessment; do not reply or resolve yet"
        },
        {
          "label": "Reply + resolve",
          "description": "Post a reply and set status to fixed"
        },
        {
          "label": "Reply only",
          "description": "Post a reply and keep thread active"
        },
        {
          "label": "Do nothing",
          "description": "Take no action on this thread"
        }
      ]
    }
  ]
}
```

Execution requirements after answers are received:
- Process threads in order, one at a time.
- For `Apply suggested change (Recommended)`: apply code changes only (no reply, no resolve).
- Immediately after applying suggested changes, ask a follow-up `question` for that same thread:
  - `Reply + resolve now (Recommended)`
  - `Skip for now`
- Do not move to the next thread until that follow-up question is asked and answered.
- If user chooses `Reply + resolve now`, post reply first, then patch thread status to `fixed`.
- If user chooses `Skip for now`, leave thread `active` without posting a reply.
- For `Reply + resolve`: post reply first, then patch thread status to `fixed`.
- For `Reply only`: post reply and keep thread `active`.
- For `Do nothing`: do not post and do not change status.

Example follow-up `question` after applying suggested change:

```json
{
  "questions": [
    {
      "header": "Post-Change Action",
      "question": "\"Some comments would be handy so we have an idea what this does\" @/docker/postgres/init-multi-db.sh",
      "options": [
        {
          "label": "Reply + resolve now (Recommended)",
          "description": "Post a reply and set status to fixed"
        },
        {
          "label": "Skip for now",
          "description": "Keep thread active and move on"
        }
      ]
    }
  ]
}
```

### 1) Get PR details (and repository id)

Use `--detect true`.

```bash
az repos pr show --id <PR_ID> --organization "https://dev.azure.com/<org>" --detect true
```

Notes:
- `az repos pr show` in this environment may not support `--project`.
- Use the repository GUID from output (`repository.id`) for `az devops invoke` calls.

### 2) Fetch threads/comments

```bash
az devops invoke \
  --organization "https://dev.azure.com/<org>" \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project=<project> repositoryId=<repo-guid> pullRequestId=<pr-id> \
  --api-version 7.1
```

Recommended compact query:

```bash
az devops invoke \
  --organization "https://dev.azure.com/<org>" \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project=<project> repositoryId=<repo-guid> pullRequestId=<pr-id> \
  --api-version 7.1 \
  --query "value[].{threadId:id,status:status,file:threadContext.filePath,comments:comments[].{id:id,type:commentType,author:author.displayName,content:content,published:publishedDate,parent:parentCommentId}}" \
  -o json
```

Notes:
- Use API version `7.1`.
- `7.1-preview.1` can fail in some setups.

### 2b) Fetch only active threads (required for review completion)

Use this query to list open threads that must be addressed before approval:

```bash
az devops invoke \
  --organization "https://dev.azure.com/<org>" \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project=<project> repositoryId=<repo-guid> pullRequestId=<pr-id> \
  --api-version 7.1 \
  --query "value[?status=='active'].{threadId:id,file:threadContext.filePath,comments:comments[].{id:id,author:author.displayName,content:content}}" \
  -o json
```

### 3) Post a reply on a thread

Use a temp JSON file with `--in-file`.

```bash
tmp=$(mktemp) && \
printf '%s' '{"content":"<reply>","commentType":"text"}' > "$tmp" && \
az devops invoke \
  --organization "https://dev.azure.com/<org>" \
  --area git \
  --resource pullRequestThreadComments \
  --route-parameters project=<project> repositoryId=<repo-guid> pullRequestId=<pr-id> threadId=<thread-id> \
  --api-version 7.1 \
  --http-method POST \
  --in-file "$tmp" && \
rm "$tmp"
```

### 4) Resolve a thread

```bash
tmp=$(mktemp) && \
printf '%s' '{"status":"fixed"}' > "$tmp" && \
az devops invoke \
  --organization "https://dev.azure.com/<org>" \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project=<project> repositoryId=<repo-guid> pullRequestId=<pr-id> threadId=<thread-id> \
  --api-version 7.1 \
  --http-method PATCH \
  --in-file "$tmp" && \
rm "$tmp"
```

### 5) Verify completion

```bash
az devops invoke \
  --organization "https://dev.azure.com/<org>" \
  --area git \
  --resource pullRequestThreads \
  --route-parameters project=<project> repositoryId=<repo-guid> pullRequestId=<pr-id> \
  --api-version 7.1 \
  --query "value[?status=='active'].[id,threadContext.filePath]" \
  -o json
```

Expected done state: `[]`.

## Conversation behavior

- If user asks to post/resolve many threads, still handle them sequentially with one `question` call per thread.
- Keep reply text simple and direct unless user asks for detail.
- If user asks for "just done" on specific threads, use `done`.
- After actions, report which thread IDs were replied to, which were resolved, and whether active threads remain.
- If user tries to move to the next thread after `Apply suggested change`, first ask the required follow-up question (`Reply + resolve now` or `Skip for now`) before continuing.
- For review requests, explicitly report: number of active threads found, which were resolved, and whether approval was cast after thread cleanup.

## Common pitfalls

- Do not use repository name in `repositoryId` route parameter; use GUID.
- Do not assume `--project` is available on `az repos pr show`.
- Avoid inline JSON quoting mistakes; use temp file + `--in-file`.
- Do not mark unresolved if user explicitly asked to resolve; set thread status to `fixed`.
