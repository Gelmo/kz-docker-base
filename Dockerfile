FROM joshhsoj1902/linuxgsm-docker:latest

WORKDIR /home/linuxgsm/linuxgsm

# Stop apt-get asking to get Dialog frontend
ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm
ENV LGSM_GAMESERVERNAME csgoserver
ENV LGSM_UPDATEINSTALLSKIP UPDATE
EXPOSE 27015/tcp
EXPOSE 27015/udp

USER root 

# Install dependencies and clean
RUN apt-get update && \
    apt-get install -y \
        sqlite \
        rsync \
        zlib1g:i386 \
        libc6-i386 \
        lib32stdc++6 \
		nano \
		vim \
    # Cleanup
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

COPY --from=joshhsoj1902/parse-env:1.0.3 /go/src/github.com/joshhsoj1902/parse-env/main /usr/bin/parse-env
COPY --from=hairyhenderson/gomplate:v3.1.0-alpine /bin/gomplate /usr/bin/gomplate

RUN find /home/linuxgsm/linuxgsm -type f -name "*.sh" -exec chmod u+x {} \; \
 && find /home/linuxgsm/linuxgsm -type f -name "*.py" -exec chmod u+x {} \; \
 && chmod u+x /home/linuxgsm/linuxgsm/lgsm/functions/README.md

ADD --chown=linuxgsm:linuxgsm common.cfg.tmpl ./lgsm/config-default/config-lgsm/
ADD --chown=linuxgsm:linuxgsm functions/* /home/linuxgsm/linuxgsm/lgsm/functions/
ADD --chown=linuxgsm:linuxgsm databases.cfg /home/linuxgsm/linuxgsm/
ADD --chown=linuxgsm:linuxgsm lgsm-gameserver.cfg /home/linuxgsm/linuxgsm/lgsm/config-lgsm/csgoserver/
ADD --chown=linuxgsm:linuxgsm totenfluch-mapchooser.zip /home/linuxgsm/linuxgsm/

USER linuxgsm

RUN parse-env --env "LGSM_" >> env.json
RUN rm -f INSTALLING.LOCK
RUN mkdir -p ~/linuxgsm/lgsm/config-lgsm/$LGSM_GAMESERVERNAME

RUN mkdir /home/linuxgsm/linuxgsm/log/ \
 && mkdir /home/linuxgsm/linuxgsm/log/script/ \
 && touch /home/linuxgsm/linuxgsm/log/script/lgsm-gameserver-script.log \
 && chmod +x /home/linuxgsm/linuxgsm/lgsm/functions/*.sh \
 &&./linuxgsm.sh csgoserver \
 && mv csgoserver lgsm-gameserver

RUN ./lgsm-gameserver auto-install

RUN echo "metamod" | ./lgsm-gameserver mi \
 && sleep 5s

RUN echo "sourcemod" | ./lgsm-gameserver mi \
 && sleep 5s

RUN mv -f databases.cfg /home/linuxgsm/linuxgsm/serverfiles/csgo/addons/sourcemod/configs/

RUN mkdir ~/downloads/ \
 && cd ~/downloads/ \
 && wget https://bitbucket.org/GameChaos/distbug/downloads/distbugfix-1.0.zip \
 && unzip distbug* \
 && rm -rf distbug* \
 && rsync -Pva /home/linuxgsm/downloads/ /home/linuxgsm/linuxgsm/serverfiles/csgo/ \
 && wget https://bitbucket.org/Sikarii/movementhud/downloads/MovementHUD-latest.smx \
 && mv /home/linuxgsm/downloads/MovementHUD-latest.smx /home/linuxgsm/linuxgsm/serverfiles/csgo/addons/sourcemod/plugins/ \
 && rm -rf ~/downloads/* \
 && mv /home/linuxgsm/linuxgsm/totenfluch-mapchooser.zip ~/downloads/ \
 && unzip totenfluch* \
 && rm -rf totenfluch* \
 && rsync -Pva /home/linuxgsm/downloads/ /home/linuxgsm/linuxgsm/serverfiles/csgo/addons/sourcemod/ \
 && rm -rf ~/downloads/ \
 && cd ~/linuxgsm/

CMD ["bash"]