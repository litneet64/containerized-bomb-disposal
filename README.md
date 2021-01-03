# Containerized Bomb Disposal

## Introduction

Set of dockerfiles meant for throw-away instances that achieve a singular purpose: to *"safely"* interact (run, play, unzip, etc) with programs or files without the need of a full VM to avoid compromise of the host machine.

 Think of it as a bomb disposal device for files you don't trust that much but still need to run, unzip, watch, open, play and so on.

## Index
1. [Motivation](##Motivation)
2. [Images](##Images)
   * [ZipperBox](###ZipperBox)

## Motivation

Example RCE, DirTrav CVEs like those from  `7zip` ([CVE-2016-2334](https://nvd.nist.gov/vuln/detail/CVE-2016-2334), [CVE-2018-10115](https://nvd.nist.gov/vuln/detail/CVE-2018-10115)), `gzip` ([CVE-2004-0603](https://nvd.nist.gov/vuln/detail/CVE-2004-0603), [CVE-2010-0001](https://nvd.nist.gov/vuln/detail/CVE-2010-0001)), `bzip2` ([CVE-2011-4089](https://nvd.nist.gov/vuln/detail/CVE-2011-4089)), `unrar` ([CVE-2017-14120](https://nvd.nist.gov/vuln/detail/CVE-2017-14120)), `vlc` ([CVE-2019-5439](https://nvd.nist.gov/vuln/detail/CVE-2019-5439)), `libreoffice` ([CVE-2018-16858](https://nvd.nist.gov/vuln/detail/CVE-2018-16858)) and others show that being always *"on-edge"* with the latest vulns and patches **while trying to get things done** is not always that simple, as other vulns like this could exist without the user's awareness at any given moment.

Besides possible unknown vulns and CVE's there's also the problem related to macros on *xlsx spreadsheets*, *docx documents*, etc. which are often passed around on e-mails (that could be work related), and we need to open them or execute those macros (for any given reason) but we just don't have the time for checks or giving it a second thought until it's already too late and it ends up blowing in our face.

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

Then running it as:

```bash
$ podman run -it --rm -v ./zips_tmp:/zip_data \
        --userns=auto:uidmapping=$UID:1000:1 \
          localhost/zipperbox {COMMAND YOU WANT TO RUN}
```
where `{COMMAND YOU WANT TO RUN}` can be empty (for a bash shell inside the container) or anything like `gzip -d my_files.gz`, `unar my_videos.zip`, `7z x other_files.7z`.
