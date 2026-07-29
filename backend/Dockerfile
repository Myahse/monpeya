# Multi-stage build — unified Mon Peya server
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY modules/platform/pom.xml modules/platform/
COPY modules/shared-kernel/pom.xml modules/shared-kernel/
COPY modules/billetterie/pom.xml modules/billetterie/
COPY modules/immo/pom.xml modules/immo/
COPY modules/server/pom.xml modules/server/
COPY modules/platform/src modules/platform/src
COPY modules/billetterie/src modules/billetterie/src
COPY modules/shared-kernel/src modules/shared-kernel/src
COPY modules/immo/src modules/immo/src
COPY modules/server/src modules/server/src
RUN mvn -q -pl modules/server -am package -DskipTests

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/modules/server/target/server-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8082
ENV DOCKER_COMPOSE_ENABLED=false
ENTRYPOINT ["java", "-jar", "app.jar"]
