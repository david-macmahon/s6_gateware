library IEEE;
use IEEE.std_logic_1164.all;

entity fft_core is
  port (
    ce : in std_logic;
    din : in std_logic_vector( 39 downto 0 );
    shift : in std_logic_vector( 31 downto 0 );
    sync_in : in std_logic;
    clk : in std_logic;
    dout : out std_logic_vector( 71 downto 0 );
    sync_out : out std_logic
  );
end fft_core;

architecture structural of fft_core is
begin
end structural;

