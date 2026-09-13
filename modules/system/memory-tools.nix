{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.scanmem ];

  security.wrappers.scanmem = {
    source = "${pkgs.scanmem}/bin/scanmem";
    capabilities = "cap_sys_ptrace+eip";
    # CAP_SYS_PTRACE bypasses yama ptrace_scope and can attach to root
    # processes, so only wheel may run it.
    owner = "root";
    group = "wheel";
    permissions = "u+rx,g+x";
  };
}
