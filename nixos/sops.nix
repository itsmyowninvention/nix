{
  inputs,
  self,
  config,
  lib,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # Only configure SSH key paths if the key exists (not in CI)
  sops.age.sshKeyPaths = lib.mkIf (lib.pathExists "/root/.ssh/id_ed25519") ["/root/.ssh/id_ed25519"];
  sops.secrets = {
    # 解密 Secure Boot 密钥
    sb_pk_key = {
      sopsFile = "${self}/shared/secrets/secureboot.yaml";
      owner = "root";
      mode = "0400";
    };
    sb_kek_key = {
      sopsFile = "${self}/shared/secrets/secureboot.yaml";
      owner = "root";
      mode = "0400";
    };
    sb_db_key = {
      sopsFile = "${self}/shared/secrets/secureboot.yaml";
      owner = "root";
      mode = "0400";
    };
  };

  # 组装lanzaboote的pkiBundle
  environment.etc = {
    # 映射私钥 (指向 sops 解密后的内存路径)
    "secureboot/keys/PK/PK.key".source = config.sops.secrets.sb_pk_key.path;
    "secureboot/keys/KEK/KEK.key".source = config.sops.secrets.sb_kek_key.path;
    "secureboot/keys/db/db.key".source = config.sops.secrets.sb_db_key.path;

    # 映射公钥/证书 (指向当前目录下的 keys 文件夹)
    "secureboot/keys/PK/PK.pem".source = ./secureboot/keys/PK/PK.pem;
    "secureboot/keys/KEK/KEK.pem".source = ./secureboot/keys/KEK/KEK.pem;
    "secureboot/keys/db/db.pem".source = ./secureboot/keys/db/db.pem;
    "secureboot/GUID".source = ./secureboot/GUID;
  };
}
