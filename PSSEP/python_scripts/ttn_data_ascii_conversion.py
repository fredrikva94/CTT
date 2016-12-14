__author__ = 'fredrikanthonisen'

from sys import stdin, stderr
import struct

def litte_to_big_endian(hex_number):
    temp = ""
    for x in range(0, len(hex_number)):
        if(x%2 != 0):
            temp = hex_number[x-1: x+1] + temp
    return temp


def battery_conversion(hex_letter):
    if hex_letter == 'A':
        return 10
    elif hex_letter == 'B':
        return 11
    elif hex_letter == 'C':
        return 12
    elif hex_letter == 'D':
        return 13
    elif hex_letter == 'E':
        return 14
    elif hex_letter == 'F':
        return 15
    else:
        return int(hex_letter)

for line in stdin:
    temp = line[36:]
    #create a list to save measurement values
    measurements = []
    #append co2 value (hex)
    measurements.append(temp[2:10])
    #append no2 value (hex)
    measurements.append(temp[12:20])
    #append temp value (hex)
    measurements.append(temp[22:30])
    #append humidity value (hex)
    measurements.append(temp[32:40])
    #append pressure value (hex)
    measurements.append(temp[42:50])
    #if node has PMx then
    if(len(temp) > 55):
        #append PM1 (hex)
        measurements.append(temp[52:60])
        #append PM2.5 (hex)
        measurements.append(temp[62:70])
        #append PM10 (hex)
        measurements.append(temp[72:80])
        #append battery (hex)
        measurements.append(temp[82:84])
    #if node does not have PMx
    else:
        #append battery value (hex)
        measurements.append(temp[52:54])

    #if node has PMX sensor, convert all values but battery level from little to big endian
    if len(measurements) == 9:
        for x in range(0, 8):
            measurements[x] = litte_to_big_endian(measurements[x])
            #use struct.unpack to convert from hex to decimal
            measurements[x] = struct.unpack('!f', measurements[x].decode('hex'))[0]
        #convert the battery level from hex to decimal (uses it's own function since it's only 2 digits)
        measurements[8] = (16*battery_conversion(measurements[8][0])) + battery_conversion(measurements[8][1])
    #if node doesn't have PMX, convert all vaues but battery level from little to big endian
    else:
        for x in range(0, 5):
            measurements[x] = litte_to_big_endian(measurements[x])
            #use struct.unpack to convert from hex to decimal
            measurements[x] = struct.unpack('!f', measurements[x].decode('hex'))[0]
        #convert battery from 2 digit hex to decimal
        measurements[5] = (16*battery_conversion(measurements[5][0])) + battery_conversion(measurements[5][1])

    #write data to file
    with open('node.txt', 'a') as data:
        data.writelines('%s ' % item for item in measurements)
        data.write('\n')
        data.close()
