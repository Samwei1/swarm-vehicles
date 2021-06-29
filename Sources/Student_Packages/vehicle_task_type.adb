-- Suggestions for packages which might be useful:
with Ada.Real_Time;              use Ada.Real_Time;
with Exceptions;                 use Exceptions;
with Real_Type;                  use Real_Type;
--  with Generic_Sliding_Statistics;
--  with Rotations;                  use Rotations;
with Vectors_3D;                 use Vectors_3D;
with Vehicle_Interface;          use Vehicle_Interface;
with Swarm_Structures_Base; use Swarm_Structures_Base;
with Vehicle_Message_Type;       use Vehicle_Message_Type;
with Ada.Numerics.Elementary_Functions;   use Ada.Numerics.Elementary_Functions;
with Swarm_Configuration; use Swarm_Configuration;
with Ada.Numerics; use Ada.Numerics;
with Swarm_Size; use Swarm_Size;

package body Vehicle_Task_Type is
   task body Vehicle_Task is
      Vehicle_No : Positive;
      mesg : Inter_Vehicle_Messages;
      Write_Message : Boolean := False;
      --next destination
      To : Vector_3D;
      -- variables for calculation next destination
      V_Angle : Long_Float;
      G_x : Real;
      G_y : Real;
      G_z : Real;
      -- save the latest message
      latest_message : Inter_Vehicle_Messages;
      -- set danger level
      danger_charge : constant Vehicle_Charges := 0.55;
      -- this is for picking vechile for counting number of vehicles
      group : Boolean;
      -- save closest globe from multiple energy globes
      Close_Globe : Energy_Globe;
      -- bound of outdated message
      message_outdate : Duration := 0.45;
      --Set speed
      search_mesg_speed : constant Throttle_T := 0.25;
      emergency_speed : constant Throttle_T := 1.0;
      normal_speed : constant Throttle_T := 0.2;
      after_charge_speed : constant Throttle_T := 0.68;
      rush_speed : constant Throttle_T := 0.73;
      start_time : Time;
      --Set radius
      after_charge_radius :  Long_Float;
      waiting_radius : Long_Float;
      Collect_Information_Duration :constant Duration := 20.0;
      Collect_Start_Time : Time;
      Number_of_vehicle : Integer ;
      Number_of_reduction : Integer;

      -- You will want to take the pragma out, once you use the "Vehicle_No"

      -- Once vehicle find globes, they send messages to others.

      -- search globes and send message to other vehicles
      procedure Vehicle_Search_Globe is
      begin
         if Energy_Globes_Around'Length > 0 then
            Write_Message := True;
            latest_message.is_Found := True;
            latest_message.No_of_Globes := Energy_Globes_Around'Length;
            latest_message.Message_Time := Clock;
            latest_message.Emergency(Vehicle_No) := False;
            latest_message.Collect_Information(Vehicle_No) := True;
            for i in Energy_Globes_Around'Range loop
               latest_message.Globe_Found (i) := Energy_Globes_Around (i);
            end loop;
            Send (latest_message);
         end if;

      end Vehicle_Search_Globe;
      -- find the next position for vehiles running on cycle track
      function Find_Position (x : Real; y : Real; z : Real; radius : Real;  angle : Long_Float) return Vector_3D is
      begin
         return (x + radius * Real (Cos (Float (angle))) , y  +  radius *Real (Sin (Float (angle))) ,
                 z  );
      end Find_Position;
      -- this is for supportting Find_Position Function
      function Find_Angle (angle : Long_Float; direction : Boolean) return Long_Float is
      begin
         if direction then
            return (angle + 0.015);
         else
            return (angle + 0.015);
         end if;

      end Find_Angle;
      -- calculate distance between two positions
      function Find_Distance (a:Positions ; b : Positions) return Float is
         x_distance : Float;
         y_distance : Float;
         z_distance : Float;
         Current_distance : Float;
      begin
         x_distance := Float((a (x) - b (x)));
         y_distance := Float((a (y) - b (y)));
         z_distance := Float((a (z) - b (z)));
         Current_distance := x_distance * x_distance + y_distance * y_distance + z_distance * z_distance;
         return Current_distance;
      end Find_Distance;


      -- find the closest energy globe
      function Find_Close_Globe (Globes : Energy_Globes; No_G : Integer; Current_position : Positions) return Energy_Globe is
         distance :Float := 0.0;
         Current_distance : Float;
         index : Integer;
         i :  Integer := 1;
      begin
         while i <= No_G loop
            Current_distance := Find_Distance(Globes(i).Position , Current_position);
            if i = 1 then
               distance := Current_distance;
               index := 1;
            else
               if Current_distance < distance then
                  distance := Current_distance;
                  index := i;
               end if;
            end if;
            i := i + 1;
         end loop;
         return Globes(index);
      end Find_Close_Globe;

      -- counting the number of vehicles in emergency
      function Find_Emergency(a:Array_Boolean; n : Integer) return Boolean is
         counter :Integer := 0;
      begin
         for i in a'Range loop
            if a(i) then
               counter := counter + 1;
            end if;
         end loop;
         if counter < n then
            return False;
         else
            return True;
         end if;

      end Find_Emergency;
      -- counting the number of vehicles recorded.
      function Find_Vehicle (a:Array_Boolean ) return Integer is
         counter : Integer :=0;
      begin
         for i in a'Range loop
            if a(i) then
               counter := counter + 1;
            end if;
         end loop;
         return counter;
      end Find_Vehicle;



   begin
      -- setting different radiuses for different number of vehicles
      if Initial_No_of_Elements <= 16 then
         after_charge_radius  := 0.5;
         waiting_radius := 0.2;
      elsif Initial_No_of_Elements <= 64 then
         after_charge_radius  := 0.15;
         waiting_radius := 0.1;
      elsif Initial_No_of_Elements <= 128 then
         after_charge_radius  := 0.2;
         waiting_radius := 0.1;
      elsif Initial_No_of_Elements <= 158 then
         after_charge_radius  := 0.25;
         waiting_radius := 0.1;
         message_outdate := 0.55;
      elsif Initial_No_of_Elements <= 195 then
         after_charge_radius  := 0.35;
         waiting_radius := 0.1;
         message_outdate := 0.65;
      else
         after_charge_radius  := 0.45;
         waiting_radius := 0.1;
         message_outdate := 0.7;
      end if;



      -- You need to react to this call and provide your task_id.
      -- You can e.g. employ the assigned vehicle number (Vehicle_No)
      -- in communications with other vehicles.
      accept Identify (Set_Vehicle_No : Positive; Local_Task_Id : out Task_Id) do
         Vehicle_No     := Set_Vehicle_No;
         Local_Task_Id  := Current_Task;
      end Identify;

      -- Replace the rest of this task with your own code.
      -- Maybe synchronizing on an external event clock like "Wait_For_Next_Physics_Update",
      -- yet you can synchronize on e.g. the real-time clock as well.

      -- Without control this vehicle will go for its natural swarming instinct.

     select

         Flight_Termination.Stop;

      then abort
         Collect_Start_Time := Clock;
         V_Angle := Long_Float (Vehicle_No);
         Outer_task_loop : loop

            Wait_For_Next_Physics_Update;
            -- Your vehicle should respond to the world here: sense, listen, talk, act?

            Vehicle_Search_Globe;
            start_time := Clock;
            group := Vehicle_No mod 400 = 1;
            -- this part is for calculating the number of vehicles
            if group and then To_Duration (Clock - Collect_Start_Time) > Collect_Information_Duration then
               Number_of_vehicle := Find_Vehicle (latest_message.Collect_Information);
               Number_of_reduction := Number_of_vehicle - Target_No_of_Elements;
               declare
                  index : Integer := 1;
               begin
                  while index < Number_of_reduction + 1 loop
                     if index mod 400 = 1 then
                        Number_of_reduction := Number_of_reduction + 1;
                     else
                        if not latest_message.Collect_Information (index) then
                           latest_message.Collect_Information(index):= True;
                           null;
                        end if;

                           latest_message.run_out_energy(index) := True;
                     end if;
                     index := index + 1;
