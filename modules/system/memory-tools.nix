{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.scanmem ];

  security.wrappers.scanmem = {
    source = "${pkgs.scanmem}/bin/scanmem";
    capabilities = "cap_sys_ptrace+eip";
    owner = "root";
    group = "root";
    permissions = "u+rx,g+x,o+x";
  };
}
