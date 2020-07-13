{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_agent_2 = vtr_agent_2.summary;
    titan_agent_2 = titan_agent_2.summary;
}
