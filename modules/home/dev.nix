{ config, pkgs, pkgs-stable, ... }: {
  home.packages = [
    pkgs-stable.openapi-generator-cli
  ] ++ (with pkgs; [
    # github
    gh
    git-lfs

    # shell tools
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

    # network tools
    nmap
    mtr
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
    google-cloud-sdk
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

    # terraform
    terraform
    terraform-docs
    tflint

    # linting
    golangci-lint
    eslint

    # languages
    go
    nodejs
    ruby
    deno
    python3

    # docker tools
    dive
    lazydocker

    # database
    pgcli

    # ai cli tools
    claude-code
    gemini-cli

    # file manager
    mc

    # misc
    lynx
    w3m
    wireshark
    postman
    keybase
    winbox
  ]);

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
