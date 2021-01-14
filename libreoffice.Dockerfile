FROM debian:buster-slim

ARG USER_UID="1000"
ARG USER_GID="1000"
ARG USER_DIR=/office_data

EXPOSE 5900

RUN mkdir -p $USER_DIR \
    && groupadd -g $USER_UID officer \
    && useradd -m -s /bin/bash -u $USER_UID -g $USER_GID officer \
    && chown -R $USER_UID:$USER_GID $USER_DIR

RUN apt update && apt install -y x11vnc xvfb \
    libreoffice-calc libreoffice-writer libreoffice-impress \
    && apt clean

USER officer

WORKDIR $USER_DIR
RUN x11vnc -storepasswd
RUN echo "libreoffice" >> ~/.bashrc

# default resolution: based on HDV 1080i (4:3)
CMD ["1440x1080"]
ENTRYPOINT ["/usr/bin/x11vnc", "-usepw", "-xkb", "-capslock", "-create", "-geometry"]
