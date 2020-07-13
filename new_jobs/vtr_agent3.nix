{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_agent3 = vtr_agent3.summary;
    titan_agent3 = titan_agent3.summary;
}
