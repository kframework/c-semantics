(** Growable Arrays *)

module LA = Longarray

type 'a fill =
    Elem of 'a
  | Susp of (int -> 'a)

type 'a t = {
            gaFill: 'a fill;
            (** Stuff to use to fill in the array as it grows *)

    mutable gaMaxInitIndex: int;
            (** Maximum index that was written to. -1 if no writes have 
             * been made.  *)

    mutable gaData: 'a LA.t;
  } 

let growTheArray (ga: 'a t) (len: int) 
                 (toidx: int) (why: string) : unit = 
  if toidx >= len then begin
    (* Grow the array by 50% *)
    let newlen = toidx + 1 + len  / 2 in
    let data' = begin match ga.gaFill with
      Elem x ->
	let data'' = LA.create newlen x in
	LA.blit ga.gaData 0 data'' 0 len;
	data''
    | Susp f -> LA.init newlen
	  (fun i -> if i < len then LA.get ga.gaData i else f i)
    end
    in
    ga.gaData <- data'
  end

let max_init_index (ga: 'a t) : int =
  ga.gaMaxInitIndex

let num_alloc_index (ga: 'a t) : int = 
  LA.length ga.gaData

let reset_max_init_index (ga: 'a t) : unit =
  ga.gaMaxInitIndex <- -1

let getg (ga: 'a t) (r: int) : 'a = 
  let len = LA.length ga.gaData in
  if r >= len then 
    growTheArray ga len r "getg";

  LA.get ga.gaData r

let setg (ga: 'a t) (r: int) (what: 'a) : unit = 
  let len = LA.length ga.gaData in
  if r >= len then 
    growTheArray ga len r "setg";
  if r > max_init_index ga then ga.gaMaxInitIndex <- r;
  LA.set ga.gaData r what

let get (ga: 'a t) (r: int) : 'a = LA.get ga.gaData r

let set (ga: 'a t) (r: int) (what: 'a) : unit = 
  if r > max_init_index ga then ga.gaMaxInitIndex <- r;
  LA.set ga.gaData r what

let make (initsz: int) (fill: 'a fill) : 'a t = 
  { gaFill = fill;
    gaMaxInitIndex = -1;
    gaData = begin match fill with
      Elem x -> LA.create initsz x
    | Susp f -> LA.init initsz f
    end; }


