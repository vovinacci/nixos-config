{ pkgs, lib, ... }: {
  environment.systemPackages = with pkgs; [
    # api codegen
    openapi-generator-cli

    # github
    gh
    git-lfs

    # shell tools
    chezmoi    # dotfiles manager; source: ~/src/vovinacci/dotfiles
    gnumake
    shellcheck
    shfmt
    hadolint
    yamllint
    actionlint   # GitHub Actions workflows
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
    hexpatch   # TUI hex editor with disassembler and ELF/PE parsing

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

    # ai cli tools: from the nix-ai-tools flake, not nixpkgs, so they track
    # upstream releases instead of the 26.05 freeze (see flake.nix)
    ai-tools.claude-code
    ai-tools.codex
    ai-tools.cursor-agent
    ai-tools.gemini-cli
    # antigravity-cli is Google's agentic coding CLI (`agy`); separate tool
    # from gemini-cli (`gemini`), both still released upstream
    ai-tools.antigravity-cli

    # git tools
    lazygit
    prek

    # misc
    lynx
    w3m
    postman
    keybase
    winbox

    # language runtimes: mise, plus `usage`, which mise's generated shell
    # completions call at completion time. Projects pin their own versions
    # (mise.toml, .tool-versions, ...); downloaded runtimes run through nix-ld
    # (modules/system/common.nix). Global versions and the shims PATH entry
    # are user configuration (dotfiles).
    mise
    usage

    # neovim language servers; nvim-lspconfig finds them on PATH
    lua-language-server
    nil
    typescript-language-server
    vscode-langservers-extracted
    rust-analyzer
    gopls
    pyright
    jdt-language-server
    tree-sitter
  ];

  # Installs direnv with nix-direnv and the zsh hook.
  programs.direnv.enable = true;
}
