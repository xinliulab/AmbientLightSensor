# Ambient Light Sensor
**Target:** Single Pixel Imaging By Ambient Light Sensor

**Author:** Xin Liu

**Date:** 6.2017 ~ 8.2017

**Status:** Failure

## File Description：
**als4MacOS.m**

It runs on the MacOS. 


**als4SensorTag.c**

It runs on the TI CC2650 Sensor Tag.


**movingLight.py**

It is used to create a moving white square on the monitor. Then the ALS can sense the white light emitted from the square and reflected by the object before the monitor.   

##  Reasons for Faliure:

* Filed of View


The FoV for the ALS, which is built in the MacBook or the phone, is very small. Besides, most of the diffusion reflection is not towards the ALS. Therefore, after the reflection, except for a small part of light emitted by the middle part of the monitor, most of the light emitted by the other parts of the monitor can not be sensed by the ALS.  

* Reflection Characteristics of Objects


The diffusion lightness is weak for the size and color of the object which the reflection is on. If the square displaying on the monitor is small, we may get many details of the object, but we will also probably get nothing for the weak lightness. If the square is big, we may lose many details of the object, but we can get some valuable ALS reading at least.


* Repose Time


Since the ALS is to match human's eyes, the response time is over 100 ms, i.e. 10-Hz, so that the effects of 50-Hz and 60-Hz noise sources from typical light bulbs are nominally reduced to a minimum. Therefore, it is too slow to recognize the gestures or activities. 





