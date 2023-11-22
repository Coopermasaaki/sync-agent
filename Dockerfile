FROM openeuler/openeuler:23.03 as BUILDER
RUN dnf update -y && \
    dnf install -y golang && \
    go env -w GOPROXY=https://goproxy.cn,direct

MAINTAINER zengchen1024<chenzeng765@gmail.com>

# build binary
WORKDIR /go/src/github.com/opensourceways/sync-agent
COPY . .
RUN GO111MODULE=on CGO_ENABLED=0 go build -a -o sync-agent -buildmode=pie --ldflags "-s -linkmode 'external' -extldflags '-Wl,-z,now'" .

# copy binary config and utils
FROM openeuler/openeuler:22.03
RUN dnf -y update && \
    dnf in -y shadow && \
    dnf remove -y gdb-gdbserver && \
    groupadd -g 1000 sync-agent && \
    useradd -u 1000 -g sync-agent -s /sbin/nologin -m sync-agent

RUN echo > /etc/issue && echo > /etc/issue.net && echo > /etc/motd
RUN mkdir /opt/app -p
RUN chmod 700 /opt/app
RUN chown sync-agent:sync-agent /opt/app

RUN echo 'set +o history' >> /root/.bashrc
RUN sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
RUN rm -rf /tmp/*

USER sync-agent

WORKDIR /opt/app

COPY  --chown=sync-agent --from=BUILDER /go/src/github.com/opensourceways/sync-agent/sync-agent /opt/app/sync-agent

RUN chmod 550 /opt/app/sync-agent

RUN echo "umask 027" >> /home/sync-agent/.bashrc
RUN echo 'set +o history' >> /home/sync-agent/.bashrc

ENTRYPOINT ["/opt/app/sync-agent"]
