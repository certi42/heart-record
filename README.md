# HeartRecord
HeartRecord is an iPhone and Apple Watch app which records [various data](##Data "various data"), and can transmit that data in a variety of different ways.

## Data
### Data Types
The data recorded are heart-rate, acceleration, and rotation rate.
**Heart Rate** -- The app receives updates every five seconds from the HealthStore. Measured in beats per minute (bpm).
**Acceleration** -- Fetches acceleration at the specified frequency. Measured in Gs (9.81 m/s<sup>2</sup>)
**Rotation Rate** -- Fetches rotation rate at the specified frequency. Measured in rad/s (radians per second).

### Data Format

The data is formatted as a CSV (comma separated value) file. The header is as follows: `date, x_acc, y_acc, z_acc, x_gyro, y_gyro, z_gyro, heart_rate`
The date column is measured in microseconds since January 1, 1970 UTC. For the first five seconds of a recording, there will be no heart-rate value, so the heart_rate column will be -1.

## Sending Data
Once data has been collected and sent to the iPhone, there are a variety of ways to transmit the data off of the device. 

**Email** -- Tapping the "Email Data" button on the iPhone app will create an email dialog which allows the user to specify an email address, and the email will have the data attached as a .zip file.

**HTTP POST** -- This will send the data in the body of a HTTP POST request, to the address which was specified in the app's settings. 

**Share** -- This makes use of iOS's built in Share dialog, which allows for options like AirDrop, sending vial Messages or Mail, or saving the data to Files.

## Built-in Settings
### iPhone
![iPhone Settings Pane](http://www.github.com/certi42/heart-record/Images/iphone-settings.jpeg "iPhone Settings Pane")
**Patient ID** -- Specifies unique identifier which applies to the patient whose data is being recorded. This is used to specify the folder name on Blackfynn to which the data should be uploaded.

**Haptic Feedback** -- By default, while the app is open, the iPhone will buzz whenever receives data from the Apple Watch. This setting specifies whether or not this should happen.

**Server Address** -- Specifies the web address to which data will be sent if the HTTP POST method is used.

**Include Date in File Name** --

**File Name** -- Specifies the name of the file which will be used if the **Save Data** option is turned on.

**Save Data** -- Specifies whether or not the data should be saved on the iPhone instead of transmitted. Currently not implemented. 

### Apple Watch
![Apple Watch Settings Pane](http://www.github.com/certi42/heart-record/Images/watch-settings.jpeg "Apple Watch Settings Pane")

**Automatically Post Data** -- Specifies whether or not data from the Apple Watch should be automatically transmitted to the iPhone. Data transmitted this way is always forwarded to the server address specified in the iPhone settings.

**Post Interval** -- Specifies the length of time to wait between sending data to iPhone, if the **Automatically Post Data** setting is turned on. The options are 1, 3, 5, 7, 9, 11, 13, and 15 minutes.

**Recording Frequency** -- The frequency at which accelerometer and gyroscope data are recorded. The options are 10, 20, 30, 40, 50, 60, 70, and 80 Hz. 

## Licence Information
The Zip module is provided under the MIT licence. 
