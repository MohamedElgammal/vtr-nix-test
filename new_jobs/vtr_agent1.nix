{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_agent_1 = vtr_agent_1.summary;
    titan_agent_1 = titan_agent_1.summary;
}
