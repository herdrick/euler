% Project Euler problem 31 
% my first Erlang program. pretty ugly and not idiomatic, mostly. uses the notorious process dictionary for state, specially to hold the graph search frontier queue and explored set.
% uses breadth-first search 
% uncomment the io:format statement with 'SOLUTION' to see all solutions

-module(euler31).
-export([coins_graph_search/4,solve/2,init_params/0]).

sum(L) -> 
    lists:foldl(fun(X, Acc) -> X + Acc end, 0, L).

product(L1,L2) ->
    lists:map(fun(X)->element(1,X) * element(2,X) end, lists:zip(L1,L2)).

init_params() ->
                put(frontier, queue:new()),    % change this to a stack, (and change the frontier_XXX functions appropriately) and this becomes depth-first search.
                put(explored, gb_sets:new()).

is_explored(Node) ->
                gb_sets:is_element(Node,get(explored)).

mark_as_explored(Node) ->
                put(explored,gb_sets:add(Node,get(explored))).

frontier_pop() ->
      case queue:is_empty(get(frontier)) of
           true -> false;     
           false -> 
             Value_and_frontier = queue:out(get(frontier)),
             put(frontier, element(2,Value_and_frontier)),
             element(2,element(1,Value_and_frontier))
      end.

next_unexplored_node() ->
            Next_node = frontier_pop(),
            case is_explored(Next_node) of
                 true -> next_unexplored_node(); % tail-recursive, sweet
                 false -> Next_node
            end. 
      
frontier_push(X) ->
                put(frontier,queue:in(X,get(frontier))).

% Coins represents the counts of the types of coints, ex.[29,1,3,0,0,0,0,1]  These are also nodes in our graph. Incrementing any one of those coins gives a node with an edge from the current node. 
% Calculting Values_length only once is an opt.
coins_graph_search(Target, Coins, Values, Values_length) ->
           Cash_value = sum(product(Coins,Values)),
           Helper=fun () when Cash_value == Target -> % io:format('SOLUTION: ~p\n',[Coins]),
                                                                                 1;
                              () when Cash_value > Target -> 0;
                              () -> 
                                                         % add all child nodes to the frontier
                                                         lists:map(fun (Idx) -> 
                                                                                          Child_coins = lists:sublist(Coins,1,Idx-1)++[lists:nth(Idx,Coins)+1]++lists:sublist(Coins,Idx+1,Values_length), % Child_coins is just Coins with one of the coin counts incremented
                                                                                          frontier_push(Child_coins)  % note that we will often push the same node onto the frontier many times.
                                                                                          end,
                                                                                     lists:seq(1, Values_length, 1)),
                                                         0  % this node is not a leaf, neither a solution nor a failure. return 0, and below (in this call to coins_graph_search) we'll pop the next node off the frontier.
                              end, 
           Is_solution = Helper(), % Is_solution is either 0 or 1. Kind of ugly.
           mark_as_explored(Coins),
           case next_unexplored_node() of
                false -> io:format('DONE\n'),
                              io:format('~p nodes explored \n',[gb_sets:size(get(explored))]), 
                              Is_solution;
                Next_node ->  
                         Is_solution + coins_graph_search(Target,Next_node,Values,Values_length)  % recur. note that this style of graph traversal, popping a node off the frontier to recur on, means that the call stack doesn't look like a path decending through the graph with max depth being the max depth of the graph. instead we go one level deeper into the call stack for each node in the graph. this is true whether we do BFS or DFS.
                         % this function is not tail recursive. put Is_solution into the signature of coins_graph_search() and then return that plus to make it so.
           end.


solve(Target,Values) ->
         init_params(),
         coins_graph_search(Target,lists:duplicate(length(Values), 0),Values,length(Values)).
