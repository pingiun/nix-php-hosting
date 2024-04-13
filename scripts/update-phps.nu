let repoRoot = (git rev-parse --show-toplevel)

print $"Will return to ($repoRoot)"

cd (mktemp -d)
print $env.PWD
git clone "https://github.com/fossar/nix-phps.git"
mkdir "$($repoRoot)/phps"
rsync --delete -r "nix-phps/pkgs/" $"($repoRoot)/packages/phps"
