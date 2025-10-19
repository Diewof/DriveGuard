#include <Arduino.h>
#include "esp_camera.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include "base64.h"

// ============================================
// CONFIGURACIÓN ESP32-CAM DRIVEGUARD
// ============================================

// Configuración WiFi
const char* WIFI_SSID = "DriveGuard";
const char* WIFI_PASSWORD = "driveguard123";
const int WIFI_MAX_RETRIES = 10;
const int WIFI_RETRY_DELAY_MS = 1000;

// LED integrado (GPIO 33 en AI-Thinker)
#define LED_BUILTIN 33

// Configuración HTTP Client
const int FLUTTER_APP_PORT = 8080;
const int HTTP_TIMEOUT_MS = 5000;
HTTPClient http;

// Variables de auto-descubrimiento (vía gateway)
String discoveredServerIP = "";
int discoveredServerPort = 0;
bool serverDiscovered = false;
int consecutiveHttpErrors = 0;
const int MAX_HTTP_ERRORS = 5;

// Variables de control
bool camera_ready = false;
TaskHandle_t captureTaskHandle = NULL;

// ==== PINES DEL MÓDULO AI THINKER (ESP32-CAM) ====
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// ============================================
// DECLARACIONES ANTICIPADAS
// ============================================
void rediscoverServer();
bool startUDPListener();

// ============================================
// COMANDOS SERIALES DE DEBUGGING
// ============================================

void processSerialCommand() {
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    command.toLowerCase();

    if (command == "help") {
      Serial.println("\n╔════════════════════════════════════════╗");
      Serial.println("║          COMANDOS DISPONIBLES          ║");
      Serial.println("╚════════════════════════════════════════╝");
      Serial.println("  help      - Mostrar esta ayuda");
      Serial.println("  server    - Información del servidor");
      Serial.println("  discover  - Redescubrir servidor UDP");
      Serial.println("  info      - Información del sistema");
      Serial.println("  wifi      - Estado del WiFi");
      Serial.println("  camera    - Estado de la cámara\n");
    }
    else if (command == "server") {
      Serial.println("\n╔════════════════════════════════════════╗");
      Serial.println("║       INFORMACIÓN DEL SERVIDOR         ║");
      Serial.println("╚════════════════════════════════════════╝");

      if (serverDiscovered) {
        Serial.println("  Estado: ✓ CONECTADO AL SERVIDOR");
        Serial.printf("  IP:     %s\n", discoveredServerIP.c_str());
        Serial.printf("  Puerto: %d\n", discoveredServerPort);
      } else {
        Serial.println("  Estado: ⚠ USANDO GATEWAY");
        Serial.printf("  IP:     %s (gateway)\n", discoveredServerIP.c_str());
        Serial.printf("  Puerto: %d\n", FLUTTER_APP_PORT);
      }

      Serial.printf("  Errores HTTP consecutivos: %d/%d\n\n", consecutiveHttpErrors, MAX_HTTP_ERRORS);
    }
    else if (command == "discover") {
      Serial.println("\n[CMD] Comando 'discover' ejecutado");
      rediscoverServer();
    }
    else if (command == "info") {
      Serial.println("\n╔════════════════════════════════════════╗");
      Serial.println("║      INFORMACIÓN DEL SISTEMA           ║");
      Serial.println("╚════════════════════════════════════════╝");
      Serial.printf("  Versión:    DriveGuard v2.0\n");
      Serial.printf("  WiFi SSID:  %s\n", WIFI_SSID);
      Serial.printf("  WiFi IP:    %s\n", WiFi.localIP().toString().c_str());
      Serial.printf("  WiFi RSSI:  %d dBm\n", WiFi.RSSI());
      Serial.printf("  Cámara:     %s\n", camera_ready ? "✓ OK" : "✗ ERROR");
      Serial.printf("  Free Heap:  %d bytes\n", ESP.getFreeHeap());
      Serial.printf("  Uptime:     %lu segundos\n\n", millis() / 1000);
    }
    else if (command == "wifi") {
      Serial.println("\n╔════════════════════════════════════════╗");
      Serial.println("║         INFORMACIÓN WIFI               ║");
      Serial.println("╚════════════════════════════════════════╝");
      Serial.printf("  Estado:     %s\n", WiFi.status() == WL_CONNECTED ? "✓ CONECTADO" : "✗ DESCONECTADO");
      Serial.printf("  SSID:       %s\n", WIFI_SSID);
      Serial.printf("  IP Local:   %s\n", WiFi.localIP().toString().c_str());
      Serial.printf("  Gateway:    %s\n", WiFi.gatewayIP().toString().c_str());
      Serial.printf("  Subnet:     %s\n", WiFi.subnetMask().toString().c_str());
      Serial.printf("  RSSI:       %d dBm\n\n", WiFi.RSSI());
    }
    else if (command == "camera") {
      Serial.println("\n╔════════════════════════════════════════╗");
      Serial.println("║        INFORMACIÓN CÁMARA              ║");
      Serial.println("╚════════════════════════════════════════╝");
      Serial.printf("  Estado:     %s\n", camera_ready ? "✓ INICIALIZADA" : "✗ ERROR");
      Serial.println("  Resolución: VGA 640x480");
      Serial.println("  Formato:    JPEG");
      Serial.println("  Calidad:    10\n");
    }
    else {
      Serial.printf("[CMD] Comando desconocido: '%s'\n", command.c_str());
      Serial.println("[CMD] Escribe 'help' para ver comandos disponibles\n");
    }
  }
}

