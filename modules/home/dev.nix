{ config, pkgs, lib, ... }: {
  home.packages = with pkgs; [
    # api codegen
    openapi-generator-cli

    # github
    gh
    git-lfs

    # shell tools
    gnumake
    shellcheck
    shfmt
    hadolint
    yamllint
    pre-commit

    # data tools
    jq
    yq
    parallel
    dos2unix
    rename
    wdiff
    tree
    watch
    socat
    asciinema
    pv
    dust       # du replacement: visual, sorted tree of disk usage
    duf        # df replacement: colored, grouped filesystem overview
    tealdeer   # `tldr`: concise command examples

    # network tools
    nmap
    mtr
    dnsutils
    tcpflow
    tcpreplay

    # document tools
    pandoc
    tectonic
    plantuml

    # protobuf
    buf
    protobuf

    # java/jvm (the JDK itself comes from mise, below; these tools are wrapped
    # with their own nixpkgs JDK)
    maven
    scala
    sbt
    groovy

    # cloud
    awscli2
    azure-cli
    (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [
      gke-gcloud-auth-plugin
      package-go-module
      beta
      terraform-tools
      pubsub-emulator
    ]))
    ssm-session-manager-plugin

    # kubernetes
    (lib.hiPrio kubectl) # win over kubectl bundled by minikube
    kubectx
    k9s
    kubernetes-helm
    helm-docs
    kind
    minikube
    ko
    stern
    argocd
    grpcurl
    kubeconform

    # terraform
    terraform
    terraform-docs
    tflint

    # secrets
    vault
    sops
    age
    age-plugin-yubikey

    # linting
    golangci-lint
    eslint

    # C toolchain for cgo and native extensions; language runtimes come from
    # mise (below)
    gcc

    # docker tools
    oxker

    # database
    pgcli

    # ai cli tools
    claude-code
    antigravity-cli  # binary is `agy`; successor to the removed gemini-cli

    # git tools
    lazygit
    prek

    # misc
    lynx
    w3m
    postman
    keybase
    winbox
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Language runtimes. Projects pin their own versions (mise.toml,
  # .tool-versions, .nvmrc, .python-version) without needing Nix; these are
  # the global defaults. Install or update them with `mise install`.
  # Downloaded binaries run through nix-ld (modules/system/common.nix).
  programs.mise = {
    enable = true;
    globalConfig = {
      tools = {
        go     = "1.27";
        node   = "24";
        python = "3.14";
        ruby   = "3.4";
        deno   = "2";
        java   = "temurin-21";
      };
      # mise defaults to compiling every runtime from source on NixOS, where
      # downloaded binaries do not run without nix-ld. nix-ld is enabled here,
      # and source builds would need headers NixOS does not provide globally.
      settings.all_compile = false;
    };
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
      "--hidden"
      "--glob=!.git/*"
    ];
  };

  # GOPATH is Go's default ~/go; only its bin directory needs to be on PATH.
  #
  # mise shims serve everything that never runs `mise activate` (an
  # interactive-zsh prompt hook): scripts, `zsh -c`, ssh commands, and tools
  # started from a shell - Claude Code runs its hooks via /bin/sh and its MCP
  # servers via npx. The session vars are sourced from .zshenv and .zprofile,
  # so this reaches every zsh. GUI apps get the shims from sway (sway.nix).
  home.sessionPath = [
    "${config.home.homeDirectory}/go/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.xdg.dataHome}/mise/shims"
  ];
}
