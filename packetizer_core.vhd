library IEEE;
use IEEE.std_logic_1164.all;

entity packetizer_core is
  port (
    ce : in std_logic;
    din : in std_logic_vector( 63 downto 0 );
    sid : in std_logic_vector( 7 downto 0 );
    sync_in : in std_logic;
    tx_enable : in std_logic;
    ip_dest_0 : in std_logic_vector( 31 downto 0 );
    ip_dest_1 : in std_logic_vector( 31 downto 0 );
    ip_dest_10 : in std_logic_vector( 31 downto 0 );
    ip_dest_11 : in std_logic_vector( 31 downto 0 );
    ip_dest_12 : in std_logic_vector( 31 downto 0 );
    ip_dest_13 : in std_logic_vector( 31 downto 0 );
    ip_dest_14 : in std_logic_vector( 31 downto 0 );
    ip_dest_15 : in std_logic_vector( 31 downto 0 );
    ip_dest_16 : in std_logic_vector( 31 downto 0 );
    ip_dest_17 : in std_logic_vector( 31 downto 0 );
    ip_dest_18 : in std_logic_vector( 31 downto 0 );
    ip_dest_19 : in std_logic_vector( 31 downto 0 );
    ip_dest_2 : in std_logic_vector( 31 downto 0 );
    ip_dest_20 : in std_logic_vector( 31 downto 0 );
    ip_dest_21 : in std_logic_vector( 31 downto 0 );
    ip_dest_22 : in std_logic_vector( 31 downto 0 );
    ip_dest_23 : in std_logic_vector( 31 downto 0 );
    ip_dest_24 : in std_logic_vector( 31 downto 0 );
    ip_dest_25 : in std_logic_vector( 31 downto 0 );
    ip_dest_26 : in std_logic_vector( 31 downto 0 );
    ip_dest_27 : in std_logic_vector( 31 downto 0 );
    ip_dest_28 : in std_logic_vector( 31 downto 0 );
    ip_dest_29 : in std_logic_vector( 31 downto 0 );
    ip_dest_3 : in std_logic_vector( 31 downto 0 );
    ip_dest_30 : in std_logic_vector( 31 downto 0 );
    ip_dest_31 : in std_logic_vector( 31 downto 0 );
    ip_dest_4 : in std_logic_vector( 31 downto 0 );
    ip_dest_5 : in std_logic_vector( 31 downto 0 );
    ip_dest_6 : in std_logic_vector( 31 downto 0 );
    ip_dest_7 : in std_logic_vector( 31 downto 0 );
    ip_dest_8 : in std_logic_vector( 31 downto 0 );
    ip_dest_9 : in std_logic_vector( 31 downto 0 );
    clk : in std_logic;
    dout0 : out std_logic_vector( 63 downto 0 );
    dout1 : out std_logic_vector( 63 downto 0 );
    dst0 : out std_logic_vector( 31 downto 0 );
    dst1 : out std_logic_vector( 31 downto 0 );
    dv0 : out std_logic;
    dv1 : out std_logic;
    eof0 : out std_logic;
    eof1 : out std_logic
  );
end packetizer_core;

architecture structural of packetizer_core is
begin
end structural;

