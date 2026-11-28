// dsh nix-node shim: 让 node-addon-require-builtin 原生探针走 Node 官方 --expose-internals 通道。
// 背景：dsh 用原生插件对 node 二进制做指令模式扫描来访问内部模块（internal/modules/*），
// nixpkgs 构建的 node（24/26 均验证）编译 flags 不同导致启发式匹配失败
// （"x64 sysv getter is not a recognized this->field accessor"，getter_pattern: none）。
// Node 官方的 --expose-internals（wrapper 里以命令行 flag 注入，NODE_OPTIONS 不允许此 flag）
// 提供同样的内部模块访问能力，对象形状满足 dsh 的全部接口校验（本机 nix node 24.22.3 实测）。
// 仅拦截该探针模块的加载，其余行为不变。
"use strict";
const Module = require("module");
const origLoad = Module._load;
Module._load = function (request) {
  if (request === "node-addon-require-builtin") {
    return { requireBuiltin: (id) => require(id) };
  }
  return origLoad.apply(this, arguments);
};
