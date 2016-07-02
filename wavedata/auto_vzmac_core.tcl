load /opt/Xilinx/Vivado/2016.1/lib/lnx64.o/librdi_dsp_tcltasks.so
cd {/home/davidm/casper/s6_gateware/wavedata}
dsp_wave_convert {auto_vzmac_core.wfv} 
set_param project.waveformStandaloneMode 1
start_gui
current_fileset
dsp_register_design_manager
dsp_open_waveform {auto_vzmac_core.wdb}
open_wave_config {auto_vzmac_core.wcfg}
source /opt/Xilinx/Vivado/2016.1/scripts/sysgen/tcl/SgPaSlaveInterp.tcl
