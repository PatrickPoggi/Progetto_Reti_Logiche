
----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineer: Patrick Poggi
--
-- Create Date: 22.03.2023 15:57:58
-- Design Name:
-- Module Name: project_reti_logiche - Behavioral
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


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity demux_1a4 is
    Port(
        i_in : in std_logic_vector(7 downto 0);
        i_controller : in std_logic_vector(1 downto 0);

        o_0, o_1, o_2, o_3 : out std_logic_vector(7 downto 0)
    );
end demux_1a4;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity registro_ffd_nbit is
    generic(N: integer:=8);
    port(
        i_signal: in std_logic_vector(N-1 downto 0);

        i_clk: in std_logic;
        i_rst: in std_logic;
        i_enable: in std_logic;

        o_q: out std_logic_vector(N-1 downto 0)
    );
end registro_ffd_nbit;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux_2a1 is
    port(
        i_1: in std_logic_vector(7 downto 0);
        i_2: in std_logic_vector(7 downto 0);

        i_sel: in std_logic;

        o_out: out std_logic_vector(7 downto 0)
    );

end mux_2a1;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity project_reti_logiche is
    Port(
        i_clk: in std_logic;
        i_rst: in std_logic;
        i_start: in std_logic;
        i_w: in std_logic;

        o_z0: out std_logic_vector(7 downto 0);
        o_z1: out std_logic_vector(7 downto 0);
        o_z2: out std_logic_vector(7 downto 0);
        o_z3: out std_logic_vector(7 downto 0);
        o_done: out std_logic;

        o_mem_addr: out std_logic_vector(15 downto 0);
        i_mem_data: in std_logic_vector(7 downto 0);
        o_mem_we: out std_logic;
        o_mem_en: out std_logic
    );
end project_reti_logiche;

architecture Behavioral of demux_1a4 is
begin
    process(i_controller, i_in)
        begin
          case i_controller is
              when "00" =>
                  o_0 <= i_in;
                  o_1 <= (others => '0');
                  o_2 <= (others => '0');
                  o_3 <= (others => '0');
              when "01" =>
                  o_0 <= (others => '0');
                  o_1 <= i_in;
                  o_2 <= (others => '0');
                  o_3 <= (others => '0');
              when "10" =>
                  o_0 <= (others => '0');
                  o_1 <= (others => '0');
                  o_2 <= i_in;
                  o_3 <= (others => '0');
              when others =>
                  o_0 <= (others => '0');
                  o_1 <= (others => '0');
                  o_2 <= (others => '0');
                  o_3 <= i_in;
          end case;
    end process;

end Behavioral;

architecture Behavioral of registro_ffd_nbit is
begin
    process(i_clk, i_rst, i_signal, i_enable)
       begin
            if i_rst = '1' then
                o_q <= (others => '0');
            elsif rising_edge(i_clk) and i_enable = '1' then
                o_q <= i_signal;
            end if;
       end process;

end Behavioral;

architecture Behavioral of mux_2a1 is
begin
    process(i_1, i_2, i_sel)
    begin
        case i_sel is
            when '0' =>
                o_out <= i_1;
            when others =>
                o_out <= i_2;
        end case;
    end process;

end Behavioral;

architecture Behavioral of project_reti_logiche is
    type state_type is (S0, S1, S2, S3, S4, S5);
    signal current_state: state_type;

    signal s_intestazione : std_logic_vector(1 downto 0);
    signal s_indirizzo: std_logic_vector(15 downto 0);

    signal s_done : std_logic;
    signal s_mem_en : std_logic;
    signal reg00_en, reg01_en, reg10_en, reg11_en : std_logic;

    signal s_reg00, s_reg01, s_reg10, s_reg11: std_logic_vector(7 downto 0);
    signal q_reg00, q_reg01, q_reg10, q_reg11: std_logic_vector(7 downto 0);

    constant GROUND8 : std_logic_vector(7 downto 0) := (others => '0');

    component demux_1a4 is
        Port(
            i_in : in std_logic_vector(7 downto 0);
            i_controller : in std_logic_vector(1 downto 0);

            o_0, o_1, o_2, o_3 : out std_logic_vector(7 downto 0)
        );
    end component;

    component registro_ffd_nbit is
        generic(N: integer:=8);
        port(
            i_signal: in std_logic_vector(N-1 downto 0);

            i_clk: in std_logic;
            i_rst: in std_logic;
            i_enable: in std_logic;

            o_q: out std_logic_vector(N-1 downto 0)
        );
    end component;

    component mux_2a1 is
        port(
            i_1: in std_logic_vector(7 downto 0);
            i_2: in std_logic_vector(7 downto 0);

            i_sel: in std_logic;

            o_out: out std_logic_vector(7 downto 0)
        );
    end component;
