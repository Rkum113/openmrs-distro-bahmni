FROM openmrs/openmrs-core:2.5.x-nightly

ENV JMX_PROMETHEUS_JAVAAGENT_VERSION=0.17.2
ENV OPENMRS_APPLICATION_DATA_DIRECTORY=/openmrs/data
# Creating Config Directories
#RUN mkdir -p /usr/local/tomcat/.OpenMRS/modules/
RUN mkdir -p /tmp/artifacts/
RUN mkdir -p /etc/jvm_metrics/

RUN curl -L -o /tmp/artifacts/jmx_prometheus_javaagent-${JMX_PROMETHEUS_JAVAAGENT_VERSION}.jar "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_PROMETHEUS_JAVAAGENT_VERSION}/jmx_prometheus_javaagent-${JMX_PROMETHEUS_JAVAAGENT_VERSION}.jar"

COPY distro/target/distro/*.omod ${OPENMRS_APPLICATION_DATA_DIRECTORY}/modules
COPY package/docker/openmrs/templates/bahmnicore.properties.template /etc/bahmni-emr/templates/
COPY package/docker/openmrs/templates/openmrs-runtime.properties.template /etc/bahmni-emr/templates/
COPY package/docker/openmrs/templates/mail-config.properties.template /etc/bahmni-emr/templates/

# Add the latest ot and web-services modules with OMRS:2.4.2 changes
RUN rm ${OPENMRS_APPLICATION_DATA_DIRECTORY}/modules/operationtheater*.omod
RUN rm ${OPENMRS_APPLICATION_DATA_DIRECTORY}/modules/webservices.rest*.omod

COPY package/docker/openmrs/resources/*.omod ${OPENMRS_APPLICATION_DATA_DIRECTORY}/modules

# Setting Soft Links from bahmni_config (Moved from bahmni-web postinstall)
RUN ln -s /etc/bahmni_config/openmrs/obscalculator ${OPENMRS_APPLICATION_DATA_DIRECTORY}/obscalculator
RUN ln -s /etc/bahmni_config/openmrs/ordertemplates ${OPENMRS_APPLICATION_DATA_DIRECTORY}/ordertemplates
RUN ln -s /etc/bahmni_config/openmrs/encounterModifier ${OPENMRS_APPLICATION_DATA_DIRECTORY}/encounterModifier
RUN ln -s /etc/bahmni_config/openmrs/patientMatchingAlgorithm ${OPENMRS_APPLICATION_DATA_DIRECTORY}/patientMatchingAlgorithm
RUN ln -s /etc/bahmni_config/openmrs/elisFeedInterceptor ${OPENMRS_APPLICATION_DATA_DIRECTORY}/elisFeedInterceptor
RUN ln -s /etc/bahmni_config /openmrs/bahmni_config

# Creating Upload Directories
RUN mkdir -p /home/bahmni/patient_images
RUN mkdir -p /home/bahmni/document_images
COPY package/resources/blank-user.png /etc/bahmni/

# Used by envsubst command for replacing environment values at runtime
RUN yum install -y \
    mysql \
    mysql-client \
    gettext-base \
    gettext

COPY package/docker/openmrs/bahmni_startup.sh /openmrs/
RUN chmod +x /openmrs/bahmni_startup.sh

RUN cp /tmp/artifacts/jmx_prometheus_javaagent-*.jar /etc/jvm_metrics/jmx_prometheus_javaagent.jar

COPY package/docker/openmrs/setenv.sh /usr/local/tomcat/bin
COPY package/docker/openmrs/config.yml /etc/jvm_metrics/
RUN chmod +x /usr/local/tomcat/bin/setenv.sh
RUN chmod +x /etc/jvm_metrics/config.yml

RUN rm -rf /tmp/artifacts

CMD ["./bahmni_startup.sh"]
