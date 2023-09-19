# The tasks module provides functionality that roughly corresponds to the Debian
# `tasksel` functionality [1]. The idea is to enable tasks in the top-level
# configuration and the imported modules can react to this choice.
#
# Note, whether a configuration is enabled may depend on a combination of tasks.
# For example, if the desktop task is enabled we may generate an xsession
# configuration, but only if the container task is disabled.
#
# [1] See https://wiki.debian.org/tasksel for a detailed description of tasks in
#     Debian.

{ config, lib, ... }:

let

  inherit (lib) mkEnableOption;

in
{
  options.systemType = {
    container = mkEnableOption "" // {
      description = ''
        Whether to enable the container task. Enable this if the configuration
        is deployed to a NixOS container.
      '';
    };

    desktop = mkEnableOption "" // {
      description = ''
        Whether to enable the desktop task. This will, for example, configure a
        graphical session and install various packages that are expected in a
        full workstation configuration.
      '';
    };

    dev = {
      python = mkEnableOption "Python development task";
      typescript = mkEnableOption "Typescript development task";
      javascript = mkEnableOption "Javascript development task";
    };

    docker = mkEnableOption "" // {
      description = ''
        Whether to enable the docker task. When enabled, this will install
        various tools that are useful for working with Docker images or
        interacting with the Docker daemon.
      '';
    };

    music = mkEnableOption "" // {
      description = ''
        Whether to enable the music task. When enabled this will ensure that
        various music related tools and applications are installed.
      '';
    };

    server = mkEnableOption "" // {
      description = ''
        Whether to enable the server task. Should be enabled when the
        configuration is deployed to a headless server.
      '';
    };
  };
  config = {
    systemType.container = lib.mkDefault false;
    systemType.desktop = lib.mkDefault false;
    systemType.dev.python = lib.mkDefault false;
    systemType.dev.typescript = lib.mkDefault false;
    systemType.dev.javascript = lib.mkDefault false;
    systemType.docker = lib.mkDefault false;
    systemType.music = lib.mkDefault false;
    systemType.server = lib.mkDefault false;
  };
}

