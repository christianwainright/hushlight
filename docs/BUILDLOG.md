# Build log

Newest first. One entry per working session that changed real code or made a real
decision. Template:

```markdown
## YYYY-MM-DD · HL-0NN Title
**Changed:** what and where
**Decisions:** numbered entries written, or "none"
**Verified:** how you know it works
**Next:** the thing a fresh session should pick up
```

This log restarts at the open-sourcing (decision 0067). The entries before it, from
the extraction on 2026-08-23 to 1.1 (6), stay in the private repository. The
decisions in `docs/decisions/` carry the reasoning those entries recorded.

## 2026-11-18 · HL-070 · The source is open
**Changed:** the repository is prepared for publication as a single fresh commit
under MIT. Added `LICENSE`, `CONTRIBUTING.md`, and a public `README.md` (what the app
is, what makes it different, how it was built, how to build it). Removed
`docs/history/`; this log restarts here; decision 0020 is cut down to what governs
this repository. Personal context was scrubbed from the backlog, the submission
checklist and decisions 0018 and 0033, along with a private artifact link and a
review-submission ID. The device checks that closed HL-011, HL-013 and SP-196 now read
as plain facts. `CLAUDE.md` gains the public-docs rule.
**Decisions:** 0067 (the source is open).
**Verified:** see the commit that publishes it. A secret scan over all 240 private
commits found no key, certificate, `.p8`, `.p12` or provisioning profile. The
remaining identifiers (team ID, bundle IDs, support address) are already public in
the shipped binary.
**Next:** Christian creates the public repository and pushes the snapshot (gate 2:
his account). 1.1 (6) still waits on §2.2: the iPad and Duo frames, the review
notes, then Submit.
