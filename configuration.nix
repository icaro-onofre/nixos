{ config, pkgs, ... }:

let
  # ---------------------------------------------------------------------------
  # Pinned helpers
  # ---------------------------------------------------------------------------
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
  imports = [
    ./hardware-configuration.nix
    "${fetchTarball "https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz"}/nixos"
  ];

  system.stateVersion = "26.05"; # Did you read the comment?

  # ===========================================================================
  # Nix
  # ===========================================================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
  };

  # ===========================================================================
  # Boot
  # ===========================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ===========================================================================
  # Networking
  # ===========================================================================
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;

    # Deskflow server listens on 24800/tcp
    firewall.allowedTCPPorts = [ 24800 ];
  };

  # ===========================================================================
  # Locale & time
  # ===========================================================================
  time.timeZone = "America/Sao_Paulo";

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

  # ===========================================================================
  # Hardware
  # ===========================================================================
  # Many adapters (Intel, Broadcom, Realtek) need non-free firmware
  hardware.enableRedistributableFirmware = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true; # shows battery level of connected devices
  };

  services.udev.packages = [ pkgs.brightnessctl ];

  # ===========================================================================
  # Desktop: X11 (i3) + Wayland (Hyprland)
  # ===========================================================================
  services.xserver = {
    enable = true;
    windowManager.i3.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.libinput.touchpad.disableWhileTyping = false;

  # Hyprland from unstable: the InputCapture portal (needed by Deskflow as a
  # Wayland *server*) only exists in xdg-desktop-portal-hyprland >= 1.4.0,
  # and it needs a Hyprland new enough to speak the input-capture protocol.
  programs.hyprland = {
    enable = true;
    package = unstable.hyprland;
    portalPackage = unstable.xdg-desktop-portal-hyprland;
  };


  # Route InputCapture explicitly to the Hyprland portal backend
  xdg.portal.config.hyprland = {
    default = [ "hyprland" "gtk" ];
    "org.freedesktop.impl.portal.InputCapture" = [ "hyprland" ];
  };


  # Default browser
  xdg.mime.enable = true;
  xdg.mime.defaultApplications = {
    "text/html" = "org.qutebrowser.qutebrowser.desktop";
    "x-scheme-handler/http" = "org.qutebrowser.qutebrowser.desktop";
    "x-scheme-handler/https" = "org.qutebrowser.qutebrowser.desktop";
    "x-scheme-handler/about" = "org.qutebrowser.qutebrowser.desktop";
    "x-scheme-handler/unknown" = "org.qutebrowser.qutebrowser.desktop";
  };

  # Notifications
  services.dbus.packages = [ pkgs.dunst ];

  # ===========================================================================
  # Audio (PipeWire)
  # ===========================================================================
  services.pulseaudio.enable = false;
  security.rtkit.enable = true; # realtime priority for audio threads

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true; # lets Mixxx use the JACK API via PipeWire
  };

  # ===========================================================================
  # Users & shell
  # ===========================================================================
  users.users."icaro" = {
    isNormalUser = true;
    description = "icaro";
    extraGroups = [ "networkmanager" "wheel" "kvm" "adbusers" "video" ];
  };

  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];
  users.defaultUserShell = pkgs.zsh;

  # ===========================================================================
  # Security: keyring, GPG, SSH
  # ===========================================================================
  services.gnome.gnome-keyring.enable = true;

  services.flatpak.enable = true;

  # Auto-unlock the keyring with the login password
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.gdm.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.ssh.extraConfig = ''
    AddKeysToAgent yes
  '';

  # ===========================================================================
  # Keyboard remapping (keyd)
  # ===========================================================================

services.keyd = {
  enable = true;
  keyboards.default = {
    ids = [ "*" ];
    settings = {
      main = {
        # Caps: tap = Esc, hold = "capsmeta" layer (behaves as Meta for everything else)
        capslock = "overload(capsmeta, esc)";
        # Space: tap = space, hold (100ms) = spacenav layer
        space = "overloadt2(spacenav, space, 200)";
      };

      # Caps held: acts as Meta, except Space → Enter
      # "capsmeta:M" = {
      #   space = "enter";
      # };

      # # Real Meta+Space → Menu (compose) → layout toggle
      # meta = {
      #   space = "compose";
      # };

      # Space held
      spacenav = {
        q = "S-grave"; # ~
        i = "backspace";
	w = "C-backspace";
      };
    };
  };
};


