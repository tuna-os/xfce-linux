# Image signing

XFCE Linux signs its OCI images with a cosign **key**, not keyless.

## Why a key

`bootc` verifies an image through [containers-policy(5)](https://github.com/containers/image/blob/main/docs/containers-policy.json.5.md).
Its `sigstoreSigned` requirement takes a public key on disk:

```json
{ "type": "sigstoreSigned", "keyPath": "/usr/share/pki/containers/xfce-linux.pub" }
```

There is no policy type that expresses a Fulcio certificate identity plus an
OIDC issuer, which is what a keyless signature is. So a keyless signature is
verifiable by a human running `cosign verify` and **not** by the thing that
actually consumes the image. That is why this repo moved off keyless.

`zirconium-dev/zirconium-hawaii` reached the same conclusion; its
`cosign.pub` and `/usr/share/pki/containers/` layout is what this follows.

## Setting the key up

One command, run by a maintainer with admin on the repository. It generates
the pair and uploads the private half straight to GitHub Actions secrets, so
the key never sits in a shell history or a file you have to remember to
delete:

```bash
cosign generate-key-pair github://tuna-os/xfce-linux
```

That writes `cosign.pub` into the working directory and sets two repository
secrets: `COSIGN_PRIVATE_KEY` and `COSIGN_PASSWORD`.

This repo's workflow reads `SIGNING_SECRET` and `SIGNING_SECRET_PASSWORD`
instead, so either rename the secrets after generating, or generate locally
and set them explicitly:

```bash
cosign generate-key-pair
gh secret set SIGNING_SECRET          -R tuna-os/xfce-linux < cosign.key
gh secret set SIGNING_SECRET_PASSWORD -R tuna-os/xfce-linux
rm -f cosign.key
git add cosign.pub && git commit -m "chore: add the image signing public key"
```

Commit `cosign.pub`. It is the public half; it is meant to be published.

## Until the key exists

The signing step is gated on `SIGNING_SECRET` being non-empty. Without it the
build still publishes, the sign step reports skipped, and the job logs

```
::warning::SIGNING_SECRET is not set — published an unsigned image.
```

so an unsigned publish is visible rather than silent.

## Still to do

Baking the public key and a `policy.json` into the image is a separate
change, because it cannot land before `cosign.pub` exists. It needs an
element along the lines of zirconium's `elements/zirconium/common.bst`:

- install `cosign.pub` to `/usr/share/pki/containers/xfce-linux.pub`
- ship `/etc/containers/policy.json` with a `sigstoreSigned` entry for
  `ghcr.io/tuna-os/xfce-linux` pointing at that `keyPath`
- add `/etc/containers/policy.json` to the element's `overlap-whitelist`,
  since the base layer ships one

Until that lands, images are signed but nothing on the installed system
enforces the signature.

## Verifying

```bash
cosign verify --key cosign.pub ghcr.io/tuna-os/xfce-linux:latest
```

## Live ISOs

ISO artifacts are still signed keyless by `build-iso.yml`, and that is fine:
they are verified by a person downloading a file, not by `bootc`. The
`--certificate-identity-regexp` instructions in README.md still apply to
them.
