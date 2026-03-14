# Requirements: Nix Configuration Project

**Defined:** 2026-03-14
**Core Value:** Single source of truth for all system configurations across platforms — reproducible, version-controlled, and secure.

## Validated Requirements

These capabilities are already implemented and working.

### Foundation

- [x] **FOUND-01**: Modular structure with darwin/, nixos/, shared/ directories
- [x] **FOUND-02**: Nix Flake with proper inputs and outputs structure
- [x] **FOUND-03**: Home-manager integration with useGlobalPkgs and useUserPackages
- [x] **FOUND-04**: Cross-platform module imports via specialArgs
- [x] **FOUND-05**: State versions configured for NixOS and home-manager

### Secrets Management

- [x] **SECRE-01**: sops-nix integration with age encryption
- [x] **SECRE-02**: Platform-specific sops configuration (darwin/sops.nix, nixos/sops.nix)
- [x] **SECRE-03**: Shared secrets directory structure
- [x] **SECRE-04**: Secrets referenced via config.sops.secrets.*.path pattern

### NixOS Platform

- [x] **NIXOS-01**: System configuration with hardware-configuration.nix
- [x] **NIXOS-02**: Secure boot support via lanzaboote
- [x] **NIXOS-03**: MicroVM support with declarative VM definitions
- [x] **NIXOS-04**: SSH daemon configuration
- [x] **NIXOS-05**: Podman container runtime
- [x] **NIXOS-06**: Zerotier networking

### Darwin Platform

- [x] **DARWN-01**: macOS system configuration via nix-darwin
- [x] **DARWN-02**: Platform-specific home-manager modules
- [x] **DARWN-03**: Platform-specific packages

### User Environment

- [x] **USER-01**: Zsh configuration with oh-my-zsh
- [x] **USER-02**: Git configuration (userName, userEmail, aliases)
- [x] **USER-03**: SSH configuration (keys, known hosts)
- [x] **USER-04**: Direnv + nix-direnv integration
- [x] **USER-05**: Tmux configuration
- [x] **USER-06**: Nix LSP (nil) and formatting (nixpkgs-fmt)

### Development Tools

- [x] **DEVEL-01**: nixvim declarative Neovim configuration
- [x] **DEVEL-02**: Kitty terminal configuration
- [x] **DEVEL-03**: VSCode configuration
- [x] **DEVEL-04**: Zed editor configuration
- [x] **DEVEL-05**: AI tooling (opencode, claude-code, MCP servers)
- [x] **DEVEL-06**: 1Password integration
- [x] **DEVEL-07**: Ollama local LLM setup

### Package Management

- [x] **PKG-01**: NixOS packages via environment.systemPackages
- [x] **PKG-02**: Darwin packages via home.packages
- [x] **PKG-03**: Flatpak integration via nix-flatpak
- [x] **PKG-04**: AppImage support

## Active Requirements

Requirements for validation and enhancement.

### Validation & Documentation

- [ ] **VAL-01**: Verify all secrets are properly encrypted (no secrets in nix store)
- [ ] **VAL-02**: Document rebuild procedures for both platforms
- [x] **VAL-03**: Verify cross-platform secret sharing works correctly
- [x] **VAL-04**: Validate MicroVM networking configuration

### Tooling Enhancement

- [x] **TOOL-01**: alejandra formatter configured in flake.nix
- [x] **TOOL-02**: statix linter added to system packages
- [x] **TOOL-03**: nom build visualizer with shell aliases
- [x] **TOOL-04**: nixd LSP configured with alejandra formatting

### Quality Improvements

- [x] **QUAL-01**: Add CI/CD for flake checks
- [x] **QUAL-02**: Regular input update schedule
- [x] **QUAL-03**: Consolidate duplicate git/ssh configs across platforms

### Build Pipeline (Phase 6)

- [x] **BUILD-01**: NixOS configuration builds successfully in CI
- [x] **BUILD-02**: Darwin configuration builds successfully in CI
- [x] **BUILD-03**: GitHub Actions caching works (magic-nix-cache)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Infrastructure

- **INFRA-01**: Impermanence (tmpfs root with persistent state)
- **INFRA-02**: Disko for declarative disk partitioning
- **INFRA-03**: NixOS anywhere / remote deployment
- **INFRA-04**: Binary cache (Cachix or attic)

### Scaling

- **SCALE-01**: Multiple machine support (nixosConfigurations for multiple hosts)
- **SCALE-02**: User profile abstraction
- **SCALE-03**: Host-specific secrets management

### Desktop (NixOS)

- **DESK-01**: Full Plasma 6 desktop configuration
- **DESK-02**: PipeWire audio configuration
- **DESK-03**: SDDM display manager
- **DESK-04**: Power management

### Gaming

- **GAME-01**: Steam + Proton-GE setup
- **GAME-02**: MangoHud performance overlay
- **GAME-03**: Sunshine game streaming

### Virtualization

- **VIRT-01**: Waydroid Android container
- **VIRT-02**: QEMU virtualization

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Imperative package installation | Breaks reproducibility, use declarative packages |
| Hardcoded secrets in config | Security risk, use sops-nix exclusively |
| Multiple Nix implementations | Lix is standardized, avoid compatibility issues |
| Real-time config sync | Git-based deployment is sufficient |
| Non-flake Nix paths | All dependencies through flake inputs |
| Windows support | Nix-focused project, no Windows target |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 - FOUND-05 | Phase 1 | Validated |
| USER-01 - USER-06 | Phase 1 | Validated |
| PKG-01 - PKG-04 | Phase 1 | Validated |
| SECRE-01 - SECRE-04 | Phase 2 | Validated |
| NIXOS-01 - NIXOS-06 | Phase 3 | Validated |
| DARWN-01 - DARWN-03 | Phase 3 | Validated |
| DEVEL-01 - DEVEL-07 | Phase 4 | Validated |
| VAL-01 - VAL-02 | Phase 5 | Pending |
| VAL-03 - VAL-04 | Phase 5 | Complete |
| TOOL-01 - TOOL-04 | Phase 5 | Complete |
| QUAL-01 - QUAL-03 | Phase 5 | Complete |
| BUILD-01 - BUILD-03 | Phase 6 | Complete |

**Coverage:**
- Validated requirements: 32 total (Phases 1-4)
- Active requirements: 14 total (Phases 5-6)
- Mapped to phases: 46
- Unmapped: 0

---
*Requirements defined: 2026-03-14*
*Last updated: 2026-03-15 after Phase 6 completion*