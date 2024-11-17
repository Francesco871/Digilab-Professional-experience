library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Mute is
	Generic(
		CHANNEL_LENGHT  : positive := 24
	);
    Port (
		---- AXI4 Receiver ----
		s_axis_tvalid	: in std_logic;
		s_axis_tdata	: in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
		s_axis_tlast    : in std_logic;
		s_axis_tready	: out std_logic;

		---- AXI4 Transmitters ----
		m_00_axis_tvalid	: out std_logic;
		m_00_axis_tdata	: out std_logic_vector(CHANNEL_LENGHT-1 downto 0);
		m_00_axis_tlast	: out std_logic;
		m_00_axis_tready	: in std_logic;
		
		---- Other Ports ----
		aclk			: in std_logic;
		aresetn			: in std_logic;
		
		muted           : out std_logic;
		mute_trig       : in std_logic
	);
end Mute;

architecture Behavioral of Mute is

	---- FSM ----
	type state_type is (ACQUIRE, SEND);
    signal state: state_type := ACQUIRE;
    signal mute_reg: std_logic :='0';

begin
	---- Managemente of the handshake ports ----
	with state select s_axis_tready    <= '1' when ACQUIRE,
                                                   '0' when others;

    with state select m_00_axis_tvalid    <= '1' when SEND,
                                                   '0' when others;
    --------------------------------------------

    muted<=mute_reg;

    process (aclk, aresetn)
    begin

        if aresetn = '0' then
            state <= ACQUIRE;
            mute_reg<='0';

        elsif rising_edge(aclk) then
            if(mute_trig='1') then
                mute_reg<= not mute_reg;
            end if;
            case state is
                when ACQUIRE =>
                    if(s_axis_tvalid = '1') then
                        m_00_axis_tlast <= s_axis_tlast;
						if mute_reg = '1' then
                            m_00_axis_tdata <=  (others => '0');-- Since the m_axis_sample_tvalid is not yet high, we can safely put the result already at the output
                        else
                            m_00_axis_tdata <= s_axis_tdata;
                        end if;
                        state <= SEND;                      
                    end if;

                when SEND =>
                    if(m_00_axis_tready = '1') then --In this case m_01_axis_tready is always '1' so is not checked
                        state <= ACQUIRE;
                    end if;

            end case;

        end if;
    end process;

end Behavioral;
