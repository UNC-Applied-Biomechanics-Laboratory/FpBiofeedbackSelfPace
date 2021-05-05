# FpBiofeedbackSelfPace

Run a Bertec split belt treadmill in self-pace mode and with Fp biofeedback. Uses Matlab-Cortex sdk (included). 

![SelfPace](/img/SelfPace.png)
## Self-Pace Mode
During self-pace mode, participants started walking on a split-belt treadmill at their preferred overground speed. Using a Matlab script in real time, we recorded their instantaneous centers of pressure (CoPs) from each belt (left and right) and averaged the sides to estimate their relative fore/aft position on the treadmill (yellow dot & line). When the participant stayed centered on the treadmill (i.e., the average CoP stayed within a 20 cm “dead zone” at the center of the treadmill), the speed would not change. But when the participant (and thus the average CoP) moved anterior/posterior of the dead zone, the treadmill speed would increase/decrease linearly with the distance from center. We ensured patients could increase and decrease treadmill speed on command prior to any data collection.  

![SpeedFpClamp](/img/SpeedFpClamp.png)
## Fp Biofeedback
Participants walked at their typical, overground walking speed (Norm) as well as ±10% and ±20% of Norm. During these 5-minute, fixed-speed trials (speed clamp), we measured and averaged FP over the duration of the trial. During another set of five 5-minute trials, we used targeted biofeedback and the self-paced treadmill mode to clamp (i.e., hold steady) walking FP. Here, we asked participants to target each of their average FPs from the speed clamp while allowing participants to naturally adjust their walking speed to maintain a normal gait pattern. 