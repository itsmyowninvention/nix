# Phase 6: GitHub PR Build Pipeline - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

为 GitHub PR 添加 nix build 构建检查，验证所有平台配置（NixOS 和 Darwin）可以正确构建。现有 CI 已有 PR 触发、alejandra 格式检查和 statix linter。此阶段专注于添加实际的构建验证。

</domain>

<decisions>
## Implementation Decisions

### 构建检查类型
- 使用 `nix build` 进行最严格的验证
- 会实际构建 derivation，下载/编译依赖
- 比 `nix eval` 或 `nix flake check --no-build` 更严格

### 构建目标
- 构建所有配置：NixOS (x86_64-linux) 和 Darwin (aarch64-darwin)
- 利用现有 CI 矩阵的跨平台能力
- 验证所有平台配置都能正确构建

### 缓存策略
- 使用 GitHub Actions 内置的 Nix store 缓存
- 无需额外配置 Cachix
- 加速后续构建，减少 CI 时间

### 执行顺序
- 先快后慢：format → statix → flake check → build
- 快失败快反馈原则
- 在快速检查通过后才运行耗时的构建

### 触发时机
- 所有 PR 都运行构建检查
- 确保合并前验证配置正确性
- 保持现有 push 到 main 分支的触发

</decisions>

<specifics>
## Specific Ideas

- 保持现有 CI 配置作为快速检查层
- 添加新的 build job 作为严格验证层
- 利用 GitHub Actions 矩阵实现跨平台构建

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/ci.yml`: 现有 CI 配置，已有 PR 触发和多平台矩阵
- `flake.nix`: 定义了 nixosConfigurations 和 darwinConfigurations

### Established Patterns
- 使用 `cachix/install-nix-action@master` 安装 Nix
- 矩阵构建：`ubuntu-latest` (x86_64-linux) 和 `macos-latest` (aarch64-darwin)
- 并发控制：`cancel-in-progress: true`

### Integration Points
- 在现有 CI 文件中添加 build job
- 或创建新的 workflow 文件专门用于构建验证
- 使用 `nix build .#nixosConfigurations.<name>.config.system.build.toplevel` 构建 NixOS 配置
- 使用 `nix build .#darwinConfigurations.<name>.config.system.build.toplevel` 构建 Darwin 配置

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-github-pr-build-pipeline*
*Context gathered: 2026-03-14*