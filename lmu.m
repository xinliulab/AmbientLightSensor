// Compile with $ gcc -o lmutracker lmu.m -framework IOKit -framework CoreFoundation -framework Foundation
// Usage: ./lmu [now]
// Prints out the value from the ambient light sensor and the back light LED every 1/10 of a second. Optionally print just one value.
// Inspired by the code found at 
//  http://google-mac-qtz-patches.googlecode.com/svn-history/r5/trunk/AmbientLightSensor 
//  and http://osxbook.com/book/bonus/chapter10/light/
//  and http://en.wikipedia.org/wiki/Wikipedia:Reference_desk/Archives/Computing/2010_February_10#Mac_OS_X_keyboard_backlight_drivers
// http://forums.macrumors.com/showthread.php?t=1133446

#include <stdio.h>
#include <string.h>

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>

io_connect_t dataPort;

enum {
    kGetSensorReadingID   = 0,  // getSensorReading(int *, int *)
    kGetLEDBrightnessID   = 1,  // getLEDBrightness(int, int *)
    kSetLEDBrightnessID   = 2,  // setLEDBrightness(int, int, int *)
    kSetLEDFadeID         = 3,  // setLEDFade(int, int, int, int *)
};

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    kern_return_t kr = KERN_FAILURE;
    io_service_t serviceObject; 
    
    // Look up a registered IOService object whose class is AppleLMUController  
    serviceObject = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                IOServiceMatching("AppleLMUController"));
    if (serviceObject) {
        NSLog(@"Got device AppleLMUController");
        kr = IOServiceOpen(serviceObject, mach_task_self(), 0, &dataPort);          
    }   
    IOObjectRelease(serviceObject);
    
    if (kr == KERN_SUCCESS) {
        NSLog(@"IOServiceOpen succeeded");
        
        while (1) {
            
            //Get the ALS reading
            uint32_t scalarOutputCount = 2;
            uint64_t values[scalarOutputCount];
            
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
            
            printf("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%llu %llu        ", MAX(values[0],values[1]), out_brightness); 
            
            // if we pass in `now` as an arg, only report 1 value
            if(argc > 1 && strcmp("now", argv[1]) == 0) {
              break;
            }
            
            sleep(0.1); //lame way to slow down the output
            
        }
    }
    
    [pool drain];
    return 0;
}