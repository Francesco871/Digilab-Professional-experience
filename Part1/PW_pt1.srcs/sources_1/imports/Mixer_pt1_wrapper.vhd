--Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
--Date        : Wed Sep 18 19:44:19 2024
--Host        : DESKTOP-C5QP7TD running 64-bit major release  (build 9200)
--Command     : generate_target Mixer_pt1_wrapper.bd
--Design      : Mixer_pt1_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity Mixer_pt1_wrapper is
  port (
    SPI_io0_o_0 : out STD_LOGIC;
    SPI_io1_i_0 : in STD_LOGIC;
    SPI_sck_o_0 : out STD_LOGIC;
    SPI_ss_o_0 : out STD_LOGIC_VECTOR ( 0 to 0 );
    led : out STD_LOGIC_VECTOR ( 15 downto 0 );
    reset : in STD_LOGIC;
    rx_lrck_0 : out STD_LOGIC;
    rx_mclk_0 : out STD_LOGIC;
    rx_sclk_0 : out STD_LOGIC;
    rx_sdin_0 : in STD_LOGIC;
    sys_clock : in STD_LOGIC;
    tx_lrck_0 : out STD_LOGIC;
    tx_mclk_0 : out STD_LOGIC;
    tx_sclk_0 : out STD_LOGIC;
    tx_sdout_0 : out STD_LOGIC;
    usb_uart_rxd : in STD_LOGIC;
    usb_uart_txd : out STD_LOGIC
  );
end Mixer_pt1_wrapper;

architecture STRUCTURE of Mixer_pt1_wrapper is
  component Mixer_pt1 is
  port (
    sys_clock : in STD_LOGIC;
    reset : in STD_LOGIC;
    led : out STD_LOGIC_VECTOR ( 15 downto 0 );
    tx_mclk_0 : out STD_LOGIC;
    tx_lrck_0 : out STD_LOGIC;
    tx_sclk_0 : out STD_LOGIC;
    tx_sdout_0 : out STD_LOGIC;
    rx_mclk_0 : out STD_LOGIC;
    rx_lrck_0 : out STD_LOGIC;
    rx_sdin_0 : in STD_LOGIC;
    SPI_io1_i_0 : in STD_LOGIC;
    SPI_sck_o_0 : out STD_LOGIC;
    SPI_ss_o_0 : out STD_LOGIC_VECTOR ( 0 to 0 );
    SPI_io0_o_0 : out STD_LOGIC;
    rx_sclk_0 : out STD_LOGIC;
    usb_uart_txd : out STD_LOGIC;
    usb_uart_rxd : in STD_LOGIC
  );
  end component Mixer_pt1;
begin
Mixer_pt1_i: component Mixer_pt1
     port map (
      SPI_io0_o_0 => SPI_io0_o_0,
      SPI_io1_i_0 => SPI_io1_i_0,
      SPI_sck_o_0 => SPI_sck_o_0,
      SPI_ss_o_0(0) => SPI_ss_o_0(0),
      led(15 downto 0) => led(15 downto 0),
      reset => reset,
      rx_lrck_0 => rx_lrck_0,
      rx_mclk_0 => rx_mclk_0,
      rx_sclk_0 => rx_sclk_0,
      rx_sdin_0 => rx_sdin_0,
      sys_clock => sys_clock,
      tx_lrck_0 => tx_lrck_0,
      tx_mclk_0 => tx_mclk_0,
      tx_sclk_0 => tx_sclk_0,
      tx_sdout_0 => tx_sdout_0,
      usb_uart_rxd => usb_uart_rxd,
      usb_uart_txd => usb_uart_txd
    );
end STRUCTURE;
