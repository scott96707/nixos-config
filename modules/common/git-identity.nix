# Git commit identity, shared by every host.
#
# This is plain data, not a NixOS module — import it and read the attrs:
#   let identity = import ../common/git-identity.nix; in identity.email
#
# It used to live in secrets/secrets.yaml behind sops. That was the wrong
# shape for it: the address below is GitHub's per-account noreply alias, so
# it is public by construction — it appears in every commit ever pushed.
# Encrypting it bought nothing and cost real capability, because a host
# could only commit if it could decrypt, which is why the dp21 and pi
# appliances had no git identity at all.
#
# The `28793087+` prefix is the GitHub account ID. That is what keeps commit
# attribution attached to the account even across a username change, so do
# not trim it to the bare `scott96707@users.noreply.github.com` form.
# Attribution is GitHub-only; commits pushed to a non-GitHub forge will show
# this as an unlinked address.
{
  name = "scott96707";
  email = "28793087+scott96707@users.noreply.github.com";
}
