-- Copyright (C) 1991-2013 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- Daewoo RAM Expander Firmware v1.00
-- Created by Wierzbowsky [RBSC] and Max Vlasov (Meteor_M)
-- Special thanks to Pyhesty [RBSC]
-- (c) RBSC 2025 and Meteor_M
-- Last modified: 10.11.2025

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ram_expander is
    port ( D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR (15 downto 0);
			  MA	:	inout STD_LOGIC_VECTOR (4 downto 0);
           RD_N : in  STD_LOGIC;
           WR_N : in  STD_LOGIC;
           RFSH_N : in  STD_LOGIC;
           RST_N  : in  STD_LOGIC;
           CLK1 : in  STD_LOGIC;
           CLK2 : in  STD_LOGIC;
			  MERQ_N : in  STD_LOGIC;
			  M1_N   : in  STD_LOGIC;
			  IORQ_N : in  STD_LOGIC;
           SLTSEL_N : in  STD_LOGIC;
           CE1 : out  STD_LOGIC;
			  CE2 : out  STD_LOGIC;
			  CE3 : out  STD_LOGIC;
			  CE4 : out  STD_LOGIC;
			  SW1 : in  STD_LOGIC;
			  SW2 : in  STD_LOGIC;
			  SW3 : in  STD_LOGIC;
			  SW4 : in  STD_LOGIC;
			  BUSDIR_N : out  STD_LOGIC);
end ram_expander;

architecture rtl of ram_expander is

	-- Read/write flags
	signal flag_rd	:	STD_LOGIC;
	signal flag_wr	:	STD_LOGIC;

	-- Array for 74LS670 latch
	type reg_array is array (3 downto 0) of std_logic_vector(6 downto 0);
   signal registers : reg_array := (others => "0000000");
	signal bank_id : std_logic_vector(6 downto 0);

	--	Port F4 signals
	--signal f4_read	:	STD_LOGIC;
	--signal f4_write	:	STD_LOGIC;
	--signal f4_bit   :	STD_LOGIC := '1';

begin

	-------------------------
	-- RAM Expansion logic --
	-------------------------

	-- Read/Write logic (74LS139 + 74LS30)
	flag_wr <= '1' when (WR_N = '0' and RD_N = '1' and RFSH_N = '1' and IORQ_N = '0' and M1_N = '1' and A(7 downto 2) = "111111") else '0';	
	flag_rd <= '1' when (WR_N = '1' and RD_N = '0' and RFSH_N = '1' and IORQ_N = '0' and M1_N = '1' and A(7 downto 2) = "111111") else '0';		

	-- Latch logic (74LS670)
	process(CLK1, RST_N)
		begin
			if RST_N = '0' then
				registers <= (others => "0000000");
			elsif rising_edge(CLK1) then
				if flag_wr = '1' then
					case A(1 downto 0) is
						 when "00" =>
							  registers(0) <= D(6 downto 0);
						 when "01" =>
							  registers(1) <= D(6 downto 0);
						 when "10" =>
							  registers(2) <= D(6 downto 0);
						 when others =>
							  registers(3) <= D(6 downto 0);
					end case;
				end if;
			end if;
	end process;

	process(A, registers)
		begin
			if flag_rd = '0' then
				case A(15 downto 14) is
					 when "00" =>
						  bank_id <= registers(0);
					 when "01" =>
						  bank_id <= registers(1);
					 when "10" =>
						  bank_id <= registers(2);
					 when others =>
						  bank_id <= registers(3);
				end case;
			else
				case A(1 downto 0) is
					 when "00" =>
						  bank_id <= registers(0);
					 when "01" =>
						  bank_id <= registers(1);
					 when "10" =>
						  bank_id <= registers(2);
					 when others =>
						  bank_id <= registers(3);
				end case;
			end if;
	end process;

	-- Higher address logic
	MA <= bank_id(4 downto 0) when MERQ_N = '0' else "ZZZZZ";

	-- Octal Latch logic (74LS373)
	D(6 downto 0) <= bank_id(6 downto 0) when flag_rd = '1' else "ZZZZZZZ";

	-- Chip select logic (74LS139) and RAM bank selection logic based on solder jumpers
	-- Installing a solder jumper disables the corresponding RAM bank (rightmost bank = 1)
	-- Possible options: 512kb, 1024kb, 1536kb, 2048kb
	CE1 <= '0' when (SLTSEL_N = '0' and bank_id(6 downto 5) = "00" and SW1 = '1') else '1';
	CE2 <= '0' when (SLTSEL_N = '0' and bank_id(6 downto 5) = "01" and SW2 = '1') else '1';
	CE3 <= '0' when (SLTSEL_N = '0' and bank_id(6 downto 5) = "10" and SW3 = '1') else '1';
	CE4 <= '0' when (SLTSEL_N = '0' and bank_id(6 downto 5) = "11" and SW4 = '1') else '1';

	-- BUSDIR logic for RAM expansion without port F4
	BUSDIR_N <= '0' when (M1_N = '1' and IORQ_N = '0' and RD_N = '0' and A(7 downto 2) = "111111") else '1';

	-- BUSDIR logic for RAM expansion with port F4 (comment the upper line and uncomment the below line)
	--BUSDIR_N <= '0' when (M1_N = '1' and IORQ_N = '0' and RD_N = '0' and A(7 downto 2) = "111111")
										--or (M1_N = '1' and IORQ_N = '0' and RD_N = '0' and A(7 downto 4) = "1111" and A(3) = '0' and A(2) = '1' and A(1 downto 0) = "00" ) else '1';


	-------------------
	-- Port F4 logic --
	-------------------

	-- Read/write conditions
	--f4_read <= '1' when (A(7 downto 4) = "1111" and A(3) = '0' and A(2) = '1' and A(1 downto 0) = "00" and IORQ_N = '0' and RD_N = '0' and WR_N = '1' and M1_N = '1') else '0';
	--f4_write <= '1' when (A(7 downto 4) = "1111" and A(3) = '0' and A(2) = '1' and A(1 downto 0) = "00" and IORQ_N = '0' and WR_N = '0' and RD_N = '1') else '0';
	
	-- Preserve bit
	--process(f4_write)
		--begin
			--if (f4_write'event and f4_write = '1') then
				--f4_bit <= D(7);
			--end if;
	--end process;
	
	-- Output bit
	--D(7) <= f4_bit when (f4_read = '1') else 'Z';

end rtl;

