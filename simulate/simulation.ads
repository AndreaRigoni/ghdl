--  Interpreted simulation
--  Copyright (C) 2014 Tristan Gingold
--
--  GHDL is free software; you can redistribute it and/or modify it under
--  the terms of the GNU General Public License as published by the Free
--  Software Foundation; either version 2, or (at your option) any later
--  version.
--
--  GHDL is distributed in the hope that it will be useful, but WITHOUT ANY
--  WARRANTY; without even the implied warranty of MERCHANTABILITY or
--  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
--  for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with GHDL; see the file COPYING.  If not, write to the Free
--  Software Foundation, 59 Temple Place - Suite 330, Boston, MA
--  02111-1307, USA.

with System;
with Grt.Types; use Grt.Types;
with Iirs; use Iirs;
with Iir_Values; use Iir_Values;
with Elaboration; use Elaboration;
with Execution; use Execution;

package Simulation is
   Trace_Simulation : Boolean := False;
   Disp_Tree : Boolean := False;
   Disp_Stats : Boolean := False;
   Disp_Ams : Boolean := False;
   Flag_Debugger : Boolean := False;
   Flag_Interractive : Boolean := False;

   type Resolv_Instance_Type is record
      Func : Iir;
      Block : Block_Instance_Acc;
      Sig : Iir_Value_Literal_Acc;
   end record;
   type Resolv_Instance_Acc is access Resolv_Instance_Type;

   --  The resolution procedure for GRT.
   procedure Resolution_Proc (Instance_Addr : System.Address;
                              Val : System.Address;
                              Bool_Vec : System.Address;
                              Vec_Len : Ghdl_Index_Type;
                              Nbr_Drv : Ghdl_Index_Type;
                              Nbr_Ports : Ghdl_Index_Type);
   pragma Convention (C, Resolution_Proc);

   type Guard_Instance_Type is record
      Instance : Block_Instance_Acc;
      Guard : Iir;
   end record;

   type Guard_Instance_Acc is access Guard_Instance_Type;

   function Guard_Func (Data : System.Address) return Ghdl_B1;
   pragma Convention (C, Guard_Func);

   --  The entry point of the simulator.
   procedure Simulation_Entity (Top_Conf : Iir_Design_Unit);

   type Process_State_Array is
      array (Process_Index_Type range <>) of aliased Process_State_Type;
   type Process_State_Array_Acc is access Process_State_Array;

   --  Array containing all processes.
   Processes_State: Process_State_Array_Acc;

   function Execute_Signal_Value (Indirect: Iir_Value_Literal_Acc)
                                 return Iir_Value_Literal_Acc;

   function Execute_Event_Attribute (Lit: Iir_Value_Literal_Acc)
                                    return Boolean;

   function Execute_Active_Attribute (Lit: Iir_Value_Literal_Acc)
                                     return Boolean;
   function Execute_Driving_Attribute (Lit: Iir_Value_Literal_Acc)
                                      return Boolean;

   function Execute_Last_Value_Attribute (Indirect: Iir_Value_Literal_Acc)
                                         return Iir_Value_Literal_Acc;
   function Execute_Driving_Value_Attribute (Indirect: Iir_Value_Literal_Acc)
                                            return Iir_Value_Literal_Acc;

   --  Return the Last_Event absolute time.
   function Execute_Last_Event_Attribute (Indirect: Iir_Value_Literal_Acc)
                                         return Ghdl_I64;
   function Execute_Last_Active_Attribute (Indirect: Iir_Value_Literal_Acc)
                                          return Ghdl_I64;

   -- Type for a transaction: it contains the value, the absolute time at which
   -- the transaction should occur and a pointer to the next transaction.
   -- This constitute a simple linked list, the elements must be ordered
   -- according to time.
   type Transaction_El_Type is record
      -- The value of the waveform element.
      -- Can't be an array.
      -- Life must be target.
      Value: Iir_Value_Literal_Acc;

      -- After time at which the transaction should occur.
      After : Grt.Types.Std_Time;
   end record;

   type Transaction_Array is array (Natural range <>) of Transaction_El_Type;

   type Transaction_Type (Len : Natural) is record
      -- Statement that created this transaction.  Used to disp location
      -- in case of error (constraint error).
      Stmt: Iir;

      Reject : Std_Time;

      Els : Transaction_Array (1 .. Len);
   end record;

   procedure Assign_Value_To_Signal (Instance: Block_Instance_Acc;
                                     Target: Iir_Value_Literal_Acc;
                                     Transaction: Transaction_Type);

   procedure Disconnect_Signal (Sig : Iir_Value_Literal_Acc);

   -- Return true if the process should be suspended.
   function Execute_Wait_Statement (Instance : Block_Instance_Acc;
                                    Stmt: Iir_Wait_Statement)
                                   return Boolean;
end Simulation;