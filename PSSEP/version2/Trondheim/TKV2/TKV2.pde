#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>
#include <WaspOPC_N2.h>

/*
  Variables for measuring cycle:
    - Sensor declaration
    - Measurement variables
    - PMx variables
    - Error codes
    - Sleep interval
*/
Gas CO2(SOCKET_A);
Gas NO2(SOCKET_C);
float co2concentration;
float no2concentration;
float temperature;
float humidity;
float pressure;
int battery;
boolean PMX = false;
int status;
float sensorError = -99.0;
float lowbat = -98.0;
char *sleepInterval;

//LoRaWAN variables
uint8_t error;
uint8_t socket = SOCKET0;
uint8_t PORT = 3;

//Code version (HEX)
char node_ID[] = "0000002";




void setup() {
    /*
      Setup loop:
        - Sets code version in data frame, using node_ID
        - Retrieves device address (for debugging purposes)
        - Sets spreading factor (may only work P2P mode)
    */
    USB.ON();
    USB.println(F("CTT Vejle 2"));
    USB.println(PWR.getBatteryVolts());
    USB.println(PWR.getBatteryLevel(),DEC);
    frame.setID(node_ID);
    LoRaWAN.ON(socket);
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
        USB.println(error, DEC);
    }
    LoRaWAN.OFF(socket);    
}


void loop() {
  /*
    - Measure battery level
    - Set the sleep interval based on measured battery level
  */
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
    
    /*
      If battery level is over 40 percent:
        - Measure all parameters except PMx, and add them to a binary data frame
      If battery level is over 60 percent:
        - Same as above, with PMx included
      If battery level is above 30 percent, but below 40 percent:
        - Send only battery level
    */
    if(battery > 40){
      CO2.ON();
      NO2.ON();
      PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);  
      NO2.autoGain();
      temperature = CO2.getTemp();
      humidity = CO2.getHumidity();
      pressure = CO2.getPressure();
      co2concentration = CO2.getConc(MCP3421_ULTRA_HIGH_RES);
      no2concentration = NO2.getConc(MCP3421_ULTRA_HIGH_RES);
      CO2.OFF();
      NO2.OFF();
      if(co2concentration <= 0){
         co2concentration = sensorError;
      }
      if(no2concentration < 0){
         no2concentration = sensorError;
      }
      if(battery > 60){
        PMX = true;  
      } else {
        PMX = false;  
      }
      if(PMX == true){
        status = OPC_N2.ON();
        if(status == 1){
            OPC_N2.getPM(5000);
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
   
   /*
     - Display frame (for debugging purposes)
     - Convert data frame into hex, for sending over LoRaWAN
     - Use LoRaWAN module to transmit data
     - Set device to sleep mode until next measurement cycle
   */
   frame.showFrame();
   char data[frame.length * 2 + 1];
   Utils.hex2str(frame.buffer, data, frame.length);
  
    error = LoRaWAN.ON(socket);
    USB.print(F("Turning on lora. Value = "));
    USB.println(error, DEC);
    
    error = LoRaWAN.joinABP();
    USB.print(F("Joining. Value = "));
    USB.println(error, DEC);
    if (error == 0) 
    {
        error = LoRaWAN.sendUnconfirmed(PORT, data);   
        USB.print(F("Sending lora. Value = "));
        USB.println(error, DEC); 
    }
    error = LoRaWAN.OFF(socket);
    USB.print(F("Turning off lora. Value = "));
    USB.println(error, DEC);
    PWR.deepSleep(sleepInterval, RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}


