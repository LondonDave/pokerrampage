defmodule Poker do

  <<a::size(32), b::size(32), c::size(32)>> = :crypto.rand_bytes(12)
  :random.seed({a, b, c})

  def deal do
    deal = Enum.shuffle(0..51) |> Enum.map(fn(x)->{rem(x,13)+2,div(x,13)} end)
    board = Enum.take(deal,5)
    hands = deal |> Enum.drop(5) |> Enum.chunk(2) |> Enum.take(6)
    evals = Enum.map(hands,fn(x)->evaluate(board,x) end)
    [unparse(board)|evals]
  end

  def evaluate(board, holecards) do
    hand = holecards ++ board
    {value,profile,suit} = hand_value(hand)
    {unparse(holecards),value,mask(profile,suit,hand)}
  end

  def hand_value(hand) do
    Enum.max([meld_value(hand),flush_value(hand),straight_value(hand)])
  end

  def meld_value(hand) do
    melds = hand |> ranks |> Tuple.to_list |> Enum.with_index
    |> Enum.filter(fn({n,_})->n>0 end)
    |> Enum.sort(&(&1 > &2))
    case melds do
      [{4,a},{3,b}]                                -> {digitise([8,a,b,0,0,0]),[a,a,a,a,b],nil}
      [{4,a},{2,b},{1,c}] when c > b               -> {digitise([8,a,c,0,0,0]),[a,a,a,a,c],nil}
      [{4,a},{2,b},{1,c}] when c <= b              -> {digitise([8,a,b,0,0,0]),[a,a,a,a,b],nil}
      [{4,a},{1,b},{1,_},{1,_}]                    -> {digitise([8,a,b,0,0,0]),[a,a,a,a,b],nil}
      [{3,a},{3,b},{1,_}]                          -> {digitise([7,a,b,0,0,0]),[a,a,a,b,b],nil}
      [{3,a},{2,b},{2,_}]                          -> {digitise([7,a,b,0,0,0]),[a,a,a,b,b],nil}
      [{3,a},{2,b},{1,_},{1,_}]                    -> {digitise([7,a,b,0,0,0]),[a,a,a,b,b],nil}
      [{3,a},{1,b},{1,c},{1,_},{1,_}]              -> {digitise([4,a,b,c,0,0]),[a,a,a,b,c],nil}
      [{2,a},{2,b},{2,c},{1,d}] when d > c         -> {digitise([3,a,b,d,0,0]),[a,a,b,b,d],nil}
      [{2,a},{2,b},{2,c},{1,d}] when d <= c        -> {digitise([3,a,b,c,0,0]),[a,a,b,b,c],nil}
      [{2,a},{2,b},{1,c},{1,_},{1,_}]              -> {digitise([3,a,b,c,0,0]),[a,a,b,b,c],nil}
      [{2,a},{1,b},{1,c},{1,d},{1,_},{1,_}]        -> {digitise([2,a,b,c,d,0]),[a,a,b,c,d],nil}
      [{1,a},{1,b},{1,c},{1,d},{1,e},{1,_},{1,_}]  -> {digitise([1,a,b,c,d,e]),[a,b,c,d,e],nil}
    end
  end

  def flush_value(hand) do
    {n,s} = hand |> suits |> Tuple.to_list |> Enum.with_index |> Enum.max
    if n < 5 do
      0
    else
      suitranks = ranksbysuit(hand,s)  |> Tuple.to_list |> Enum.with_index
                                       |> Enum.filter_map(fn({n,_})->n>0 end,fn({_,r})->r end)
                                       |> Enum.sort(&(&1 > &2))
      case suitranks do
        [a,b,c,d,e]     when a-1==b and b-1==c and c-1==d and d-1==e -> {digitise([9,a,0,0,0,0]),[a,b,c,d,e],s}
        [_,a,b,c,d,e]   when a-1==b and b-1==c and c-1==d and d-1==e -> {digitise([9,a,0,0,0,0]),[a,b,c,d,e],s}
        [a,b,c,d,e,_]   when a-1==b and b-1==c and c-1==d and d-1==e -> {digitise([9,a,0,0,0,0]),[a,b,c,d,e],s}
        [a,b,c,d,e,_,_] when a-1==b and b-1==c and c-1==d and d-1==e -> {digitise([9,a,0,0,0,0]),[a,b,c,d,e],s}
        [_,a,b,c,d,e,_] when a-1==b and b-1==c and c-1==d and d-1==e -> {digitise([9,a,0,0,0,0]),[a,b,c,d,e],s}
        [_,_,a,b,c,d,e] when a-1==b and b-1==c and c-1==d and d-1==e -> {digitise([9,a,0,0,0,0]),[a,b,c,d,e],s}
        [14,5,4,3,2]                                                 -> {digitise([9,5,0,0,0,0]),[5,4,3,2,14],s}
        [14,_,5,4,3,2]                                               -> {digitise([9,5,0,0,0,0]),[5,4,3,2,14],s}
        [14,_,_,5,4,3,2]                                             -> {digitise([9,5,0,0,0,0]),[5,4,3,2,14],s}
        [a,b,c,d,e]                                                  -> {digitise([6,a,b,c,d,e]),[a,b,c,d,e],s}
        [a,b,c,d,e,_]                                                -> {digitise([6,a,b,c,d,e]),[a,b,c,d,e],s}
        [a,b,c,d,e,_,_]                                              -> {digitise([6,a,b,c,d,e]),[a,b,c,d,e],s}
      end
    end
  end

  def straight_value(hand) do
    allranks = ranks(hand) |> Tuple.to_list |> Enum.with_index
                           |> Enum.filter_map(fn({n,_})->n>0 end,fn({_,r})->r end)
                           |> Enum.sort(&(&1 > &2))
    case allranks do
      [a,b,c,d,e]     when a-1==b and b-1==c and c-1==d and d-1==e -> {digitise([5,a,0,0,0,0]),[a,b,c,d,e],nil}
      [_,a,b,c,d,e]   when a-1==b and b-1==c and c-1==d and d-1==e -> {digitise([5,a,0,0,0,0]),[a,b,c,d,e],nil}
      [a,b,c,d,e,_]   when a-1==b and b-1==c and c-1==d and d-1==e -> {digitise([5,a,0,0,0,0]),[a,b,c,d,e],nil}
      [a,b,c,d,e,_,_] when a-1==b and b-1==c and c-1==d and d-1==e -> {digitise([5,a,0,0,0,0]),[a,b,c,d,e],nil}
      [_,a,b,c,d,e,_] when a-1==b and b-1==c and c-1==d and d-1==e -> {digitise([5,a,0,0,0,0]),[a,b,c,d,e],nil}
      [_,_,a,b,c,d,e] when a-1==b and b-1==c and c-1==d and d-1==e -> {digitise([5,a,0,0,0,0]),[a,b,c,d,e],nil}
      [14,5,4,3,2]                                                 -> {digitise([5,5,0,0,0,0]),[5,4,3,2,14],nil}
      [14,_,5,4,3,2]                                               -> {digitise([5,5,0,0,0,0]),[5,4,3,2,14],nil}
      [14,_,_,5,4,3,2]                                             -> {digitise([5,5,0,0,0,0]),[5,4,3,2,14],nil}
      _                                                            -> {0,nil,nil}
    end
  end

  def ranks(hand) do
    Enum.reduce(hand,{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},fn({r,_},acc) ->
      new_count = elem(acc,r) + 1
      put_elem(acc,r,new_count)
    end )
  end

  def ranksbysuit(hand,suit) do
    Enum.reduce(hand,{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},fn({r,s},acc) ->
      if s==suit, do: put_elem(acc,r,1), else: acc
    end )
  end

  def suits(hand) do
    Enum.reduce(hand,{0,0,0,0},fn({_,s},acc) ->
      new_count = elem(acc,s) + 1
      put_elem(acc,s,new_count)
    end )
  end

  def parse(card_string) do
    card_string
    |> String.codepoints
    |> Enum.chunk(2)
    |> Enum.map(fn([r,s])->{rindex(r),sindex(s)} end)
  end
  def rindex(r), do: Enum.find_index(String.codepoints("  23456789TJQKA"), &(r==&1))
  def sindex(s), do: Enum.find_index(String.codepoints("cdhs"), &(s==&1))

  def unparse(cards) do
    Enum.flat_map(cards,fn({r,s})-> [String.at("  23456789TJQKA",r),String.at("chds",s)] end) |> Enum.reduce(fn(x,acc)-> acc<>x end)
  end

  def digitise(pattern), do: Enum.reduce(pattern, 0, fn(x, acc) -> x + 16*acc end)

  def mask(profile,suit,hand) do
    Enum.reduce(profile,{0,0,0,0,0,0,0},fn(x,mask)->
      masked_hand = Enum.zip(hand,Tuple.to_list(mask))
      index = Enum.find_index(masked_hand, fn({{r,s},m})-> m==0 and x==r and (suit==nil||suit==s) end)
      put_elem(mask,index,1)
    end)
  end

end

Enum.each(1..10_000, fn(_)->
# [Poker.evaluate("KsTsQcAsJs","KcQd"),
# Poker.evaluate("4c4d3c3d4c","3h3s"),
# Poker.evaluate("Ac4d3c5d2c","3h3s"),
# Poker.evaluate("Ac4c3c5c2c","3h3s"),
# Poker.evaluate("Ac4c3cKc2c","5cAh"),
# Poker.evaluate("Ac4c3cKd2c","5sAh"),
# Poker.evaluate("Tc4d8c9d4c","6h7s"),
# Poker.evaluate("Ac4c3cKd2c","8s9h"),
# Poker.evaluate("Ac4c3cKd2c","8s9c"),
# Poker.evaluate("4c6d3c5dKc","QhJs")]
# |> inspect(base: :hex)
Poker.deal
|> inspect
# |> Poker.unparse
|> IO.puts
end)
