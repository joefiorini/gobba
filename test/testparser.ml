open Gobba.Types
open Util

module A = Alcotest

let test_numbers () =
   checkparse "-3" (NumInt(-3));
   checkparse "-1251356125" (NumInt(-1251356125));
   checkparse "-32" (NumInt(-32));
   checkparse "0" (NumInt(0));
   checkparse "0" (NumInt(0));
   checkparse "2.3 :+ 4.5" (Binop(MakeComplex, NumFloat 2.3, NumFloat 4.5))

let test_bool () =
  checkparse "true" (Boolean(true));
  checkparse "false" (Boolean(false))

let test_unit () = checkparse "()" (Unit)

let test_arithmetic () =
  checkparse "5 + 3" (Binop(Plus,NumInt 5, NumInt 3));
  checkparse "x - 123" (Binop(Sub,Symbol "x", NumInt 123));
  checkparse "x * 123" (Binop(Mult,Symbol "x", NumInt 123));
  checkparse "1235 + 2345 * (123 - 2) + 11"
    (Binop(Plus,Binop(Plus,(NumInt 1235),
                  Binop(Mult,(NumInt 2345), Binop(Sub,(NumInt 123), (NumInt 2)))),
           (NumInt 11)));
  checkparse "1234 + -32" (Binop(Plus,(NumInt 1234), (NumInt(-32))));
  checkparsefail "1234 +- 32";
  checkparsefail "1234 /- 32";
  checkparsefail "1234 + + 32"

let test_lists () =
  checkparse "[]" (List []);
  checkparse "[1,2,3]" (List [NumInt 1; NumInt 2; NumInt 3]);
  checkparse "[1,2,[1,2,3]]" (List [NumInt 1; NumInt 2; List [NumInt 1; NumInt 2; NumInt 3]])

let test_dicts () =
  checkparse "{}" (Dict []);
  checkparse "{a = 1, b = [1, 2, 3], abcde = fun x -> x}"
    (Dict
       [(false, "a", (NumInt 1));
        (false, "b", (List [(NumInt 1); (NumInt 2); (NumInt 3)]));
        (false, "abcde", (Lambda ("x", (Symbol "x"))))]);
  checkparsefail "{342=}"; checkparsefail "{;}";
  checkparsefail "{;=}"; checkparsefail "{a=}"



let test_random_hell () =
  checkparse "[(20 >> () >> ([0, ([] >> [] >> [1] >> let f = fun n -> if n < 2 then n else f(n - 1) in f 3)])), [30, 40, 50], 2]"
  (List
      [(Sequence ((Sequence ((NumInt 20), Unit)),
          (List
             [(NumInt 0);
               (Sequence (
                  (Sequence ((Sequence ((List []), (List []))),
                     (List [(NumInt 1)]))),
                  (Let (
                     [(false, "f",
                       (Lambda ("n",
                          (IfThenElse (
                             (Binop (Lt, (Symbol "n"), (NumInt 2))),
                             (Symbol "n"),
                             (Apply ((Symbol "f"),
                                (Binop (Sub, (Symbol "n"), (NumInt 1)))))
                             ))
                          )))
                       ],
                     (Apply ((Symbol "f"), (NumInt 3)))))
                  ))
               ])
          ));
        (List [(NumInt 30); (NumInt 40); (NumInt 50)]); (NumInt 2)])

let test_misc_functions () =
  checkparse
    "let fib = fun n -> if n < 2 then n else fib (n - 1) + fib (n - 2) in fib 5"
    (Let (
      [(false, "fib",
        (Lambda ("n",
           (IfThenElse ((Binop (Lt, (Symbol "n"), (NumInt 2))), (Symbol "n"),
              (Binop (Plus,
                 (Apply ((Symbol "fib"),
                    (Binop (Sub, (Symbol "n"), (NumInt 1))))),
                 (Apply ((Symbol "fib"),
                    (Binop (Sub, (Symbol "n"), (NumInt 2)))))
                 ))
              ))
           )))
        ],
      (Apply ((Symbol "fib"), (NumInt 5)))));
  checkparse "let lazy fact = fun n -> if n < 2 then n else n * fact (n - 1) in fact 20"
     (Let (
      [(true, "fact",
        (Lambda ("n",
           (IfThenElse ((Binop (Lt, (Symbol "n"), (NumInt 2))), (Symbol "n"),
              (Binop (Mult, (Symbol "n"),
                 (Apply ((Symbol "fact"),
                    (Binop (Sub, (Symbol "n"), (NumInt 1)))))
                 ))
              ))
           )))
        ],
      (Apply ((Symbol "fact"), (NumInt 20)))))

let test_pipeline () =
  checkparse
    "((let fib = fun n -> if n < 2 then n else (fib (n - 1)) + (fib (n - 2)) in fib) >=> (fun x -> x + 1)) "
   (Binop (Compose, (Lambda ("x", (Binop (Plus, (Symbol "x"), (NumInt 1))))),
      (Let (
         [(false, "fib",
           (Lambda ("n",
              (IfThenElse ((Binop (Lt, (Symbol "n"), (NumInt 2))),
                 (Symbol "n"),
                 (Binop (Plus,
                    (Apply ((Symbol "fib"),
                       (Binop (Sub, (Symbol "n"), (NumInt 1))))),
                    (Apply ((Symbol "fib"),
                       (Binop (Sub, (Symbol "n"), (NumInt 2)))))
                    ))
                 ))
              )))
           ],
         (Symbol "fib")))
      ))

let test_suite = List.map quickcase [
    ("parse numbers", test_numbers);

    ("booleans", test_bool);
    ("unit", test_unit);
    ("lists", test_lists);
    ("dictionaries", test_dicts);
    ("arithmetics", test_arithmetic);
    ("miscellaneous functions", test_misc_functions)
  ]