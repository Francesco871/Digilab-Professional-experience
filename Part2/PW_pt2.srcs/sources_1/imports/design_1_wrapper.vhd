--Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
--Date        : Sat Sep 21 14:46:32 2024
--Host        : lucky-work16 running 64-bit unknown
--Command     : generate_target design_1_wrapper.bd
--Design      : design_1_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity design_1_wrapper is
  port (
    SPI_0_io0_io : out STD_LOGIC;
    SPI_0_io1_io : in STD_LOGIC;
    SPI_0_sck_io : out STD_LOGIC;
    SPI_0_ss_io : out STD_LOGIC_VECTOR ( 0 to 0 );
    an : out STD_LOGIC_VECTOR ( 3 downto 0 );
    dp : out STD_LOGIC;
    led : out STD_LOGIC_VECTOR ( 15 downto 0 );
    reset : in STD_LOGIC;
    rx_lrck_0 : out STD_LOGIC;
    rx_mclk_0 : out STD_LOGIC;
    rx_sclk_0 : out STD_LOGIC;
    rx_sdin_0 : in STD_LOGIC;
    seg : out STD_LOGIC_VECTOR ( 0 to 6 );
    sw_ch0 : in STD_LOGIC;
    sw_ch1 : in STD_LOGIC;
    sw_eff : in STD_LOGIC;
    sys_clock : in STD_LOGIC;
    tx_lrck_0 : out STD_LOGIC;
    tx_mclk_0 : out STD_LOGIC;
    tx_sclk_0 : out STD_LOGIC;
    tx_sdout_0 : out STD_LOGIC;
    usb_uart_rxd : in STD_LOGIC;
    usb_uart_txd : out STD_LOGIC
  );
end design_1_wrapper;

architecture STRUCTURE of design_1_wrapper is
  component design_1 is
  port (
    sys_clock : in STD_LOGIC;
    reset : in STD_LOGIC;
    sw_ch1 : in STD_LOGIC;
    sw_ch0 : in STD_LOGIC;
    sw_eff : in STD_LOGIC;
    seg : out STD_LOGIC_VECTOR ( 0 to 6 );
    an : out STD_LOGIC_VECTOR ( 3 downto 0 );
    dp : out STD_LOGIC;
    tx_mclk_0 : out STD_LOGIC;
    tx_lrck_0 : out STD_LOGIC;
    rx_mclk_0 : out STD_LOGIC;
    rx_lrck_0 : out STD_LOGIC;
    tx_sclk_0 : out STD_LOGIC;
    tx_sdout_0 : out STD_LOGIC;
    rx_sclk_0 : out STD_LOGIC;
    led : out STD_LOGIC_VECTOR ( 15 downto 0 );
    rx_sdin_0 : in STD_LOGIC;
    SPI_0_ss_io : out STD_LOGIC_VECTOR ( 0 to 0 );
    SPI_0_io0_io : out STD_LOGIC;
    SPI_0_sck_io : out STD_LOGIC;
    SPI_0_io1_io : in STD_LOGIC;
    usb_uart_txd : out STD_LOGIC;
    usb_uart_rxd : in STD_LOGIC
  );
  end component design_1;
begin
design_1_i: component design_1
     port map (
      SPI_0_io0_io => SPI_0_io0_io,
      SPI_0_io1_io => SPI_0_io1_io,
      SPI_0_sck_io => SPI_0_sck_io,
      SPI_0_ss_io(0) => SPI_0_ss_io(0),
      an(3 downto 0) => an(3 downto 0),
      dp => dp,
      led(15 downto 0) => led(15 downto 0),
      reset => reset,
      rx_lrck_0 => rx_lrck_0,
      rx_mclk_0 => rx_mclk_0,
      rx_sclk_0 => rx_sclk_0,
      rx_sdin_0 => rx_sdin_0,
      seg(0 to 6) => seg(0 to 6),
      sw_ch0 => sw_ch0,
      sw_ch1 => sw_ch1,
      sw_eff => sw_eff,
      sys_clock => sys_clock,
      tx_lrck_0 => tx_lrck_0,
      tx_mclk_0 => tx_mclk_0,
      tx_sclk_0 => tx_sclk_0,
      tx_sdout_0 => tx_sdout_0,
      usb_uart_rxd => usb_uart_rxd,
      usb_uart_txd => usb_uart_txd
    );
end STRUCTURE;
