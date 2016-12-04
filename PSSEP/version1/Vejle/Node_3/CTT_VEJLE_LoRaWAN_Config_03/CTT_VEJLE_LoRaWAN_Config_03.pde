#include <WaspLoRaWAN.h>

//Define the node id for the data frame
char node_ID[] = "VJCTT03";

//Define LoRaWAN Parameters
char DEVICE_EUI[] = "";
char DEVICE_ADDR[] = "";
char NWK_SESSION_KEY[] = "";
char APP_SESSION_KEY[] = "";
uint8_t PORT = 3;
uint8_t SOCKET = SOCKET0;

//Used to store error codes
uint8_t error;

void setup() {
    // put your setup code here, to run once:
    USB.ON();
    USB.println(F("CTT Vejle node LoRaWAN configuration"));
    
    //Turn the switch on
    error = LoRaWAN.ON(SOCKET);
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
    //upload the other code...

}

