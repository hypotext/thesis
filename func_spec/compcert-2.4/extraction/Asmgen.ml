open AST
open Asm
open Coqlib
open Datatypes
open Errors
open Floats
open Integers
open List0
open Mach
open Machregs
open Op

(** val ireg_of : mreg -> ireg res **)

let ireg_of r =
  match preg_of r with
  | IR mr -> OK mr
  | _ ->
    Error
      (msg
        ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('i'::('r'::('e'::('g'::('_'::('o'::('f'::[])))))))))))))))

(** val freg_of : mreg -> freg res **)

let freg_of r =
  match preg_of r with
  | FR mr -> OK mr
  | _ ->
    Error
      (msg
        ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('f'::('r'::('e'::('g'::('_'::('o'::('f'::[])))))))))))))))

(** val mk_mov : preg -> preg -> Asm.code -> Asm.code res **)

let mk_mov rd rs k =
  match rd with
  | IR rd0 ->
    (match rs with
     | IR rs0 -> OK ((Pmov_rr (rd0, rs0)) :: k)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('m'::('k'::('_'::('m'::('o'::('v'::[])))))))))))))))
  | FR rd0 ->
    (match rs with
     | FR rs0 -> OK ((Pmovsd_ff (rd0, rs0)) :: k)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('m'::('k'::('_'::('m'::('o'::('v'::[])))))))))))))))
  | _ ->
    Error
      (msg
        ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('m'::('k'::('_'::('m'::('o'::('v'::[]))))))))))))))

(** val mk_shrximm : Int.int -> Asm.code -> Asm.code res **)

let mk_shrximm n k =
  let p = Int.sub (Int.shl Int.one n) Int.one in
  OK ((Ptest_rr (EAX, EAX)) :: ((Plea (ECX, (Addrmode ((Some EAX), None,
  (Coq_inl p))))) :: ((Pcmov (Cond_l, EAX, ECX)) :: ((Psar_ri (EAX,
  n)) :: k))))

(** val low_ireg : ireg -> bool **)

let low_ireg = function
| ESI -> false
| EDI -> false
| EBP -> false
| ESP -> false
| _ -> true

(** val mk_intconv :
    (ireg -> ireg -> Asm.instruction) -> ireg -> ireg -> Asm.code ->
    Asm.instruction list res **)

let mk_intconv mk rd rs k =
  if low_ireg rs
  then OK ((mk rd rs) :: k)
  else OK ((Pmov_rr (EAX, rs)) :: ((mk rd EAX) :: k))

(** val addressing_mentions : addrmode -> ireg -> bool **)

let addressing_mentions addr r =
  let Addrmode (base, displ, const) = addr in
  (||)
    (match base with
     | Some r' -> (fun x -> x) (ireg_eq r r')
     | None -> false)
    (match displ with
     | Some p -> let (r', sc) = p in (fun x -> x) (ireg_eq r r')
     | None -> false)

(** val mk_smallstore :
    (addrmode -> ireg -> Asm.instruction) -> addrmode -> ireg -> Asm.code ->
    Asm.instruction list res **)

let mk_smallstore sto addr rs k =
  if low_ireg rs
  then OK ((sto addr rs) :: k)
  else if addressing_mentions addr EAX
       then OK ((Plea (ECX, addr)) :: ((Pmov_rr (EAX,
              rs)) :: ((sto (Addrmode ((Some ECX), None, (Coq_inl Int.zero)))
                         EAX) :: k)))
       else OK ((Pmov_rr (EAX, rs)) :: ((sto addr EAX) :: k))

(** val loadind :
    ireg -> Int.int -> typ -> mreg -> Asm.code -> Asm.instruction list res **)

