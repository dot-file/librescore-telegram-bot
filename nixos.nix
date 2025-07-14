{ pkgs, config, lib, ... }:

let
  package = import ./package.nix { inherit pkgs; };
  description = "Telegram bot that allows you to download pdf, midi and mp3 from musescore.com";
  configPath = "/etc/pytelegrambots/librescore-telegram-bot/config";

  cfg = config.services.pythonTelegramBots.librescore-telegram-bot;
in
{
  options = {
    services.pythonTelegramBots.librescore-telegram-bot = {
      enable = lib.mkEnableOption description;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."librescore-telegram-bot" = {
      inherit description;
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Restart = "always";
      };

      script = ''
        set -a

        CONFIG=${configPath}
        if [ ! -f $CONFIG ]
        then
          echo "Config file at $CONFIG doesn't exist"
          exit 1
        fi

        export LIBRESCORE_BIN="${lib.getExe pkgs.dl-librescore}"

        . $CONFIG

        ${package}/bin/librescore-telegram-bot
      '';
    };
  };
}
