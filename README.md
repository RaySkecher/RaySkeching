# RaySkecher

This is the main repository for the code. Due to the multiple tools needed to run it, this will NOT work out of the box.

The `Vitis` folder has the necessary config and source files. `image.c` is a testbench, while `trace_path.c` is the main source file. `hls_config.cfg` WILL need to be updated/modified, as it contains an absolute directory in it.

The `Vivado` folder has multiple source files and the necessary Basys 3 constraints file. `transmitter.v` is based on `alexwonglik`'s [instructable](https://www.instructables.com/UART-Communication-on-Basys-3-FPGA-Dev-Board-Power/) guide, and modified with an LLM to have an `idle` output.

The `main.py` file serves as a UART client, and will stitch the pixels sent over the USB into an image.

There are some minor bugs, such as the first pixel not being sent, which resuls in a red line on the right side of the image. This is likely able to be resolved by either fixing the code (why would you do that?) or making the client start on the 2nd pixel. Also, the current `x, y` values are `uint8_t`, meaning they cannot go larger than 256. This is easily changeable.
