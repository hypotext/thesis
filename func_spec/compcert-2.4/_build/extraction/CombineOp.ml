open BinNums
open CSEdomain
open Integers
open Op

type valnum = positive

(** val combine_compimm_ne_0 :
    (valnum -> rhs option) -> valnum -> (condition * valnum list) option **)

let combine_compimm_ne_0 get x =
  match get x with
  | Some r ->
    (match r with
     | Op (o, ys) ->
       (match o with
        | Oandimm n -> Some ((Cmasknotzero n), ys)
        | Ocmp c -> Some (c, ys)
        | _ -> None)
     | Load (m, a, l) -> None)
  | None -> None

(** val combine_compimm_eq_0 :
    (valnum -> rhs option) -> valnum -> (condition * valnum list) option **)

let combine_compimm_eq_0 get x =
  match get x with
  | Some r ->
    (match r with
     | Op (o, ys) ->
       (match o with
        | Oandimm n -> Some ((Cmaskzero n), ys)
        | Ocmp c -> Some ((negate_condition c), ys)
        | _ -> None)
     | Load (m, a, l) -> None)
  | None -> None

(** val combine_compimm_eq_1 :
    (valnum -> rhs option) -> valnum -> (condition * valnum list) option **)

let combine_compimm_eq_1 get x =
  match get x with
  | Some r ->
    (match r with
     | Op (o, ys) ->
       (match o with
        | Ocmp c -> Some (c, ys)
        | _ -> None)
     | Load (m, a, l) -> None)
  | None -> None

(** val combine_compimm_ne_1 :
    (valnum -> rhs option) -> valnum -> (condition * valnum list) option **)

let combine_compimm_ne_1 get x =
  match get x with
  | Some r ->
    (match r with
     | Op (o, ys) ->
       (match o with
        | Ocmp c -> Some ((negate_condition c), ys)
        | _ -> None)
     | Load (m, a, l) -> None)
  | None -> None

(** val combine_cond :
    (valnum -> rhs option) -> condition -> valnum list -> (condition * valnum
    list) option **)

let combine_cond get cond args =
  match cond with
  | Ccompimm (c, n) ->
    (match c with
     | Ceq ->
       (match args with
        | [] -> None
        | x :: l ->
          (match l with
           | [] ->
             if Int.eq_dec n Int.zero
             then combine_compimm_eq_0 get x
             else if Int.eq_dec n Int.one
                  then combine_compimm_eq_1 get x
                  else None
           | v :: l0 -> None))
     | Cne ->
       (match args with
        | [] -> None
        | x :: l ->
          (match l with
           | [] ->
             if Int.eq_dec n Int.zero
             then combine_compimm_ne_0 get x
             else if Int.eq_dec n Int.one
                  then combine_compimm_ne_1 get x
                  else None
           | v :: l0 -> None))
     | _ -> None)
  | Ccompuimm (c, n) ->
    (match c with
     | Ceq ->
       (match args with
        | [] -> None
        | x :: l ->
          (match l with
           | [] ->
             if Int.eq_dec n Int.zero
             then combine_compimm_eq_0 get x
             else if Int.eq_dec n Int.one
                  then combine_compimm_eq_1 get x
                  else None
           | v :: l0 -> None))
     | Cne ->
       (match args with
        | [] -> None
        | x :: l ->
          (match l with
           | [] ->
             if Int.eq_dec n Int.zero
             then combine_compimm_ne_0 get x
             else if Int.eq_dec n Int.one
                  then combine_compimm_ne_1 get x
                  else None
           | v :: l0 -> None))
     | _ -> None)
  | _ -> None

(** val combine_addr :
    (valnum -> rhs option) -> addressing -> valnum list ->
    (addressing * valnum list) option **)

let combine_addr get addr args =
  match addr with
  | Aindexed n ->
    (match args with
     | [] -> None
     | x :: l ->
       (match l with
        | [] ->
          (match get x with
           | Some r ->
             (match r with
              | Op (o, ys) ->
                (match o with
                 | Olea a -> Some ((offset_addressing_total a n), ys)
                 | _ -> None)
              | Load (m, a, l0) -> None)
           | None -> None)
        | v :: l0 -> None))
  | _ -> None

(** val combine_op :
    (valnum -> rhs option) -> operation -> valnum list -> (operation * valnum
    list) option **)

let combine_op get op args =
  match op with
  | Oandimm n ->
    (match args with
     | [] -> None
     | x :: l ->
       (match l with
        | [] ->
          (match get x with
           | Some r ->
             (match r with
              | Op (o, ys) ->
                (match o with
                 | Oandimm m -> Some ((Oandimm (Int.coq_and m n)), ys)
                 | _ -> None)
              | Load (m, a, l0) -> None)
           | None -> None)
        | v :: l0 -> None))
  | Oorimm n ->
    (match args with
     | [] -> None
     | x :: l ->
       (match l with
        | [] ->
          (match get x with
           | Some r ->
             (match r with
              | Op (o, ys) ->
                (match o with
                 | Oorimm m -> Some ((Oorimm (Int.coq_or m n)), ys)
                 | _ -> None)
              | Load (m, a, l0) -> None)
           | None -> None)
        | v :: l0 -> None))
  | Oxorimm n ->
    (match args with
     | [] -> None
     | x :: l ->
       (match l with
        | [] ->
          (match get x with
           | Some r ->
             (match r with
              | Op (o, ys) ->
                (match o with
                 | Oxorimm m -> Some ((Oxorimm (Int.xor m n)), ys)
                 | _ -> None)
              | Load (m, a, l0) -> None)
           | None -> None)
        | v :: l0 -> None))
  | Olea addr ->
    (match combine_addr get addr args with
     | Some p -> let (addr', args') = p in Some ((Olea addr'), args')
     | None -> None)
  | Ocmp cond ->
    (match combine_cond get cond args with
     | Some p -> let (cond', args') = p in Some ((Ocmp cond'), args')
     | None -> None)
  | _ -> None

