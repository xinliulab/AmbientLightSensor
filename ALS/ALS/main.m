//
//  main.m
//  ALS
//
//  Created by pengzhuojun on 7/2/17.
//  Copyright © 2017 pengzhuojun. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include <stdio.h>
#include <string.h>

#import <Foundation/Foundation.h>
//Access essential data types, collections, and operating-system services to define the base layer of functionality for your app.
//https://developer.apple.com/documentation/foundation

#import <IOKit/IOKitLib.h>
//https://developer.apple.com/documentation/iokit/iokitlib.h


io_connect_t dataPort;

enum
{
    kGetSensorReadingID   = 0,  // getSensorReading(int *, int *)
    kGetLEDBrightnessID   = 1,  // getLEDBrightness(int, int *)
    kSetLEDBrightnessID   = 2,  // setLEDBrightness(int, int, int *)
    kSetLEDFadeID         = 3,  // setLEDFade(int, int, int, int *)
};

void creatFile (void)
{
    
    // Build the path, and create if needed.
    NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* fileName = @"myTextFile.txt";
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:fileName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath])
    {
        [[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];
    }
}

void writeStringToFile (NSString* aString)
{
    NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* fileName = @"myTextFile.txt";
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:fileName];
    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:fileAtPath];
    // The main act...
    [myHandle seekToEndOfFile];
    //[[aString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileAtPath atomically:NO];
    [myHandle writeData:[aString dataUsingEncoding:NSUTF8StringEncoding]];

}

int main (int argc, const char * argv[])
{
    // argc means argument count, i.e. the number of strings pointed to by argv
    // for example, running the a program like this: ./test a1 b2 c3
    // argc = 4; argv[0] = "./test"; argv[1] = "a1"; argv[2] = "b2"; argv[3] = "c3";
    
    @autoreleasepool
    {
        kern_return_t kr = KERN_FAILURE;
        io_service_t serviceObject;
        // IOService The base class for most I/O Kit families, devices, and drivers.
        // Look up a registered IOService object whose class is AppleLMUController
        
        serviceObject = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleLMUController"));
        // AppleLMUController is the definition of ambient light sensor
        
        if (serviceObject)
        {
            NSLog(@"Got device AppleLMUController");
            kr = IOServiceOpen(serviceObject, mach_task_self(), 0, &dataPort);
        }
        
        IOObjectRelease(serviceObject);
    
        if (kr == KERN_SUCCESS)
        {
            NSLog(@"IOServiceOpen succeeded");
            creatFile();
            while (1)
            {
            
                //Get the ALS reading
                uint32_t scalarOutputCount = 2;
                uint64_t values[scalarOutputCount];
                //kern_return_t IOConnectCallMethod
                //(
                //  mach_port_t connection,
                //  uint32_t selector,
                //  const uint64_t *input,
                //  uint32_t inputCnt,
                //  const void *inputStruct,
                //  size_t inputStructCnt,
                //  uint64_t *output,
                //  uint32_t *outputCnt,
                //  void *outputStruct,
                //  size_t *outputStructCnt
                //);
                kr = IOConnectCallMethod(dataPort,
                                         kGetSensorReadingID,
                                         nil,
                                         0,
                                         nil,
                                         0,
                                         values,
                                         &scalarOutputCount,
                                         nil,
                                         0);
            
                // Get the LED reading
                uint32_t scalarInputCountKB  = 1;
                uint32_t scalarOutputCountKB = 1;
                uint64_t in_unknown = 0, out_brightness;
            
                kr = IOConnectCallMethod(dataPort,
                                         kGetLEDBrightnessID,
                                         &in_unknown,
                                         scalarInputCountKB,
                                         nil,
                                         0,
                                         &out_brightness,
                                         &scalarOutputCountKB,
                                         nil,
                                         0);
            
                // The code at http://google-mac-qtz-patches.googlecode.com/svn-history/r5/trunk/AmbientLightSensor
                // suggests that values be calibrated to 0x00FFFFFF for the MacbookPro5 family and 1600 otherwise
                // This seems too low.
                // Output as high as 67,092,480 (0x03ffc000) has been observed on my Macbook 5,2
                // So I'll report the raw value instead and remove the calibration code.
                // Also since for the MBP5,2 the two values agree
                // (there is only one ALS sensor) I'll report only the maximum value.
            
                // The LED value however does seem to go 0-4091 though the values do not seem fixed.
                // They vary with light level and time such that maxing it out results in slightly
                // lower values over time.
                // Somewhere between 2,500,000 and 3,000,000 the KB light turns off. It's hard to capture it since the light ramps off.
            
                printf("\n %llu %llu %llu      ", values[0],values[1], out_brightness);
                
                NSString *strFromInt = [NSString stringWithFormat:@"\n%llu",values[0]];
                
                writeStringToFile(strFromInt);
                
                // if we pass in `now` as an arg, only report 1 value
                if(argc > 1 && strcmp("now", argv[1]) == 0)
                {
                    break;
                }
            
                sleep(1); //lame way to slow down the output
                // 67092480 - 3FFC000
                // 66381120
                // 7670340
                // 5588100
                // 4802400 - 494760
                // 2445300
                // 2062080
                // 1531980
                // 1276740
                // 1021320
                // 893520 - DA250
                // 765900 - BAFCC
                // 638100 -
                // 549720
                // 510660 - 7CAC4
                // 422100
                // 402480
                // 382860 - 5D78C
                // 274680
                // 271800
                // 255240 - 3E508
                // 135900
                // 127440
                // 127260
                // 0
            }
        }
    }
    return 0;
}
