-module(bench).
-behaviour(gen_server).

-export([main/1, start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

start_link() ->
    gen_server:start_link(?MODULE, 0, []).

main(N) when is_integer(N), N >= 0 ->
    {ok, Pid} = start_link(),
    send_loop(Pid, N),
    Count = gen_server:call(Pid, barrier, infinity),
    case Count of
        N -> ok;
        _ -> erlang:error({count_mismatch, N, Count})
    end,
    ok = gen_server:stop(Pid).

send_loop(_Pid, 0) -> ok;
send_loop(Pid, N) ->
    gen_server:cast(Pid, tick),
    send_loop(Pid, N - 1).

init(Initial) -> {ok, Initial}.

handle_cast(tick, Count) -> {noreply, Count + 1}.

handle_call(barrier, _From, Count) -> {reply, Count, Count}.

handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.
