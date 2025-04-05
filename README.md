# WireEDM

Wire EDM uses electrical discharges to cut any conductive materials (brass, steel, aluminium even tungsten carbide) with no mechanical forces, enabling high precision, deep cuts, and machining of hard or delicate materials without deformation. 
This project demonstrates how to build a DIY wire EDM machine using salvaged components from an old 3D printer and other affordable parts, keeping the total cost around 150€ + the ender 3 and less than 30h of work.

The machine's frame and motion system leverage the hardware of the Ender 3,  with 1:51 gear reductions on the X and Y axes to enable extremely slow and precise movements required for EDM. 
A Raspberry Pi Pico clone with a TC4428 and a powerful MOSFET are used to switch up to 10A at 50KHz

This project includes guidance on generating toolpaths using a modified post processor from Fusion 360
Depending on the availability of tools and salvaged materials, replication costs may vary slightly. This project took me a few hundreds of hours of developpment but you should be able to replicate in less than 50h.

The conversion from a 3D printer to a wire EDM can be done in 6 steps:
- Mechanical modifications
- Wire feeder
- Firmware update (marlin)
- Ark generator
- Water loop
- Fusion 360 post processor

The full part list with some products link is in the #parts folder

| Part | Quantity | Cost |
|- | - | - |
| Raspberry pi pico  | 1 | 15€ |
| Linear rail MGN12H 300mm | 2 | 30€ |
| M3*8 screws | 30 | 30€ |
| M3 T nuts| 1 | 30€ |
| M5*16 screws | 8 | 30€ |
| M6*12 screws | 2 | 30€ |
| M4*12 screws | 5 | 30€ |
| Nema 17 gearbox 1:51 | 2 | 30€ |
| 24V membrane pump | 1 | 30€ |
| Filter cardridge | 2 | 30€ |
| Filter holder| 2 | 30€ |
| 6mm pipes | 2 | 30€ |
| Push pull connector | 8 | 30€ |
| Waterblock | 2 | 30€ |
| TC4428 | 2 | 30€ |
| IRF135B203 | 2 | 30€ |
| 4.7uF polymer capacitor | 2 | 30€ |
| Buck converter | 2 | 30€ |
| Acrylic sheet (3*235*635mm) | 1 | 30€ |
| Oled screen | 1 | 30€ |
| L7812CV| 1 | 30€ |
| JST connectors | 1 | 30€ |
| Banana connectors | 1 | 30€ |
| Wire diodes resistor | 1 | 30€ |
| Aluminium parts | 1 | 30€ |
| Brass wheel | 1 | 30€ |
| Ceramic bearings | 1 | 30€ |
| Bearings | 1 | 30€ |
| PLA ~200g | 1 | 30€ |
| Total | a lot | 327€ |

# WARNiNGs 
The voltage is lower than the SELV (50V for AC 120V for DC) in DRY CONDITIONS, for WET CONDITION the SELV is (25V for AC and 60 for DC). In addition there is no GFCI to protect you so disconnect the PSU everytime you're planning to touch a metalic component and wear at leat nitrile gloves. If you don't know precisely what you are doing just skip this project.

<img src="Photos/electicity.jpeg" width="400">


Copper is consiered as a heavy metal, the best way to deal with the dirty water is to let it sit for a while in a ventilated area to evaporate all the water, after that it's jsut metal powder and can be disposed in the local recycling center.


# Mecanical parts
## Motion

A big advantage of wire EDM compared to CNC milling is that the frame doesn't need to be very stiff, the hardware just need to support the wire feeder on the X axis and the water tank ~4kg on the Y axis. The Z axis isn't used during the cutting process but it's quite usefull to help changing the wire.

I've had a linear rail (MGN12H) on X and Y axis, it can be bolted directly on X axis with T nuts and for the why axis you need to drill 4 holes in the buildplate support thats all.
Wire EDM can be very slow depending on the thickness so one of the most important requirement is to be able to move slowly at a fixed rate. Regular stepper motors aren't able to do that, even with microstepping I made a fully printable belt reducer 1:64 but it need some improvements so I've just brought gearbox for nema 17 that can be directly connected to a 2GT pulley.

## Wire feeder

The wire feeder is the only complicated part which need to be custom made because it needs to fullfill a few requierments:
- Stifness, during the cutting process the arcs can generate vibrations, to achieve a good surface finish the wire need to be very straight
- Electrically insulated, even if the cutting is done under de-ionised water some electrolysis can occur which can reduce the power output. An insulated feeder also prevent from shorts if a metal part fall between the wire and the feeder
- Grounded, at 20kHz the long wire is a big antenna which can emit a lot of parasites and damage electronics. Grounding as much part as possible is crucial to avoid that (and any risk for pacemaker users)
- Tensionner mechanism, to avoid wire vibration the wire need to be adequatly tensionned.
- Waste spool, wire edm consume the workpiece AND the wire, depending on the material it can use a lot of wire
- Hard wire guide, I you have an old ender 3 you've probably experience filament grinding the extruder even if its plastic against plastic, the same thing can happend here with soft brass




<img src="Photos/CAD.jpg" width="400">