# Optional: same layouts on the TTY
console.useXkbConfig = true;
  # Group keyd expects, and let the daemon set the group on its socket
  # (the NixOS unit drops this capability)
  users.groups.keyd = { };
  systemd.services.keyd.serviceConfig.CapabilityBoundingSet = [ "CAP_SETGID" ];

  # ===========================================================================
  # Programs
  # ===========================================================================
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # ===========================================================================
  # System packages
  # ===========================================================================
  environment.systemPackages = with pkgs; [
    # --- Editors ---
    vim
    neovim

    # --- Terminal & shell tools ---
    kitty
    tmux
    zellij
    fzf
    zoxide
    lsd
    ripgrep
    jq
    htop
    ncdu
    pet
    stow
    wget
    hyprpaper

    # --- Dev ---
    git
    lazygit
    claude-code

    # --- Desktop / WM ---
    waybar
    rofi
    dunst
    libnotify
    nemo
    adwaita-icon-theme
    brightnessctl
    keyd
    lan-mouse

    # --- Apps ---
    firefox
    qutebrowser
    discord
    zathura
    zathuraPkgs.zathura_core

    # --- Audio CLI (pactl etc.) ---
    pulseaudio

    # --- Security / sync ---
    pass
    age
    rclone
  ];

  fonts.packages = with pkgs; [
   noto-fonts
   liberation_ttf
   vivaldi
   nerd-fonts.fira-code
  ];

  # ===========================================================================
  # Environment variables
  # ===========================================================================
  environment.sessionVariables.BROWSER = "qutebrowser";

  environment.variables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";

    # Flutter / Android toolchain
    JAVA_HOME = "${jdk}";
    ANDROID_HOME = androidSdkRoot;
    ANDROID_SDK_ROOT = androidSdkRoot;

    # So pkg-config can find gtk3, sqlite, libsecret, etc.
    PKG_CONFIG_PATH = "/run/current-system/sw/lib/pkgconfig:/run/current-system/sw/share/pkgconfig";

    # Use the Nix-provided aapt2 instead of the one Gradle downloads (won't run on NixOS)
    # GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdkRoot}/build-tools/34.0.0/aapt2";
  };

  # Install "dev" outputs too (headers, .pc files, cmake configs)
  environment.extraOutputsToInstall = [ "dev" ];

  environment.pathsToLink = [
    "/include"
    "/lib"
    "/lib/pkgconfig"
    "/share/pkgconfig"
  ];

  # ===========================================================================
  # nix-ld: run unpatched, prebuilt Linux binaries (npm/pip native modules,
  # Gradle-downloaded tools like aapt2, language servers, release tarballs...).
  # If a binary still fails, run `ldd ./binary` and add the missing library.
  # ===========================================================================
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # --- Core C/C++ runtime ---
      stdenv.cc.cc.lib
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
      systemd
      util-linux
      dbus
      libcap
      attr
      acl
      e2fsprogs
      elfutils
      libusb1
      fuse
      fuse3
      pciutils
      libseccomp
      libpsl

      # --- Data formats / misc ---
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

      # --- Java / Android tooling ---
      jdk
    ];
  };

  # ===========================================================================
  # Services: databases
  # ===========================================================================
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;

    ensureDatabases = [ "Unifrota" ];

    ensureUsers = [
      {
        name = "icaro";
        ensurePermissions."Unifrota.*" = "ALL PRIVILEGES";
      }
      {
        name = "masterUnifrota";
        ensurePermissions."Unifrota.*" = "ALL PRIVILEGES";
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

    settings.mysqld = {
      bind-address = "127.0.0.1"; # loopback only, not exposed on LAN
      port = 3306;
    };
  };

  # services.openssh.enable = true;

  # ===========================================================================
  # NVIDIA (disabled — uncomment if needed)
  # ===========================================================================
  # hardware.graphics = {
  #   enable = true;
  #   enable32Bit = true; # Required for 32-bit games (Steam)
  # };
  #
  # services.xserver.videoDrivers = [ "nvidia" ];
  #
  # hardware.nvidia = {
  #   modesetting.enable = true;          # required for Wayland
  #   powerManagement.enable = false;     # experimental; can break suspend
  #   powerManagement.finegrained = false; # Turing+ only
  #   open = true;                        # open kernel module (RTX / GTX 1650+)
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };

  # ===========================================================================
  # Home Manager (disabled — uncomment to use)
  # ===========================================================================
  # home-manager.users."icaro" = { pkgs, ... }:
  #   let
  #     dotfiles = builtins.fetchGit {
  #       url = "https://github.com/icaro-onofre/dotfiles.git";
  #       ref = "master";
  #     };
  #   in
  #   {
  #     home.stateVersion = "26.05";
  #
  #     home.file.".config" = {
  #       source = "${dotfiles}/config";
  #       recursive = true;
  #     };
  #
  #     home.packages = with pkgs; [ ];
  #
  #     programs.git = {
  #       enable = true;
  #       userName = "icaro";
  #       userEmail = "icaro.onofre.s@gmail.com";
  #     };
  #   };
}

