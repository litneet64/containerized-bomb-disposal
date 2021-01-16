# Containerized Bomb Disposal

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/litneet64/zipperbox?label=zipperbox%20docker%20build) ![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/litneet64/officebox?label=officebox%20docker%20build) ![GitHub](https://img.shields.io/github/license/litneet64/containerized-bomb-disposal) ![GitHub top language](https://img.shields.io/github/languages/top/litneet64/containerized-bomb-disposal)

## Introduction

Set of dockerfiles meant for throw-away instances that achieve a singular purpose: to *"safely"* interact (run, play, unzip, etc) with programs or files without the need of a full VM to avoid compromise of the host machine.

 Think of it as a bomb disposal device for files you don't trust that much but still need to run, unzip, watch, open, play and so on.

## Index
1. [Motivation](#motivation)
2. [Security Caveats](#security-caveats)
3. [Security Recommendations](#security-recommendations)
4. [Before Starting](#before-starting)
5. [Images](#images)
   * [ZipperBox](#zipperbox)
   * [OfficeBox](#officebox)
6. [Common Problems](#common-problems)

## Motivation

Example RCE, DirTrav CVEs like those from  `7zip` ([CVE-2016-2334](https://nvd.nist.gov/vuln/detail/CVE-2016-2334), [CVE-2018-10115](https://nvd.nist.gov/vuln/detail/CVE-2018-10115)), `gzip` ([CVE-2004-0603](https://nvd.nist.gov/vuln/detail/CVE-2004-0603), [CVE-2010-0001](https://nvd.nist.gov/vuln/detail/CVE-2010-0001)), `bzip2` ([CVE-2011-4089](https://nvd.nist.gov/vuln/detail/CVE-2011-4089)), `unrar` ([CVE-2017-14120](https://nvd.nist.gov/vuln/detail/CVE-2017-14120)), `vlc` ([CVE-2019-5439](https://nvd.nist.gov/vuln/detail/CVE-2019-5439), [CVE-2020-13428](https://nvd.nist.gov/vuln/detail/CVE-2020-13428), [CVE-2020-26664](https://nvd.nist.gov/vuln/detail/CVE-2020-26664)), `libreoffice` ([CVE-2018-16858](https://nvd.nist.gov/vuln/detail/CVE-2018-16858)) and others show that being always *"on-edge"* with the latest vulns and patches **while trying to get things done** is not always that simple, as other vulns like this could exist without the user's awareness at any given moment.

Besides possible unknown vulns and CVE's there's also the problem related to macros on *xlsx spreadsheets*, *docx documents*, etc. which are often passed around on e-mails (that could be work related), and we need to open them or execute those macros (for any given reason) but we just don't have the time for checks or giving it a second thought until it's already too late and it ends up blowing in our face.

## Security Caveats

Note that just running these containerized programs with `docker`, `podman`, `runc`, etc. is **not enough** to guarantee security for the host, as there are other issues that can undermine host security overall as seen on [this Black Hat presentation from 2019](https://i.blackhat.com/USA-19/Thursday/us-19-Edwards-Compendium-Of-Container-Escapes-up.pdf), which explains the different methods that were used before and the ones that can still be found nowadays.

Even if these containers possess their own `network`, `mnt`, `uts`, `cgroup` and `pid` [*namespaces*](https://www.redhat.com/sysadmin/container-namespaces-nsenter), there's still some security problems that can arise from bad configurations: **too much privileges** (in the form of `capabilities`) for the container in the host namespace, **mounting the all-too-sensible** `proc/` dir inside the container, etc; **kernel vulns** (as the host and container share the same kernel) or even **container engine vulnerabilities** that arise every now and then, all of which enable some form of escape from the container to the host.

## Security Recommendations

As previously stated, containers alone **are not the panacea** for isolation and security, we need more tools to swim confidently in this *sea of interactions* with unknown files (the main purpose for this repo).

 My recommendations for achieving a higher level of isolation with the host:

* Enable creation of **user namespaces** for your containers
* Use **rootless containers** if possible
* Don't mount more volumes than necessary (at most the ones required for these images to work)
* Enable `cgroupsv2` for your linux distro (if you don't have it already)
* Use an up-to-date Linux Kernel

First and second point are the most valuable ones and are easily achievable by using `podman`, as it already supports *user namespaces* and can be run as an unprivileged user (straight out-of-the box), then just adding the flag `--userns=auto` when using `podman run` enables creation of a new *user namespace* for that container instance, which provides us with even more isolation with the host as now the *UID* for the container process in the host will be >100000 (on a default *uid mapping*), which is very restricted to the point it can't even act as the original unprivileged user that started the container instance (if the process could escape the container somehow).

More of this can be read on [this awesome Red Hat article](https://www.redhat.com/en/blog/understanding-root-inside-and-outside-container) about permissions and privileges, both inside and outside of containers that possess their own *user namespace* and containers using the *host namespace* (which is sadly the default on `podman` as of version `2.1.1`).


## Before Starting

In this repo we'll assume `podman` is already installed, but you can follow up with `docker` too as it supports *user namespaces* and works with the same flags. For instructions on running the Docker daemon as a rootless process you can [read the official documentation](https://docs.docker.com/engine/security/rootless/).

Note that every image here could have used the `COPY` command in the *Dockerfiles* but this makes it way too slow at build time (and massively increases overall image size) if your dirs contain files that are very big (as it could be for a movie or set of long videos). You're free to clone and modify these *Dockerfiles* but remember to use `COPY --chown=1000:1000` (matching the default *UID* used in these Dockerfiles) to set the required permissions for the files.



## Images
### ZipperBox ![](https://img.shields.io/docker/cloud/build/litneet64/zipperbox) ![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/litneet64/zipperbox) ![](https://img.shields.io/docker/cloud/automated/litneet64/zipperbox)

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

Setting correct permissions for `zips_tmp/`:

```bash
$ podman unshare chown -R 1000:1000 zips_tmp/
```

Then running it as:

```bash
$ podman run -it --rm -v ./zips_tmp:/zip_data \
        --userns=auto:uidmapping=$UID:1000:1 \
          litneet64/zipperbox {COMMAND YOU WANT TO RUN}
```
where `{COMMAND YOU WANT TO RUN}` can be empty (for a bash shell inside the container) or anything like `gzip -d my_files.gz`, `unar my_videos.zip`, `7z x other_files.7z`.

### OfficeBox ![](https://img.shields.io/docker/cloud/build/litneet64/officebox) ![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/litneet64/officebox) ![](https://img.shields.io/docker/cloud/automated/litneet64/officebox)

This box's main purpose is opening common Office files (`.xlsx`, `.docx`, `.pptx`, etc) so that  any existent macro can be "fired" without us having to worry about the effects of the code (or if it was actually malicious), as it will run inside our _sandbox_.

It **requires** that you have any VNC client, such as `vncviewer` and the likes.

#### Usage

Our office files should be on the dir `off_data/` for these examples.

Setting correct permissions for `off_data/`:

```bash
$ podman unshare chown -R 1000:1000 off_data/
```

Then running it as:

```bash
$ podman run -d --rm -v ./off_data:/office_data \
        --userns=auto:uidmapping=$UID:1000:1 \
        -p 127.0.0.1:5900:5900 \
          litneet64/officebox {GEOMETRY}
```

Where `{GEOMETRY}` represents the resolution for the VNC server (e.g: `1920x1080`), if left empty then the default resolution `1440x1080` (4:3 ratio) is used.

Finally, you can connect to and interact with it doing:

```bash
$ vncviewer localhost:5900
```

**NOTE**: You'll be asked for a password when connecting, this one is set up as `zipperpass` as default at build time.

## Common Problems

#### Permission denied inside container

If you stumble upon problems related to permissions in the mounted volumes, it could be that either you haven't *"chown-ed"* the mounted dir for that specific user inside the container:

* if you are using *user namespaces* then you'll need to set the correct permissions for **the user inside the container** (in our *Dockerfiles* it's `UID=1000`) for it to be able to make changes inside that dir

```bash
$ podman unshare chown -R 1000:1000 my_mounted_dir/
```

Or maybe it's **SELinux** (if you are using any RHEL-based distro), which means you should re-label the files in the mounted volume or add the `:Z` option as `-v host_dir/:/cont_dir:Z` at container creation (which basically does the same thing).

More info about these problems can be found [here](https://www.redhat.com/sysadmin/user-namespaces-selinux-rootless-containers).

#### Permission denied outside container (host)
*  After *"chown-ing"* all files inside a dir that was mounted inside the container, you'll notice the UID and GID for your files inside are > 100000 (the extra UIDs for your user):

```bash
$ id            # checking our current host-user privileges
uid=1000(my-user) gid=1000(my-user) groups=1000(my-user)
$ stat my_dir/   # checking dir permissions
  File: my_dir/
  Size: 4096      	Blocks: 8          IO Block: 4096   directory
Device: fe06h/65030d	Inode: 5242881     Links: 2
Access: (0755/drwxr-xr-x)  Uid: (100999/ UNKNOWN)   Gid: (100999/ UNKNOWN)
...             # trimmed output
```
* This can be easily reverted:

```bash
$ podman unshare chown -R 0:0 my_dir/
$ # UID=0 here means perms of the original (host) unprivileged user
$ stat my_dir/
File: my_dir/
Size: 4096      	Blocks: 8          IO Block: 4096   directory
Device: fe06h/65030d	Inode: 5242881     Links: 2
Access: (0755/drwxr-xr-x)  Uid: (1000/ my-user)   Gid: (1000/ my-user)
...
```