// ============================================
// AUTO-DESCUBRIMIENTO MEDIANTE GATEWAY
// ============================================

bool discoverServerViaGateway() {
  Serial.println("\n[Gateway] Iniciando auto-descubrimiento...");

  // Obtener Gateway IP (que es el celular que creó el hotspot)
  IPAddress gatewayIP = WiFi.gatewayIP();

  Serial.println("\n[DEBUG] Información de red:");
  Serial.printf("  IP ESP32:  %s\n", WiFi.localIP().toString().c_str());
  Serial.printf("  Gateway:   %s ← Este es el celular!\n", gatewayIP.toString().c_str());
  Serial.printf("  Subnet:    %s\n", WiFi.subnetMask().toString().c_str());
  Serial.printf("  WiFi RSSI: %d dBm\n\n", WiFi.RSSI());

  // El servidor Flutter está en el gateway (celular)
  discoveredServerIP = gatewayIP.toString();
  discoveredServerPort = FLUTTER_APP_PORT;

  // Intentar hacer un handshake HTTP para verificar que el servidor está corriendo
  Serial.printf("[Gateway] Intentando conectar a %s:%d...\n",
                discoveredServerIP.c_str(), discoveredServerPort);

  String handshakeUrl = "http://" + discoveredServerIP + ":" +
                        String(discoveredServerPort) + "/handshake";

  http.begin(handshakeUrl);
  http.setTimeout(5000); // 5 segundos de timeout
  http.addHeader("Content-Type", "application/json");

  // Enviar información del ESP32
  String payload = "{\"type\":\"ESP32_HANDSHAKE\",\"ip\":\"" +
                   WiFi.localIP().toString() + "\",\"mac\":\"" +
                   WiFi.macAddress() + "\"}";

  int httpResponseCode = http.POST(payload);
  http.end();

  if (httpResponseCode > 0) {
    serverDiscovered = true;

    Serial.println("\n╔════════════════════════════════════════╗");
    Serial.println("║   SERVIDOR FLUTTER DETECTADO! ✓        ║");
    Serial.println("╚════════════════════════════════════════╝");
    Serial.printf("  IP Gateway:  %s\n", discoveredServerIP.c_str());
    Serial.printf("  Puerto:      %d\n", discoveredServerPort);
    Serial.printf("  HTTP Code:   %d\n", httpResponseCode);
    Serial.println("========================================\n");

    return true;
  } else {
    Serial.printf("\n[Gateway] ⚠ No se pudo conectar al servidor (HTTP: %d)\n", httpResponseCode);
    Serial.println("[Gateway] Esto es normal si aún no has iniciado el servidor en Flutter");
    Serial.println("[Gateway] El ESP32 seguirá intentando enviar frames al gateway...\n");

    // Aún así, usar el gateway como servidor (fallback)
    serverDiscovered = false;
    return false;
  }
}


void rediscoverServer() {
  Serial.println("\n[Gateway] ⟳ Reintentar conexión con servidor...");

  delay(500);

  // Reiniciar el proceso de descubrimiento
  discoverServerViaGateway();

  if (serverDiscovered) {
    consecutiveHttpErrors = 0; // Reiniciar contador de errores
    Serial.println("[Gateway] ✓ Servidor redescubierto exitosamente");
  } else {
    Serial.println("[Gateway] ⚠ Servidor aún no disponible, usando gateway como fallback");
  }
}

// ============================================
// FUNCIONES WIFI
// ============================================

bool connectToWiFi() {
  Serial.println("[WiFi] Conectando...");

  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int retry_count = 0;
  while (WiFi.status() != WL_CONNECTED && retry_count < WIFI_MAX_RETRIES) {
    delay(WIFI_RETRY_DELAY_MS);
    Serial.print(".");
    retry_count++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    digitalWrite(LED_BUILTIN, HIGH);
    Serial.println("\n[WiFi] Conectado");
    Serial.printf("[WiFi] IP: %s\n", WiFi.localIP().toString().c_str());
    return true;
  } else {
    Serial.println("\n[WiFi] Error de conexión");
    return false;
  }
}

void reconnectWiFi() {
  if (WiFi.status() != WL_CONNECTED) {
    digitalWrite(LED_BUILTIN, LOW);
    WiFi.disconnect();
    delay(1000);
    connectToWiFi();
  }
}

// ============================================
// CONFIGURACIÓN DE CÁMARA
// ============================================

