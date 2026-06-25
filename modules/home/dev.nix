{ config, pkgs, ... }: {
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
    fzf
    parallel
    dos2unix
    rename
    wdiff
    diffutils
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

    # java/jvm
    jdk21
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
    kubectl
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

    # languages
    gcc
    go
    nodejs
    ruby
    deno
    python3

    # docker tools
    dive
    oxker

    # database
    pgcli

    # ai cli tools
    claude-code
    gemini-cli

    # git tools
    lazygit
    delta
    prek

    # file manager
    mc

    # misc
    lynx
    w3m
    wireshark
    postman
    keybase
    winbox
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
      "--hidden"
      "--glob=!.git/*"
    ];
  };

  home.sessionVariables.GOPATH = "${config.home.homeDirectory}/go";
  home.sessionPath = [
    "${config.home.homeDirectory}/go/bin"
    "${config.home.homeDirectory}/.local/bin"
  ];
}
