# Product reviews (selfmanaged)

**Purpose:** Public, git-tracked **product quality surface** for this bootstrap Type 0 CLI — peer of `tests/`. Holds the living review plan, test-plan lock-in, prior-report lessons, and committed run reports.

**Not:** Product law (`docs/requirements/`). Not harness blank checklists (`docs/templates/checklists/`). Not session `/tmp` scratch (promote durable outcomes here).

**Product class:** Bootstrap project (Type 0; no domain requirements SSOT).  
**Ship unit:** `src/selfmanaged` (+ `src/selfmanaged.sha256`)  
**Tests:** `./tests/run.sh`

## Layout

```text
reviews/
  README.md              # this file
  index.md               # registry of plans + reports + open items
  what-to-review.md      # living checklist (review plan)
  test-plan.md           # TP-* → tests/
  lessons.md             # L-* failure modes from prior reports
  reports/
    YYYY-MM-DD-<scope>.md
```

## Agent rules

1. Every durable product review **loads** `lessons.md` first.  
2. Walk applicable sections of `what-to-review.md`.  
3. Map open **bugs** to `test-plan.md` rows (have / TODO / n/a).  
4. Publish under `reports/` + update `index.md` in the same change.  
5. No secrets. No harness path tree dumps as navigation.  
6. Review-only by default — do not change ship unit unless implement is authorized.  
7. Prefer root `reviews/` (this tree). Historical harness note may exist under `docs/reviews/`; product SSOT is **here**.

## Skills / terms

| Artifact | Path |
|----------|------|
| Product review skill | `docs/skills/skill-product-review.md` |
| Write review skill | `docs/skills/skill-write-review.md` |
| Template | `docs/templates/template-project-reviews.md` |
| Terms | `project-reviews`, `review-plan`, `project-review-folder`, `review-report` |
