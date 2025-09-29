# I2C-Protocol
This repository contains a custom I²C protocol implementation written in Verilog/SystemVerilog. The design supports both master and slave modes, with additional features that closely follow the I²C specification

## Features

**Multi-Master Support with Arbitration**
Implements proper arbitration handling when multiple masters attempt to drive the bus simultaneously.
Masters retry gracefully upon losing arbitration.

## **Clock Stretching**
Slave devices can hold SCL low to delay data transfer until they are ready.
Master releases the clock line when slaves stretch the clock.
Start, Stop, and Repeated Start Conditions
Handles correct bus signaling for transaction control.

## **7-bit Addressing**
Supports standard 7-bit slave addressing.

## **Read and Write Operations**
Byte-level read/write functionality with ACK/NACK signaling.

## **Open-Drain SDA & SCL Implementation**
Correct tri-state behavior for bus sharing.

## **Configurable Parameters**
Clock frequency division.
Address width and slave enable control.


