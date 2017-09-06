-module(fib).
-compile(export_all).

fib(End,N,LastFib,SecondLastFib) ->
  case N of
    End -> LastFib + SecondLastFib;
    0 -> fib(End, 1, 0, 0) ;
    1 -> fib(End, 2, 1, 0) ;
    _ -> fib(End,N+1,SecondLastFib+LastFib,LastFib)
  end.
fib(N)->
  fib(N,0,0,0).

