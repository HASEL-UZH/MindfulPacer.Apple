# Contributing to MindfulPacer

Thank you for your interest in contributing! Please read this guide before opening issues or submitting pull requests.


## Roles

| Role             | Person            | Responsibility                                                  |
|------------------|-------------------|-----------------------------------------------------------------|
| Product Owner    | Andre Meyer       | Organizes project and prioritizes backlog                       |
| Lead Developer   | Grigor Dochev     | Implements features according to project management             |
| Developer        | Tobias Grossmann  | Implements features (currently in onboarding)                   |
| Community Lead   | Tobi Hoch         | Collects user feedback, creates issues, provides support        |
| Research Lead    | Isabelle Cuber    | Runs studies to validate the project                            |

## Project Management

We use a **GitHub Project** to track all work. Each issue has the following fields:

| Field     | Values                                                               | Set by              |
|-----------|----------------------------------------------------------------------|----------------------|
| Status    | Backlog → In Specification → Ready → In Progress → In Review → Done | Developer / Reporter |
| Priority  | High, Medium, Low                                                    | Product Owner        |
| Size      | XS (minutes), S, M, L, XL (a day or more)                           | Developer            |
| Iteration | Version-based, e.g. V1.8, V1.9, V1.10                               | Product Owner        |
| Type      | Bug, Feature, Task                                                   | Reporter             |
| Labels    | bug, enhancement, documentation, etc. (optional)                     | Reporter             |

## Gitflow

We maintain two long-lived branches:

- **`main`** — production. Only updated via release PRs from `dev`. Tagged with a version after each release (e.g. `v1.8.4`).
- **`dev`** — integration branch. All feature/bugfix/task branches merge here.

### Branch naming

Create a branch from `dev` for every issue. The name follows:
```
<type>/<issue-number>-<short-description>
```

| Type    | Prefix     | Example                                          |
|---------|------------|--------------------------------------------------|
| Bug     | `bugfix/`  | `bugfix/107-bug-opening-app-through-complication` |
| Feature | `feature/` | `feature/39-mode-of-use-setting`                  |
| Task    | `task/`    | `task/114-support-additional-languages`            |

## Commits

Prefix every commit message with the issue number:
```
[#107] Added tests for debugging
[#39] Implemented mode selection in onboarding
```

## Pull Requests

### Feature/bugfix PRs → `dev`

Each PR addresses a **single issue**. Use **squash and merge** to keep `dev` history clean. Delete the branch after merging.

**Title:** Short description of the change

**Body format:**
```
# <Title> (Closes #<issue>)

## Description
Brief explanation of what this PR does and why.

### Changes Made
- Bullet points summarising the key changes.

## Implementation Details
Numbered list of notable implementation decisions (optional, for larger PRs).

## Screenshots
Side-by-side tables if there are UI changes (optional).

Closes #<issue>
```

Include `Closes #<issue>` so the issue auto-closes and moves to Done when the PR is merged.

### Release PRs → `main`

When `dev` is ready for a public release, open a single PR from `dev` to `main`. This bundles multiple issues into one release.

**Title:** `Release <version>` (e.g. `Release 1.8.4`)

**Body format:**
```
## Summary
One-liner describing the scope of the release.

### <Category>
- Change description (#<issue>)
- Change description (#<issue>)

### <Category>
- ...
```

Group changes into logical categories (e.g. Monitoring & Reminders, Analytics, Data & Syncing, Content & UI, Housekeeping). Reference issue numbers inline.

After merging, tag `main` with the version (e.g. `v1.8.4`) and create a corresponding GitHub Release.

## Summary
```
Issue → Branch from dev → Commits prefixed [#N] → PR to dev (squash merge) → Delete branch
                                                                    ↓
                                          Multiple PRs accumulate on dev
                                                                    ↓
                                              Release PR: dev → main (merge) → Tag → GitHub Release
```

## Disclaimer

MindfulPacer is classified as evaluation software (Auswertesoftware), not a medical device, under applicable regulations in Switzerland (MepV/EU-MDR), the EU (MDCG 2019-11), the UK (MHRA guidance), and the USA (FDA General Wellness Policy). The app visualizes raw biometric data from off-the-shelf smartwatches alongside user-created diary entries to support self-directed activity management (Activity Pacing) — it does not make diagnoses, generate automated recommendations, or suggest individual actions.

Contributors must ensure this remains the case: any new feature that introduces automated inference, personalized medical suggestions, or diagnostic functionality would fundamentally change the regulatory status of the app and must be discussed with the core team before implementation. When in doubt, keep the app in display and reflection mode — show data, don't interpret it (i.e. no AI features, no automated correlations, no automated suggestions).
