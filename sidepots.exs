defmodule Poker.Hand do

 def sidepots(bets,stakes) do
   Enum.zip(Tuple.to_list(bets),Tuple.to_list(stakes))
   |> Enum.filter_map(fn({_,s})->s==0 end,fn({b,_})->b end)
   |> Enum.sort
   |> ranges
   |> Enum.map(fn({a,b})->sidepot(bets,{a,b}) end)
 end

 def sidepot(bets,{a,b}) do
   Enum.reduce(Tuple.to_list(bets),0,fn(bet,pot)->
     cond do
       bet > b -> pot + b - a
       bet > a -> pot + bet - a
       true -> pot
     end
   end )
 end

 def ranges(stakelist), do:  Enum.zip([0|stakelist],stakelist++[9999])


end

Poker.Hand.sidepots({1,2,3},{10,0,10}) |> inspect |> IO.puts
