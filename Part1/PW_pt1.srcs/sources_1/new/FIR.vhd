----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.09.2021 10:45:42
-- Design Name: 
-- Module Name: FIR - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FIR is
    Generic(
        LOG2_LEN: POSITIVE := 5;
        REG_LENGHT : POSITIVE := 8;
        CHANNEL_LENGHT  : integer := 24
    );
    Port ( 
        s_axis_tready : OUT STD_LOGIC;
        s_axis_tdata : IN STD_LOGIC_VECTOR(CHANNEL_LENGHT-1 DOWNTO 0);
        s_axis_tlast : IN STD_LOGIC;
        s_axis_tvalid : IN STD_LOGIC;
        s_rx_axis_tready : OUT STD_LOGIC;
        s_rx_axis_tdata : IN STD_LOGIC_VECTOR(CHANNEL_LENGHT-1 DOWNTO 0);
        s_rx_axis_tvalid : IN STD_LOGIC;
        m_axis_tvalid : OUT STD_LOGIC;
        m_axis_tdata : OUT STD_LOGIC_VECTOR(CHANNEL_LENGHT-1 DOWNTO 0);
        m_axis_tready : IN STD_LOGIC;
        m_axis_tlast : OUT STD_LOGIC;
        enable_filter_trig : IN STD_LOGIC;
        filter_enabled : OUT STD_LOGIC;
        aclk : IN STD_LOGIC;
        aresetn : IN STD_LOGIC
    );
end FIR;

architecture Behavioral of FIR is
    constant LOG2_LEN2 : integer := LOG2_LEN/2;
    constant LOG2_LEN1 : integer := LOG2_LEN-LOG2_LEN2;
    constant LEN : integer := 2**LOG2_LEN;
    constant LEN1 : integer := 2**LOG2_LEN1;
    constant LEN2 : integer := 2**LOG2_LEN2;
    constant SUM_LEN : integer := 2**(LOG2_LEN-1);

    type state_type is (rx, buff, buff1, buff2, tx);
    type reg_type is array(integer range <>) of signed(REG_LENGHT-1 downto 0);
    type mem_type is array(integer range <>) of signed(CHANNEL_LENGHT-1 downto 0);
    --type mem_type1 is array(integer range <>) of signed(CHANNEL_LENGHT+REG_LENGHT-1 downto 0);
    type channel_type is (right, left);

    signal state: state_type :=rx;
    signal memL : mem_type(LEN-1 downto 0) :=(others=>(others=>'0'));
    signal memR : mem_type(LEN-1 downto 0) :=(others=>(others=>'0'));
    signal reg : reg_type(LEN-1 downto 0) :=(others=>(REG_LENGHT-1=>'0', others => '1'));
    signal res : mem_type(LEN-1 downto 0);
    signal mem : mem_type(LEN-1 downto 0);
    signal res1 : mem_type(LEN2-1 downto 0);
    signal mem1 : mem_type(LEN2-1 downto 0);
    signal channel : channel_type;
    signal data : signed(CHANNEL_LENGHT-1 downto 0);
    signal enable_filter_reg : std_logic :='0';

    type rx_state_type is (addr, reg_data);

    signal rx_state: rx_state_type :=addr;
    signal wr_addr : integer range 0 to LEN-1;
        
    
begin
    with channel select m_axis_tlast<= '1' when right,
                                                '0' when others;
    
    with state select s_axis_tready<= '1' when rx,
                                               '0' when others;
    with state select m_axis_tvalid<= '1' when tx,
                                               '0' when others;
    
    filter_enabled<=enable_filter_reg;

    process(aclk, aresetn)
    begin
        if aresetn='0' then
            state<=rx;
            memL<=(others=>(others=>'0'));
            memR<=(others=>(others=>'0'));
            enable_filter_reg<='0';
        elsif rising_edge(aclk) then
            if enable_filter_trig='1' then
                enable_filter_reg<= not enable_filter_reg;
            end if;
            case state is
                when rx=>
                    if(s_axis_tvalid='1') then
                        if s_axis_tlast='1' then
                            channel<=right;
                            memR(0)<=signed(s_axis_tdata);
                            for I in 1 to LEN-1 loop
                                memR(I)<=memR(I-1);
                            end loop;
                        else
                            channel<=left;
                            memL(0)<=signed(s_axis_tdata);
                            for I in 1 to LEN-1 loop
                                memL(I)<=memL(I-1);
                            end loop;
                        end if;
                        state<=buff;
                    end if;
                when buff=>
                    mem<=res;
                    state<=buff1;
                when buff1=>
                    mem1<=res1;
                    state<=buff2;
                when buff2=>
                    if(enable_filter_reg='0') then
                        if(channel=left) then
                            m_axis_tdata<=std_logic_vector(memL(0));
                        else
                            m_axis_tdata<=std_logic_vector(memR(0));   
                        end if;
                    else
                        m_axis_tdata<=std_logic_vector(data);   
                    end if;
                    state<=tx;
                when tx=>
                    if(m_axis_tready='1') then
                        state<=rx;
                    end if;
            end case;
        end if;
    end process;

    process (reg ,memL, memR, channel)
    variable result: signed(CHANNEL_LENGHT-1+REG_LENGHT downto 0);
    begin
        for I in 0 to LEN-1 loop
            if(channel=left) then
                result:=reg(I)*memL(I);
            else
                result:=reg(I)*memR(I);
            end if;
            res(I)<=result(CHANNEL_LENGHT-1+REG_LENGHT downto REG_LENGHT);
        end loop;
    end process;

    process(mem)
        variable result: signed(CHANNEL_LENGHT-1+LOG2_LEN1 downto 0);
    begin
        for J in 0 to LEN2-1 loop
            result:=(others=>'0');
            for I in 0 to LEN1-1 loop
                result:=result+mem(I);
            end loop;
            res1(J)<=result(CHANNEL_LENGHT-1+LOG2_LEN1 downto LOG2_LEN1);
        end loop;
    end process;

    process(mem1)
        variable result: signed(CHANNEL_LENGHT-1+LOG2_LEN2 downto 0);
    begin
        result:=(others=>'0');
        for I in 0 to LEN2-1 loop
            result:=result+mem1(I);
        end loop;
        data<=result(CHANNEL_LENGHT-1+LOG2_LEN2 downto LOG2_LEN2);
    end process;

    process(aclk, aresetn)
    begin
        if aresetn='0' then
            rx_state<=addr;
            reg<=(others=>(REG_LENGHT-1=>'0', others => '1'));
        elsif rising_edge(aclk) then
            case rx_state is
                when addr=>
                    if(s_rx_axis_tvalid='1') then
                        if(unsigned(s_rx_axis_tdata)<LEN) then
                            wr_addr<=to_integer(unsigned(s_rx_axis_tdata));
                            rx_state<=reg_data;
                        end if;
                    end if;
                when reg_data=>
                    if(s_rx_axis_tvalid='1') then
                        reg(wr_addr)<=signed(2**(REG_LENGHT-1)-unsigned(s_rx_axis_tdata));
                        rx_state<=addr;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;