let loadind base ofs ty dst k =
  match ty with
  | Tint ->
    (match preg_of dst with
     | IR r ->
       OK ((Pmov_rm (r, (Addrmode ((Some base), None, (Coq_inl ofs))))) :: k)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('l'::('o'::('a'::('d'::('i'::('n'::('d'::[]))))))))))))))))
  | Tfloat ->
    (match preg_of dst with
     | FR r ->
       OK ((Pmovsd_fm (r, (Addrmode ((Some base), None, (Coq_inl
         ofs))))) :: k)
     | ST0 ->
       OK ((Pfldl_m (Addrmode ((Some base), None, (Coq_inl ofs)))) :: k)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('l'::('o'::('a'::('d'::('i'::('n'::('d'::[]))))))))))))))))
  | Tlong ->
    Error
      (msg
        ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('l'::('o'::('a'::('d'::('i'::('n'::('d'::[])))))))))))))))
  | Tsingle ->
    (match preg_of dst with
     | FR r ->
       OK ((Pmovss_fm (r, (Addrmode ((Some base), None, (Coq_inl
         ofs))))) :: k)
     | ST0 ->
       OK ((Pflds_m (Addrmode ((Some base), None, (Coq_inl ofs)))) :: k)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('l'::('o'::('a'::('d'::('i'::('n'::('d'::[]))))))))))))))))
  | Tany32 ->
    (match preg_of dst with
     | IR r ->
       OK ((Pmov_rm_a (r, (Addrmode ((Some base), None, (Coq_inl
         ofs))))) :: k)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('l'::('o'::('a'::('d'::('i'::('n'::('d'::[]))))))))))))))))
  | Tany64 ->
    (match preg_of dst with
     | FR r ->
       OK ((Pmovsd_fm_a (r, (Addrmode ((Some base), None, (Coq_inl
         ofs))))) :: k)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('l'::('o'::('a'::('d'::('i'::('n'::('d'::[]))))))))))))))))

(** val storeind :
    mreg -> ireg -> Int.int -> typ -> Asm.code -> Asm.instruction list res **)

let storeind src base ofs ty k =
  match ty with
  | Tint ->
    (match preg_of src with
     | IR r ->
       OK ((Pmov_mr ((Addrmode ((Some base), None, (Coq_inl ofs))), r)) :: k)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('s'::('t'::('o'::('r'::('e'::('i'::('n'::('d'::[])))))))))))))))))
  | Tfloat ->
    (match preg_of src with
     | FR r ->
       OK ((Pmovsd_mf ((Addrmode ((Some base), None, (Coq_inl ofs))),
         r)) :: k)
     | ST0 ->
       OK ((Pfstpl_m (Addrmode ((Some base), None, (Coq_inl ofs)))) :: k)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('s'::('t'::('o'::('r'::('e'::('i'::('n'::('d'::[])))))))))))))))))
  | Tlong ->
    Error
      (msg
        ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('s'::('t'::('o'::('r'::('e'::('i'::('n'::('d'::[]))))))))))))))))
  | Tsingle ->
    (match preg_of src with
     | FR r ->
       OK ((Pmovss_mf ((Addrmode ((Some base), None, (Coq_inl ofs))),
         r)) :: k)
     | ST0 ->
       OK ((Pfstps_m (Addrmode ((Some base), None, (Coq_inl ofs)))) :: k)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('s'::('t'::('o'::('r'::('e'::('i'::('n'::('d'::[])))))))))))))))))
  | Tany32 ->
    (match preg_of src with
     | IR r ->
       OK ((Pmov_mr_a ((Addrmode ((Some base), None, (Coq_inl ofs))),
         r)) :: k)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('s'::('t'::('o'::('r'::('e'::('i'::('n'::('d'::[])))))))))))))))))
  | Tany64 ->
    (match preg_of src with
     | FR r ->
       OK ((Pmovsd_mf_a ((Addrmode ((Some base), None, (Coq_inl ofs))),
         r)) :: k)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('s'::('t'::('o'::('r'::('e'::('i'::('n'::('d'::[])))))))))))))))))

(** val transl_addressing : addressing -> mreg list -> addrmode res **)

let transl_addressing a args =
  match a with
  | Aindexed n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[])))))))))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of a1 with
           | OK x -> OK (Addrmode ((Some x), None, (Coq_inl n)))
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[])))))))))))))))))))))))))))
  | Aindexed2 n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[])))))))))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[])))))))))))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             (match ireg_of a1 with
              | OK x ->
                (match ireg_of a2 with
                 | OK x0 ->
                   OK (Addrmode ((Some x), (Some (x0, Int.one)), (Coq_inl
                     n)))
                 | Error msg0 -> Error msg0)
              | Error msg0 -> Error msg0)
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[]))))))))))))))))))))))))))))
  | Ascaled (sc, n) ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[])))))))))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of a1 with
           | OK x -> OK (Addrmode (None, (Some (x, sc)), (Coq_inl n)))
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[])))))))))))))))))))))))))))
  | Aindexed2scaled (sc, n) ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[])))))))))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[])))))))))))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             (match ireg_of a1 with
              | OK x ->
                (match ireg_of a2 with
                 | OK x0 ->
                   OK (Addrmode ((Some x), (Some (x0, sc)), (Coq_inl n)))
                 | Error msg0 -> Error msg0)
              | Error msg0 -> Error msg0)
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[]))))))))))))))))))))))))))))
  | Aglobal (id, ofs) ->
    (match args with
     | [] -> OK (Addrmode (None, None, (Coq_inr (id, ofs))))
     | m :: l ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[]))))))))))))))))))))))))))
  | Abased (id, ofs) ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[])))))))))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of a1 with
           | OK x -> OK (Addrmode ((Some x), None, (Coq_inr (id, ofs))))
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[])))))))))))))))))))))))))))
  | Abasedscaled (sc, id, ofs) ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[])))))))))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of a1 with
           | OK x ->
             OK (Addrmode (None, (Some (x, sc)), (Coq_inr (id, ofs))))
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[])))))))))))))))))))))))))))
  | Ainstack n ->
    (match args with
     | [] -> OK (Addrmode ((Some ESP), None, (Coq_inl n)))
     | m :: l ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('a'::('d'::('d'::('r'::('e'::('s'::('s'::('i'::('n'::('g'::[]))))))))))))))))))))))))))

