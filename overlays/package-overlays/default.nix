final: prev: {
  chatgpt = { ... }@args: prev.callPackage ../../home/packages/chatgpt args;
  frankendrift = { ... }@args: prev.callPackage ../../packages/frankendrift args;
  mermaidcli = import ./mermaid.nix { pkgs = prev; };
}

