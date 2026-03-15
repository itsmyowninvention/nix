---
phase: quick-3
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - darwin/sops.nix
autonomous: true
requirements: []
must_haves:
  truths:
    - "alejandra --check passes for darwin/sops.nix"
  artifacts:
    - path: "darwin/sops.nix"
      provides: "sops configuration for darwin"
      formatted: true
  key_links: []
---

<objective>
Fix nix formatting in darwin/sops.nix to pass alejandra checks.

Purpose: Ensure consistent code style across the nix configuration.
Output: Properly formatted darwin/sops.nix file.
</objective>

<execution_context>
@./.claude/get-shit-done/workflows/execute-plan.md
@./.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Format darwin/sops.nix with alejandra</name>
  <files>darwin/sops.nix</files>
  <action>
    Fix formatting issue in darwin/sops.nix. The current code has incorrect spacing in the function argument pattern.

    Current (incorrect):
    ```nix
    {inputs, lib, ...}: {
    ```

    Expected (correct per alejandra):
    ```nix
    { inputs, lib, ... }: {
    ```

    Run `alejandra ./darwin/sops.nix` to automatically fix the formatting.
    This adds spaces after `{` and before `}` in the attribute set pattern.
  </action>
  <verify>
    <automated>alejandra --check ./darwin/sops.nix</automated>
  </verify>
  <done>alejandra --check passes for darwin/sops.nix with exit code 0</done>
</task>

</tasks>

<verification>
- Run `alejandra --check ./darwin/sops.nix` to verify formatting is correct
- Run `git diff ./darwin/sops.nix` to confirm minimal, formatting-only changes
</verification>

<success_criteria>
- alejandra --check passes for darwin/sops.nix
- Only formatting changes (no logic changes)
- File committed to git
</success_criteria>

<output>
After completion, create `.planning/quick/3-nix-formatting/3-SUMMARY.md`
</output>