(** val floatcomp : comparison -> freg -> freg -> Asm.instruction **)

let floatcomp cmp r1 r2 =
  match cmp with
  | Clt -> Pcomisd_ff (r2, r1)
  | Cle -> Pcomisd_ff (r2, r1)
  | _ -> Pcomisd_ff (r1, r2)

(** val floatcomp32 : comparison -> freg -> freg -> Asm.instruction **)

let floatcomp32 cmp r1 r2 =
  match cmp with
  | Clt -> Pcomiss_ff (r2, r1)
  | Cle -> Pcomiss_ff (r2, r1)
  | _ -> Pcomiss_ff (r1, r2)

(** val transl_cond : condition -> mreg list -> Asm.code -> Asm.code res **)

let transl_cond cond args k =
  match cond with
  | Ccompimm (c, n) ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of a1 with
           | OK x ->
             OK
               (if Int.eq_dec n Int.zero
                then (Ptest_rr (x, x)) :: k
                else (Pcmp_ri (x, n)) :: k)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))))
  | Ccompuimm (c, n) ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of a1 with
           | OK x -> OK ((Pcmp_ri (x, n)) :: k)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))))
  | Ccompf cmp ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             (match freg_of a1 with
              | OK x ->
                (match freg_of a2 with
                 | OK x0 -> OK ((floatcomp cmp x x0) :: k)
                 | Error msg0 -> Error msg0)
              | Error msg0 -> Error msg0)
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[]))))))))))))))))))))))
  | Cnotcompf cmp ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             (match freg_of a1 with
              | OK x ->
                (match freg_of a2 with
                 | OK x0 -> OK ((floatcomp cmp x x0) :: k)
                 | Error msg0 -> Error msg0)
              | Error msg0 -> Error msg0)
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[]))))))))))))))))))))))
  | Ccompfs cmp ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             (match freg_of a1 with
              | OK x ->
                (match freg_of a2 with
                 | OK x0 -> OK ((floatcomp32 cmp x x0) :: k)
                 | Error msg0 -> Error msg0)
              | Error msg0 -> Error msg0)
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[]))))))))))))))))))))))
  | Cnotcompfs cmp ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             (match freg_of a1 with
              | OK x ->
                (match freg_of a2 with
                 | OK x0 -> OK ((floatcomp32 cmp x x0) :: k)
                 | Error msg0 -> Error msg0)
              | Error msg0 -> Error msg0)
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[]))))))))))))))))))))))
  | Cmaskzero n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of a1 with
           | OK x -> OK ((Ptest_ri (x, n)) :: k)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))))
  | Cmasknotzero n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of a1 with
           | OK x -> OK ((Ptest_ri (x, n)) :: k)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))))
  | _ ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[])))))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             (match ireg_of a1 with
              | OK x ->
                (match ireg_of a2 with
                 | OK x0 -> OK ((Pcmp_rr (x, x0)) :: k)
                 | Error msg0 -> Error msg0)
              | Error msg0 -> Error msg0)
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('c'::('o'::('n'::('d'::[]))))))))))))))))))))))

(** val testcond_for_signed_comparison : comparison -> testcond **)

let testcond_for_signed_comparison = function
| Ceq -> Cond_e
| Cne -> Cond_ne
| Clt -> Cond_l
| Cle -> Cond_le
| Cgt -> Cond_g
| Cge -> Cond_ge

(** val testcond_for_unsigned_comparison : comparison -> testcond **)

let testcond_for_unsigned_comparison = function
| Ceq -> Cond_e
| Cne -> Cond_ne
| Clt -> Cond_b
| Cle -> Cond_be
| Cgt -> Cond_a
| Cge -> Cond_ae

type extcond =
| Cond_base of testcond
| Cond_or of testcond * testcond
| Cond_and of testcond * testcond

