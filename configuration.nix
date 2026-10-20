{ config, pkgs, ... }:

let
  jdk = pkgs.jdk17;

  unstable = import (fetchTarball
    "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
      config.allowUnfree = true;
    };

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

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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


  # Install the "dev" outputs too (headers, .pc files, cmake configs)
  environment.extraOutputsToInstall = [ "dev" ];

  # Make sure these directories are linked into /run/current-system/sw
  environment.pathsToLink = [
    "/include"
    "/lib"
    "/lib/pkgconfig"
    "/share/pkgconfig"
  ];


   environment.systemPackages = with pkgs; [
     vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     wget
     neovim
     adwaita-icon-theme
     tmux		
     kitty
     rclone
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
     dunst
     libnotify
     zathura
     zathuraPkgs.zathura_core
     jq
     zellij

     # Flutter / Android dev begin.
     cmake
     ninja
     clang
     unstable.flutter
     androidComposition.androidsdk
     jdk
     gtk3
     libsecret
     libsysprof-capture
     sqlite
     pcre2
     curl
     curl.dev
     zlib
     zlib.dev
     openssl
     openssl.dev
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

	xdg.mime.defaultApplications = {
	  "text/html" = "qutebrowser.desktop";
	  "x-scheme-handler/http" = "qutebrowser.desktop";
	  "x-scheme-handler/https" = "qutebrowser.desktop";
	};
  # ---------------------------------------------------------------------------
  # nix-ld: run unpatched, prebuilt Linux binaries (npm/pip native modules,
  # Gradle-downloaded tools like aapt2, language servers, release tarballs...).
  # Libraries listed here are exposed via NIX_LD_LIBRARY_PATH to those binaries.
  # If a binary still fails, run `ldd ./binary` and add the missing library.
  # ---------------------------------------------------------------------------
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # --- Core C/C++ runtime ---
      stdenv.cc.cc.lib      # libstdc++, libgcc_s
      glibc
      libgcc
      libunwind
      libffi
      gmp
      icu
      ncurses
      readline

      # --- Compression ---
      zlib
      zstd
      bzip2
      xz
      lz4
      libarchive

      # --- Crypto / networking ---
      openssl
      curl
      libssh
      libssh2
      nss
      nspr
      krb5
      libsodium
      gnutls
      libidn2
      c-ares
      nghttp2

      # --- System / hardware ---
      systemd               # libudev, libsystemd
      util-linux            # libuuid, libblkid, libmount
      dbus
      libcap
      attr
      acl
      e2fsprogs
      elfutils              # libelf
      libusb1
      fuse
      fuse3
      pciutils
      libseccomp
      libpsl

      # --- Data formats / misc libs ---
      sqlite
      expat
      libxml2
      libxslt
      pcre2
      json-glib
      libyaml
      libsecret
      libnotify
      libappindicator-gtk3
      libdbusmenu-gtk3

      # --- GLib / GTK / desktop stack ---
      glib
      gtk3
      gtk2
      gdk-pixbuf
      pango
      cairo
      harfbuzz
      atk
      at-spi2-atk
      at-spi2-core
      fontconfig
      freetype
      cups
      libsysprof-capture

      # --- Graphics: OpenGL / Vulkan / Wayland ---
      libGL
      libglvnd
      mesa
      libgbm
      libdrm
      vulkan-loader
      wayland
      libxkbcommon
      libva
      libvdpau

      # --- X11 ---
      libx11
      libxext
      libxrender
      libxrandr
      libxi
      libxcursor
      libxfixes
      libxcomposite
      libxdamage
      libxtst
      libxscrnsaver
      libxinerama
      libxxf86vm
      libxmu
      libxt
      libxft
      libxcb
      libxkbfile
      libxshmfence
      libsm
      libice
      libxcb-util
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxcb-wm

      # --- Audio / media ---
      alsa-lib
      libpulseaudio
      pipewire
      libjack2
      ffmpeg
      libogg
      libvorbis
      flac
      libopus
      SDL2
      openal
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base

      # --- Images ---
      libpng
      libjpeg
      libtiff
      libwebp
      giflib

      # --- Java / Android tooling (Gradle-downloaded aapt2, emulator, etc.) ---
      jdk
    ];
  };

  # # Enable the OpenSSH daemon.
  # services.openssh.enable = true;


  programs.ssh.extraConfig = ''
   AddKeysToAgent yes
  '';


  # Habilitando o steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Optional: open ports for Steam Remote Play
    dedicatedServer.openFirewall = true; # Optional: open ports for source servers
  };

  # List services that you want to enable:


  #services.displayManager.sddm.wayland.enable = true;

  # configuration.nix
  services.gnome.gnome-keyring.enable = true;

  # Enabling dunst
  services.dbus.packages = [ pkgs.dunst ];

  services.xserver = {
   enable = true;
    windowManager.i3 = {
      enable = true;
    };
  };

  
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
  # hardware.graphics = {
  #   enable = true;
  #   enable32Bit = true; # Required for 32-bit games (Steam)
  # };

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

  initialScript = pkgs.writeText "mysql-init.sql" ''
    CREATE USER IF NOT EXISTS 'masterUnifrota'@'localhost' IDENTIFIED BY 'masterUnifrota';
    CREATE USER IF NOT EXISTS 'masterUnifrota'@'127.0.0.1' IDENTIFIED BY 'masterUnifrota';
    ALTER USER 'masterUnifrota'@'localhost' IDENTIFIED BY 'masterUnifrota';
    ALTER USER 'masterUnifrota'@'127.0.0.1' IDENTIFIED BY 'masterUnifrota';
    GRANT ALL PRIVILEGES ON Unifrota.* TO 'masterUnifrota'@'localhost';
    GRANT ALL PRIVILEGES ON Unifrota.* TO 'masterUnifrota'@'127.0.0.1';
    FLUSH PRIVILEGES;
  '';

  settings = {
    mysqld = {
      bind-address = "127.0.0.1";   # loopback only, not exposed on LAN
      port = 3306;
    };
  };
};

  # 4. Configure Nvidia settings
  # hardware.nvidia = {
  #
  #   # Modesetting is required for Wayland and most compositors
  #   modesetting.enable = true;
  #
  #   # Nvidia power management. Experimental, and can cause sleep/suspend issues.
  #   # Enable this only if you experience screen tearing or sleep issues.
  #   powerManagement.enable = false;
  #   # Fine-grained power management. Turns off GPU when not in use.
  #   # Only available on Turing or newer architectures (GTX 16xx / RTX 20xx and later).
  #   powerManagement.finegrained = false;
  #
  #   # Use the NVidia open source kernel module (not to be confused with nouveau)
  #   # Only available for Turing and newer architectures (Geforce RTX series / GTX 1650 and up)
  #   # Set to true if you have a modern card, otherwise false.
  #   open = true;
  #
  #   # Enable the Nvidia settings menu (nvidia-settings)
  #   nvidiaSettings = true;
  #
  #   # Select the appropriate driver version for your specific GPU.
  #   # Options: stable, beta, production, legacy_470, legacy_390, etc.
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };


}

