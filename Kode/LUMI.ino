/*
 * LightMonitorSystem.ino
 */

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <RTClib.h>
#include <Adafruit_PWMServoDriver.h>

// Objek global
LiquidCrystal_I2C lcd(0x27, 16, 2);
RTC_DS3231 rtc;
Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver();

// Pin definitions
#define BUTTON_PIN 2
#define SERVO_CHANNEL 0
#define SERVO_OPEN 150
#define SERVO_CLOSED 450

// Variabel global
volatile bool boxState = true;
volatile bool buttonPressed = false;

// Deklarasi fungsi Assembly
extern "C" {
  void setupPins();
  void setupADC();
  int readLightSensor();
  void setLEDs(bool greenOn, bool redOn);
  void blinkLEDTimes(int pin, int count);
  int getThreshold();
}

void setup() {
  Serial.begin(9600);
  Serial.println(F("Light Monitor System"));
  
  // Setup interrupt
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(BUTTON_PIN), buttonInterrupt, FALLING);
  
  // I2C dan perangkat
  Wire.begin();
  lcd.init();
  lcd.backlight();
  
  if (!rtc.begin()) {
    Serial.println(F("RTC Error!"));
    while(1);
  }
  
  if (rtc.lostPower()) {
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  }
  
  pwm.begin();
  pwm.setPWMFreq(60);
  
  // Setup Assembly functions
  setupPins();
  setupADC();
  
  // Status awal
  int lightValue = readLightSensor();
  boxState = (lightValue <= getThreshold());
  controlServo(boxState);
  setLEDs(boxState, !boxState);
  
  lcd.clear();
  lcd.print("System Ready");
  delay(2000);
}

void buttonInterrupt() {
  static unsigned long lastTime = 0;
  unsigned long currentTime = millis();
  
  if (currentTime - lastTime > 200) {
    buttonPressed = true;
    setLEDs(false, true); // Red ON saat tombol ditekan
  }
  lastTime = currentTime;
}

void loop() {
  // Handle button press
  if (buttonPressed) {
    boxState = !boxState;
    
    // Blink LED sesuai status baru
    int blinkPin = boxState ? 9 : 10; // Green : Red
    blinkLEDTimes(blinkPin, 3);
    
    controlServo(boxState);
    setLEDs(boxState, !boxState);
    buttonPressed = false;
    
    Serial.print(F("Manual toggle: "));
    Serial.println(boxState ? F("Open") : F("Closed"));
  }
  
  // Auto control berdasarkan cahaya
  int lightValue = readLightSensor();
  int threshold = getThreshold();
  
  if (lightValue > threshold && boxState) {
    boxState = false;
    controlServo(false);
    setLEDs(false, true);
    Serial.println(F("Auto closed"));
  } 
  else if (lightValue <= threshold && !boxState) {
    boxState = true;
    controlServo(true);
    setLEDs(true, false);
    Serial.println(F("Auto opened"));
  }
  
  // Update LCD
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(F("Light: "));
  lcd.print(lightValue);
  
  lcd.setCursor(0, 1);
  lcd.print(F("Box: "));
  lcd.print(boxState ? F("Open") : F("Closed"));
  
  // Tampilkan waktu
  DateTime now = rtc.now();
  lcd.setCursor(10, 1);
  if (now.hour() < 10) lcd.print('0');
  lcd.print(now.hour());
  lcd.print(':');
  if (now.minute() < 10) lcd.print('0');
  lcd.print(now.minute());
  
  delay(500);
}

// Servo control - tetap di Arduino karena menggunakan library
void controlServo(bool openBox) {
  static int currentPos = -1;
  int targetPos = openBox ? SERVO_OPEN : SERVO_CLOSED;
  
  if (currentPos == -1) {
    currentPos = targetPos;
    pwm.setPWM(SERVO_CHANNEL, 0, currentPos);
    return;
  }
  
  if (currentPos < targetPos) {
    for (int pos = currentPos; pos <= targetPos; pos += 5) {
      pwm.setPWM(SERVO_CHANNEL, 0, pos);
      delay(15);
    }
  } else {
    for (int pos = currentPos; pos >= targetPos; pos -= 5) {
      pwm.setPWM(SERVO_CHANNEL, 0, pos);
      delay(15);
    }
  }
  currentPos = targetPos;
}