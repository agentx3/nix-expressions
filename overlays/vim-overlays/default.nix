let
  vimOverlays = final: prev:
    let
      buildVimPluginFrom2Nix = final.vimUtils.buildVimPluginFrom2Nix;
      fetchFromGitHub = final.fetchFromGitHub;
    in
    {
      vimPlugins = prev.vimPlugins // {
        BetterLua-vim = buildVimPluginFrom2Nix {
          pname = "BetterLua.vim";
          version = "2020-08-14";
          src = fetchFromGitHub {
            owner = "euclidianAce";
            repo = "BetterLua.vim";
            rev = "d2d6c115575d09258a794a6f20ac60233eee59d5";
            sha256 = "1rvlx21kw8865dg6q97hx9i2s1n8mn1nyhn0m7dkx625pghsx3js";
          };
          meta.homepage = "https://github.com/euclidianAce/BetterLua.vim/";
        };

        black-nvim = buildVimPluginFrom2Nix {
          pname = "black-nvim";
          version = "2022-09-15";
          src = fetchFromGitHub {
            owner = "averms";
            repo = "black-nvim";
            rev = "8fb3efc562b67269e6f31f8653297f826534fa4b";
            sha256 = "022hjbh8szsr6ba6bz5zvss3p4k2aknkb7crp99mqr7q228xpdm5";
          };
          meta.homepage = "https://github.com/averms/black-nvim/";
        };

        hyprland-vim-syntax = buildVimPluginFrom2Nix {
          pname = "hyprland-vim-syntax";
          version = "2022-10-27";
          src = fetchFromGitHub {
            owner = "theRealCarneiro";
            repo = "hyprland-vim-syntax";
            rev = "254df6b476db5784bc6bfe3f612129b73dfc43b5";
            sha256 = "19splbhy3782nij2p8x5ajl9psvrn38ypr1xxj4hsy6rz9c4s7dk";
          };
          meta.homepage = "https://github.com/theRealCarneiro/hyprland-vim-syntax/";
        };


        coc-snippets = buildVimPluginFrom2Nix {
          pname = "coc-snippets";
          version = "2023-01-22";
          src = fetchFromGitHub {
            owner = "neoclide";
            repo = "coc-snippets";
            rev = "baace9714161d13afe335b0ad38eb0b939724c03";
            sha256 = "0q2lsy5j6wd52881bd0irixwid3jvykpn0syhlaqv5zm1x5xjv8s";
          };
          meta.homepage = "https://github.com/neoclide/coc-snippets/";
        };

        indent-blankline-nvim = buildVimPluginFrom2Nix {
          pname = "indent-blankline.nvim";
          version = "2023-02-20";
          src = fetchFromGitHub {
            owner = "lukas-reineke";
            repo = "indent-blankline.nvim";
            rev = "018bd04d80c9a73d399c1061fa0c3b14a7614399";
            sha256 = "1ncpar0n8702j5h4a2bv8zx9kcg7gwfhs52qqrcg1yfsgjzb86bl";
          };
          meta.homepage = "https://github.com/lukas-reineke/indent-blankline.nvim/";
        };

        mermaid-vim = buildVimPluginFrom2Nix {
          pname = "mermaid.vim";
          version = "2022-02-15";
          src = fetchFromGitHub {
            owner = "mracos";
            repo = "mermaid.vim";
            rev = "a8470711907d47624d6860a2bcbd0498a639deb6";
            sha256 = "1ksih50xlzqrp5vgx2ix8sa1qs4h087nsrpfymkg1hm6aq4aw6rd";
          };
          meta.homepage = "https://github.com/mracos/mermaid.vim/";
        };


        nvim-highlight-colors = buildVimPluginFrom2Nix {
          pname = "nvim-highlight-colors";
          version = "2023-04-15";
          src = fetchFromGitHub {
            owner = "brenoprata10";
            repo = "nvim-highlight-colors";
            rev = "8d7e7fe540b404ec06a248d6e5797eaf3362420c";
            sha256 = "1saabc855b0pqhfvhph9lgir090126f1nh4hpv57d44fn8n0cwgh";
          };
          meta.homepage = "https://github.com/brenoprata10/nvim-highlight-colors/";
        };

        nvim-ts-autotag = buildVimPluginFrom2Nix {
          pname = "nvim-ts-autotag";
          version = "2023-03-04";
          src = fetchFromGitHub {
            owner = "agentx3";
            repo = "nvim-ts-autotag";
            rev = "e636a4acf435b94c0ea3777d58923680cbb0a605";
            sha256 = "0xy4bqxxbjjqlwgx8mxmf7xnhsy95scrrh08azwkdim0n3crcdh1";
          };
          meta.homepage = "https://github.com/agentx3/nvim-ts-autotag/";
        };

        rigel = buildVimPluginFrom2Nix {
          pname = "rigel";
          version = "2021-10-04";
          src = fetchFromGitHub {
            owner = "Rigellute";
            repo = "rigel";
            rev = "87b7f563f3777cecec6881d804dd658dabaebcc9";
            sha256 = "1cf6rwkfglfsxw80lz7zchpb7s2gqf4siwm1ilzyx9cm5ry136jp";
          };
          meta.homepage = "https://github.com/Rigellute/rigel/";
        };

        semshi = buildVimPluginFrom2Nix {
          pname = "semshi";
          version = "2023-03-20";
          src = fetchFromGitHub {
            owner = "wookayin";
            repo = "semshi";
            rev = "8047086306b1951e741f519f53d293d8b4b37f1a";
            sha256 = "15dy8xafpcl1wxn7n8n9zdqkz9mi9i5vg29achqxw3jqqx3lhrd6";
          };
          patches = [
            (final.fetchpatch {
              url = "https://patch-diff.githubusercontent.com/raw/wookayin/semshi/pull/10.patch";
              sha256 = "sha256-G1geBakgtzzyBwoT5sdUDh8OqYdXK2Tnmfl17SNPEhw=";
            })
          ];
          meta.homepage = "https://github.com/wookayin/semshi/";
        };

        vim-nix = buildVimPluginFrom2Nix {
          pname = "vim-nix";
          version = "2023-08-17";
          src = fetchFromGitHub {
            owner = "agentx3";
            repo = "vim-nix";
            rev = "4c7f63458a34d22b38d523c6e77e62c778eff473";
            sha256 = "sha256-8bt3I8EBKB95uZrgeqfqAUTcEG77mPPfCM6d5HBVUVM=";
          };
          meta.homepage = "https://github.com/agentx3/vim-nix/";
        };

      };
    };
in
vimOverlays
