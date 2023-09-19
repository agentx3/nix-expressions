{ config, lib, pkgs, ... }:
with lib;
let

  cfg = config.programs.chatgpt;

in
{
  options = {
    programs.chatgpt = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable the ChatGPT";
      };
      package = mkOption {
        type = types.package;
        default = (pkgs.chatgpt cfg // { scriptName = cfg.scriptName; });
        defaultText = literalExpression "pkgs.chatgpt";
        description = lib.mdDoc "The ChatGPT package";
      };
      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [ pkgs.tmux ];
        description = lib.mdDoc
          "Extra packages to be installed for the program";
      };
      apiKeyFile = mkOption {
        type = types.path;
        description = lib.mdDoc
          "The path to the file containing the API key";
      };
      orgIdFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = lib.mdDoc "The path to the file containing the organization ID";
      };
      conversationsDir = mkOption {
        type = types.path;
        default = "${config.xdg.dataHome}/chatgpt/conversations";
        description = lib.mdDoc "The directory where the conversations are stored";
      };
      defaultPrompt = mkOption {
        type = types.str;
        default = "You are a very helpful Linux expert.";
        description = lib.mdDoc "The default prompt";
      };
      scriptName = mkOption {
        type = types.str;
        default = "chatgpt";
        description = lib.mdDoc "The name of the executable script";
      };
    };
  };
  config = (mkIf cfg.enable {
    home.packages = [ (cfg.package) ] ++ cfg.extraPackages;
    home.file."${config.xdg.configHome}/fish/completions/${cfg.scriptName}.fish" = mkIf config.programs.fish.enable {
      text = ''
        function __fish_${cfg.scriptName}_saved_chats
          set -l chats (ls -1 ${cfg.conversationsDir})
          for chat in $chats
            echo $chat
          end
        end
        complete -c ${cfg.scriptName} -a '( __fish_chatgpt_saved_chats )'
      '';
    };
  });
}

