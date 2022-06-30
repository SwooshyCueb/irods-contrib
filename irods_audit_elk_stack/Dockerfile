#
# Build Audit Stack for iRODS Monitoring via Audit Plugin
#
# Used in iRODS Training
#
FROM ubuntu:20.04

SHELL [ "/bin/bash", "-c" ]
ENV DEBIAN_FRONTEND=noninteractive

# Make sure we're starting with an up-to-date image
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*
# To mark all installed packages as manually installed:
#apt-mark showauto | xargs -r apt-mark manual

RUN mkdir -p /var/lib/irods-elk/versions
WORKDIR /var/lib/irods-elk

RUN apt-get update && \
    apt-get install -y \
        apt-transport-https \
        gnupg \
        curl \
        jq \
    && \
    apt-get install --no-install-recommends -y \
        systemd \
        systemd-sysv \
        dbus \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ADD https://packages.adoptium.net/artifactory/api/gpg/key/public /usr/share/keyrings/adoptium.asc
ADD https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public /usr/share/keyrings/adoptopenjdk.asc
RUN gpg --dearmor -o /usr/share/keyrings/adoptium.gpg /usr/share/keyrings/adoptium.asc && \
    gpg --dearmor -o /usr/share/keyrings/adoptopenjdk.gpg /usr/share/keyrings/adoptopenjdk.asc && \
    echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
    echo "deb [signed-by=/usr/share/keyrings/adoptopenjdk.gpg] https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptopenjdk.list && \
    apt-get update && \
    apt-get install -y \
        adoptium-ca-certificates \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

#ARG java_ver=8
#ARG java_ver=11
#ARG java_vendor=adoptopenjdk
#ARG java_dist=hotspot-jre
ARG java_ver=17
ARG java_vendor=temurin
ARG java_dist=jdk

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        ${java_vendor}-${java_ver}-${java_dist} \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*
ENV JAVA_HOME=/usr/lib/jvm/${java_vendor}-${java_ver}-${java_dist}-amd64
RUN update-java-alternatives --set ${JAVA_HOME}
RUN awk -F='' '/^FULL_VERSION/{print$2}' "${JAVA_HOME}/release" | tr -d '"' > versions/jvm
ENV ES_JAVA_HOME=${JAVA_HOME}
ENV LS_JAVA_HOME=${JAVA_HOME}

#ARG es_ver=6
#ARG es_ver=7
ARG es_ver=8
ADD https://artifacts.elastic.co/GPG-KEY-elasticsearch /usr/share/keyrings/elasticsearch-keyring.asc
RUN gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg /usr/share/keyrings/elasticsearch-keyring.asc && \
    echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/${es_ver}.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-${es_ver}.x.list && \
    echo 'path-exclude=/usr/share/elasticsearch/jdk' >> /etc/dpkg/dpkg.cfg.d/excludes-elasticsearch-jvm && \
    echo 'path-exclude=/usr/share/elasticsearch/jdk/*' >> /etc/dpkg/dpkg.cfg.d/excludes-elasticsearch-jvm && \
    echo 'path-exclude=/usr/share/logstash/jdk' >> /etc/dpkg/dpkg.cfg.d/excludes-elasticsearch-jvm && \
    echo 'path-exclude=/usr/share/logstash/jdk/*' >> /etc/dpkg/dpkg.cfg.d/excludes-elasticsearch-jvm

RUN apt-get update && \
    apt-get install -y \
        elasticsearch \
        logstash \
        kibana \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# TODO: dpkg hook to re-do links when package updated
RUN ln -sfT "${ES_JAVA_HOME}" /usr/share/elasticsearch/jdk && \
    ln -sfT "${LS_JAVA_HOME}" /usr/share/logstash/jdk && \
    echo "ES_JAVA_HOME=\"${ES_JAVA_HOME}\"" >> /etc/default/elasticsearch && \
    echo "LS_JAVA_HOME=\"${LS_JAVA_HOME}\"" >> /etc/default/logstash

RUN echo "/usr/share/elasticsearch/lib/elasticsearch-${es_ver}."*".jar" | grep -o '[0-9][0-9\.]\+[0-9]' > versions/elasticsearch && \
    /usr/share/logstash/bin/logstash --version | grep -o '[0-9][0-9\.]\+[0-9]' > versions/logstash && \
    /usr/share/kibana/bin/kibana --allow-root --version > versions/kibana

