FROM solr:9.11

ENV DEBIAN_FRONTEND=noninteractive
ENV VUFIND_HOME=/alphabrowse
ENV SOLR_JAR_PATH=/opt/solr

USER root

RUN mkdir -p /configsets/biblio/lib && \
    mkdir -p /alphabrowse/import/lib && \
    mkdir -p /var/solr/data

# Copy startup script
COPY ./docker/solr/startup.sh /

# Copy configsets
COPY ./vufind/solr/vufind/authority /configsets/authority
COPY ./vufind/solr/vufind/biblio /configsets/biblio
COPY ./vufind/solr/vufind/reserves /configsets/reserves
COPY ./vufind/solr/vufind/website /configsets/website

# Copy biblio libraries (<lib> cannot be used with Solr 10)
COPY ./vufind/import/lib/marc4j*.jar ./vufind/import/solrmarc_core*.jar ./vufind/solr/vufind/jars/*.jar ./vufind/solr/vendor/modules/analysis-extras/lib/*.jar /configsets/biblio/lib/

# Prepare /alphabrowse to run index-alphabetic-browse.sh
COPY ./vufind/index-alphabetic-browse.sh /alphabrowse/
COPY ./vufind/import/lib/*.jar ./vufind/solr/vufind/jars/*.jar /alphabrowse/import/lib/
COPY ./vufind/import/*.jar /alphabrowse/import/

RUN chown -R "${SOLR_UID}:${SOLR_GID}" /var/solr /configsets /startup.sh /alphabrowse

USER $SOLR_UID

CMD ["/startup.sh", "solr-foreground"]
