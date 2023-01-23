# ibex_wb
RISC-V Ibex core with Wishbone B4 interface.

## Design
The instruction and data memory interfaces are converted to
Wishbone.
[These examples](https://github.com/pbing/ibex_wb/tree/master/sim) use shared bus
interconnection between masters (instruction bus, data bus) and slaves (e.g. memory, LED driver).
For better throughput or latency a crossbar interconnect can be considered.


## Ibex memory control vs. Wishbone bus

### Basic Memory Transaction
<p align="center"><img src="doc/images/timing1.svg" width="650"></p>

### Back-to-back Memory Transaction
<p align="center"><img src="doc/images/timing2.svg" width="650"></p>

### Slow Response Memory Transaction
<p align="center"><img src="doc/images/timing3.svg" width="650"></p>


## Status
Simulated with Synopsys VCS.

### Timing with uncompressed instructions
| Program    | Cycles | Instructions   | CPI  |
|------------|--------|----------------|------|
| crc_32     | 43277  | 24714          | 1.75 |
| fib        | 172    | 107            | 1.61 |
| led        | 509993 | 382481         | 1.33 |
| nettle-aes | 118693 | 63235          | 1.88 |
|            |        | mean           | 1.64 |

### Timing with compressed instructions
| Program    | Cycles | Instructions   | CPI  |
|------------|--------|----------------|------|
| crc_32     | 37105  | 23687          | 1.57 |
| fib        | 165    | 107            | 1.54 |
| led        | 509993 | 382492         | 1.33 |
| nettle-aes | 113482 | 63235          | 1.79 |
|            |        | mean           | 1.56 |

## FPGA Implementation

### Intel/Cyclone-V
[Cyclone V GX Starter Kit](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=167&No=830)

For Quartus 19.1 use branch `fpga_quartus` in submodules `common_cells`, `ibex` and`riscv-dbg`.

### Xilinx/Artix-7
[Arty A7-100T](https://www.xilinx.com/products/boards-and-kits/1-w51quh.html)

For Vivado 2019.2 use branch `master` in all submodules.

## Recources
- [Wishbone at opencores.org](https://opencores.org/howto/wishbone)
- [ZipCPU](http://zipcpu.com/zipcpu/2017/11/07/wb-formal.html) for a deeper understanding of the pipelined mode.

