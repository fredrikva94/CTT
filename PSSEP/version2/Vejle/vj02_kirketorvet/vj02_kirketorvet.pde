#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>
#include <WaspOPC_N2.h>

Gas CO2(SOCKET_A);
Gas NO2(SOCKET_C);
float co2concentration;
float no2concentration;
float temperature;
float humidity;
float pressure;
int battery;
uint8_t errorLoRaWAN;
uint8_t socket = SOCKET0;
char node_ID[] = "VJCTT02";
uint8_t PORT = 3; // Port to use in Back-End: from 1 to 223
boolean PMX = false;
char info_string[61];
int status;
int measure;
int unconnected = -99;
float lowbat = -98.0;
char *sleepInterval;

uint8_t socketLoRaWAN = SOCKET0;

//Used to store error codes
uint8_t error;


void setup() {
    // put your setup code here, to run once:
    USB.ON();
    USB.println(F("CTT Vejle 2"));
    USB.println(PWR.getBatteryVolts());
    USB.println(PWR.getBatteryLevel(),DEC);
    frame.setID(node_ID);
    // Checking network
    LoRaWAN.ON(socketLoRaWAN);
            error = LoRaWAN.getDeviceAddr();
    if(error == 0){
        USB.print(F("Successfully retrieved the device address. Device address: "));  
        USB.println(LoRaWAN._devAddr);
    } 
    error == LoRaWAN.setRadioSF("sf9");
    if(error == 0){
        USB.println(F("Radio SF set."));
    } else {
        USB.print(F("Error setting SF. Error: "));
        USB.println(errorLoRaWAN, DEC);
    }

    LoRaWAN.OFF(socketLoRaWAN);    
}


void loop() {
    // put your main code here, to run repeatedly:
  battery = PWR.getBatteryLevel();
    if(battery >= 60){
        sleepInterval = "00:00:07:30";
    } else if(battery > 30 && battery < 60){
        sleepInterval = "00:00:57:30";
    } else {
        while(battery <= 30){
          battery = PWR.getBatteryLevel();
          USB.print(F("Low bat: "));
          USB.println(battery, DEC);
          PWR.deepSleep("00:12:00:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
        } 
        sleepInterval = "00:00:57:30";
    }
    
    USB.print(F("Battery level: "));
    USB.println(battery, DEC);
    
    if(battery > 40){
      // Do measure as we have power
      // Turning on heating
      CO2.ON();
      NO2.ON();
      PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);  
      // Doing the measurements
      NO2.autoGain();
      temperature = CO2.getTemp();
      humidity = CO2.getHumidity();
      pressure = CO2.getPressure();
      co2concentration = CO2.getConc(MCP3421_ULTRA_HIGH_RES);
      no2concentration = NO2.getConc(MCP3421_ULTRA_HIGH_RES);
      CO2.OFF();
      NO2.OFF();
      if(co2concentration <= 0){
         co2concentration = -99.0;
      }
      if(no2concentration < 0){
         no2concentration = -99.0;
      }
      if(battery > 60){
        PMX = true;  
      } else {
        PMX = false;  
      }
      if(PMX == true){
        status = OPC_N2.ON();
        if(status == 1){
            OPC_N2.getPM(8000);
        }
        OPC_N2.OFF();
      }
      frame.createFrame(BINARY);
      frame.addSensor(SENSOR_GP_CO2, co2concentration);
      frame.addSensor(SENSOR_GP_NO2, no2concentration);
      frame.addSensor(SENSOR_GP_TC, temperature);
      frame.addSensor(SENSOR_GP_HUM, humidity);
      frame.addSensor(SENSOR_GP_PRES, pressure);
      if(PMX == true){
        frame.addSensor(SENSOR_OPC_PM1, OPC_N2._PM1);
        frame.addSensor(SENSOR_OPC_PM2_5, OPC_N2._PM2_5);
        frame.addSensor(SENSOR_OPC_PM10, OPC_N2._PM10);
      } else {
        frame.addSensor(SENSOR_OPC_PM1, lowbat);
        frame.addSensor(SENSOR_OPC_PM2_5, lowbat);
        frame.addSensor(SENSOR_OPC_PM10, lowbat); 
      }

   } else {
      // Only sending battery status
      frame.createFrame(BINARY);
      frame.addSensor(SENSOR_GP_CO2, lowbat);
      frame.addSensor(SENSOR_GP_NO2, lowbat);
      frame.addSensor(SENSOR_GP_TC, lowbat);
      frame.addSensor(SENSOR_GP_HUM, lowbat);
      frame.addSensor(SENSOR_GP_PRES, lowbat);
      frame.addSensor(SENSOR_OPC_PM1, lowbat);
      frame.addSensor(SENSOR_OPC_PM2_5, lowbat);
      frame.addSensor(SENSOR_OPC_PM10, lowbat); 
   }

   frame.addSensor(SENSOR_BAT, battery);
   frame.showFrame();
   char data[frame.length * 2 + 1];
   Utils.hex2str(frame.buffer, data, frame.length);
  
   // Sending
    errorLoRaWAN = LoRaWAN.ON(socketLoRaWAN);
    USB.print(F("Turning on lora. Value = "));
    USB.println(errorLoRaWAN, DEC);
    // Join network
    errorLoRaWAN = LoRaWAN.joinABP();
    USB.print(F("Joining. Value = "));
    USB.println(errorLoRaWAN, DEC);
    if (errorLoRaWAN == 0) 
    {
        errorLoRaWAN = LoRaWAN.sendUnconfirmed(PORT, data);   
        USB.print(F("Sending lora. Value = "));
        USB.println(errorLoRaWAN, DEC); 
    }
    errorLoRaWAN = LoRaWAN.OFF(socketLoRaWAN);
    USB.print(F("Turning off lora. Value = "));
    USB.println(errorLoRaWAN, DEC);
    // Wait before next measurement
    PWR.deepSleep(sleepInterval, RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}


