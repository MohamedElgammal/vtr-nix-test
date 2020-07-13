{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_agent2 = vtr_agent2.summary;
    titan_agent2 = titan_agent2.summary;
}
