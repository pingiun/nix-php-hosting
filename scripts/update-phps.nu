let repoRoot = (git rev-parse --show-toplevel)

print $"Will return to ($repoRoot)"

cd (mktemp -d)
print $env.PWD
