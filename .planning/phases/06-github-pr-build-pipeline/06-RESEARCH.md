# Phase 6: GitHub PR Build Pipeline - Research

**Researched:** 2026-03-14
**Domain:** GitHub Actions CI/CD for Nix Flake Builds
**Confidence:** HIGH

## Summary

This phase adds actual `nix build` verification to the existing CI pipeline. The current CI only runs fast checks (format, linter, flake check --no-build) but does not verify that configurations can actually build. This research covers: GitHub Actions best practices for Nix, caching strategies to optimize build times, and specific challenges related to building configurations that use sops-nix secrets.

**Primary recommendation:** Use DeterminateSystems/nix-installer-action with magic-nix-cache-action for zero-configuration caching, and build system toplevel derivations for both NixOS and Darwin configurations. Note: secrets-dependent modules will require conditional handling in CI.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Build Check Type:**
- Use `nix build` for strictest verification
- Actually builds derivations, downloads/compiles dependencies
- More strict than `nix eval` or `nix flake check --no-build`

**Build Targets:**
- Build all configurations: NixOS (x86_64-linux) and Darwin (aarch64-darwin)
- Leverage existing CI matrix cross-platform capability
- Verify all platform configurations build correctly

**Cache Strategy:**
- Use GitHub Actions built-in Nix store cache
- No need for additional Cachix configuration
- Accelerate subsequent builds, reduce CI time

**Execution Order:**
- Fast then slow: format -> statix -> flake check -> build
- Fast fail, fast feedback principle
- Only run time-consuming builds after fast checks pass

**Trigger Timing:**
- All PRs run build checks
- Ensure configuration correctness is verified before merge
- Keep existing push to main branch trigger

### Claude's Discretion

(Not specified - research should recommend optimal approaches within locked decisions)

### Deferred Ideas (OUT OF SCOPE)

None - discussion stayed within phase scope
</user_constraints>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| DeterminateSystems/nix-installer-action | @main | Install Nix on GitHub Actions | Fast (~4s Linux, ~20s macOS), KVM support, flakes enabled by default |
| DeterminateSystems/magic-nix-cache-action | @main | Free GitHub Actions cache for Nix | Zero configuration, free, secure, works with forks |
| actions/checkout | @v4 | Checkout repository | Standard GitHub Action |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| cachix/install-nix-action | @v31 | Alternative Nix installer | Already in use in project - can migrate or keep |
| cachix/cachix-action | @v31 | Cachix binary cache | If using external cache service |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| magic-nix-cache-action | FlakeHub Cache | FlakeHub Cache offers sharing builds outside CI, but requires paid subscription after trial |
| DeterminateSystems actions | cachix actions | cachix/install-nix-action already used, but magic-nix-cache provides free caching without account |

**Installation:**
```yaml
# Recommended modern approach
- uses: DeterminateSystems/nix-installer-action@main
- uses: DeterminateSystems/magic-nix-cache-action@main
```

## Architecture Patterns

### Recommended Workflow Structure

```
.github/workflows/
├── ci.yml              # Existing fast checks (keep as-is)
└── build.yml           # New: actual build verification (or add job to ci.yml)
```

### Pattern 1: Matrix Build for Cross-Platform
**What:** Use GitHub Actions matrix to build both platforms in parallel
**When to use:** Always for multi-platform Nix projects
**Example:**
```yaml
# Source: DeterminateSystems/nix-installer-action README
jobs:
  build:
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            system: x86_64-linux
          - os: macos-latest
            system: aarch64-darwin
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main
      - name: Build configuration
        run: nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

### Pattern 2: Build System Toplevel
**What:** Build the full system configuration derivation
**When to use:** Verifying system configurations (not just packages)
**Example:**
```bash
# Build NixOS configuration
nix build .#nixosConfigurations.nixos.config.system.build.toplevel

# Build Darwin configuration
nix build .#darwinConfigurations.zhaochanglongdeMacBook-Air.config.system.build.toplevel
```

### Pattern 3: Job Dependencies for Fast Fail
**What:** Run fast checks first, only build if they pass
**When to use:** Optimizing CI time with fast feedback
**Example:**
```yaml
jobs:
  check:
    # Fast checks (format, lint, flake check)
    # ...

  build:
    needs: check  # Only runs if check passes
    # Actual build verification
    # ...
```

### Anti-Patterns to Avoid
- **Running build without caching:** Wastes time rebuilding same dependencies
- **Building all configurations in single job:** Slower feedback, harder to debug platform-specific issues
- **Ignoring secrets in CI:** Builds will fail if sops-nix secrets are required

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Nix caching | Custom cache scripts | magic-nix-cache-action | Handles cache keys, restore, save automatically |
| Nix installation | Custom install scripts | nix-installer-action | Handles KVM, macOS specifics, flakes setup |
| Matrix configuration | Manual job duplication | GitHub Actions matrix | Cleaner YAML, easier maintenance |

**Key insight:** The DeterminateSystems actions are maintained by Nix experts and handle edge cases you'll miss in custom solutions.

## Common Pitfalls

### Pitfall 1: Secrets Required During Build
**What goes wrong:** sops-nix configurations require SSH keys for secret decryption at evaluation/build time, causing CI builds to fail
**Why it happens:** The project uses `sops.age.sshKeyPaths` pointing to `/root/.ssh/id_ed25519` (NixOS) or `/var/root/.ssh/id_ed25519` (Darwin)
**How to avoid:**
1. Option A: Use `nix eval` to evaluate only, don't build secrets-dependent parts
2. Option B: Mock secrets in CI using `sops.secrets.*.neededForDocs = false` or conditional config
3. Option C: Build specific outputs that don't require secrets
**Warning signs:** Build fails with "cannot read SSH key" or sops decryption errors

### Pitfall 2: Cache Rate Limits
**What goes wrong:** GitHub Actions cache has rate limits, causing HTTP 418 errors on large builds
**Why it happens:** Many cache reads/writes in short time
**How to avoid:** Magic Nix Cache handles this gracefully - failed cache operations don't fail builds
**Warning signs:** Logs show "HTTP error 418" but build continues

### Pitfall 3: Platform Mismatch in Build Command
**What goes wrong:** Running `nix build .#nixosConfigurations...` on macOS runner or vice versa
**Why it happens:** Matrix runs both platforms, but build commands must match
**How to avoid:** Use conditional commands based on matrix `system` variable, or use `--system` flag
**Warning signs:** "error: attribute 'nixosConfigurations' missing" on Darwin runner

