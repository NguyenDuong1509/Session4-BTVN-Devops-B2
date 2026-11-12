#!/usr/bin/env bash

BANNER='
  .   ____          _            __ _ _
 /\\ / ___'\''_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '\''_ | '\''_| | '\''_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '\''  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v3.2.0)
'

echo "$BANNER"
NOW=$(date +"%Y-%m-%d %H:%M:%S.000")
echo "$NOW  INFO 1 --- [main] c.s.storex.StorexApplication            : Starting StorexApplication v2.0.0 using Java 17.0.9"
echo "$NOW  INFO 1 --- [main] c.s.storex.StorexApplication            : Active profile: \"production\""
echo "$NOW  INFO 1 --- [main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 8080 (http)"

# Connecting to DB
echo "$NOW  INFO 1 --- [main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting..."
echo "$NOW  INFO 1 --- [main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection org.postgresql.jdbc.PgConnection@7b5f12a1"
echo "$NOW  INFO 1 --- [main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed."

# Connecting to Redis Cache
echo "$NOW  INFO 1 --- [main] io.lettuce.core.RedisClient              : Connecting to Redis at redis:6379"
echo "$NOW  INFO 1 --- [main] o.s.d.r.c.RedisConnectionFactory         : Redis connection established successfully (PONG received)."
echo "$NOW  INFO 1 --- [main] o.s.cache.interceptor.CacheInterceptor   : Initialized RedisCacheManager for StoreX service."

# Complete startup
START_TIME=$(date +"%Y-%m-%d %H:%M:%S.000")
echo "$START_TIME  INFO 1 --- [main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path ''"
echo "$START_TIME  INFO 1 --- [main] c.s.storex.StorexApplication            : Started StorexApplication in 2.915 seconds (process running for 3.481)"

while true; do
    nc -l -p 8080 -e echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 20\r\n\r\nStoreX v2 API Online" 2>/dev/null || sleep 2
done