--                       Put_Line(Integer'Image(index));
                  end loop;
               end;
               Send(latest_message);
            end if;

            -- if vehicles not write message by themselves, check receiveing any message or not.
            if not Write_Message then
               if Messages_Waiting then
                  Receive (mesg);
                  if mesg.is_Found then
                     Write_Message := True;
                     latest_message := mesg;
                  end if;
               end if;
            end if;
            -- if vehicles are chose to vanish, they cannot recharge
            if latest_message.run_out_energy(Vehicle_No) then
               V_Angle := Find_Angle (V_Angle, group);
               To := Find_Position (G_x, G_y, G_z, after_charge_radius+0.1, V_Angle);
               Set_Destination (To);
               Set_Throttle (0.5);
               Send(latest_message);
            else

               if Messages_Waiting then
                  Receive (mesg);
                  -- check message is newest or not
                  if mesg.is_Found and then latest_message.Message_Time <= mesg.Message_Time then
                     if latest_message.Emergency_Time >= mesg.Message_Time then
                        mesg.Emergency := latest_message.Emergency;
                     end if;
                     latest_message := mesg;
                  else
                     if mesg.is_Found and then mesg.Emergency_Time > latest_message.Emergency_Time then
                        latest_message.Emergency := mesg.Emergency;
                     end if;
                  end if;
               end if;

               if Write_Message and then latest_message.is_Found then
               -- check message is outdated or not
                  if To_Duration (start_time - latest_message.Message_Time) < message_outdate then
                     Close_Globe := Find_Close_Globe (latest_message.Globe_Found, latest_message.No_of_Globes, Position);
                     G_x := Close_Globe.Position (x);
                     G_y := Close_Globe.Position (y);
                     G_z := Close_Globe.Position (z);
                     -- assigning vehicles to differnt tracks beased on energy level
                     if  Current_Charge < 0.8 then
                        if Current_Charge < danger_charge then
                           latest_message.Collect_Information (Vehicle_No) := True;
                           latest_message.Emergency_Time := Clock;
                           latest_message.Emergency (Vehicle_No) := True;
                           Set_Destination (Close_Globe.Position);
                           Set_Throttle (emergency_speed);
                           Send (latest_message);
                        else
                           if Find_Emergency (latest_message.Emergency, 2) then
                              latest_message.Collect_Information (Vehicle_No) := True;
                              latest_message.Emergency (Vehicle_No) := False;
                              V_Angle := Find_Angle (V_Angle, group);
                              To := Find_Position (G_x, G_y, G_z, waiting_radius, V_Angle);
                              Set_Destination (To);
                              Set_Throttle (normal_speed);
                              Send (latest_message);
                           else
                              latest_message.Collect_Information (Vehicle_No) := True;
                              latest_message.Emergency (Vehicle_No) := False;
                              Set_Destination (Close_Globe.Position);
                              Set_Throttle (rush_speed);
                              Send (latest_message);
                           end if;
                        end if;

                     else
                        if Current_Charge > 0.95 then
                           V_Angle := Find_Angle (V_Angle, group);
                           To := Find_Position (G_x, G_y, G_z, after_charge_radius, V_Angle);
                           latest_message.Collect_Information (Vehicle_No) := True;
                           latest_message.Emergency (Vehicle_No) := False;
                           Set_Destination (To);
                           Set_Throttle (after_charge_speed);
                           Send (latest_message);
                        else
                           V_Angle := Find_Angle (V_Angle, group);
                           To := Find_Position (G_x, G_y, G_z, after_charge_radius, V_Angle);
                           latest_message.Emergency (Vehicle_No) := False;
                           Set_Destination (To);
                           Set_Throttle (normal_speed);
                           latest_message.Collect_Information (Vehicle_No) := True;
                           Send (latest_message);
                        end if;
                     end if;
                  else
                     -- message is outdated, go to the closest energy globe
                     Close_Globe := Find_Close_Globe (latest_message.Globe_Found, latest_message.No_of_Globes, Position);
                     Set_Destination (Close_Globe.Position);
                     Set_Throttle (search_mesg_speed);
                     latest_message.Collect_Information (Vehicle_No) := True;
                     latest_message.Emergency (Vehicle_No) := False;
                     Send (latest_message);
                  end if;
               end if;
            end if;

         end loop Outer_task_loop;
     end select;

   exception
      when E : others => Show_Exception (E);

   end Vehicle_Task;

end Vehicle_Task_Type;
