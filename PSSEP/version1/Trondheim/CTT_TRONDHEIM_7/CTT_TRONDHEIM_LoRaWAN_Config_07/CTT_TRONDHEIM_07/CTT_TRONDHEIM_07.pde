#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>

Gas CO2(SOCKET_A);
float co2concentration;
boolean co2measure = false;
uint8_t error;
int battery;
uint8_t errorLoRaWAN;
uint8_t socket = SOCKET0;
char node_ID[] = "TKCTT07";
uint8_t PORT = 3; // Port to use in Back-End: from 1 to 223
int unconnected = -99;
char *sleepInterval;

char DEVICE_EUI[] = "000000001B1A8C66";
char DEVICE_ADDR[] = "1B1A8C66";
char NWK_SESSION_KEY[] = "AF69701983CDF4C1626DA5A584CC3F50";
char APP_SESSION_KEY[] = "1AC0EB0C95AB4932BD3AC5A8A6FADFF5";


uint8_t socketLoRaWAN = SOCKET0;

void setup() {
    // put your setup code here, to run once:
    USB.ON();
    USB.println(F("CTT TRONDHEIM"));
    frame.setID(node_ID);
    USB.println(F("CTT TRONDHEIM node LoRaWAN configuration"));
    
    //Turn the switch on
    error = LoRaWAN.ON(socket);
    if(error == 0){
        USB.println(F("LoRaWan switch turned ON."));  
    } else {
        USB.print(F("Error when turning ON LoRaWAN switch. Error code: "));
        USB.println(error, DEC);
    }
    
    //Reset to factory settings
    error = LoRaWAN.factoryReset();
    if(error == 0){
        USB.println(F("Module is now set to factory default values."));  
    } else {
        USB.print(F("Error when setting module to factory default values. Error code: "));
        USB.println(error, DEC);
    }
    
    //Set the Device EUI
    error = LoRaWAN.setDeviceEUI(DEVICE_EUI);
    if(error == 0){
        USB.println(F("The device EUI is now set to defined value."));  
    } else {
        USB.print(F("Error when setting the device EUI. Error code: "));
        USB.println(error, DEC);
    }
    
    //Retrieve the device eui
    error = LoRaWAN.getDeviceEUI();
    if(error == 0){
        USB.print(F("Successfully retrieved the Device EUI. DEVICE EUI: "));
        USB.println(LoRaWAN._devEUI);  
    } else {
        USB.print(F("Error when retrieving the device EUI. Error code: "));
        USB.println(error, DEC);
    }
    
    //Set the device address
    error = LoRaWAN.setDeviceAddr(DEVICE_ADDR);
    if(error == 0){
        USB.println(F("The device address is now set to defined value."));  
    } else {
        USB.print(F("Error when setting the device address. Error code: "));
        USB.println(error, DEC);
    }
    
    //Retrieve the device address
    error = LoRaWAN.getDeviceAddr();
    if(error == 0){
        USB.print(F("Successfully retrieved the device address. Device address: "));  
        USB.println(LoRaWAN._devAddr);
    } else {
        USB.print(F("Error when retrieving the device address. Error code: "));
        USB.println(error, DEC);
    }
    
    //Set the network session key to the defined value
    error = LoRaWAN.setNwkSessionKey(NWK_SESSION_KEY);
    if(error == 0){
        USB.println(F("The network session key is now set to the provided value."));     
    } else {
        USB.print(F("Error when setting the network session key. Error code: "));
        USB.println(error, DEC);
    }
    
    //Set Application Session Key to the defined value
    error = LoRaWAN.setAppSessionKey(APP_SESSION_KEY);
    if(error == 0){
        USB.println(F("The application session key is now set to the defined value."));     
    } else {
        USB.print(F("Error when setting the application session key. Error code: ")); 
        USB.println(error, DEC);
    }

    //Set retransmissions for uplink confirmed packet
    error = LoRaWAN.setRetries(7);
    if(error == 0){
        USB.println(F("Th retransmissions for uplink confirmed packet are now set."));     
    } else {
        USB.print(F("Error when setting the retransmissions for uplink confirmed packet. Error code: ")); 
        USB.println(error, DEC);
    }
    
    //Retrieve the retries
    error = LoRaWAN.getRetries();
    if(error == 0){
        USB.print(F("Successfully retrieved the transmissions for uplink confirmed packet, ")); 
        USB.print(F("TX retries: "));
        USB.println(LoRaWAN._retries, DEC);
    }
    else 
    {
      USB.print(F("Error when retrieving the transmissions for uplink confirmed pcket. Error code: ")); 
      USB.println(error, DEC);
    }

    uint32_t freq = 867100000;    
    for (uint8_t ch = 3; ch <= 7; ch++){
        error = LoRaWAN.setChannelFreq(ch, freq);
        freq += 200000;
        if(error == 0){
            USB.println(F("The frequency channel is now set."));     
        } else {
            USB.print(F("Error when setting the frequency channel. Error code: ")); 
            USB.println(error, DEC);
        }
     }
    
    //Set the Duty Cycle for specific channel
    for (uint8_t ch = 0; ch <= 2; ch++){
        error = LoRaWAN.setChannelDutyCycle(ch, 33333);
        if(error == 0){
            USB.println(F("The duty cycle channel is now set."));     
        } else {
            USB.print(F("Error when setting the duty cycle channel. Error code: ")); 
            USB.println(error, DEC);
        }
    }
  
    for (uint8_t ch = 3; ch <= 7; ch++){
        error = LoRaWAN.setChannelDutyCycle(ch, 40000);
        if(error == 0){
            USB.println(F("The duty cycle channel is now set."));     
        } else {
            USB.print(F("Error when setting the duty cycle channel. Error code: ")); 
            USB.println(error, DEC);
        }
    }
  
    // 11. Set Data Range for specific channel. (Recomemnded)
    // Consult your Network Operator and Backend Provider
    //////////////////////////////////////////////
  
    for (int ch = 0; ch <= 7; ch++)
    {
      error = LoRaWAN.setChannelDRRange(ch, 0, 5);
    
      // Check status
      if( error == 0 ) 
      {
        USB.println(F("11. Data rate range channel set OK"));     
      }
      else 
      {
        USB.print(F("11. Data rate range channel set error = ")); 
        USB.println(error, DEC);
      }
    }
  
    //Set the Data rate range for specific channel
    for (int ch = 0; ch <= 7; ch++){
        error = LoRaWAN.setChannelStatus(ch, "on");
        if( error == 0 ) 
        {
            USB.println(F("The channel status is now set."));     
        } else {
            USB.print(F("Error when setting the channel status.")); 
            USB.println(error, DEC);
        }
    }
  
    //Save the configurations
    error = LoRaWAN.saveConfig();
    if(error == 0){
        USB.println(F("The configuration is now saved."));     
    } else {
        USB.print(F("Error when saving the configuration. Error code: ")); 
        USB.println(error, DEC);
    }
  
    USB.println(F("Finito!"));
}


