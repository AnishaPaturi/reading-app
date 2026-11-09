# Multi-stage build for Reading Sanctuary Spring Boot API
FROM eclipse-temurin:25-jdk AS build

WORKDIR /app

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw

COPY src/ ./src/
RUN ./mvnw -B clean package -DskipTests

# Minimal secure runtime container
FROM eclipse-temurin:25-jre

WORKDIR /app

RUN useradd -m -u 1001 sanctuaryuser

COPY --from=build --chown=sanctuaryuser:sanctuaryuser /app/target/*.jar app.jar

USER sanctuaryuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-Dspring.profiles.active=prod", "-jar", "app.jar"]
