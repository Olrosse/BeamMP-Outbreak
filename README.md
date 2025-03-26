
# BeamMP Outbreak/Infection

This is a recreation of the Infection game mode from Dirt 3 for BeamMP

## BeamMP Installation

1. Download the newest version from the release page
1. Open the zip and put what's in the Client folder into your server's "Resources/Client" folder and Server files into "Resources/Server"
1. Then to start infection you can type /outbreak start or /infection start into the in game chat and hit enter
1. A full list of commands can be found with /outbreak help or /infection help

## Server Chat Commands

1. ```/infection help``` Displays List of available commands
1. ```/infection start``` Starts infection game
1. ```/infection stop``` Stops infection game
1. ```/infection reset``` Resets randomizer weights so everyone has an equal chance of getting infected again
1. ```/infection game length set``` Sets the length of the round in minutes
1. ```/infection greenFadeDist set``` Adjusts how close in meters an infected car needs to be for the screen to start going green
1. ```/infection filterIntensity set ``` Sets how intense the vignetting effect is
1. ```/infection ColorPulse toggle``` Enabling this makes the infected cars pulse between green and the original color of the car
1. ```/infection infector tint toggle``` This toggles on or off the vignetting effect on infected players
1. ```/infection ResetAtSpeedAllowed toggle``` This toggles whether players can reset at speed
1. ```/infection MaxResetSpeed set``` Sets the highest speed where resets are allowed

## Special thanks to

1. [Stefan750](https://github.com/stefan750) for some help with colors and for making the vignette shader
1. [Saile](https://github.com/saile515) for help with the weighted randomizer
1. And also thanks to the [Neilogical](https://www.youtube.com/@Neilogical)/[Camodo](https://www.youtube.com/@CamodoGaming) crew as well as the [Failrace](https://www.youtube.com/@FailRace) crew for feedback and testing.

## Some notes

this build may not be very suitable for public servers yet as it is very easy to cheat, but it's good for private servers where you might have some personalized rules haha

Also feel free to use this mod as reference if you want to make your own game modes, it's not the best documented and there's probably some wacky code haha, but maybe it's helpful for some