# Bài tập 2: Quản lý dữ liệu (Volumes) và Dependency giữa các container

## 1. Giải thích cơ chế Healthcheck & Dependency

### 1.1. Vấn đề của `depends_on` mặc định
* Theo mặc định trong Docker Compose, `depends_on` dạng danh sách (list) chỉ đảm bảo container phụ thuộc được tạo và khởi chạy (**start**), nghĩa là tiến trình trong container vừa bắt đầu chạy.
* Tuy nhiên, các service như **PostgreSQL** hay **Redis** cần một khoảng thời gian nhất định sau khi start để khởi tạo dữ liệu, tải cấu hình và mở cổng mạng sẵn sàng nhận kết nối.
* Nếu Backend khởi động ngay lúc này, nó sẽ gửi yêu cầu kết nối khi Database/Redis chưa mở port $\rightarrow$ Backend crash ngay lập tức (`Connection refused`).

### 1.2. Cơ chế Healthcheck & `condition: service_healthy`
Để giải quyết bài toán trên, Docker cung cấp cơ chế **Healthcheck** để chủ động giám sát trạng thái thực sự của ứng dụng bên trong container:
* **PostgreSQL Healthcheck:**
  ```yaml
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U admin -d storex_db"]
    interval: 5s
    timeout: 5s
    retries: 5
    start_period: 10s
  ```
  - Lệnh `pg_isready -U admin -d storex_db` liên tục thăm dò PostgreSQL. Lệnh trả về mã thoát `0` khi máy chủ PostgreSQL đã sẵn sàng chấp nhận các kết nối mạng bình thường.
  - `start_period: 10s`: Dành 10 giây cho tiến trình khởi tạo ban đầu, các lỗi trong thời gian này không tính vào số lần retry.
  - `interval: 5s`, `timeout: 5s`, `retries: 5`: Cứ mỗi 5s kiểm tra 1 lần, tối đa 5s cho một lần thử, thử lại 5 lần trước khi báo lỗi.

* **Redis Healthcheck:**
  ```yaml
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 5s
    timeout: 3s
    retries: 5
    start_period: 5s
  ```
  - Sử dụng `redis-cli ping` để gửi tín hiệu PING tới server Redis. Khi Redis sẵn sàng xử lý bộ đệm, nó sẽ phản hồi `PONG` (exit code `0`).

* **Kết hợp điều kiện trong `backend`:**
  ```yaml
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
  ```
  - Docker Compose sẽ tạm dừng (block) tiến trình khởi động của `backend`, chỉ cho phép `backend` khởi động khi và chỉ khi cả **PostgreSQL** và **Redis** đã vượt qua bài kiểm tra sức khỏe và đạt trạng thái **`healthy`**.

---

## 2. Cơ chế lưu trữ dữ liệu bền vững (Data Persistence với Volumes)

* Container có tính chất tạm thời (**ephemeral**): khi chạy `docker compose down`, các container bị xóa hoàn toàn, dữ liệu nằm trong tầng ghi tạm (writable layer) của container sẽ bị mất.
* Bằng cách mount một **Named Volume**:
  ```yaml
  volumes:
    - postgres_data:/var/lib/postgresql/data
  ```
  Toàn bộ cơ sở dữ liệu vật lý nằm tại `/var/lib/postgresql/data` sẽ được lưu trữ trực tiếp trên phân vùng quản lý của Docker Host.
* Nhờ vậy, khi thực hiện chu kỳ `docker compose down` rồi `docker compose up -d`, volume `postgres_data` vẫn tồn tại và được mount lại vào container mới $\rightarrow$ **Dữ liệu được bảo toàn 100%**.

---

## 3. Nội dung file `docker-compose.yml` hoàn chỉnh

```yaml
version: '3.8'

services:
  backend:
    image: storex-backend:v2
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: always

  postgres:
    image: postgres:13
    environment:
      - POSTGRES_DB=storex_db
      - POSTGRES_USER=admin
      - POSTGRES_PASSWORD=admin
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U admin -d storex_db"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s
    restart: always

  redis:
    image: redis:alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 5s
    restart: always

volumes:
  postgres_data:
```

---

## 4. Hướng dẫn chạy và kiểm tra kết quả

1. **Khởi động các dịch vụ:**
   ```bash
   docker compose up -d
   ```
2. **Kiểm tra trạng thái healthy:**
   ```bash
   docker compose ps
   ```
   Kết quả kỳ vọng: Các container `postgres` và `redis` hiển thị trạng thái `Up ... (healthy)` trước khi `backend` khởi động.
3. **Kiểm tra tính bền vững của dữ liệu:**
   - Tạo bảng và insert dữ liệu vào PostgreSQL:
     ```bash
     docker compose exec postgres psql -U admin -d storex_db -c "CREATE TABLE test(id serial, name text); INSERT INTO test(name) VALUES ('StoreX Data Persistence Test');"
     ```
   - Xóa bỏ container bằng lệnh down:
     ```bash
     docker compose down
     ```
   - Khởi động lại:
     ```bash
     docker compose up -d
     ```
   - Truy vấn lại dữ liệu:
     ```bash
     docker compose exec postgres psql -U admin -d storex_db -c "SELECT * FROM test;"
     ```
   - $\rightarrow$ Kết quả bản ghi vẫn tồn tại đầy đủ!
