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


uint8_t socketLoRaWAN = SOCKET0;

void setup() {
    // put your setup code here, to run once:
    USB.ON();
    USB.println(F("CTT Vejle"));
    frame.setID(node_ID);
    status = OPC_N2.ON();
    if(status == 1){
        status = OPC_N2.getInfoString(info_string);
        OPC_N2.OFF();  
    }
}


void loop() {
    // put your main code here, to run repeatedly:
    CO2.ON();
    NO2.ON();
    PWR.deepSleep("00:00:02:10", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
    battery = PWR.getBatteryLevel();
    if(battery < 40){
        while(battery < 40){
            PWR.deepSleep("00:01:00:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
            battery = PWR.getBatteryLevel();
        }  
    }
    if(battery > 60){
        PMX = true;  
    } else {
        PMX = false;  
    }
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
      frame.addSensor(SENSOR_OPC_PM1, -1);
      frame.addSensor(SENSOR_OPC_PM2_5, -1);
      frame.addSensor(SENSOR_OPC_PM10, -1); 
    }
    frame.addSensor(SENSOR_BAT, battery);
    frame.showFrame();
    char data[frame.length*2 + 1];
    Utils.hex2str(frame.buffer, data, frame.length);
    
    errorLoRaWAN = LoRaWAN.ON(socketLoRaWAN);
    // Join network
    errorLoRaWAN = LoRaWAN.joinABP();
    if (errorLoRaWAN == 0) 
    {
        errorLoRaWAN = LoRaWAN.sendUnconfirmed(PORT, data);   
    }
    errorLoRaWAN = LoRaWAN.OFF(socketLoRaWAN);
    PWR.deepSleep("00:00:04:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
