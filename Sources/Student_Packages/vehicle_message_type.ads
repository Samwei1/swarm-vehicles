-- Suggestions for packages which might be useful:

with Ada.Real_Time;         use Ada.Real_Time;
with Swarm_Structures_Base; use Swarm_Structures_Base;
with Swarm_Configuration; use Swarm_Configuration;
package Vehicle_Message_Type is

   -- Replace this record definition by what your vehicles need to communicate.
   type Array_Boolean is array (Natural range <>) of Boolean;
   type Inter_Vehicle_Messages is record
      Globe_Found :  Energy_Globes (1 .. 100);
      Message_Time : Time := Clock;
      Emergency_Time : Time := Clock;
      No_of_Globes : Integer := 0;
      is_Found : Boolean := False;
      Emergency : Array_Boolean (1 .. Initial_No_of_Elements) := (others => False);
      Collect_Information : Array_Boolean (1 .. Initial_No_of_Elements) := (others => False);
      run_out_energy : Array_Boolean (1 .. Initial_No_of_Elements) := (others => False);
   end record;

   -- velocity and position communicate.
end Vehicle_Message_Type;