begin

    whole_fsm: process(current_state, i_clk, i_rst, i_start, i_mem_data)
    begin
        if i_rst = '1' then
            current_state <= S0;
            s_indirizzo <= (others => '0');
            s_intestazione <= (others => '0');
            s_done <= '0';
            s_mem_en <= '0';
            reg00_en <= '0';
            reg01_en <= '0';
            reg10_en <= '0';
            reg11_en <= '0';
        elsif rising_edge(i_clk) then
            if current_state = S0 then -- aspetto lo start, se e' arrivato leggo il primo bit di intestazione
                    if i_start = '1' then
                        if i_w = '1' then
                            s_intestazione <= (1 => '1', others => '0');
                        else
                            s_intestazione <= (others => '0');
                        end if;
                        current_state <= S1;
                    else
                        s_intestazione <= (others => '0');
                        current_state <= S0;
                    end if;
                    s_indirizzo <= (others => '0');
                    s_mem_en <= '0';
                    s_done <= '0';
                    reg00_en <= '0';
                    reg01_en <= '0';
                    reg10_en <= '0';
                    reg11_en <= '0';
               elsif current_state =  S1 then -- leggo il secondo bit di intestazione
                    s_indirizzo <= (others => '0');
                    if i_start = '1' then -- in teoria e' garantito start = '1'...
                        if i_w = '1' then
                            s_intestazione <= (1 => s_intestazione(1), 0 => '1');
                        else
                            s_intestazione <= (1=> s_intestazione(1), 0 => '0');
                        end if;
                    else                  -- Non entrerò mai qui...
                        s_intestazione <= "00";
                    end if;

                    s_mem_en <= '0';
                    s_done <= '0';
                    reg00_en <= '0';
                    reg01_en <= '0';
                    reg10_en <= '0';
                    reg11_en <= '0';
                    current_state <= S2;
               elsif current_state = S2 then -- leggo l'indirizo, non so per quanto...
                    s_intestazione <= s_intestazione;

                    if i_start = '1' then
                        for i in 15 downto 1 loop
                            s_indirizzo(i) <= s_indirizzo(i-1);
                        end loop;
                        s_indirizzo(0) <= i_w;
                        current_state <= S2;
                    else
                        s_indirizzo <= s_indirizzo;
                        current_state <= S3;
                    end if;

                    s_done <= '0';
                    s_mem_en <= '0';
                    reg00_en <= '0';
                    reg01_en <= '0';
                    reg10_en <= '0';
                    reg11_en <= '0';

               elsif current_state = S3 then  -- ho letto l'indirizzo, lo mando alla memoria
                    s_intestazione <= s_intestazione;
                    s_indirizzo <= s_indirizzo;
                    s_mem_en <= '1';
                    s_done <= '0';
                    reg00_en <= '0';
                    reg01_en <= '0';
                    reg10_en <= '0';
                    reg11_en <= '0';

                    -- Si può assumere che la memoria risponda sempre entro un ciclo di clock, quindi...
                    current_state <= S4;
               elsif current_state = S4 then -- ho ricevuto il dato, lo mando ai registri
                    s_intestazione <= s_intestazione;
                    s_indirizzo <= s_indirizzo;
                    s_mem_en <= '0';
                    s_done <= '0';

                    reg00_en <= not(s_intestazione(1)) and not(s_intestazione(0));
                    reg01_en <= not(s_intestazione(1)) and s_intestazione(0);
                    reg10_en <= s_intestazione(1) and not(s_intestazione(0));
                    reg11_en <= s_intestazione(1) and s_intestazione(0);

                    current_state <= S5;
              elsif current_state = S5 then -- S5: i registri hanno registrato, mando in uscita
                    s_intestazione <= s_intestazione;
                    s_indirizzo <= s_indirizzo;
                    s_mem_en <= '0';
                    reg00_en <= '0';
                    reg01_en <= '0';
                    reg10_en <= '0';
                    reg11_en <= '0';
                    s_done <= '1';
                    current_state <= S0;
              else -- In teoria non dovrei mai capitare qui, nel caso resetto
                    s_intestazione <= (others => '0');
                    s_indirizzo <= (others => '0');
                    s_mem_en <= '0';
                    reg00_en <= '0';
                    reg01_en <= '0';
                    reg10_en <= '0';
                    reg11_en <= '0';
                    s_done <= '0';
                    current_state <= S0;
            end if;
        end if;
    end process;

    o_mem_en <= s_mem_en;
    o_done <= s_done;
    o_mem_we <= '0';
    o_mem_addr <= s_indirizzo;

-- =============================================================================
    dispatcher: demux_1a4
        port map(i_mem_data, s_intestazione, s_reg00, s_reg01, s_reg10, s_reg11);
-- =============================================================================

    reg00: registro_ffd_nbit
        generic map(8)
        port map(s_reg00, i_clk, i_rst, reg00_en, q_reg00);

    reg01: registro_ffd_nbit
        generic map(8)
        port map(s_reg01, i_clk, i_rst, reg01_en, q_reg01);

    reg10: registro_ffd_nbit
        generic map(8)
        port map(s_reg10, i_clk, i_rst, reg10_en, q_reg10);

    reg11: registro_ffd_nbit
        generic map(8)
        port map(s_reg11, i_clk, i_rst, reg11_en, q_reg11);

-- =============================================================================

    filtro00: mux_2a1
        port map(GROUND8, q_reg00, s_done, o_z0);

    filtro01: mux_2a1
        port map(GROUND8, q_reg01, s_done, o_z1);

    filtro10: mux_2a1
        port map(GROUND8, q_reg10, s_done, o_z2);

    filtro11: mux_2a1
        port map(GROUND8, q_reg11, s_done, o_z3);
end Behavioral;