This is the CAD of the second version, the extruder (nema 17 + a brass cylinder) is pulling the wire all the way from the tensionner. 
The tensionner conssit of two all bearing pressing into each other like a 3D printer extruder, the sping can b adjust to block more the wire and provide more tension.
Then, the wire need to be guided very precisely, for the upper guide I use a off the shelf rubis nozzle with a plastic nozzle around it for watercooling. The lower guide is a ceramic ball bearing with a PLA spacer and a .4mm brass nozzle to push the wire against the spacer. The two other ball bearings (ceramic for the lower one and steel with plastic cover for the upper one) just guide the wire to the extruder.

The ball bearings needs to be in ceramic for three reason:
1. Corosion
2. No lubricant can desovle in water
3. High hardness


The wire is connected to the (-) terminal of the PSU by the brass wheel and in the future a tungsten carbide contact block, but since the wire emit EMF like an antenna, I want to ground as much metal as I can, so the whole motor assembly is at the same potential as the wire, but the frame of the printer and the red part are grounded. The voltage arent high so a layer of epoxy or an anodization is enougth to insulate the two regions.

<img src="Photos/V1.jpg" width="300"><img src="Photos/V2.jpg" width="300">

The first version on the left use a lots of printed parts, it works but the tensionner some part can flex and reduce the wire tension/straightness so I made a second version in 5mm thick alluminium plate with 10mm thick tensionners.

All the parts are availlable in .sldprt and .step

### Spool

Wire edm as you can guess consume wire, so I need a simple way to manage the waste wire. My solution is to have the new spool of wireconnected to the waste spool with magnet so the second one can be drived by the first one. Since the first spool will get smaller and smaller and the second bigger and bigger, the first one will have to turn way fater to maintain a tension. With this configurtion, the first spool has a way smaller inner diameter which made it spin fzster at any moment. The magnets act like a clutch to maintain constant load at variable speeds.

<img src="Photos/spool.JPG" width="300">


# Electronics
## generator

It's actually pretty easy to make an arc for EDM, it won't be as powerfull as a commercial machine but pretty close. We just need to switch a powerfull MOSFET on and of very fast, I use the IRF135B203 wich can handle 135V 129A and 500A peak. The mosfet is drived by a TC4428 with a schotcky diode to protect the IC a square pwm signal is generated by the pi pico, the pico code is optimised to generate the wave as fast as possible.


![image](https://github.com/user-attachments/assets/f70182c3-5eb5-4c20-92ec-79943a7b8fd9)


## Power managment 

The power supply should be able to deliver at least 5A, 48V is enougth to cutt alluminium but a higher voltager means a higher energy stored in the capacitors (E = 1/2C U²). If you plan to cut copper or steel you can buy a switch mode power supply with adjustable output (mine can go up to 110V).

In the best case scenario, each pulse will create an arc and remove some matter but in realitty sometimes the wire is too far to create a spark and sometimes the wir eis in direct contact and will create a (momentary) short circuit. In the future I will make a short circuit detection system but for now a serie of 100W what resistors limit the current to avoid destroing the PSU and the wire.

Last part is the capacitors, it helps deliver high current durring short amount of time. You can't use some standard electrolitic capacitor (belive me I tried) ceramic is a good option but we need very low ESR so polymer is the only suitable option. In my setup I use 4x 4.7uF in parallel so ~20uF rated for 200V.

These 3 main components are connected to a waterblock for cooling, in my experience it's a bit overkilled and air cooling will be enougth in the future but I need to circulate the water anyway so...


# Water

The EDM process must be done under a dielectric fluid, it can be ethanol, oil or kerosene but the easyest solution is obviously deionised water. Water is also used for cooling (the electrical components and the workpiece) and chip evacuation. The "builtplate" is a water tank made out of acrily sheets welded with aceton and a bit of silicone for etancheity. I've also add a steel shit so I can quickly remove it from my magnetic buildplate.

EDM generate a ton of small metalic particles which needs to be filter during the cutting, The best pump I've found is a membrane pump which can provide high pressure (necessary for good filtration) and is quite silent when underpowered, it's design for 24V and I power it between 5-7V depending on the material. The filter is a standard polyester coton filter <0.1um in a cardrige in the future I'll probably try washables filters like ceramic or stainless steel. I use push pull and 6mm tubes for all my connection except for the nozzle its a 4mm.

After each cuts I put the deionised water in it's original tank for decantation, and separate the "pure" water from the dirty one a few days later.

Copper is consiered as a heavy metal, the best way to deal with the dirty water is to let it sit for a while in a ventilated area to evaporate all the water, after that it's jsut metal powder and can be disposed in the local recycling center.


# Firmware modifications


# Toolpath generation





Some more commun supply are also needed like heat shrink tube, solder, wires (I use wires from old RJ45 cable it can handle something like 5A without a problem, its free nd easly accessible).

A lots of tools are needed to work properly:

- Soldering iron
- Drill press
- Caliper
- Dial indicator
- Heat gun
- A good square rule
- Handed metal saw 
- Metal band saw (if your alumiun extrusions needed to be with a perfect 90° angle)
- Hand drill
- Center punch
- Marker for metal
- Hammer, clamps, screw drivers others hand tools
- 3D printer
- deburr tool



