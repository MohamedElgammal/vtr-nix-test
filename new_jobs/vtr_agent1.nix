{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_agent1 = vtr_agent1.summary;
    titan_agent1 = titan_agent1.summary;
}