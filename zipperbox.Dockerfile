FROM debian:buster-slim

ARG ZIP_UID="1000"
ARG ZIP_GID="1000"
ARG ZIP_DIR=/zip_data

RUN mkdir -p $ZIP_DIR \
    && groupadd -g $ZIP_UID zipper \
    && useradd -m -d $ZIP_DIR -s /bin/bash -u $ZIP_UID -g $ZIP_GID zipper

RUN apt update && apt install -y \
    file p7zip-full unzip zip lzip bzip2 tar gzip unar unrar-free

USER "zipper"

WORKDIR $ZIP_DIR
VOLUME ["$ZIP_DIR"]

CMD ["/bin/bash"]
