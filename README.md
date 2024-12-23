# WireEDM

Wire EDM (Electrical Discharge Machining) uses electrical arcs to cut any conductive materials (brass, steel, aluminium even tungsten carbide) with no mechanical forces, enabling high precision, deep cuts, and machining of hard or delicate materials without deformation. This project demonstrates how to build a DIY wire EDM machine using salvaged components from an old 3D printer and other affordable parts, keeping the total cost around 100€ + the ender 3. 

The machine's frame and motion system leverage the hardware of the Ender 3, enhanced with 1:51 gear reductions on the X and Y axes to enable extremely slow and precise movements required for EDM. A Raspberry Pi Pico clone serves as the control unit, driving the system with custom firmware. For high-frequency current switching, the setup includes a powerful MOSFET controlled by a TC4428 driver, ensuring efficient and precise discharges. Deionized water is used as the dielectric fluid, with adjustments made to keep the system functional despite frequent short circuits.

In addition to the hardware, this project includes guidance on generating toolpaths using a modified post processeur from Fusion 360, with detailed settings tailored for various materials. Depending on the availability of tools and salvaged materials, replication costs may vary slightly. This project took me a few hundreds of hours of developpment but you should be able to replicate in less than 30h.


![image](https://github.com/user-attachments/assets/fe1162ec-6423-45ec-9d0a-92f5aba33980)
