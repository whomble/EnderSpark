# WireEDM

Wire EDM uses electrical discharges to cut any conductive materials (brass, steel, aluminium even tungsten carbide) with no mechanical forces, enabling high precision, deep cuts, and machining of hard or delicate materials without deformation. 
This project demonstrates how to build a DIY wire EDM machine using salvaged components from an old 3D printer and other affordable parts, keeping the total cost around 150€ + the ender 3 and less than 30h of work.

The machine's frame and motion system leverage the hardware of the Ender 3,  with 1:51 gear reductions on the X and Y axes to enable extremely slow and precise movements required for EDM. 
A Raspberry Pi Pico clone with a TC4428 and a powerful MOSFET are used to switch up to 10A at 50KHz

This project includes guidance on generating toolpaths using a modified post processor from Fusion 360
Depending on the availability of tools and salvaged materials, replication costs may vary slightly. This project took me a few hundreds of hours of developpment but you should be able to replicate in less than 30h.

# Part list


| Part | Quantity | Cost |
|- | - | - |
| Arduino uno + CNC shield + DRV8825  | 1 | 15€ |
| M3 * 10mm screws | 100 | 4€ |
| M3 * 8mm screws| 50 | 2€ |
| Linear rail MGN12H 300mm | 4 | 60€ |
| Linear rail MGN12H 150mm | 2 | 20€ |
| Additionnal block for linear rail MGN12H | 2 | 15€ |
| T8 lead screw pitch 2mm lead 2mm 400mm with anty backlash | 1 | 10€ |
| T8 lead screw pitch 2mm lead 2mm 350mm with anty backlash | 2 | 15€ |
| T8 lead screw pitch 2mm lead 2mm 200mm with anty backlash | 1 | 5€ |
| Ball bearing KP08 | 4 | 6€ |
| Ball bearing KFL08 | 4 | 6€ |
| 3W warm white LED | 2 | 1€ |
| Nema 17 0.59N.m at least | 4 | 50€ |
| 5 * 8 aluminium coupler | 4 | 4€ |
| GT2 20 to 60 pulley kit with 200mm belt | 1 | 4€ |
| 500W spindle with controller | 1 | 80€ |
| M3 insert for plastic | 50 | 3€ |
| M4 wood insert | 50 | 2€ |
| 10mm cable sleeve | 5m | 5€ |
| 12V 150W power supply | 1 | 15€ |
| Lithium grease | 1 | 5€ |
| Total | a lot | 327€ |

In addition you need to find something to build the base on like aluminium extrusion, if you can found from second hand it can cost something like 40€ otherwise it's more like 80€. Even if it looks stiff 2020 extrusion from 3D printer can bend en vibrate with this type of machine so I'll recommand to use at least 30mm thick aluminuim extrusion.
You will also need 8mm thick aluminium plate about 200 * 200mm again if you can found some from second hand it can be really cheap.
T nut for aluminium extrusion could be added to the list (to fix the linear rails) but it's quite expensive and there isn't much load in this direction so i've 3D printed my own and add m3 inserts

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


# Conception

![image](https://github.com/user-attachments/assets/fe1162ec-6423-45ec-9d0a-92f5aba33980)
