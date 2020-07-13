{ ... }: # ignore arguments

with import ../default.nix { pkgs = import <nixpkgs> {}; }; # import default.nix, passing in nixpkgs

# each attribute is a job
{
    vtr_merge_ = vtr_merge_.summary;
    titan_merge_ = titan_merge_.summary;
}
