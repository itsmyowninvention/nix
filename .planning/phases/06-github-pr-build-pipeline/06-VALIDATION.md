---
phase: 6
slug: github-pr-build-pipeline
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-14
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GitHub Actions CI |
| **Config file** | `.github/workflows/ci.yml` |
| **Quick run command** | `nix flake check --no-build` |
| **Full suite command** | `nix build .#nixosConfigurations.nixos.config.system.build.toplevel` |
| **Estimated runtime** | ~15-30 minutes (build) |

---

## Sampling Rate

- **After every task commit:** Run `nix flake check --no-build` locally
- **After every plan wave:** Push to branch, check CI passes
- **Before `/gsd:verify-work`:** All CI checks green
- **Max feedback latency:** 30 minutes (CI build time)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 6-01-01 | 01 | 1 | Build Job | integration | `gh workflow run ci.yml` | ❌ W0 | ⬜ pending |
| 6-01-02 | 01 | 1 | Cache | integration | CI log shows cache hit | ❌ W0 | ⬜ pending |
| 6-02-01 | 02 | 1 | Secrets | integration | `nix build --dry-run` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.github/workflows/ci.yml` — existing CI config
- [ ] `flake.nix` — defines nixosConfigurations and darwinConfigurations

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| PR build status | Build verification | Requires actual PR | Create PR, verify build job runs |
| Cache effectiveness | Performance | Requires multiple CI runs | Check second run is faster |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30 min
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending