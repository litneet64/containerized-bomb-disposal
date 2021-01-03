# Containerized Bomb Disposal

## Introduction

Set of dockerfiles meant for throw-away instances that achieve a singular purpose: to *"safely"* interact (run, play, unzip, etc) with programs or files without the need of a full VM to avoid compromise of the host machine.

 Think of it as a bomb disposal device for files you don't trust that much but still need to run, unzip, watch, open, play and so on.

## Index
1. [Motivation](#motivation)
2. [Security Caveats](#security-caveats)
3. [Security Recommendations](#security-recommendations)
4. [Images](#images)
   * [ZipperBox](#zipperbox)

## Motivation

Example RCE, DirTrav CVEs like those from  `7zip` ([CVE-2016-2334](https://nvd.nist.gov/vuln/detail/CVE-2016-2334), [CVE-2018-10115](https://nvd.nist.gov/vuln/detail/CVE-2018-10115)), `gzip` ([CVE-2004-0603](https://nvd.nist.gov/vuln/detail/CVE-2004-0603), [CVE-2010-0001](https://nvd.nist.gov/vuln/detail/CVE-2010-0001)), `bzip2` ([CVE-2011-4089](https://nvd.nist.gov/vuln/detail/CVE-2011-4089)), `unrar` ([CVE-2017-14120](https://nvd.nist.gov/vuln/detail/CVE-2017-14120)), `vlc` ([CVE-2019-5439](https://nvd.nist.gov/vuln/detail/CVE-2019-5439)), `libreoffice` ([CVE-2018-16858](https://nvd.nist.gov/vuln/detail/CVE-2018-16858)) and others show that being always *"on-edge"* with the latest vulns and patches **while trying to get things done** is not always that simple, as other vulns like this could exist without the user's awareness at any given moment.

Besides possible unknown vulns and CVE's there's also the problem related to macros on *xlsx spreadsheets*, *docx documents*, etc. which are often passed around on e-mails (that could be work related), and we need to open them or execute those macros (for any given reason) but we just don't have the time for checks or giving it a second thought until it's already too late and it ends up blowing in our face.

## Security Caveats

Note that just running these conainerized programs with `docker`, `podman`, `runc`, etc. is **not enough** to guarantee security for the host, as there are other issues that can undermine host security overall as seen on [this Black Hat presentation from 2019](https://i.blackhat.com/USA-19/Thursday/us-19-Edwards-Compendium-Of-Container-Escapes-up.pdf), which explains the different methods that were used before and the ones that can still be found nowadays.

Even if these containers possess their own `network`, `uts`, `cgroup` and `pid` *namespaces*, there's still some security problems that can arise from bad configurations: **too much privileges** (in the form of `capabilities`) for the container in the host namespace, mounting the all-too-sensible `proc/` dir inside the container, etc; **kernel vulns** (as the host and container share the same kernel) or even **container engine vulnerabilities** that arise every now and then, all of which enable some form of escape from the container to the host.

## Security Recommendations

As previously stated, containers alone **are not the panacea** for isolation and security, we need more tools to swim confidently in this *sea of interactions* with unknown files (the main purpose for this repo).

 My recommendations for achieving a higher level of isolation with the host:

* Enable creation of **user namespaces** for your containers
* Use rootless containers if possible
* Don't mount more volumes than necessary (at most the ones required for these images)
* Enable `cgroupsv2` for your linux distro (if you don't have it already)
* Use an up-to-date Linux Kernel

First and second point are the most valuable ones and are easily achievable by using `podman`, as it already supports *user namespaces* and can be run as an unprivileged user, then just adding the flag `--userns=auto` when using `podman run` enables creation of a new *user namespace* for that container instance, which provides us with even more isolation with the host as now the *UID* for the container process in the host will be >100000 (on a default *uid mapping*), which is very restricted (to the point it can't even act as the original unprivileged user that started the container instance).

More of this can be read on [this awesome Red Hat article](https://www.redhat.com/en/blog/understanding-root-inside-and-outside-container) about permissions and privileges, both inside and outside of containers that possess their own *user namespace* and containers using the *host namespace* (which is sadly the default on `podman`).


In this repo we'll assume `podman` is already installed.


## Images
### ZipperBox

Its main purpose is for decompressing/compressing files that sometimes require specific programs, like `unar` or `7za` for `.7z` *part files*, `lsar` for listing archives not yet *fully-downloaded* or just the plain old `gzip`. Most common compression algorithms/programs are included on this image:

* `p7zip`
* `7z`, `7za`, `7zr`
* `unzip`, `zip`
* `gzip`
* `lzip`
* `bzip2`
* `unar`
* `unrar`

#### Usage

We need to have our data that's going to be compressed/decompressed on a specific folder that contains those files only, we'll call it here as `zips_tmp/`.

For building:

```bash
$ podman build -t zipperbox -f zipper.Dockerfile .
```

Setting correct permissions for `zips_tmp/`:

```bash
$ podman unshare chown -R $UID:$UID zips_tmp/
```

Then running it as:

```bash
$ podman run -it --rm -v ./zips_tmp:/zip_data \
        --userns=auto:uidmapping=$UID:1000:1 \
          localhost/zipperbox {COMMAND YOU WANT TO RUN}
```
where `{COMMAND YOU WANT TO RUN}` can be empty (for a bash shell inside the container) or anything like `gzip -d my_files.gz`, `unar my_videos.zip`, `7z x other_files.7z`.