ARG activemq_ver=5.17
# Fetch latest dotrelease version number
RUN curl -sL "https://api.github.com/repos/apache/activemq/git/matching-refs/tags/activemq-${activemq_ver}." | jq .[-1].ref | grep -o '[0-9][0-9\.]\+[0-9]' > versions/activemq
RUN mkdir /opt/activemq && \
    curl -sL -o /tmp/apache-activemq.tar.gz "https://archive.apache.org/dist/activemq/$(<versions/activemq)/apache-activemq-$(<versions/activemq)-bin.tar.gz" && \
    tar -xf /tmp/apache-activemq.tar.gz --strip-components=1 --directory=/opt/activemq && \
    rm -rf /opt/activemq/bin/{linux-x86-32,macosx} /tmp/apache-activemq.tar.gz && \
    mkdir -p /var/lib/activemq/data && \
    cp -R /opt/activemq/conf /var/lib/activemq/ && \
    addgroup --system activemq && \
    adduser --system --no-create-home --ingroup activemq --home /var/lib/activemq --shell /bin/bash activemq && \
    chown -R activemq:root /var/lib/activemq && \
    chmod 755 /var/lib/activemq && \
    cp /opt/activemq/bin/env /etc/default/activemq && \
    sed -i '~s/^ACTIVEMQ\_USER=""/ACTIVEMQ\_USER="activemq"/;/^JAVACMD=.*/d' /etc/default/activemq && \
    echo 'ACTIVEMQ_HOME="/opt/activemq"' >> /etc/default/activemq && \
    echo 'ACTIVEMQ_BASE="/var/lib/activemq"' >> /etc/default/activemq && \
    echo 'ACTIVEMQ_PIDFILE="/run/activemq.pid"' >> /etc/default/activemq && \
    echo 'JAVA_HOME="'"${JAVA_HOME}"'"' >> /etc/default/activemq && \
    echo 'ACTIVEMQ_OPTS="-Xms512M -Xmx512M -Dorg.apache.activemq.UseDedicatedTaskRunner=true"' >> /etc/default/activemq && \
    ln -snf /opt/activemq/bin/activemq /etc/init.d/activemq && \
    update-rc.d activemq defaults

RUN /usr/share/logstash/bin/logstash-plugin install logstash-input-stomp

COPY logstash-irods_audit.conf /etc/logstash/conf.d/irods_audit.conf

RUN echo "server.host: \"0.0.0.0\"" >> /etc/kibana/kibana.yml

COPY elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
RUN /usr/share/elasticsearch/bin/elasticsearch-keystore remove \
        xpack.security.http.ssl.keystore.secure_password \
        xpack.security.transport.ssl.keystore.secure_password \
        xpack.security.transport.ssl.truststore.secure_password

# utils
RUN apt-get update && \
    apt-get install -y \
        procps \
        nano \
        less \
        iproute2 \
        file \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# from ubi8-init
STOPSIGNAL SIGRTMIN+3

# from ubi8-init
RUN systemctl mask \
        systemd-remount-fs.service \
        dev-hugepages.mount \
        sys-fs-fuse-connections.mount \
        systemd-logind.service \
        getty.target \
        console-getty.service \
        systemd-udev-trigger.service \
        systemd-udevd.service \
        systemd-random-seed.service

# from ubi8-init
#mask systemd-machine-id-commit.service - partial fix for https://bugzilla.redhat.com/show_bug.cgi?id=1472439
RUN systemctl mask systemd-machine-id-commit.service

RUN systemctl mask \
        unattended-upgrades.service \
        packagekit-offline-update.service \
        systemd-timesyncd.service \
        systemd-resolved.service \
        e2scrub_reap.service \
        apt-daily-upgrade.service \
        apt-daily-upgrade.timer \
        apt-daily.service \
        apt-daily.timer \
        e2scrub_all.service \
        e2scrub_all.timer \
        ondemand.service \
        systemd-modules-load.service \
        fstrim.service \
        fstrim.timer

#RUN systemctl mask \
#        remote-fs.target \
#        systemd-pstore.service \
#        cryptsetup.target

RUN systemctl mask \
        getty-static.service \
        networkd-dispatcher.service

#RUN systemctl mask \
#        kmod-static-nodes.service
#        proc-sys-fs-binfmt_misc.mount \
#        proc-sys-fs-binfmt_misc.automount \
#        dev-mqueue.mount \
#        sys-kernel-config.mount \
#        sys-kernel-debug.mount \
#        sys-kernel-tracing.mount \
#        systemd-ask-password-console.path \
#        systemd-binfmt.service \
#        systemd-boot-system-token.service \
#        systemd-sysctl.service \
#        systemd-sysusers.service \
#        systemd-update-utmp.service \
#        systemd-initctl.socket \
#        systemd-update-utmp-runlevel.service \
#        systemd-ask-password-wall.path \
#        systemd-user-sessions.service

#RUN systemctl mask \
#        systemd-tmpfiles-setup-dev.service \
#        systemd-tmpfiles-setup.service \
#        systemd-tmpfiles-clean.timer \
#        systemd-tmpfiles-clean.service

# from ubi8-init
CMD ["/sbin/init"]

RUN mkdir -p /etc/systemd/system/logstash.service.d && \
    echo "[Unit]" >> /etc/systemd/system/logstash.service.d/elasticsearch.conf && \
    echo "After=elasticsearch.service" >> /etc/systemd/system/logstash.service.d/elasticsearch.conf && \
    echo "Wants=elasticsearch.service" >> /etc/systemd/system/logstash.service.d/elasticsearch.conf

RUN mkdir -p /etc/systemd/system/kibana.service.d && \
    echo "[Unit]" >> /etc/systemd/system/kibana.service.d/elasticsearch.conf && \
    echo "After=elasticsearch.service" >> /etc/systemd/system/kibana.service.d/elasticsearch.conf && \
    echo "Wants=elasticsearch.service" >> /etc/systemd/system/kibana.service.d/elasticsearch.conf

COPY elk-firstrun.service /etc/systemd/system/
COPY example_kibana_dashboard.ndjson /var/lib/irods-elk/
COPY firstrun.sh /var/lib/irods-elk/

RUN systemctl enable \
        elasticsearch \
        logstash \
        activemq \
        kibana \
        elk-firstrun

