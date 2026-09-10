# Zsh + Starship prompt + Fastfetch on terminal launch
{ config, pkgs, lib, ... }:
let
  theme = import ./theme.nix;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
      extended = true;
    };

    shellAliases = {
      ls = "eza --group-directories-first --icons";
      ll = "eza -la --git --icons --group-directories-first";
      lt = "eza --tree --level=2 --icons";
      cat = "bat --paging=never";
      cd = "z";
      rebuild = "sudo nixos-rebuild switch --flake ~/.dotfiles#blessed";
      rbuild = "sudo nixos-rebuild switch --flake ~/.dotfiles#blessed";
      rtest = "sudo nixos-rebuild test --flake ~/.dotfiles#blessed";
      update = "nix flake update --flake ~/.dotfiles";
      gc = "sudo nix-collect-garbage -d";
      ff = "fastfetch";
      ".." = "cd ..";
      "..." = "cd ../..";
    };

    initContent = ''
      # Show system info on every new interactive terminal
      if [[ -o interactive ]]; then
        fastfetch 2>/dev/null
      fi

      # opencode through v2rayN proxy when it's running (API endpoints
      # are blocked without it); direct connection otherwise.
      opencode() {
        if ss -tln 2>/dev/null | grep -q ':10808'; then
          HTTPS_PROXY=http://127.0.0.1:10808 \
          HTTP_PROXY=http://127.0.0.1:10808 \
          NO_PROXY=localhost,127.0.0.1 \
          command opencode "$@"
        else
          command opencode "$@"
        fi
      }

      # fast directory jumping
      eval "$(zoxide init zsh)"
      # fzf integration
      eval "$(fzf --zsh 2>/dev/null)"
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      format = lib.concatStrings [
        "$directory"
        "$git_branch"
        "$git_status"
        "$python"
        "$nix_shell"
        "$character"
      ];
      character = {
        success_symbol = "[→](${theme.purple})";
        error_symbol = "[→](${theme.red})";
      };
      directory = {
        style = "bold ${theme.mauve}";
        truncation_length = 3;
        truncate_to_repo = false;
        read_only = " ro";
        read_only_style = "${theme.red}";
      };
      git_branch = {
        symbol = " ";
        style = "${theme.blue}";
      };
      git_status = {
        style = "${theme.yellow}";
        conflicted = " !";
        ahead = " up";
        behind = " down";
        diverged = " div";
        modified = " ~";
        staged = " +";
        untracked = " ?";
      };
      nix_shell = {
        symbol = "❄ ";
        style = "${theme.blue}";
        format = "[$symbol$state]($style) ";
      };
      python = {
        symbol = " ";
        style = "${theme.yellow}";
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--color=bg+:${lib.strings.removePrefix "#" theme.surface}"
      "--color=bg:${lib.strings.removePrefix "#" theme.bg}"
      "--color=fg:${lib.strings.removePrefix "#" theme.text}"
      "--color=hl:${lib.strings.removePrefix "#" theme.purple}"
      "--color=hl+:${lib.strings.removePrefix "#" theme.purple}"
      "--color=info:${lib.strings.removePrefix "#" theme.subtext}"
      "--color=prompt:${lib.strings.removePrefix "#" theme.purple}"
      "--color=pointer:${lib.strings.removePrefix "#" theme.purple}"
      "--color=marker:${lib.strings.removePrefix "#" theme.green}"
    ];
  };
}
