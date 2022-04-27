{
  description = "";
  # Our dependencies:
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # [preformance]
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  # What we are trying to build:
  outputs = { nixpkgs, home-manager, nur, ... }@inputs: {
    # to run:
    # sudo nixos-rebuild switch --flake .#
    nixosConfigurations = {
      # nixos is your hostname 
      nixos = nixpkgs.lib.nixosSystem {
	      system = "x86_64-linux";
	      modules = [
	        ({config, lib, pkgs, modulesPath, ...}:
	          {
	            # configuration goes here:

	            # [boot]
	            boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "ums_realtek" "usbhid" "sd_mod" "sr_mod" ];
	            boot.initrd.kernelModules = [ ];
	            boot.kernelModules = [ "kvm-intel" ];
	            boot.extraModulePackages = [ ];
	            
	            fileSystems."/" =
	              { device = "/dev/disk/by-uuid/baaff9b6-ee52-4758-be9a-5cdc5f698974";
	                fsType = "btrfs";
	                options = [ "subvol=nixos" ];
	              };
	            
	            swapDevices = [ ];
	            
	            hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
	            
	            boot = {
	              cleanTmpDir = true;
	              loader = {
	                grub = {
	                  enable = true;
	                  version = 2;
	                  device = "/dev/sda";
	                };
	              };
	              extraModprobeConfig = "options kvm_intel nested=1";
	            };
	            # Also known as Central Standard Time (CST). The largest City in North America (Mexico City) is CST.
	            time.timeZone = "America/Chicago";
	            i18n.defaultLocale = "en_US.UTF-8";
	            nix = {
	              extraOptions = "experimental-features = nix-command flakes";
	              package = pkgs.nixFlakes;
	            };
	            fileSystems."/media/sd" =
	              { device = "/dev/disk/by-uuid/97b81ce9-5e1d-476e-939d-a7f3446f0732";
	                fsType = "ext4";
	                options = ["nofail" "user" "defaults"];
	                # not owned as root?
	                # options = [ "GROUP=users" "MODE=0666" ];
	              };

	            # [desktop]
	            # when you define a user account. Don't forget to set a password with ‘passwd’.
	            users.users.green = {
	              isNormalUser = true;
	              # Enable ‘sudo’ for the user. It is called wheel since "you become
	              # the driver and take the wheel", a metaphor that has died out.
	              extraGroups = [ "wheel" "audio" "video" "users" "libvirtd"];
	              shell = pkgs.fish;
	              # home = "/media/sd";   
	            };
	            services.pipewire = {
	              enable = true;
	              pulse.enable = true;
	            };
	            # necessary to set to use pipewire
	            security.rtkit.enable = true;
	            hardware.pulseaudio.enable = false;
	            programs.sway.enable = true;
	            hardware.opengl.enable = true;
	            services = {
	              xserver = {
	                enable = true;
	                layout = "us";
	                displayManager.gdm.enable = true;
	                displayManager.gdm.wayland = false;
	                desktopManager.gnome.enable = true;
	              };
	              
	              dbus.packages = [ pkgs.dconf ];
	              udev.packages = [ pkgs.gnome3.gnome-settings-daemon ];
	            };
	            fonts.fonts = with pkgs; [
	              # mono fonts: every char is same width
	              fira-code
	              fira-code-symbols
	              ibm-plex
	              jetbrains-mono
	              julia-mono
	              roboto-mono
	              
	              # serif: tiny little strokes at the end
	              source-serif
	            ];

	            # [security]
	            services.clamav.daemon.enable = true;
	            services.clamav.updater.enable = true;
	            # required to run chromium
	            security.chromiumSuidSandbox.enable = true;
	            
	            # enable firejail
	            programs.firejail.enable = true;
	            
	            # create system-wide executables firefox and chromium
	            # that will wrap the real binaries so everything
	            # work out of the box.
	            programs.firejail.wrappedBinaries = {
	              # firefox = {
	              #   executable = "${pkgs.lib.getBin pkgs.firefox-wayland}/bin/firefox";
	              #   profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
	              # };
	              chromium = {
	      	        executable = "${pkgs.lib.getBin pkgs.chromium}/bin/chromium";
	      	        profile = "${pkgs.firejail}/etc/firejail/chromium.profile";
	              };
	            };
	            # network filtering:
	            services.opensnitch.enable = true;
	            # to check: systemctl --user status gpg-agent
	            programs.gnupg.agent.enable = true;
	            programs.gnupg.agent.pinentryFlavor = "tty";
	            networking.wireguard.enable = true;
	            services.mullvad-vpn.enable = true;
	            networking.iproute2.enable = true;
	            
	            # only for testing!
	            networking.firewall.enable = false;

	            # [networked services]
	            services.openssh = {
	              enable = true;
	              # enable forwarding graphics. This is useful for viewing images.
	              forwardX11 = true;
	            };
	            programs.mosh.enable = true;
	            services.deluge = {
	              enable = true;
	              openFirewall = true;
	              user = "green";
	              # maybe change this?
	              # dataDir = /home/green/Downloads;
	              web = {
	                enable = true;
	                openFirewall = true;
	                port = 8112;
	              };
	            };
	            # services.syncthing = {
	            #       # TODO: this could probably refactored to not be user specific
	            #       enable = true;
	            #       dataDir = "/home/green";
	            #       openDefaultPorts = true;
	            #       configDir = "/home/green/.config/syncthing";
	            #       user = "green";
	            #       group = "users";
	            #       guiAddress = "127.0.0.1:8384";
	            # };
	            
	            services.syncthing = {
	              enable = true;
	              dataDir = "/home/green";
	              openDefaultPorts = true;
	              configDir = "/home/green/.config/syncthing";
	              user = "green";
	              group = "users";
	              guiAddress = "127.0.0.1:8384";
	              overrideDevices = true;     # overrides any devices added or deleted through the WebUI
	              overrideFolders = true;     # overrides any folders added or deleted through the WebUI
	              devices = {
	                # my laptop
	                "debian" = { id = "6FXKI76-AITYOG7-ZLRBNWR-DIAE5US-YVEM7N4-MZOC46G-CJRSF3L-XV27AAX"; };
	              };
	              folders = {
	                "Code" = {        # Name of folder in Syncthing, also the folder ID
	                  path = "/home/green/Sync/Projects/";
	                  devices = [ "debian" ];
	                  ignorePerms = false;
	                };
	                "Music" = {
	                  path = "/home/green/Sync/Music/";
	                  devices = [ "debian" ];
	                  ignorePerms = false;
	                };
	                "Writing" = {
	                  path = "/home/green/Sync/Writing/";
	                  devices = [ "debian" ];
	                  ignorePerms = false;
	                };
	              };
	            };
	            

	            services.emacs.package = pkgs.emacsGit;
	            nixpkgs.overlays = [
	              (import (builtins.fetchGit {
	                url = "https://github.com/nix-community/emacs-overlay.git";
	                # ref = "master";
	                allRefs = true;
	                # 29.0.50. I think it is better to just pin it, since if you
	                # don't it always compiles from latest commit. Which takes a lot
	                # of time with little benefit.
	                rev = "43fadd1cc5db73a27c52ecbdaa1a7f45a50908fb"; # change the revision
	                # rev = "352fc739a1df259b1d2de6bc442465f344e44fec";
	              }))
	            ];
	            
	            environment.systemPackages = with pkgs; [
	              # Bleeding edge Emacs. I need it for editing, so I install it as root.
	              emacsGit
	            ];
	          }
	        )];
      };
      "isoimage" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
          ({config, lib, pkgs, modulesPath, ...}:
            {
              nix.extraOptions = "experimental-features = nix-command flakes";
              # nix.package = pkgs.nixUnstable; # If you're still on 21.11
              programs.fish.enable = true;
              users.defaultUserShell = pkgs.fish;
              programs.sway.enable = true;
              hardware.opengl.enable = true;
              networking.networkmanager.enable = true;
              networking.wireless.enable = false;
              services.openssh = {
	              enable = true;
	              # enable forwarding graphics. This is useful for viewing images.
	              forwardX11 = true;
	            };
	            programs.mosh.enable = true;
              time.timeZone = "America/Chicago";
              i18n.defaultLocale = "en_US.UTF-8";
              environment.systemPackages = with pkgs; [
                # Bleeding edge Emacs. I need it for editing, so I install it as root.
                emacs
                git
                chromium
                mpv
                wordnet
                ripgrep
                hunspell
                hunspellDicts.en_US  
              ];
            }
          )];
      };
    };
    # to run:
    # nix build .#homeConfigurations."green@nixos".activationPackage && result/activate
    homeConfigurations = {
      # user@hostname
      "green@nixos" = home-manager.lib.homeManagerConfiguration {
	      system = "x86_64-linux";
	      homeDirectory = "/home/green";
	      username = "green";
	      stateVersion = "21.11";
	      pkgs = import inputs.nixpkgs {
	        system = "x86_64-linux";
	      };
	      configuration = { config, lib, pkgs, ... }: {
	        # home manager configuration goes here:
	        programs.password-store = {
	          enable = true;
	          package = pkgs.pass.withExtensions (exts: [
	            # pkgs.pass-securid
	            exts.pass-otp
	            exts.pass-import
	          ]);
	          settings = {
	            PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
	          };
	        };
	        # retrieve mail
	        programs.mbsync.enable = true;
	        
	        # send out mail
	        programs.msmtp.enable = true;
	        
	        # index mail
	        programs.mu.enable = true;
	        
	        accounts.email = {
	          # ~/Mail
	          maildirBasePath = "Mail";
	          accounts = {
	            # I like cockli since it has IMAP and SMTP support and doesn't require phone verification.
	            cock = {
	              address = "AmaziahBender49964@cock.li";
	              imap.host = "mail.cock.li";
	              primary = true;
	              
	              # this is meant for the indexers configuration?
	              mu.enable = true;
	              
	              mbsync = {
	                enable = true;
	                create = "both";
	                patterns = [ 
	                  "*" 
	                ];
	              };
	              
	              msmtp.enable = true;
	              realName = "M Bender";
	              passwordCommand = "pass /Root/emails/AmaziahBender49964@cock.li";
	              smtp.host = "mail.cock.li";
	              userName = "AmaziahBender49964@cock.li";
	              signature = {
	                text = ''
	          '';
	                showSignature = "append";
	              };
	            };
	          };
	        };
	        programs.git = {
	          enable = true;
	          userName = "Wiktor Cooley";
	          userEmail = "swbvty@gmail.com";
	          aliases = {
	            st = "status";
	          };
	          extraConfig = {
	            http = { sslCAinfo = "/etc/ssl/certs/ca-certificates.crt"; };
	            push = { default = "matching"; };
	          };
	        };
	        programs.fish = {
	          enable = true;
	          shellAliases = {
	            # always keep your shell abbreviations one letter
	            l = "exa";
	            g = "git";
	            e = "emacsclient";
	            
	            # I alias them since I only remember the classic UNIX programs.
	            # Might not be best practice.
	            ls = "exa";
	            sed = "sd";
	            cat = "bat";
	            top = "htop";
	            diff = "delta";
	            du = "dust";
	            df = "duf";
	            tree = "broot";
	            find = "fd";
	            grep = "rg";
	            ack = "ag";
	          };
	          shellInit = ''
	  	  fish_add_path ~/Sync/Projects/new-nixos-configuration/bin/
	      '';
	        };
	        
	        programs.zoxide = {
	          enable = true;
	          enableFishIntegration = true;
	        };
	        programs.foot = {
	          enable = true;
	          server.enable = true;
	          settings = {
	            main = {
	              shell = "fish";
	              font = "IBM Plex Mono:size=15";
	            };
	            scrollback = {
	              lines = "50000";
	            };
	            colors = { 
	              foreground = "839496";
	              background = "002B36";
	              alpha = "0.9";
	              
	              # GNOME palette
	              regular0 = "171421";
	              regular1 = "C01C28";
	              regular2 = "26A269";
	              regular3 = "A2734C";
	              regular4 = "12488B";
	              regular5 = "A347BA";
	              regular6 = "2AA1B3";
	              regular7 = "D0CFCC";
	              bright0  = "5E5C64";
	              bright1  = "F66151";
	              bright2  = "33D17A";
	              bright3  = "E9AD0C";
	              bright4  = "2A7BDE";
	              bright5  = "C061CB";
	              bright6  = "33C7DE";
	              bright7  = "FFFFFF";
	            };
	          };
	        };
          programs.firefox = {
            enable = true;
            profiles.default = {
              id = 0;
              settings = {
                "extensions.autoDisableScopes" = 0;
                
                "browser.search.defaultenginename" = "Google";
                "browser.search.selectedEngine" = "Google";
                "browser.urlbar.placeholderName" = "Google";
                "browser.search.region" = "US";
                
                "browser.uidensity" = 1;
                "browser.search.openintab" = true;
                "xpinstall.signatures.required" = false;
                "extensions.update.enabled" = false;
                
                "browser.display.use_document_fonts" = true;
                "pdfjs.disabled" = true;
                "media.videocontrols.picture-in-picture.enabled" = true;
                
                "widget.non-native-theme.enabled" = false;
                
                # "browser.newtabpage.enabled" = false;
                # "browser.startup.homepage" = "about:blank";
                
                "browser.newtabpage.activity-stream.feeds.telemetry" = false;
                "browser.newtabpage.activity-stream.telemetry" = false;
                "browser.ping-centre.telemetry" = false;
                "toolkit.telemetry.archive.enabled" = false;
                "toolkit.telemetry.bhrPing.enabled" = false;
                "toolkit.telemetry.enabled" = false;
                "toolkit.telemetry.firstShutdownPing.enabled" = false;
                "toolkit.telemetry.hybridContent.enabled" = false;
                "toolkit.telemetry.newProfilePing.enabled" = false;
                "toolkit.telemetry.reportingpolicy.firstRun" = false;
                "toolkit.telemetry.shutdownPingSender.enabled" = false;
                "toolkit.telemetry.unified" = false;
                "toolkit.telemetry.updatePing.enabled" = false;
                
                "experiments.activeExperiment" = false;
                "experiments.enabled" = false;
                "experiments.supported" = false;
                "network.allow-experiments" = false;
              };
            };
            extensions =
              let
                nurpkgs = import nixpkgs { system = pkgs.system; overlays = [ nur.overlay ]; };
              in
                with nurpkgs.nur.repos.rycee.firefox-addons; [
                  ublock-origin
                  old-reddit-redirect
                  tridactyl
                ];
          };
          programs.chromium = {
            enable = true;
            extensions = [
              # 4chan X the most viewable way to browse 4chan
              "ohnjgmpcibpbafdlkimncjhflgedgpam"
              # Hacker news enhancement suite: slightly fixes that never updating orange website
              "bappiabcodbpphnojdiaddhnilfnjmpm"
              # reddit enhancement suite: works best with old.reddit
              "kbmfpngjjgdllneeigpgjifpgocmfgmb"
              # reddit redirect: go to the better version of reddit old.reddit
              "dneaehbmnbhcippjikoajpoabadpodje"
              # ublock origin: is faster on firefox but still really great
              "cjpalhdlnbpafiamejdnhcphjbkeiagm"
              # do not see cookie boxes ever again
              "fihnjjcciajhdojfnbdddfaoknhalnja"
              # darkreader: fix awful website design
              "eimadpbcbfnmbkopoojfekhnkhdbieeh"
            ];
          };
	        home.packages = with pkgs; [
	          mullvad-vpn
	          exa              # ls
	          sd               # sed
	          bat              # cat
	          htop             # top
	          delta            # diff
	          dust             # du
	          duf              # df
	          broot            # tree
	          fd               # find
	          ripgrep          # grep
	          silver-searcher  # ack
	          curlie           # curl
	          fasd             # cd TODO fix errors
	          tldr             # help
	          fzf              # completion
	          jq               # parse JSON
	          moreutils        # collection of useful utilities
	          wget             # web scraping
	          file             # information on files
	          lshw             # information on hardware
	          p7zip            # extractor
	          yt-dlp           # youtube downloader  
	          # Image viewer (it also can be used to set a desktop background)
	          feh
	          
	          # music and video player
	          mpv
	          vlc
	          
	          # music tagging
	          picard
	          
	          # book and article references I might use calibre since I have little
	          # need for citations.
	          zotero
	          
	          pandoc      # convert documents to any format
	          ffmpeg      # edit audio and video.
	          imagemagick # convert and edit images  
	          # basic english dictionary, also supports synonyms
	          wordnet
	          # spellchecker
	          hunspell
	          hunspellDicts.en_US  
	          # related to my website
	          hugo
	          stork
	          nodePackages.vercel
	          
	          # shell scripting
	          gnumake
	          shellcheck
	          
	          # lua scripting
	          lua5_3
	          lua53Packages.luacheck
	          lua53Packages.luasocket
	          # sumneko-lua-language-server
	          
	          # haskell development  
	          haskell-language-server
	          ghc
	          
	          # syntax highlighting (never tried this before)
	          tree-sitter
	        ];
	      };
      };
    };
  };
}
  
