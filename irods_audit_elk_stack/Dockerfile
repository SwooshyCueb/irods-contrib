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

RUN apt-get update && \
    apt-get install -y \
        apt-transport-https \
        gnupg \
        curl \
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
    apt-get install -y \
        ${java_vendor}-${java_ver}-${java_dist} \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*
ENV JAVA_HOME=/usr/lib/jvm/${java_vendor}-${java_ver}-${java_dist}-amd64
RUN update-java-alternatives --set ${JAVA_HOME}
ENV ES_JAVA_HOME=${JAVA_HOME}

#ARG es_ver=6
#ARG es_ver=7
ARG es_ver=8
ADD https://artifacts.elastic.co/GPG-KEY-elasticsearch /usr/share/keyrings/elasticsearch-keyring.asc
RUN gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg /usr/share/keyrings/elasticsearch-keyring.asc && \
    echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/${es_ver}.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-${es_ver}.x.list && \
    echo 'path-exclude=/usr/share/elasticsearch/jdk' >> /etc/dpkg/dpkg.cfg.d/excludes-elasticsearch-jvm && \
    echo 'path-exclude=/usr/share/elasticsearch/jdk/*' >> /etc/dpkg/dpkg.cfg.d/excludes-elasticsearch-jvm

RUN apt-get update && \
    apt-get install -y \
        elasticsearch \
        kibana \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN echo "ES_JAVA_HOME=\"${ES_JAVA_HOME}\"" >> /etc/default/elasticsearch

ADD https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey /usr/share/keyrings/rabbitmq_rabbitmq-server.asc
RUN add-apt-repository --no-update -y ppa:rabbitmq/rabbitmq-erlang && \
    gpg --dearmor -o /usr/share/keyrings/rabbitmq_rabbitmq-server.gpg /usr/share/keyrings/rabbitmq_rabbitmq-server.asc && \
    echo "deb [signed-by=/usr/share/keyrings/rabbitmq_rabbitmq-server.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu/ $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/rabbitmq_rabbitmq-server.list && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ADD https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc /usr/share/keyrings/erlang_solutions.asc
#RUN gpg --dearmor -o /usr/share/keyrings/erlang_solutions.gpg /usr/share/keyrings/erlang_solutions.asc && \
#    echo "deb [signed-by=/usr/share/keyrings/erlang_solutions.gpg] https://packages.erlang-solutions.com/ubuntu $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) contrib" | tee /etc/apt/sources.list.d/erlang-solutions.list
RUN gpg --dearmor -o /usr/share/keyrings/erlang_solutions.gpg /usr/share/keyrings/erlang_solutions.asc && \
    echo "deb [signed-by=/usr/share/keyrings/erlang_solutions.gpg] http://binaries.erlang-solutions.com/debian $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) contrib" | tee /etc/apt/sources.list.d/erlang-solutions.list

RUN apt-get update && \
    apt-get install -y \
        rabbitmq-server \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN rabbitmq-plugins enable rabbitmq_amqp1_0 && \
    rabbitmq-plugins enable rabbitmq_management

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
        apt-daily-upgrade.service \
        apt-daily-upgrade.timer \
        apt-daily.service \
        apt-daily.timer \
        e2scrub_reap.service \
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
        rabbitmq-server \
        kibana \
        elk-firstrun

WORKDIR /root
