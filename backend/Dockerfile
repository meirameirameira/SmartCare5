# Imagem de execucao da API Smart HAS.
# O jar e gerado antes (./gradlew bootJar ou job "backend" do pipeline), entao
# a imagem nao recompila nada e carrega so o JRE.
FROM eclipse-temurin:21-jre-alpine

RUN addgroup -S smarthas && adduser -S smarthas -G smarthas
WORKDIR /app
COPY build/libs/smarthas-api.jar app.jar
USER smarthas

# Perfil e credenciais chegam por variavel de ambiente no deploy:
#   SPRING_PROFILES_ACTIVE=oracle, ORACLE_URL, ORACLE_USER, ORACLE_PASSWORD,
#   SMARTHAS_JWT_SECRET
ENV SPRING_PROFILES_ACTIVE=oracle \
    JAVA_OPTS="-XX:MaxRAMPercentage=75"
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health | grep -q '"UP"' || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
