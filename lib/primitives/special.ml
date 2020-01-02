open Types
open Typecheck
open Util

(* Special Primitives that are eval-recursive *)
(** Map a function over an iterable structure *)
let map args applyfun opts =
  let f, s =
    match args with [ f; s ] -> (f, s) | _ -> raise WrongPrimitiveArgs
  in
  typecheck f "fun";
  match s with
  | EvtList x ->
    EvtList
      (List.map (fun x -> applyfun f [ AlreadyEvaluated x ] opts) x)
  | EvtDict d ->
    let keys, values = unzip d in
    EvtDict
      (zip keys
         (List.map
            (fun x -> applyfun f [ AlreadyEvaluated x ] opts)
            values))
  | _ -> failwith "Value is not iterable"

let map2 args applyfun opts =
  let f, s1, s2 =
    match args with
    | [ f; s1; s2 ] -> (f, s1, s2)
    | _ -> raise WrongPrimitiveArgs
  in
  typecheck f "fun";
  match s1 with
  | EvtList x ->
    let y = unpack_list s2 in
    EvtList
      (List.map2
         (fun a b ->
            applyfun f [ AlreadyEvaluated a; AlreadyEvaluated b ] opts)
         x y)
  | _ -> failwith "Value is not iterable"

let foldl args applyfun opts =
  let f, a, s =
    match args with
    | [ f; ac; s ] -> (f, ac, s)
    | _ -> raise WrongPrimitiveArgs
  in
  typecheck f "fun";
  match s with
  | EvtList x ->
    List.fold_left
      (fun acc x ->
         applyfun f [ AlreadyEvaluated acc; AlreadyEvaluated x ] opts)
      a x
  | EvtDict d ->
    let _, values = unzip d in
    List.fold_left
      (fun acc x ->
         applyfun f [ AlreadyEvaluated acc; AlreadyEvaluated x ] opts)
      a values
  | _ -> failwith "Value is not iterable"

let filter args applyfun opts =
  let p, s =
    match args with
    | [ p; s ] -> (p, s)
    | _ -> raise WrongPrimitiveArgs
  in
  typecheck p "fun";
  match s with
  | EvtList x ->
    EvtList
      (List.filter
         (fun x ->
            applyfun p [ AlreadyEvaluated x ] opts = EvtBool true)
         x)
  | EvtDict d ->
    EvtDict
      (List.filter
         (fun (_, v) ->
            applyfun p [ AlreadyEvaluated v ] opts = EvtBool true)
         d)
  | _ -> failwith "Value is not iterable"

let table = [
  ("map", (map, 2));
  ("map2", (map2, 3));
  ("foldl", (foldl, 3));
  ("filter", (filter, 2));
]