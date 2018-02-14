FROM alpine:edge
ENV HOME /home/plex

# Install dependencies
RUN apk add --no-cache shadow bash git openssh \
                    python3 python2 \
                    py-psutil py-setuptools py-termcolor

COPY . /prt
RUN cd /prt && \
    python3 setup.py install

# SSH user configuration
RUN cat /dev/zero | ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -q -N "" && \
	cat /dev/zero | ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -q -N "" && \
    cat /dev/zero | ssh-keygen -q -N "" && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
	echo "StrictHostKeyChecking no" >> /etc/ssh/sshd_config && \
    useradd -m -s /bin/bash -u 10000 plex && \
	echo "plex:plex" | chpasswd && \
    mkdir -p /home/plex/.ssh
ADD host_ssh_key /home/plex/.ssh/authorized_keys

# Fix User permissions
RUN chown plex -R /home/plex && \
	chmod 600 -R /home/plex/.ssh/*

# Setup Plex Media Server
RUN mkdir -p /var/lib/plexmediaserver && \
    mkdir -p /usr/lib/plexmediaserver && \
    mkdir -p /opt/plex/tmp && \
    mkdir -p /storage

# Cleanup
RUN apk --no-cache del --purge shadow git && \
    cd / && rm -rf /prt

VOLUME /var/lib/plexmediaserver
VOLUME /usr/lib/plexmediaserver
VOLUME /opt/plex/tmp
VOLUME /storage

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
