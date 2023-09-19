# X3 Nix Expressions
These are a collection of some modules and packages that I use.
## Main Additions

The highlight of this collection is `x3framework.docker` related settings. My expressions add a `virtualisation.docker.networks`(waiting to get merged to upstream [nixpkgs PR #255035](https://github.com/NixOS/nixpkgs/pull/255035)) option that is wrapped with `x3framework.docker.networks` in order to create a declaratively created docker network.

`x3framework.docker.services` contains modules that create docker compose files and a helper command. Each service created via this method will be located on a network defined `x3framework.docker.network`. The containers and the network are controlled with systemd service units. This allows for some pretty powerful stuff, e.g. if you modify the docker network, it will spin down all connected containers, destroy the existing network, re-create it with the new configurations, and spin back up the containers on the new networks.

## Why
This shares a lot of capabilities with `virtualisation.oci-containers`, in fact, I would probably even recommend using that instead in most cases. I've decided to use this for certain applications rather than `virtualisation.oci-containers` mainly in order to:
 * Support my custom implementation of binding containers to a docker network. 
 * Enable the usage of compose files for applications that utilize a multi-container setup.

### Advantages
* Configuration files outside of the nix store
    * Although we all love the /nix/store, some applications and services need to mutate their files to operate correctly. The idiomatic solution would be to dive into the derivations for the original services and patch in the new config files, but that's simply not always an option based on the complexity of the derivation.
    * By trading off some immutability, we open up a much much larger swath of services that we can use through Docker, at least until a better nix expression is written for the desired service.
* File-based secrets
    * Not all NixOS services have the option to pass in secrets via file. With docker containers, we can always use the `env_file` option to pass in secrets (providing the underlying application supports it) and using system bind-mounts to pass in files.
* Control over ports
    * A lot of applications and services are bound to a specific port. Now with docker port bindings, we have applications on any port we want. Even better, they don't even need to even be bound to host!
* Helper scripts
    * A fish shell alias is created that wraps the `docker compose` command with the location of the application's compose file. This allows for easy controlling of entire compose projects.
    * If you want to setup aliases for a different shell, you can just set your shell aliases to be equal to `config.programs.fish.shellAliases`
* Control over docker networks
    * Hoping to get https://github.com/NixOS/nixpkgs/pull/255035 merged officially, then I'll remove it from this flake.

### Limitations
* Some applications require a multi-container setup. This introduces complexity in managing the compose file configuration.
    * Currently it suffices to simply extend the module options if needed
    * Maybe a new submodule type can be created to allow granular control over sibling containers
* Currently just compatible with docker, but podman substitutions can be explored.

## Additional Packages
todo: add descriptions
* `fblitz`
* `pycln`
* `frankendrift`
* `chatgpt` 