(** val testcond_for_condition : condition -> extcond **)

let testcond_for_condition = function
| Ccomp c -> Cond_base (testcond_for_signed_comparison c)
| Ccompu c -> Cond_base (testcond_for_unsigned_comparison c)
| Ccompimm (c, n) -> Cond_base (testcond_for_signed_comparison c)
| Ccompuimm (c, n) -> Cond_base (testcond_for_unsigned_comparison c)
| Ccompf c ->
  (match c with
   | Ceq -> Cond_and (Cond_np, Cond_e)
   | Cne -> Cond_or (Cond_p, Cond_ne)
   | Clt -> Cond_base Cond_a
   | Cgt -> Cond_base Cond_a
   | _ -> Cond_base Cond_ae)
| Cnotcompf c ->
  (match c with
   | Ceq -> Cond_or (Cond_p, Cond_ne)
   | Cne -> Cond_and (Cond_np, Cond_e)
   | Cle -> Cond_base Cond_b
   | Cge -> Cond_base Cond_b
   | _ -> Cond_base Cond_be)
| Ccompfs c ->
  (match c with
   | Ceq -> Cond_and (Cond_np, Cond_e)
   | Cne -> Cond_or (Cond_p, Cond_ne)
   | Clt -> Cond_base Cond_a
   | Cgt -> Cond_base Cond_a
   | _ -> Cond_base Cond_ae)
| Cnotcompfs c ->
  (match c with
   | Ceq -> Cond_or (Cond_p, Cond_ne)
   | Cne -> Cond_and (Cond_np, Cond_e)
   | Cle -> Cond_base Cond_b
   | Cge -> Cond_base Cond_b
   | _ -> Cond_base Cond_be)
| Cmaskzero n -> Cond_base Cond_e
| Cmasknotzero n -> Cond_base Cond_ne

(** val mk_setcc_base :
    extcond -> ireg -> Asm.code -> Asm.instruction list **)

let mk_setcc_base cond rd k =
  match cond with
  | Cond_base c -> (Psetcc (c, rd)) :: k
  | Cond_or (c1, c2) ->
    if ireg_eq rd EAX
    then (Psetcc (c1, EAX)) :: ((Psetcc (c2, ECX)) :: ((Por_rr (EAX,
           ECX)) :: k))
    else (Psetcc (c1, EAX)) :: ((Psetcc (c2, rd)) :: ((Por_rr (rd,
           EAX)) :: k))
  | Cond_and (c1, c2) ->
    if ireg_eq rd EAX
    then (Psetcc (c1, EAX)) :: ((Psetcc (c2, ECX)) :: ((Pand_rr (EAX,
           ECX)) :: k))
    else (Psetcc (c1, EAX)) :: ((Psetcc (c2, rd)) :: ((Pand_rr (rd,
           EAX)) :: k))

(** val mk_setcc : extcond -> ireg -> Asm.code -> Asm.instruction list **)

let mk_setcc cond rd k =
  if low_ireg rd
  then mk_setcc_base cond rd k
  else mk_setcc_base cond EAX ((Pmov_rr (rd, EAX)) :: k)

(** val mk_jcc : extcond -> Asm.label -> Asm.code -> Asm.instruction list **)

let mk_jcc cond lbl k =
  match cond with
  | Cond_base c -> (Pjcc (c, lbl)) :: k
  | Cond_or (c1, c2) -> (Pjcc (c1, lbl)) :: ((Pjcc (c2, lbl)) :: k)
  | Cond_and (c1, c2) -> (Pjcc2 (c1, c2, lbl)) :: k

(** val transl_op :
    operation -> mreg list -> mreg -> Asm.code -> Asm.code res **)

