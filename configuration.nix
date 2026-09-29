{ config, pkgs, ... }:

let
  jdk = pkgs.jdk17;

  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "34" "35" ];
    buildToolsVersions = [ "34.0.0" "35.0.0" ];
    cmakeVersions = [ "3.22.1" ];
    includeNDK = true;
    includeEmulator = true;
    includeSystemImages = false;
  };

  androidSdkRoot = "${androidComposition.androidsdk}/libexec/android-sdk";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      "${fetchTarball "https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz"}/nixos"
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."icaro" = {
    isNormalUser = true;
    description = "icaro";
    extraGroups = [ "networkmanager" "wheel" "kvm" "adbusers" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.android_sdk.accept_license = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
   programs.zsh.enable = true;
   environment.shells = with pkgs; [ zsh ];
   users.defaultUserShell = pkgs.zsh;

  # Session-wide variables (cursor + Flutter/Android toolchain)
  environment.variables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";

    JAVA_HOME = "${jdk}";
    ANDROID_HOME = androidSdkRoot;
    ANDROID_SDK_ROOT = androidSdkRoot;

    # so pkg-config can find gtk3, sqlite, libsecret, etc.
    PKG_CONFIG_PATH = "/run/current-system/sw/lib/pkgconfig:/run/current-system/sw/share/pkgconfig";

    # Use the Nix-provided aapt2 instead of the one Gradle downloads (won't run on NixOS)
    # GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdkRoot}/build-tools/34.0.0/aapt2";
  };

  # install the .pc files / headers (the "dev" outputs) into the system profile
  environment.extraOutputsToInstall = [ "dev" ];

   environment.systemPackages = with pkgs; [
     vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     wget
     neovim
     adwaita-icon-theme
     tmux		
     kitty
     nemo
     htop
     discord
     lazygit
     firefox
     qutebrowser
     lsd
     pet
     fzf
     zoxide
     rofi
     zsh
     stow
     git
     waybar
     pass
     pulseaudio
     ripgrep
     ncdu

     # Flutter / Android dev begin.
     cmake
     ninja
     clang
     flutter
     androidComposition.androidsdk
     jdk
     gtk3
     libsecret
     libsysprof-capture
     sqlite
     pcre2
     curl
     curl.dev
     vscodium
     # Flutter / Android end.

   ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
   programs.hyprland.enable = true;
   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };
  # Habilitando o steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Optional: open ports for Steam Remote Play
    dedicatedServer.openFirewall = true; # Optional: open ports for source servers
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  #services.displayManager.sddm.wayland.enable = true;

  # configuration.nix
  services.gnome.gnome-keyring.enable = true;
  
  # PAM integration so it auto-unlocks with your login password
  security.pam.services.login.enableGnomeKeyring = true;
  # or if you use a display manager, e.g.:
  security.pam.services.gdm.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  system.stateVersion = "26.05"; # Did you read the comment?

  # HOME MANAGER CONFIG

# home-manager.users."icaro" = { pkgs, ... }:
#   let
#     dotfiles = builtins.fetchGit {
#       url = "https://github.com/icaro-onofre/dotfiles.git";
#       ref = "master";
#     };
#   in
#   {
#     home.stateVersion = "26.05"; # match your system's release, don't just copy this
#
#     home.file.".config" = {
#       source = "${dotfiles}/config";
#       recursive = true;
#     };
#
#     home.packages = with pkgs; [
#       # user-specific packages here, as an alternative to environment.systemPackages
#     ];
#
#     programs.git = {
#       enable = true;
#       userName = "icaro";
#       userEmail = "icaro.onofre.s@gmail.com";
#     };
#   };

  #NVIDIA CONFIG, disable if broken
    # 2. Enable OpenGL / Hardware Acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for 32-bit games (Steam)
  };

  # 3. Load Nvidia driver for Xorg and Wayland
  # services.xserver.videoDrivers = [ "nvidia" ];
  services.mysql = {
  enable = true;
  package = pkgs.mariadb;

  ensureDatabases = [ "Unifrota" ];

  ensureUsers = [
    {
      name = "icaro";
      ensurePermissions = {
        "Unifrota.*" = "ALL PRIVILEGES";
      };
    }
    {
      name = "masterUnifrota";
      ensurePermissions = {
        "Unifrota.*" = "ALL PRIVILEGES";
        # or scope to specific tables/db as needed
      };
    }
  ];

  settings = {
    mysqld = {
      bind-address = "127.0.0.1";   # loopback only, not exposed on LAN
      port = 3306;
    };
  };
};

  # 4. Configure Nvidia settings
  hardware.nvidia = {

    # Modesetting is required for Wayland and most compositors
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend issues.
    # Enable this only if you experience screen tearing or sleep issues.
    powerManagement.enable = false;
    # Fine-grained power management. Turns off GPU when not in use.
    # Only available on Turing or newer architectures (GTX 16xx / RTX 20xx and later).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with nouveau)
    # Only available for Turing and newer architectures (Geforce RTX series / GTX 1650 and up)
    # Set to true if you have a modern card, otherwise false.
    open = true;

    # Enable the Nvidia settings menu (nvidia-settings)
    nvidiaSettings = true;

    # Select the appropriate driver version for your specific GPU.
    # Options: stable, beta, production, legacy_470, legacy_390, etc.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

}

