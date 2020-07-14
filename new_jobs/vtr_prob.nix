{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_agent_prob = vtr_agent_prob.summary;
    titan_agent_prob = titan_agent_prob.summary;
}