let transl_op op args res0 k =
  match op with
  | Omove ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] -> mk_mov (preg_of res0) (preg_of a1) k
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Ointconst n ->
    (match args with
     | [] ->
       (match ireg_of res0 with
        | OK x ->
          OK
            ((if Int.eq_dec n Int.zero then Pxor_r x else Pmov_ri (x, n)) :: k)
        | Error msg0 -> Error msg0)
     | m :: l ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))
  | Ofloatconst f ->
    (match args with
     | [] ->
       (match freg_of res0 with
        | OK x ->
          OK
            ((if Float.eq_dec f Float.zero
              then Pxorpd_f x
              else Pmovsd_fi (x, f)) :: k)
        | Error msg0 -> Error msg0)
     | m :: l ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))
  | Osingleconst f ->
    (match args with
     | [] ->
       (match freg_of res0 with
        | OK x ->
          OK
            ((if Float32.eq_dec f Float32.zero
              then Pxorps_f x
              else Pmovss_fi (x, f)) :: k)
        | Error msg0 -> Error msg0)
     | m :: l ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))
  | Oindirectsymbol id ->
    (match args with
     | [] ->
       (match ireg_of res0 with
        | OK x -> OK ((Pmov_ra (x, id)) :: k)
        | Error msg0 -> Error msg0)
     | m :: l ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))
  | Ocast8signed ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of a1 with
           | OK x ->
             (match ireg_of res0 with
              | OK x0 -> mk_intconv (fun x1 x2 -> Pmovsb_rr (x1, x2)) x0 x k
              | Error msg0 -> Error msg0)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Ocast8unsigned ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of a1 with
           | OK x ->
             (match ireg_of res0 with
              | OK x0 -> mk_intconv (fun x1 x2 -> Pmovzb_rr (x1, x2)) x0 x k
              | Error msg0 -> Error msg0)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Ocast16signed ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of a1 with
           | OK x ->
             (match ireg_of res0 with
              | OK x0 -> mk_intconv (fun x1 x2 -> Pmovsw_rr (x1, x2)) x0 x k
              | Error msg0 -> Error msg0)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Ocast16unsigned ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of a1 with
           | OK x ->
             (match ireg_of res0 with
              | OK x0 -> mk_intconv (fun x1 x2 -> Pmovzw_rr (x1, x2)) x0 x k
              | Error msg0 -> Error msg0)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Oneg ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match ireg_of res0 with
                | OK x -> OK ((Pneg x) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Osub ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match ireg_of res0 with
                   | OK x ->
                     (match ireg_of a2 with
                      | OK x0 -> OK ((Psub_rr (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Omul ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match ireg_of res0 with
                   | OK x ->
                     (match ireg_of a2 with
                      | OK x0 -> OK ((Pimul_rr (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Omulimm n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match ireg_of res0 with
                | OK x -> OK ((Pimul_ri (x, n)) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Omulhs ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 AX
             then if mreg_eq res0 DX
                  then (match ireg_of a2 with
                        | OK x -> OK ((Pimul_r x) :: k)
                        | Error msg0 -> Error msg0)
                  else assertion_failed
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Omulhu ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 AX
             then if mreg_eq res0 DX
                  then (match ireg_of a2 with
                        | OK x -> OK ((Pmul_r x) :: k)
                        | Error msg0 -> Error msg0)
                  else assertion_failed
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Odiv ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 AX
             then if mreg_eq a2 CX
                  then if mreg_eq res0 AX
                       then OK ((Pidiv ECX) :: k)
                       else assertion_failed
                  else assertion_failed
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Odivu ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 AX
             then if mreg_eq a2 CX
                  then if mreg_eq res0 AX
                       then OK ((Pdiv ECX) :: k)
                       else assertion_failed
                  else assertion_failed
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Omod ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 AX
             then if mreg_eq a2 CX
                  then if mreg_eq res0 DX
                       then OK ((Pidiv ECX) :: k)
                       else assertion_failed
                  else assertion_failed
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Omodu ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 AX
             then if mreg_eq a2 CX
                  then if mreg_eq res0 DX
                       then OK ((Pdiv ECX) :: k)
                       else assertion_failed
                  else assertion_failed
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Oand ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match ireg_of res0 with
                   | OK x ->
                     (match ireg_of a2 with
                      | OK x0 -> OK ((Pand_rr (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Oandimm n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match ireg_of res0 with
                | OK x -> OK ((Pand_ri (x, n)) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Oor ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match ireg_of res0 with
                   | OK x ->
                     (match ireg_of a2 with
                      | OK x0 -> OK ((Por_rr (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Oorimm n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match ireg_of res0 with
                | OK x -> OK ((Por_ri (x, n)) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Oxor ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match ireg_of res0 with
                   | OK x ->
                     (match ireg_of a2 with
                      | OK x0 -> OK ((Pxor_rr (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Oxorimm n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match ireg_of res0 with
                | OK x -> OK ((Pxor_ri (x, n)) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Onot ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match ireg_of res0 with
                | OK x -> OK ((Pnot x) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Oshl ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then if mreg_eq a2 CX
                  then (match ireg_of res0 with
                        | OK x -> OK ((Psal_rcl x) :: k)
                        | Error msg0 -> Error msg0)
                  else assertion_failed
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Oshlimm n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match ireg_of res0 with
                | OK x -> OK ((Psal_ri (x, n)) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Oshr ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then if mreg_eq a2 CX
                  then (match ireg_of res0 with
                        | OK x -> OK ((Psar_rcl x) :: k)
                        | Error msg0 -> Error msg0)
                  else assertion_failed
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Oshrimm n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match ireg_of res0 with
                | OK x -> OK ((Psar_ri (x, n)) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Oshrximm n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 AX
          then if mreg_eq res0 AX then mk_shrximm n k else assertion_failed
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Oshru ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then if mreg_eq a2 CX
                  then (match ireg_of res0 with
                        | OK x -> OK ((Pshr_rcl x) :: k)
                        | Error msg0 -> Error msg0)
                  else assertion_failed
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Oshruimm n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match ireg_of res0 with
                | OK x -> OK ((Pshr_ri (x, n)) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Ororimm n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match ireg_of res0 with
                | OK x -> OK ((Pror_ri (x, n)) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Oshldimm n ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match ireg_of res0 with
                   | OK x ->
                     (match ireg_of a2 with
                      | OK x0 -> OK ((Pshld_ri (x, x0, n)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Olea addr ->
    (match transl_addressing addr args with
     | OK x ->
       (match ireg_of res0 with
        | OK x0 -> OK ((Plea (x0, x)) :: k)
        | Error msg0 -> Error msg0)
     | Error msg0 -> Error msg0)
  | Onegf ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match freg_of res0 with
                | OK x -> OK ((Pnegd x) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Oabsf ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match freg_of res0 with
                | OK x -> OK ((Pabsd x) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Oaddf ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match freg_of res0 with
                   | OK x ->
                     (match freg_of a2 with
                      | OK x0 -> OK ((Paddd_ff (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Osubf ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match freg_of res0 with
                   | OK x ->
                     (match freg_of a2 with
                      | OK x0 -> OK ((Psubd_ff (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Omulf ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match freg_of res0 with
                   | OK x ->
                     (match freg_of a2 with
                      | OK x0 -> OK ((Pmuld_ff (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Odivf ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match freg_of res0 with
                   | OK x ->
                     (match freg_of a2 with
                      | OK x0 -> OK ((Pdivd_ff (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Onegfs ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match freg_of res0 with
                | OK x -> OK ((Pnegs x) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Oabsfs ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          if mreg_eq a1 res0
          then (match freg_of res0 with
                | OK x -> OK ((Pabss x) :: k)
                | Error msg0 -> Error msg0)
          else assertion_failed
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Oaddfs ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match freg_of res0 with
                   | OK x ->
                     (match freg_of a2 with
                      | OK x0 -> OK ((Padds_ff (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Osubfs ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match freg_of res0 with
                   | OK x ->
                     (match freg_of a2 with
                      | OK x0 -> OK ((Psubs_ff (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Omulfs ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match freg_of res0 with
                   | OK x ->
                     (match freg_of a2 with
                      | OK x0 -> OK ((Pmuls_ff (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Odivfs ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
        | a2 :: l0 ->
          (match l0 with
           | [] ->
             if mreg_eq a1 res0
             then (match freg_of res0 with
                   | OK x ->
                     (match freg_of a2 with
                      | OK x0 -> OK ((Pdivs_ff (x, x0)) :: k)
                      | Error msg0 -> Error msg0)
                   | Error msg0 -> Error msg0)
             else assertion_failed
           | m :: l1 ->
             Error
               (msg
                 ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[]))))))))))))))))))))
  | Osingleoffloat ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match freg_of res0 with
           | OK x ->
             (match freg_of a1 with
              | OK x0 -> OK ((Pcvtsd2ss_ff (x, x0)) :: k)
              | Error msg0 -> Error msg0)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Ofloatofsingle ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match freg_of res0 with
           | OK x ->
             (match freg_of a1 with
              | OK x0 -> OK ((Pcvtss2sd_ff (x, x0)) :: k)
              | Error msg0 -> Error msg0)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Ointoffloat ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of res0 with
           | OK x ->
             (match freg_of a1 with
              | OK x0 -> OK ((Pcvttsd2si_rf (x, x0)) :: k)
              | Error msg0 -> Error msg0)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Ofloatofint ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match freg_of res0 with
           | OK x ->
             (match ireg_of a1 with
              | OK x0 -> OK ((Pcvtsi2sd_fr (x, x0)) :: k)
              | Error msg0 -> Error msg0)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Ointofsingle ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match ireg_of res0 with
           | OK x ->
             (match freg_of a1 with
              | OK x0 -> OK ((Pcvttss2si_rf (x, x0)) :: k)
              | Error msg0 -> Error msg0)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Osingleofint ->
    (match args with
     | [] ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))
     | a1 :: l ->
       (match l with
        | [] ->
          (match freg_of res0 with
           | OK x ->
             (match ireg_of a1 with
              | OK x0 -> OK ((Pcvtsi2ss_fr (x, x0)) :: k)
              | Error msg0 -> Error msg0)
           | Error msg0 -> Error msg0)
        | m :: l0 ->
          Error
            (msg
              ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))))
  | Ocmp c ->
    (match ireg_of res0 with
     | OK x -> transl_cond c args (mk_setcc (testcond_for_condition c) x k)
     | Error msg0 -> Error msg0)
  | _ ->
    Error
      (msg
        ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('o'::('p'::[])))))))))))))))))

(** val transl_load :
    memory_chunk -> addressing -> mreg list -> mreg -> Asm.code -> Asm.code
    res **)

let transl_load chunk addr args dest k =
  match transl_addressing addr args with
  | OK x ->
    (match chunk with
     | Mint8signed ->
       (match ireg_of dest with
        | OK x0 -> OK ((Pmovsb_rm (x0, x)) :: k)
        | Error msg0 -> Error msg0)
     | Mint8unsigned ->
       (match ireg_of dest with
        | OK x0 -> OK ((Pmovzb_rm (x0, x)) :: k)
        | Error msg0 -> Error msg0)
     | Mint16signed ->
       (match ireg_of dest with
        | OK x0 -> OK ((Pmovsw_rm (x0, x)) :: k)
        | Error msg0 -> Error msg0)
     | Mint16unsigned ->
       (match ireg_of dest with
        | OK x0 -> OK ((Pmovzw_rm (x0, x)) :: k)
        | Error msg0 -> Error msg0)
     | Mint32 ->
       (match ireg_of dest with
        | OK x0 -> OK ((Pmov_rm (x0, x)) :: k)
        | Error msg0 -> Error msg0)
     | Mfloat32 ->
       (match freg_of dest with
        | OK x0 -> OK ((Pmovss_fm (x0, x)) :: k)
        | Error msg0 -> Error msg0)
     | Mfloat64 ->
       (match freg_of dest with
        | OK x0 -> OK ((Pmovsd_fm (x0, x)) :: k)
        | Error msg0 -> Error msg0)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('l'::('o'::('a'::('d'::[]))))))))))))))))))))
  | Error msg0 -> Error msg0

(** val transl_store :
    memory_chunk -> addressing -> mreg list -> mreg -> Asm.code -> Asm.code
    res **)

let transl_store chunk addr args src k =
  match transl_addressing addr args with
  | OK x ->
    (match chunk with
     | Mint8signed ->
       (match ireg_of src with
        | OK x0 -> mk_smallstore (fun x1 x2 -> Pmovb_mr (x1, x2)) x x0 k
        | Error msg0 -> Error msg0)
     | Mint8unsigned ->
       (match ireg_of src with
        | OK x0 -> mk_smallstore (fun x1 x2 -> Pmovb_mr (x1, x2)) x x0 k
        | Error msg0 -> Error msg0)
     | Mint16signed ->
       (match ireg_of src with
        | OK x0 -> OK ((Pmovw_mr (x, x0)) :: k)
        | Error msg0 -> Error msg0)
     | Mint16unsigned ->
       (match ireg_of src with
        | OK x0 -> OK ((Pmovw_mr (x, x0)) :: k)
        | Error msg0 -> Error msg0)
     | Mint32 ->
       (match ireg_of src with
        | OK x0 -> OK ((Pmov_mr (x, x0)) :: k)
        | Error msg0 -> Error msg0)
     | Mfloat32 ->
       (match freg_of src with
        | OK x0 -> OK ((Pmovss_mf (x, x0)) :: k)
        | Error msg0 -> Error msg0)
     | Mfloat64 ->
       (match freg_of src with
        | OK x0 -> OK ((Pmovsd_mf (x, x0)) :: k)
        | Error msg0 -> Error msg0)
     | _ ->
       Error
         (msg
           ('A'::('s'::('m'::('g'::('e'::('n'::('.'::('t'::('r'::('a'::('n'::('s'::('l'::('_'::('s'::('t'::('o'::('r'::('e'::[])))))))))))))))))))))
  | Error msg0 -> Error msg0

(** val transl_annot_param : annot_param -> Asm.annot_param **)

let transl_annot_param = function
| APreg r -> Asm.APreg (preg_of r)
| APstack (chunk, ofs) -> Asm.APstack (chunk, ofs)

(** val transl_instr :
    coq_function -> instruction -> bool -> Asm.code -> Asm.instruction list
    res **)

let transl_instr f i edx_is_parent k =
  match i with
  | Mgetstack (ofs, ty, dst) -> loadind ESP ofs ty dst k
  | Msetstack (src, ofs, ty) -> storeind src ESP ofs ty k
  | Mgetparam (ofs, ty, dst) ->
    if edx_is_parent
    then loadind EDX ofs ty dst k
    else (match loadind EDX ofs ty dst k with
          | OK x -> loadind ESP f.fn_link_ofs Tint DX x
          | Error msg0 -> Error msg0)
  | Mop (op, args, res0) -> transl_op op args res0 k
  | Mload (chunk, addr, args, dst) -> transl_load chunk addr args dst k
  | Mstore (chunk, addr, args, src) -> transl_store chunk addr args src k
  | Mcall (sig0, s) ->
    (match s with
     | Coq_inl reg ->
       (match ireg_of reg with
        | OK x -> OK ((Pcall_r (x, sig0)) :: k)
        | Error msg0 -> Error msg0)
     | Coq_inr symb -> OK ((Pcall_s (symb, sig0)) :: k))
  | Mtailcall (sig0, s) ->
    (match s with
     | Coq_inl reg ->
       (match ireg_of reg with
        | OK x ->
          OK ((Pfreeframe (f.fn_stacksize, f.fn_retaddr_ofs,
            f.fn_link_ofs)) :: ((Pjmp_r (x, sig0)) :: k))
        | Error msg0 -> Error msg0)
     | Coq_inr symb ->
       OK ((Pfreeframe (f.fn_stacksize, f.fn_retaddr_ofs,
         f.fn_link_ofs)) :: ((Pjmp_s (symb, sig0)) :: k)))
  | Mbuiltin (ef, args, res0) ->
    OK ((Pbuiltin (ef, (map preg_of args), (map preg_of res0))) :: k)
  | Mannot (ef, args) ->
    OK ((Pannot (ef, (map transl_annot_param args))) :: k)
  | Mlabel lbl -> OK ((Plabel lbl) :: k)
  | Mgoto lbl -> OK ((Pjmp_l lbl) :: k)
  | Mcond (cond, args, lbl) ->
    transl_cond cond args (mk_jcc (testcond_for_condition cond) lbl k)
  | Mjumptable (arg, tbl) ->
    (match ireg_of arg with
     | OK x -> OK ((Pjmptbl (x, tbl)) :: k)
     | Error msg0 -> Error msg0)
  | Mreturn ->
    OK ((Pfreeframe (f.fn_stacksize, f.fn_retaddr_ofs,
      f.fn_link_ofs)) :: (Pret :: k))

(** val it1_is_parent : bool -> instruction -> bool **)

let it1_is_parent before = function
| Msetstack (src, ofs, ty) -> before
| Mgetparam (ofs, ty, dst) -> negb ((fun x -> x) (mreg_eq dst DX))
| _ -> false

(** val transl_code_rec :
    coq_function -> instruction list -> bool -> (Asm.code -> Asm.code res) ->
    Asm.code res **)

let rec transl_code_rec f il it1p k =
  match il with
  | [] -> k []
  | i1 :: il' ->
    transl_code_rec f il' (it1_is_parent it1p i1) (fun c1 ->
      match transl_instr f i1 it1p c1 with
      | OK x -> k x
      | Error msg0 -> Error msg0)

(** val transl_code' :
    coq_function -> instruction list -> bool -> Asm.code res **)

let transl_code' f il it1p =
  transl_code_rec f il it1p (fun c -> OK c)

(** val transl_function : coq_function -> Asm.coq_function res **)

let transl_function f =
  match transl_code' f f.fn_code true with
  | OK x ->
    OK { Asm.fn_sig = f.fn_sig; Asm.fn_code = ((Pallocframe (f.fn_stacksize,
      f.fn_retaddr_ofs, f.fn_link_ofs)) :: x) }
  | Error msg0 -> Error msg0

(** val transf_function : coq_function -> Asm.coq_function res **)

let transf_function f =
  match transl_function f with
  | OK x ->
    if zlt Int.max_unsigned (list_length_z x.Asm.fn_code)
    then Error
           (msg
             ('c'::('o'::('d'::('e'::(' '::('s'::('i'::('z'::('e'::(' '::('e'::('x'::('c'::('e'::('e'::('d'::('e'::('d'::[])))))))))))))))))))
    else OK x
  | Error msg0 -> Error msg0

(** val transf_fundef : fundef -> Asm.fundef res **)

let transf_fundef f =
  transf_partial_fundef transf_function f

(** val transf_program : program -> Asm.program res **)

let transf_program p =
  transform_partial_program transf_fundef p

