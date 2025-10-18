---
description: Create a git commit with proper message format
---

Create a git commit following these steps:

1. Run `git status` to see all untracked and modified files
2. Run `git diff --cached` to see staged changes (if any exist)
3. Run `git diff` to see unstaged changes (if any exist)
4. Run `git log --oneline -5` to see recent commit messages for style reference

5. Analyze the changes and write a concise commit message that:
   - Has a clear, imperative subject line describing WHAT changed (not HOW)
   - Focuses on the actual changes shown in the diff
   - Uses bullet points for multiple changes
   - Does NOT describe implementation steps or processes
   - Follows the style of recent commits in the repository

6. Stage the relevant files with `git add`

7. Run `git status` after staging to verify

Important: Base the commit message ONLY on what the git diff shows, not assumptions about what was moved or reorganized.
