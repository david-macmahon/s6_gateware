library IEEE;
use IEEE.std_logic_1164.all;

entity cross_vzmac_core is
  port (
    ce : in std_logic;
    im0 : in std_logic_vector( 7 downto 0 );
    im1 : in std_logic_vector( 7 downto 0 );
    re0 : in std_logic_vector( 7 downto 0 );
    re1 : in std_logic_vector( 7 downto 0 );
    sync : in std_logic;
    clk : in std_logic;
    im : out std_logic_vector( 20 downto 0 );
    re : out std_logic_vector( 20 downto 0 );
    valid : out std_logic
  );
end cross_vzmac_core;

architecture structural of cross_vzmac_core is
begin
end structural;

