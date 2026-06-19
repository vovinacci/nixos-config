{ pkgs, ... }: {
  # Modern TUI file manager (replaces mc). Rust, vi-keys, async preview, plugins.
  # Shell integration adds the `y` wrapper that cd's to yazi's last dir on quit.
  programs.yazi = {
    enable                = true;
    enableZshIntegration  = true;
    enableBashIntegration = true;

    # Plugins from nixpkgs (symlinked into ~/.config/yazi/plugins/). APIs below
    # verified against each plugin's main.lua/README for yazi 26.x.
    plugins = {
      inherit (pkgs.yaziPlugins)
        git              # git status signs in the file list (fetcher)
        full-border      # rounded full border UI
        smart-enter      # single key: enter dir OR open file
        jump-to-char     # vim f<char> jump
        smart-filter     # incremental filter + auto-enter
        chmod            # chmod selection without a shell
        mount            # disk/USB mount manager modal
        ouch             # archive preview + compress (zip/tar/7z/rar/zst...)
        diff             # diff hovered vs selected file
        lazygit          # open lazygit in the cwd
        mediainfo        # rich media metadata preview
        relative-motions # vim relative-number motions (5j etc.)
        glow             # pretty markdown preview
        yatline          # statusline/header framework (lualine-like)
        yatline-catppuccin # mocha theme for yatline
        bookmarks        # vim-like marks
        wl-clipboard;    # copy file to the Wayland clipboard
    };

    # ~/.config/yazi/yazi.toml — note yazi 26 renamed [manager] -> [mgr].
    settings = {
      mgr = {
        show_hidden    = true;
        sort_by        = "natural";
        sort_dir_first = true;
        linemode       = "size";
      };
      plugin = {
        # git status (yazi > 26.1.22 drops the old `id` field)
        prepend_fetchers = [
          { url = "*";  run = "git"; group = "git"; }
          { url = "*/"; run = "git"; group = "git"; }
        ];
        prepend_preloaders = [
          { mime = "{audio,video,image}/*"; run = "mediainfo"; }
        ];
        prepend_previewers = [
          { url = "*.md";                   run = "glow"; }
          { mime = "{audio,video,image}/*"; run = "mediainfo"; }
          { mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}"; run = "ouch"; }
        ];
      };
    };

    # ~/.config/yazi/keymap.toml
    #
    # Layout logic:
    #   * vim-natural actions stay as single keys (extend yazi's own defaults)
    #   * everything else lives under the "=" leader, which pops a which-key
    #     menu so the bindings are discoverable, not memorized
    #   * digits 1-9 are relative-motions (vim counts); switch tabs with [ ]
    keymap = {
      mgr.prepend_keymap = [
        # --- vim-natural singles -------------------------------------------
        { on = "l"; run = "plugin smart-enter";   desc = "Enter dir / open file"; }
        { on = "f"; run = "plugin smart-filter";  desc = "Filter (smart)"; }       # upgrades default f=filter
        { on = "F"; run = "plugin jump-to-char";  desc = "Jump to char"; }
        { on = "'"; run = "plugin bookmarks jump"; desc = "Jump to bookmark"; }     # vim '
        # --- "=" leader: extras / plugin actions ---------------------------
        { on = [ "=" "g" ]; run = "plugin lazygit";          desc = "Git (lazygit)"; }
        { on = [ "=" "c" ]; run = "plugin chmod";            desc = "Chmod selection"; }
        { on = [ "=" "d" ]; run = "plugin diff";             desc = "Diff hovered vs selected"; }
        { on = [ "=" "y" ]; run = "plugin wl-clipboard";     desc = "Yank file to clipboard"; }
        { on = [ "=" "a" ]; run = "plugin ouch";             desc = "Archive (compress)"; }
        { on = [ "=" "v" ]; run = "plugin mount";            desc = "Volumes (mount manager)"; }
        { on = [ "=" "m" ]; run = "plugin bookmarks save";   desc = "Mark (save bookmark)"; }
        { on = [ "=" "x" ]; run = "plugin bookmarks delete"; desc = "Delete bookmark"; }
      ] ++ map (n: {
        on   = toString n;
        run  = "plugin relative-motions ${toString n}";
        desc = "Relative motion ${toString n}";
      }) [ 1 2 3 4 5 6 7 8 9 ];
    };

    initLua = ''
      require("git"):setup { order = 1500 }
      require("full-border"):setup { type = ui.Border.ROUNDED }

      require("relative-motions"):setup {
        show_numbers = "relative_absolute",
        show_motion  = true,
      }

      require("bookmarks"):setup {
        last_directory = { enable = true, persist = false },
        persist        = "all",
        desc_format    = "full",
        file_pick_mode = "hover",
        notify         = { enable = true, timeout = 1 },
      }

      local catppuccin = require("yatline-catppuccin"):setup("mocha")
      require("yatline"):setup { theme = catppuccin }
    '';
  };

  # Runtime deps for the previewer/action plugins above.
  home.packages = with pkgs; [
    mediainfo     # mediainfo previewer
    glow          # markdown previewer
    ouch          # archive preview + compress
    wl-clipboard  # wl-clipboard plugin (Wayland)
  ];
}
