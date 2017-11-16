library IEEE;
use IEEE.std_logic_1164.all;

entity pfb_fir_core is
  port (
    ce : in std_logic;
    in0 : in std_logic_vector( 31 downto 0 );
    in1 : in std_logic_vector( 31 downto 0 );
    sync_in : in std_logic;
    clk : in std_logic;
    out0 : out std_logic_vector( 39 downto 0 );
    out1 : out std_logic_vector( 39 downto 0 );
    sync_out : out std_logic
  );
end pfb_fir_core;

architecture structural of pfb_fir_core is
begin
end structural;

