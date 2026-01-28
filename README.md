# **Real-Time Image Processing on FPGA Board**

## **Overview**

This project implements a complete **real-time image processing system** on FPGA, capturing live video from OV7670 camera, processing frames in hardware, and displaying results on VGA with low latency. Built in **Verilog HDL** for **Xilinx ZedBoard**, it leverages FPGA parallelism for operations impossible in software at real-time speeds.

**Pipeline**: Camera Input → FPGA Processing → VGA Display (640×480@60Hz)

## **System Functionality**

Continuous real-time video streaming:

- OV7670 captures live RGB frames
- FPGA processes pixels in single-cycle pipeline
- VGA displays processed video instantly

## **Supported Operations**

Runtime-selectable pixel & convolution filters:

| **Operation**          | **Description**                                  |
|------------------------|--------------------------------------------------|
| **RGB to Grayscale**   | Weighted RGB→intensity conversion                |
| **Brightness Adjust**  | Fixed offset addition/subtraction                |
| **Color Inversion**    | Pixel-wise negative image                        |
| **Average Blur**       | 3×3 neighborhood averaging                       |
| **Gaussian Blur**      | Edge-preserving weighted smoothing               |
| **Sobel Edge Detect**  | Horizontal/vertical gradient detection           |
| **Laplacian Edge**     | Second-derivative edge enhancement               |
| **Sharpen Filter**     | Center-pixel edge boosting                       |
| **Emboss Filter**      | 3D directional gradient effect                   |

## **Technical Architecture**

Modular streaming dataflow:

OV7670 → Async FIFO → Line Buffers → Convolution Core → VGA Controller


- **Camera Interface**: OV7670 config + RGB streaming
- **FIFO Buffer**: Clock domain crossing
- **Line Buffers**: 3×3 windows for convolutions
- **Grayscale Engine**: Hardware RGB→YUV conversion
- **Processing Core**: Parallel filters (1 pixel/clock)
- **VGA Controller**: 640×480@60Hz timing

## **Performance & Resources**

**Target: Xilinx ZedBoard (Zynq-7000)**

| **Resource**     | **Utilization** |
|------------------|-----------------|
| **LUTs**         | ~750            |
| **Flip-Flops**   | ~230            |
| **DSP Slices**   | 2               |
| **BRAM**         | Line buffers    |

**Real-time**: 60 FPS, fully pipelined.

## **Development Tools**

- **Design/Synthesis**: Xilinx Vivado
- **Simulation**: Vivado Simulator/ModelSim
- **Hardware**: ZedBoard + OV7670 + VGA monitor

## **Author**

**Shubham Kumar Jha**  
Dept. of Electronics & Communication Engineering  
**Jaypee Institute of Information Technology (JIIT), Noida**
