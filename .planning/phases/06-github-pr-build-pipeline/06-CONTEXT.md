# Phase 6: GitHub PR Build Pipeline - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning (modification)

<domain>
## Phase Boundary

修改 GitHub CI pipeline，将 `nix build` 构建验证改为 `nix eval` 求值验证。现有 CI 已有 PR 触发、alejandra 格式检查、statix linter 和 `nix flake check --no-build`。此阶段将添加 `nix eval` 来验证所有配置 derivations 正确求值，移除耗时的 build job。

</domain>

<decisions>
## Implementation Decisions

### 验证方法
- 使用 `nix eval` 替代 `nix build` 进行验证
- `nix eval` 检查 derivations 能正确解析和求值，但不实际构建
- 类似 Terraform plan 的理念：验证配置正确性而不应用

### 求值目标
- 求值所有配置 derivations：NixOS 和 Darwin
- 使用 `nix eval .#nixosConfigurations.<name>.config.system.build.toplevel.drvPath` 或类似路径
- 确保所有模块导入正确解析、所有选项定义有效

### Job 结构
- 将 `nix eval` 合并到现有的 check job 中
- 完全移除 build job（不再需要单独的 60 分钟构建）
- 保持现有的 format check 和 statix check

### 权衡接受
- 接受 `nix eval` 不验证实际构建成功的权衡
- CI 时间大幅缩短（从 60+ 分钟到几分钟）
- 配置正确性验证足够，实际构建在部署时验证

</decisions>

<specifics>
## Specific Ideas

- 保持现有 CI 配置作为快速检查层
- 添加 `nix eval` 步骤到 check job
- 移除整个 build job 及其相关配置（DeterminateSystems actions, cache 等）

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/ci.yml`: 现有 CI 配置，check job 已有矩阵构建
- `flake.nix`: 定义了 nixosConfigurations 和 darwinConfigurations

### Established Patterns
- 使用 `cachix/install-nix-action@master` 安装 Nix
- 矩阵构建：`ubuntu-latest` (x86_64-linux) 和 `macos-latest` (aarch64-darwin)
- 并发控制：`cancel-in-progress: true`

### Integration Points
- 在 check job 中添加 `nix eval` 步骤
- 删除 build job（lines 44-74）
- 评估路径示例：
  - `nix eval .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath --raw`
  - `nix eval .#darwinConfigurations.zhaochanglongdeMacBook-Air.config.system.build.toplevel.drvPath --raw`

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-github-pr-build-pipeline*
*Context gathered: 2026-03-15*