FROM tomcat:9-jre8-slim

LABEL maintainer="Florian JUDITH <florian.judith.b@gmail.com>"

ENV VERSION=9.3.1

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        openjdk-8-jdk-headless ant git patch wget xmlstarlet certbot && \
    cd /tmp && \
    wget https://github.com/jgraph/draw.io/archive/v${VERSION}.zip && \
    unzip v${VERSION}.zip && \
    cd /tmp/drawio-${VERSION} && \
    cd /tmp/drawio-${VERSION}/etc/build && \
    ant war && \
    cd /tmp/drawio-${VERSION}/build && \
    unzip /tmp/drawio-${VERSION}/build/draw.war -d $CATALINA_HOME/webapps/draw && \
    apt-get remove -y --purge openjdk-8-jdk-headless ant git patch wget && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -r /var/lib/apt/lists/* && \
    rm -rf \
        /tmp/v${VERSION}.zip \
        /tmp/drawio-${VERSION}

# Update server.xml to set Draw.io webapp to root
RUN cd $CATALINA_HOME && \
    xmlstarlet ed \
    -P -S -L \
    -i '/Server/Service/Engine/Host/Valve' -t 'elem' -n 'Context' \
    -i '/Server/Service/Engine/Host/Context' -t 'attr' -n 'path' -v '/' \
    -i '/Server/Service/Engine/Host/Context[@path="/"]' -t 'attr' -n 'docBase' -v 'draw' \
    -s '/Server/Service/Engine/Host/Context[@path="/"]' -t 'elem' -n 'WatchedResource' -v 'WEB-INF/web.xml' \
    -i '/Server/Service/Engine/Host/Valve' -t 'elem' -n 'Context' \
    -i '/Server/Service/Engine/Host/Context[not(@path="/")]' -t 'attr' -n 'path' -v '/ROOT' \
    -s '/Server/Service/Engine/Host/Context[@path="/ROOT"]' -t 'attr' -n 'docBase' -v 'ROOT' \
    -s '/Server/Service/Engine/Host/Context[@path="/ROOT"]' -t 'elem' -n 'WatchedResource' -v 'WEB-INF/web.xml' \
    conf/server.xml

# Offline redirection
COPY index.jsp webapps/draw/index.jsp
RUN sed -i '/<welcome-file>index.html<\/welcome-file>/i \ \ \ \ <welcome-file>index.jsp<\/welcome-file>' webapps/draw/WEB-INF/web.xml

# Remove external URLs (just precaution)
COPY custom_urls.js webapps/draw/custom_urls.js
RUN sed -i "/App.main();/i mxscript('custom_urls.js');" webapps/draw/index.html

# Copy docker-entrypoint
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

WORKDIR $CATALINA_HOME

EXPOSE 8080 8443

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["catalina.sh", "run"]
