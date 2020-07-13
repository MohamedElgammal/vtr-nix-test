{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_agent_3 = vtr_agent_3.summary;
    titan_agent_3 = titan_agent_3.summary;
}
