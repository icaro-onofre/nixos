# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

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
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable networking
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

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
   programs.zsh.enable = true;
   environment.shells = with pkgs; [ zsh ];
   users.defaultUserShell = pkgs.zsh;

# Set X11/GTK cursor globally if needed
environment.variables = {
  XCURSOR_THEME = "Adwaita";
  XCURSOR_SIZE = "24";
};

   environment.systemPackages = with pkgs; [
     vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     wget
     neovim
     adwaita-icon-theme
     tmux		
     kitty
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
   ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
   programs.hyprland.enable = true;
   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  #services.displayManager.sddm.wayland.enable = true;

  system.stateVersion = "26.05"; # Did you read the comment?

  # HOME MANAGER CONFIG

home-manager.users."icaro" = { pkgs, ... }:
  let
    dotfiles = builtins.fetchGit {
      url = "https://github.com/icaro-onofre/dotfiles.git";
      ref = "master";
    };
  in
  {
    home.stateVersion = "26.05"; # match your system's release, don't just copy this

    home.file.".config" = {
      source = "${dotfiles}/config";
      recursive = true;
    };

    home.packages = with pkgs; [
      # user-specific packages here, as an alternative to environment.systemPackages
    ];

    programs.git = {
      enable = true;
      userName = "icaro";
      userEmail = "you@example.com";
    };
  };

  #NVIDIA CONFIG, disable if broken
    # 2. Enable OpenGL / Hardware Acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for 32-bit games (Steam)
  };

  # 3. Load Nvidia driver for Xorg and Wayland
  # services.xserver.videoDrivers = [ "nvidia" ];

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
  #   open = false;
  #
  #   # Enable the Nvidia settings menu (nvidia-settings)
  #   nvidiaSettings = true;
  #
  #   # Select the appropriate driver version for your specific GPU.
  #   # Options: stable, beta, production, legacy_470, legacy_390, etc.
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };

}
