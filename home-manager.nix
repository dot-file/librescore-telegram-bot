{ pkgs, config, lib, ... }:

let
  package = import ./package.nix { inherit pkgs; };
  description = "Telegram bot that allows you to download pdf, midi and mp3 from musescore.com";
  configPath = "~/.config/pytelegrambots/librescore-telegram-bot/config";
  wrapper = pkgs.writeShellScriptBin "librescore-telegram-bot-wrapper" ''
    set -a

    CONFIG=${configPath}
    if [ ! -f $CONFIG ]
    then
      echo "Config file at $CONFIG doesn't exist"
      exit 1
    fi

    . $CONFIG

    ${package}/bin/librescore-telegram-bot
  '';

  cfg = config.services.pythonTelegramBots.librescore-telegram-bot;
in
{
  options = {
    services.pythonTelegramBots.librescore-telegram-bot = {
      enable = lib.mkEnableOption description;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services."librescore-telegram-bot" = {
      Unit = {
        Description = description;
        After = "default.target";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
      
      Service = {
        Restart = "always";
        RestartSec = 5;
        ExecStart = "${wrapper}/bin/librescore-telegram-bot-wrapper";
      };
    };
  };
}
