{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_agent_4 = vtr_agent_4.summary;
    titan_agent_4 = titan_agent_4.summary;
}
