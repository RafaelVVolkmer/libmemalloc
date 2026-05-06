<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Signature Guide

> [!NOTE]
> Reference specification:
>
> This signature guideline is based on the following provenance and
> signing mechanisms:
>
> - [Developer Certificate of Origin][dco-url]
> - [OpenPGP][openpgp-url]
> - [Cosign][cosign-url]
> - [Sigstore][sigstore-url]

---

## DCO Guide

DCO means Developer Certificate of Origin.

A DCO sign-off is a contributor certification attached to a commit message. It
states that the contributor has the right to submit the contribution under the
project license and understands that the contribution will be public.

The required trailer format is:

```text
Signed-off-by: Full Name <email@example.com>
```

For this repository, commits authored by the project maintainer should use:

```text
Signed-off-by: Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
```

### Add DCO sign-off

Add a sign-off automatically:

```sh
git commit -s -m "feat(scope): add short imperative summary"
```

Add a sign-off and sign the commit cryptographically:

```sh
git commit -s -S -m "fix(allocator): validate free list links"
```

Add a sign-off to the most recent commit:

```sh
git commit --amend -s --no-edit
```

Add sign-offs while replaying commits:

```sh
git rebase --signoff main
```

### DCO Policy

All non-merge commits submitted to protected branches should contain a valid
`Signed-off-by` trailer.

Recommended rules:

- every non-merge commit must contain `Signed-off-by`;
- the sign-off should use the contributor's real name and email;
- the sign-off email should match the Git author email when possible;
- commits without a valid sign-off should be amended before merge;
- maintainers should not add a sign-off for another contributor unless
  explicitly authorized.

---

## GPG / OpenPGP Guide

GPG/OpenPGP signing is used to cryptographically sign Git commits and tags.

DCO sign-off and GPG signing are different:

| Mechanism                    | Purpose                                                          |
| ---------------------------- | ---------------------------------------------------------------- |
| `Signed-off-by`              | Contributor certification and DCO intent.                        |
| GPG/OpenPGP commit signature | Verifies that a commit was signed by a trusted private key.      |
| GPG/OpenPGP tag signature    | Verifies that a release tag was signed by a trusted private key. |

### Configure Git identity

```sh
git config --global user.name "Rafael V. Volkmer"
git config --global user.email "rafael.v.volkmer@gmail.com"
```

### Generate or list keys

Generate a new key when needed:

```sh
gpg --full-generate-key
```

List available secret keys:

```sh
gpg --list-secret-keys --keyid-format=long
```

Export the public key:

```sh
gpg --armor --export <KEY_ID>
```

The exported public key can be added to GitHub or another forge so commit and
tag signatures can be verified.

### Configure Git signing

Configure the signing key globally:

```sh
git config --global user.signingkey <KEY_ID>
git config --global gpg.program gpg
git config --global commit.gpgSign true
git config --global tag.gpgSign true
```

Configure signing only for this repository:

```sh
git config user.signingkey <KEY_ID>
git config commit.gpgSign true
git config tag.gpgSign true
```

### Sign commits

Signed commit with DCO:

```sh
git commit -s -S -m "feat(scope): add short imperative summary"
```

Signed amend with DCO:

```sh
git commit --amend -s -S --no-edit
```

Verify the latest commit signature:

```sh
git log --show-signature -1
```

### Sign release tags

Create a signed release tag:

```sh
git tag -s v1.0.0 -m "libmemalloc v1.0.0"
```

Verify a signed tag:

```sh
git tag -v v1.0.0
```

Push the signed tag:

```sh
git push origin v1.0.0
```

Recommended rules:

- stable release tags must be signed;
- release candidate tags should be signed;
- release tags must not be moved after publication;
- publish a new version instead of rewriting an already published tag.

---

## Cosign / Sigstore Guide

Cosign is used to sign and verify release artifacts that are not Git commits
or Git tags.

Recommended artifacts to sign:

- release archives;
- binary archives;
- checksum files;
- SBOM files;
- provenance files;
- container images;
- in-toto attestations.

### Sign a release archive

Example artifact:

```text
dist/libmemalloc-v1.0.0.tar.gz
```

Create a keyless signature bundle:

```sh
cosign sign-blob \
    --yes \
    --bundle dist/libmemalloc-v1.0.0.tar.gz.cosign.bundle \
    dist/libmemalloc-v1.0.0.tar.gz
```

Verify the signed blob:

```sh
cosign verify-blob \
    --bundle dist/libmemalloc-v1.0.0.tar.gz.cosign.bundle \
    --certificate-identity-regexp "https://github.com/RafaelVVolkmer/libmemalloc/.github/workflows/.*" \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
    dist/libmemalloc-v1.0.0.tar.gz
```

### Sign a checksum file

Generate a checksum:

```sh
sha256sum dist/libmemalloc-v1.0.0.tar.gz \
    > dist/libmemalloc-v1.0.0.tar.gz.sha256
```

Sign the checksum file:

```sh
cosign sign-blob \
    --yes \
    --bundle dist/libmemalloc-v1.0.0.tar.gz.sha256.cosign.bundle \
    dist/libmemalloc-v1.0.0.tar.gz.sha256
```

### Sign a container image

Example image:

```text
ghcr.io/rafaelvvolkmer/libmemalloc:v1.0.0
```

Sign the image:

```sh
cosign sign --yes ghcr.io/rafaelvvolkmer/libmemalloc:v1.0.0
```

Verify the image:

```sh
cosign verify \
    --certificate-identity-regexp "https://github.com/RafaelVVolkmer/libmemalloc/.github/workflows/.*" \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
    ghcr.io/rafaelvvolkmer/libmemalloc:v1.0.0
```

### Attest an SBOM

Attach an SPDX SBOM as an attestation:

```sh
cosign attest \
    --yes \
    --predicate dist/sbom.spdx.json \
    --type spdx \
    ghcr.io/rafaelvvolkmer/libmemalloc:v1.0.0
```

Verify the SBOM attestation:

```sh
cosign verify-attestation \
    --type spdx \
    --certificate-identity-regexp "https://github.com/RafaelVVolkmer/libmemalloc/.github/workflows/.*" \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
    ghcr.io/rafaelvvolkmer/libmemalloc:v1.0.0
```

---

## Signature and Provenance Checklist

Before merging or releasing:

- [ ] every non-merge commit has a valid DCO `Signed-off-by`;
- [ ] trusted-branch commits are GPG/OpenPGP signed when required;
- [ ] release tags are GPG/OpenPGP signed;
- [ ] release tags use `vMAJOR.MINOR.PATCH`;
- [ ] release artifacts are generated from a signed tag;
- [ ] checksum files are generated for release artifacts;
- [ ] release artifacts are signed with Cosign when published;
- [ ] SBOM files are signed or attested when published;
- [ ] container images are signed with Cosign when published;
- [ ] verification commands are documented in release notes.

---

<!-- ======================================================================= -->
<!-- References                                                              -->
<!-- ======================================================================= -->

[dco-url]: https://developercertificate.org/
[openpgp-url]: https://www.openpgp.org/
[cosign-url]: https://docs.sigstore.dev/cosign/
[sigstore-url]: https://www.sigstore.dev/

<!-- EOF -->
