#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>
#include <WaspOPC_N2.h>


int battery;
int status;
float lowbat = -98.0;
char *sleepInterval;

//LoRaWAN variables
uint8_t error;
uint8_t socket = SOCKET0;
uint8_t PORT = 3;

//Code version (HEX)
char node_ID[] = "0000002";

void setup() {
  USB.ON();
  USB.println(F("CTT Waspmote debug:"));
  USB.println(PWR.getBatteryVolts());
  USB.println(PWR.getBatteryLevel(),DEC);
  frame.setID(node_ID);
  LoRaWAN.ON(socket);
  error = LoRaWAN.getDeviceAddr();
  if(error == 0){
    USB.print(F("Successfully retrieved the device address. Device address: "));
    USB.println(LoRaWAN._devAddr);
  }
  if(error == 0){
    USB.println(F("Radio SF set."));
  } else {
    USB.print(F("ERROR setting SF. Error: "));
    USB.println(error, DEC);
  }
  LoRaWAN.OFF(socket);
}


void loop() {
  battery = PWR.getBatteryLevel();
  USB.print(F("Battery level: "));
  USB.println(battery, DEC);

  frame.createFrame(BINARY);
  frame.addSensor(SENSOR_GP_CO2, lowbat);
  frame.addSensor(SENSOR_GP_NO2, lowbat);
  frame.addSensor(SENSOR_GP_TC, lowbat);
  frame.addSensor(SENSOR_GP_HUM, lowbat);
  frame.addSensor(SENSOR_GP_PRES, lowbat);
  frame.addSensor(SENSOR_OPC_PM1, lowbat);
  frame.addSensor(SENSOR_OPC_PM2_5, lowbat);
  frame.addSensor(SENSOR_OPC_PM10, lowbat);
  frame.addSensor(SENSOR_BAT, battery);

  frame.showFrame();

  sendFrame();

  sleepInterval = "00:00:01:00";
  PWR.deepSleep(sleepInterval, RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}

//Send data frame over LoRaWAN
void sendFrame() {
  char data[frame.length * 2 + 1];
  Utils.hex2str(frame.buffer, data, frame.length);

  error = LoRaWAN.ON(socket);
  USB.print(F("Turning on lora. Value = "));
  USB.println(error, DEC);

  error = LoRaWAN.joinABP();
  USB.print(F("Joining. Value = "));
  USB.println(error, DEC);
  if (error == 0){
    error = LoRaWAN.sendUnconfirmed(PORT, data);
    USB.print(F("Sending lora. Value = "));
    USB.println(error, DEC);
  }
  error = LoRaWAN.OFF(socket);
  USB.print(F("Turning off lora. Value = "));
  USB.println(error, DEC);
}
