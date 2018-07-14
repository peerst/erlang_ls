-module(erlang_ls_text_synchronization).

-export([ did_open/1
        , did_save/2
        ]).

-spec did_open(map()) -> ok.
did_open(Params) ->
  TextDocument = maps:get(<<"textDocument">>, Params),
  Uri          = maps:get(<<"uri">>         , TextDocument),
  Text         = maps:get(<<"text">>        , TextDocument),
  {ok, Pid}    = supervisor:start_child(erlang_ls_buffer_sup, [Text]),
  ok           = erlang_ls_buffer_server:add_buffer(Uri, Pid).

-spec did_save(any(), map()) -> ok.
did_save(Socket, Params) ->
  TextDocument = maps:get(<<"textDocument">>, Params),
  Uri          = maps:get(<<"uri">>         , TextDocument),
  CDiagnostics = erlang_ls_compiler_diagnostics:diagnostics(Uri),
  DDiagnostics = erlang_ls_dialyzer_diagnostics:diagnostics(Uri),
  Method = <<"textDocument/publishDiagnostics">>,
  Params1  = #{ uri => Uri
              , diagnostics => CDiagnostics ++ DDiagnostics
              },
  erlang_ls_protocol:notification(Socket, Method, Params1),
  ok.