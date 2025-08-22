{ pkgs, config, lib, ... }:

let
  package = import ./package.nix { inherit pkgs; };
  description = "Telegram bot that allows you to download pdf, midi and mp3 from musescore.com";

  cfg = config.services.pythonTelegramBots.librescore-telegram-bot;
in
{
  options = {
    services.pythonTelegramBots.librescore-telegram-bot = {
      enable = lib.mkEnableOption description;

      configDir = lib.mkOption {
        type = lib.types.str;
        default = "/etc/pytelegrambots/librescore-telegram-bot";
        description = "Config directory of the bot.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."librescore-telegram-bot" = {
      inherit description;
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      preStart = "while ! ${pkgs.iputils}/bin/ping -c1 1.1.1.1; do sleep 1; done";

      serviceConfig = {
        Restart = "always";
      };

      script = ''
        set -a

        CONFIG=${cfg.configDir}/config
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