### Pitfall 4: Lix vs Standard Nix
**What goes wrong:** Project uses Lix, but CI installs standard Nix
**Why it happens:** Configuration specifies `nix.package = pkgs.lixPackageSets.stable.lix`
**How to avoid:** This is fine for CI - Lix is compatible. Build will use Lix as specified in config
**Warning signs:** None - Lix works with standard Nix installer

## Code Examples

### Complete CI Build Job
```yaml
# Source: DeterminateSystems documentation patterns
jobs:
  build:
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            system: x86_64-linux
            config: nixos
          - os: macos-latest
            system: aarch64-darwin
            config: darwin
    runs-on: ${{ matrix.os }}
    timeout-minutes: 60
    needs: check  # Run after fast checks pass

    steps:
      - uses: actions/checkout@v4

      - uses: DeterminateSystems/nix-installer-action@main

      - uses: DeterminateSystems/magic-nix-cache-action@main

      - name: Build NixOS configuration
        if: matrix.config == 'nixos'
        run: nix build .#nixosConfigurations.nixos.config.system.build.toplevel

      - name: Build Darwin configuration
        if: matrix.config == 'darwin'
        run: nix build .#darwinConfigurations.zhaochanglongdeMacBook-Air.config.system.build.toplevel
```

### Alternative: Build Specific Outputs
```bash
# If secrets cause issues, build package outputs instead
nix build .#packages.x86_64-linux.default

# Or use nix flake check with actual builds
nix flake check --system x86_64-linux
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| cachix/install-nix-action | DeterminateSystems/nix-installer-action | 2023-2024 | Faster installs, KVM auto-config, flakes by default |
| Manual cache actions | magic-nix-cache-action | 2023 | Zero-config free caching |
| Build everything | Matrix parallel builds | Always | Faster feedback, parallel execution |
| nix-build | nix build (new CLI) | 2020+ | Cleaner syntax, better flake integration |

**Deprecated/outdated:**
- `nix-build` command: Use `nix build` instead
- Custom caching scripts: Use magic-nix-cache-action

## Open Questions

1. **How to handle sops-nix secrets in CI?**
   - What we know: Secrets require SSH keys at `/root/.ssh/id_ed25519` and `/var/root/.ssh/id_ed25519`
   - What's unclear: Whether builds fail at evaluation time or can proceed without actual secret values
   - Recommendation: Test locally with `nix build --dry-run` to see if secrets are needed at evaluation time. If so, either mock secrets or skip full builds in CI.

2. **Should we migrate from cachix/install-nix-action to DeterminateSystems?**
   - What we know: Both work; DeterminateSystems is newer and better maintained
   - What's unclear: Migration effort for existing project
   - Recommendation: Migrate for better caching integration; the action is drop-in compatible

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | nix build (no traditional test framework) |
| Config file | flake.nix |
| Quick run command | `nix build .#nixosConfigurations.nixos.config.system.build.toplevel` |
| Full suite command | `nix flake check && nix build .#nixosConfigurations.nixos.config.system.build.toplevel && nix build .#darwinConfigurations.zhaochanglongdeMacBook-Air.config.system.build.toplevel` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BUILD-01 | NixOS config builds successfully | build | `nix build .#nixosConfigurations.nixos.config.system.build.toplevel` | N/A - CI job |
| BUILD-02 | Darwin config builds successfully | build | `nix build .#darwinConfigurations.zhaochanglongdeMacBook-Air.config.system.build.toplevel` | N/A - CI job |
| BUILD-03 | Build caching works | integration | CI runtime comparison | N/A - CI metrics |

### Sampling Rate
- **Per task commit:** Not applicable - build verification is per PR
- **Per wave merge:** Full build verification
- **Phase gate:** Both platforms build successfully

### Wave 0 Gaps
- [ ] `.github/workflows/build.yml` - new workflow file for build verification
- [ ] Secrets handling strategy - determine if builds require actual secrets or can proceed with mock/empty values

*(Test infrastructure is CI-based; no traditional test files needed)*

## Sources

### Primary (HIGH confidence)
- [DeterminateSystems/nix-installer-action README](https://github.com/DeterminateSystems/nix-installer-action) - installation options, configuration
- [DeterminateSystems/magic-nix-cache-action README](https://github.com/DeterminateSystems/magic-nix-cache-action) - caching configuration, rate limits
- [cachix/install-nix-action README](https://github.com/cachix/install-nix-action) - current project action documentation
- Project files: `flake.nix`, `nixos/default.nix`, `darwin/default.nix`, `.github/workflows/ci.yml`

### Secondary (MEDIUM confidence)
- Nix manual: `nix build` command reference - build syntax and options

### Tertiary (LOW confidence)
- None - all critical information verified from official sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Direct from DeterminateSystems official documentation
- Architecture: HIGH - Based on current CI patterns and Nix best practices
- Pitfalls: MEDIUM - Secrets handling in CI requires testing to confirm

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (30 days - GitHub Actions ecosystem stable)