void loop() {
    battery = PWR.getBatteryLevel();
    if(battery >= 60){
        sleepInterval = "00:00:08:00";
    } else if(battery > 40 && battery < 60){
        sleepInterval = "00:01:00:00";
    } else {
        sleepNow(battery);
        sleepInterval = "00:00:08:00";
        
    }
    
    USB.print(F("Battery level: "));
    USB.println(battery, DEC);
    
    if(battery > 45){
      co2measure = true;
      CO2.ON();
      PWR.deepSleep("00:00:02:10", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);  
    }

    co2concentration = CO2.getConc(MCP3421_ULTRA_HIGH_RES);
    CO2.OFF();
    if(co2concentration <= 0 || co2measure == false){
        co2concentration = -99.0;
    }

    frame.createFrame(BINARY);
    frame.addSensor(SENSOR_GP_CO2, co2concentration);
    /*frame.addSensor(SENSOR_GP_NO2, unconnected);
    frame.addSensor(SENSOR_GP_TC, unconnected);
    frame.addSensor(SENSOR_GP_HUM, unconnected);
    frame.addSensor(SENSOR_GP_PRES, unconnected);
    */
    frame.addSensor(SENSOR_BAT, battery);
    frame.showFrame();
    char data[frame.length * 2 + 1];
    Utils.hex2str(frame.buffer, data, frame.length);
    
    errorLoRaWAN = LoRaWAN.ON(socketLoRaWAN);
    USB.println(LoRaWAN._devAddr);
    USB.println(LoRaWAN._devEUI);
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
    PWR.deepSleep(sleepInterval, RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}

void sleepNow(int battery){
  while(battery <= 40){
    PWR.deepSleep("00:24:00:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
    battery = PWR.getBatteryLevel();
  }
}
  
