# dsh: DeepSeek Harness — 开源 agent harness（terminal/web/headless/ACP/SDK 多 profile）。
# 上游: https://github.com/deepseek-ai/deepseek-harness (MIT)，npm 包 @deepseek-ai/dsh。
# 打包的是 npm 发布包（官方安装路径，README 指定 `npx @deepseek-ai/dsh web`），
# 非源码构建：发布包只带预编译的 lib/*.js，无 build script；deps 里 91 个都是运行时依赖。
# 三个带 install script 的包在 nix 构建里不跑脚本也能工作（本机实测 0.2.2-rc.5）：
#   - node-pty / koffi：平台原生库走预编译产物（node-pty 自带 prebuilds/，
#     koffi 走 @koromix/koffi-<平台> optionalDependencies），无需 cnoke/node-gyp；
#   - @deepseek-ai/dsh-subprocess-local：postinstall 幂等保护脚本，缺失不影响功能。
# nix 构建的 node 需要 shim（dsh-builtin-loader.cjs + wrapper 注入 --expose-internals）：
#   dsh 用原生插件扫描 node 二进制以访问 internal/modules/*，nixpkgs node（24/26 均验证）
#   编译 flags 不同导致指令模式匹配失败（"x64 sysv getter..."）。Node 官方
#   --expose-internals 提供同等能力且接口校验全过；该 flag 不允许进 NODE_OPTIONS，
#   因此由包内 wrapper 以命令行 flag 注入。
# 运行时需要 DEEPSEEK_API_KEY（机器上由 sops 管理，secrets/api_keys.yaml）。
{
  lib,
  stdenvNoCC,
  fetchurl,
  importNpmLock,
  buildNpmPackage,
  nodejs,
}: let
  version = "0.2.2-rc.5";
  # 上游 npm tarball 不带 package-lock.json：解包后注入本目录生成的 lock
  # （npm install --package-lock-only --omit=dev --ignore-scripts，含全平台 optional 依赖）
  published = stdenvNoCC.mkDerivation {
    pname = "dsh-npm-published";
    inherit version;
    src = fetchurl {
      url = "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-${version}.tgz";
      hash = "sha256-Z9paPEWPRs0njg7satDjpE6Z/RMIfG8RobNiJokApSw=";
    };
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a . $out/
      cp ${./package-lock.json} $out/package-lock.json
      runHook postInstall
    '';
  };
in
  buildNpmPackage {
    pname = "dsh";
    inherit version;
    nodejs = nodejs; # upstream engines: >=24.9.0

    src = published;

    # 依赖 hash 全部取自 package-lock.json 的 integrity 字段，无需 fetchNpmDeps hash
    npmDeps = importNpmLock {
      package = builtins.fromJSON (builtins.readFile ./package.json);
      packageLock = builtins.fromJSON (builtins.readFile ./package-lock.json);
    };
    npmConfigHook = importNpmLock.npmConfigHook;

    # 发布包无构建步骤；npmInstallHook 只做 npm ci --ignore-scripts + bin 链接
    dontNpmBuild = true;

    # 覆盖 npmInstallHook 生成的 bin：注入 require-shim + --expose-internals（见文件头注释）
    postFixup = ''
      mkdir -p $out/lib/node_modules/@deepseek-ai/dsh/bin
      install -m644 ${./dsh-builtin-loader.cjs} $out/lib/node_modules/@deepseek-ai/dsh/bin/dsh-builtin-loader.cjs
      for f in $out/bin/*; do
        [ -f "$f" ] || continue
        mv "$f" "$f.real"
        {
          echo '#! /bin/sh'
          echo "exec ${nodejs}/bin/node --require $out/lib/node_modules/@deepseek-ai/dsh/bin/dsh-builtin-loader.cjs --expose-internals $out/lib/node_modules/@deepseek-ai/dsh/lib/bin.js \"\$@\""
        } > "$f"
        chmod +x "$f"
      done
    '';

    meta = with lib; {
      description = "DeepSeek Harness (dsh): open-source agent harness, everything is a plugin";
      homepage = "https://github.com/deepseek-ai/deepseek-harness";
      license = licenses.mit;
      mainProgram = "dsh";
      platforms = platforms.linux;
    };
  }
