open Angstrom 

type changes = [
  `Focus of Coord.t * Coord.t
| `Update of Coord.t * CellValue.t
]

let parens p = char '(' *> p <* char ')'

let equals = char '='
let hash   = char '#'
let comma  = char ','
let space  = char ' '
let newline = char '\n'
let bang = char '!'
let integer =
  let is_integer = function
    | '0'..'9' -> true
    | _ -> false
  in take_while1 is_integer >>| int_of_string

let value = integer >>| fun n -> CellValue.Value n

let formula0 =
  integer >>= fun r1 ->
  comma   *>
  space   *>
  integer >>= fun c1 ->
  comma   *>
  space   *>
  integer >>= fun r2 ->
  comma   *>
  space   *>
  integer >>= fun c2 ->
  comma   *>
  space   *>
  integer >>= fun v ->
  let c  = Coord.of_int r1 c1 in
  let c' = Coord.of_int r2 c2 in
  return CellValue.(Formula (Count(c,c',v)))

let formula = equals *> hash *> parens formula0

let cellvalue = (formula <|> value)

let focus : changes Angstrom.t =
  bang *> space *>
    integer >>= fun r1 ->
  space *>
    integer >>= fun c1 ->
  space *>
    integer >>= fun r2 ->
  space *>
    integer >>= fun c2 ->
  let c = Coord.of_int r1 c1 in
  let c' = Coord.of_int r2 c2 in
  return (`Focus (c, c'))

let update : changes Angstrom.t =
  integer >>= fun r ->
  space *>
  integer >>= fun c ->
  space *>
  cellvalue >>= fun f -> 
  let c = Coord.of_int r c in
  return (`Update (c, f))

let row = (focus <|> update)

let parse_row str =
  match parse_only row (`String str) with
  |Ok v -> v
  | Error msg -> failwith msg

let parse filename =
  let file = Pervasives.open_in filename in
  let rec aux () =
    try
      let row_str = Pervasives.input_line file in
      let cf  = parse_row row_str          in
      cf :: aux ()
    with End_of_file -> []
  in
  let change_list = aux () in
  Pervasives.close_in file;
  change_list
