{ config, ... }: {
  xdg.configFile."wofi/style.css".text = ''
    window {
      background-color: #1a1a2e;
      border:           1px solid #313244;
      border-radius:    8px;
    }

    #input {
      background-color: #181825;
      color:            #cdd6f4;
      border:           none;
      border-radius:    6px;
      padding:          8px 12px;
      margin:           8px;
    }

    #inner-box {
      background-color: transparent;
    }

    #entry {
      padding:       4px 12px;
      border-radius: 4px;
    }

    #entry:selected {
      background-color: #313244;
    }

    #text {
      color: #cdd6f4;
    }

    #text:selected {
      color: #89b4fa;
    }
  '';
}