bool initCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size = FRAMESIZE_VGA;   // 640x480
  config.jpeg_quality = 10;
  config.fb_count = 2;

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("[Camera] Error: 0x%x\n", err);
    return false;
  }

  sensor_t * s = esp_camera_sensor_get();
  if (s != NULL) {
    s->set_brightness(s, 0);
    s->set_contrast(s, 0);
    s->set_saturation(s, 0);
    s->set_whitebal(s, 1);
    s->set_awb_gain(s, 1);
    s->set_exposure_ctrl(s, 1);
    s->set_gain_ctrl(s, 1);
    s->set_hmirror(s, 0);
    s->set_vflip(s, 0);
  }

  Serial.println("[Camera] Iniciada - VGA 640x480");
  camera_ready = true;
  return true;
}

// ============================================
// CLIENTE HTTP Y ENVÍO
// ============================================

bool sendImageToFlutter(camera_fb_t *fb) {
  if (!fb || WiFi.status() != WL_CONNECTED) return false;

  String base64Image = base64::encode(fb->buf, fb->len);
  if (base64Image.length() == 0) return false;

  // Usar IP descubierta (que siempre será el gateway)
  String serverIP = discoveredServerIP;
  int serverPort = discoveredServerPort;

  String url = "http://" + serverIP + ":" + String(serverPort) + "/upload";
  String jsonPayload = "{\"image\":\"" + base64Image + "\",\"timestamp\":" + String(millis()) + "}";

  http.begin(url);
  http.setTimeout(HTTP_TIMEOUT_MS);
  http.addHeader("Content-Type", "application/json");

  int httpResponseCode = http.POST(jsonPayload);
  http.end();

  return (httpResponseCode > 0);
}

// ============================================
// TAREA DE CAPTURA CONTINUA
// ============================================

void captureTask(void *parameter) {
  const TickType_t delay500ms = pdMS_TO_TICKS(500);

  while (true) {
    if (WiFi.status() != WL_CONNECTED) {
      reconnectWiFi();
      vTaskDelay(pdMS_TO_TICKS(5000));
      continue;
    }

    if (camera_ready) {
      camera_fb_t *fb = esp_camera_fb_get();
      if (fb) {
        bool success = sendImageToFlutter(fb);
        esp_camera_fb_return(fb);

        if (success) {
          Serial.print(".");
          consecutiveHttpErrors = 0; // Reset error counter on success
        } else {
          consecutiveHttpErrors++;
          Serial.printf("\n[HTTP] Error de envío (%d/%d)\n", consecutiveHttpErrors, MAX_HTTP_ERRORS);

          // Si hay muchos errores consecutivos, intentar redescubrir servidor
          if (consecutiveHttpErrors >= MAX_HTTP_ERRORS) {
            Serial.println("[HTTP] ⚠ Demasiados errores, intentando redescubrir servidor...");
            rediscoverServer();
          }
        }
      }
    }

    vTaskDelay(delay500ms);
  }
}

// ============================================
// SETUP Y LOOP
// ============================================

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n╔════════════════════════════════════════╗");
  Serial.println("║     ESP32-CAM DriveGuard v2.0          ║");
  Serial.println("║     Auto-Descubrimiento UDP            ║");
  Serial.println("╚════════════════════════════════════════╝\n");

  if (!initCamera()) {
    Serial.println("[ERROR] ✗ Cámara no inicializada");
    while (1) { delay(1000); }
  }

  if (!connectToWiFi()) {
    Serial.println("[ERROR] ✗ WiFi no conectado");
    while (1) { delay(1000); }
  }

  // Iniciar auto-descubrimiento mediante gateway
  Serial.println("\n[Sistema] Iniciando auto-descubrimiento de servidor...");
  discoverServerViaGateway();

  // Mostrar información del servidor a usar
  if (serverDiscovered) {
    Serial.println("\n[Sistema] ✓ Servidor Flutter detectado en gateway:");
    Serial.printf("  → %s:%d\n", discoveredServerIP.c_str(), discoveredServerPort);
  } else {
    Serial.println("\n[Sistema] ⚠ Usando gateway como destino (el servidor Flutter puede no estar iniciado):");
    Serial.printf("  → %s:%d (gateway)\n", discoveredServerIP.c_str(), discoveredServerPort);
    Serial.println("\n  NOTA: El ESP32 seguirá enviando frames al gateway.");
    Serial.println("        Cuando inicies el servidor Flutter, la conexión se establecerá automáticamente.");
  }

  // Iniciar tarea de captura
  xTaskCreatePinnedToCore(
    captureTask,
    "CaptureTask",
    8192,
    NULL,
    1,
    &captureTaskHandle,
    0
  );

  Serial.println("\n╔════════════════════════════════════════╗");
  Serial.println("║     ✓ SISTEMA INICIADO                 ║");
  Serial.println("╚════════════════════════════════════════╝");
  Serial.println("\nComandos disponibles:");
  Serial.println("  help      - Mostrar ayuda");
  Serial.println("  server    - Info del servidor actual");
  Serial.println("  discover  - Redescubrir servidor");
  Serial.println("  info      - Información del sistema\n");
}

void loop() {
  static unsigned long lastWiFiCheck = 0;
  if (millis() - lastWiFiCheck > 30000) {
    if (WiFi.status() != WL_CONNECTED) {
      reconnectWiFi();
    }
    lastWiFiCheck = millis();
  }

  // Procesar comandos seriales
  processSerialCommand();

  delay(100);
}
