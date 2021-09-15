(* Helper function to get account *)
function get_account(
  const key : (address * nat);
  const s : dex_storage) : account_info is
  case s.ledger[key] of
    None -> record [
      balance    = 0n;
      allowances = (set [] : set (address));
    ]
  | Some(instance) -> instance
  end;

(* Helper function to get token pair *)
function get_pair(
  const key : tokens_info;
  const s : dex_storage) : (pair_info * nat) is
  block {
    const token_bytes : token_pair = Bytes.pack(key);
    const token_id : nat = case s.token_to_id[token_bytes] of
        None -> s.pairs_count
      | Some(instance) -> instance
      end;
    const pair : pair_info = case s.pairs[token_id] of
        None -> record [
          token_a_pool    = 0n;
          token_b_pool    = 0n;
          total_supply    = 0n;
        ]
      | Some(instance) -> instance
      end;
  } with (pair, token_id)

(* Helper function to wrap the pair for swap *)
function form_pools(
  const from_pool: nat;
  const to_pool: nat;
  const supply: nat;
  const direction: swap_type) : pair_info is
  case direction of
    Buy -> record [
      token_a_pool = to_pool;
      token_b_pool = from_pool;
      total_supply = supply;
    ]
  | Sell -> record [
      token_a_pool = from_pool;
      token_b_pool = to_pool;
      total_supply = supply;
    ]
  end;

(* Helper function to unwrap the pair for swap *)
function form_swap_data(
  const pair: pair_info;
  const swap: tokens_info;
  const direction: swap_type) : swap_data is
  block {
    const side_a : swap_side = record [
      pool = pair.token_a_pool;
      token = swap.token_a_address;
      id = swap.token_a_id;
      standard = swap.token_a_type;
    ];
    const side_b : swap_side = record [
      pool = pair.token_b_pool;
      token = swap.token_b_address;
      id = swap.token_b_id;
      standard = swap.token_b_type;
    ];
  } with case direction of
      Sell -> record [
        from_ = side_a;
        to_ = side_b;
      ]
    | Buy -> record [
        from_ = side_b;
        to_ = side_a;
      ]
    end;

(* Helper function to prepare the token transfer *)
function wrap_fa2_transfer_trx(
  const owner : address;
  const receiver : address;
  const value : nat;
  const token_id : nat) : transfer_type_fa2 is
  TransferTypeFA2(list[
    record[
      from_ = owner;
      txs = list [ record [
          to_ = receiver;
          token_id = token_id;
          amount = value;
        ] ]
    ]
  ])

(* Helper function to prepare the token transfer *)
function wrap_fa12_transfer_trx(
  const owner : address;
  const receiver : address;
  const value : nat) : transfer_type_fa12 is
  TransferTypeFA12(owner, (receiver, value))

(* Helper function to get fa2 token contract *)
function get_fa2_token_contract(
  const token_address : address) : contract(transfer_type_fa2) is
  case (Tezos.get_entrypoint_opt(
      "%transfer",
      token_address) : option(contract(transfer_type_fa2))) of
    Some(contr) -> contr
  | None -> (failwith("Dex/not-token") : contract(transfer_type_fa2))
  end;

(* Helper function to get fa1.2 token contract *)
function get_fa12_token_contract(
  const token_address : address) : contract(transfer_type_fa12) is
  case (Tezos.get_entrypoint_opt(
      "%transfer",
      token_address) : option(contract(transfer_type_fa12))) of
    Some(contr) -> contr
  | None -> (failwith("Dex/not-token") : contract(transfer_type_fa12))
  end;

(* Helper function to get fa2 token contract *)
function get_fa2_balance_entrypoint(
  const token_address : address) : contract(transfer_type_fa2) is
  case (Tezos.get_entrypoint_opt(
      "%transfer",
      token_address) : option(contract(transfer_type_fa2))) of
    Some(contr) -> contr
  | None -> (failwith("Dex/not-token") : contract(transfer_type_fa2))
  end;

(* Helper function to get fa1.2 token contract *)
function get_fa12_balance_entrypoint(
  const token_address : address) : contract(transfer_type_fa12) is
  case (Tezos.get_entrypoint_opt(
      "%transfer",
      token_address) : option(contract(transfer_type_fa12))) of
    Some(contr) -> contr
  | None -> (failwith("Dex/not-token") : contract(transfer_type_fa12))
  end;

(* Helper function to get the reentrancy entrypoint of the current contract *)
function get_close_entrypoint(
  const contract_address : address) : contract(unit) is
  case (Tezos.get_entrypoint_opt(
      "%close", contract_address) : option(contract(unit))) of
    Some(contr) -> contr
  | None -> (failwith("Dex/no-close-entrypoint") : contract(unit))
  end;

(* Helper function to transfer fa2 tokens *)
function transfer_fa2(
  const sender_ : address;
  const receiver : address;
  const amount_ : nat;
  const token_id : nat;
  const contract_address : address) : operation is
  Tezos.transaction(
    wrap_fa2_transfer_trx(
      sender_,
      receiver,
      amount_,
      token_id),
    0mutez,
    get_fa2_token_contract(contract_address)
  );

(* Helper function to transfer fa1.2 tokens *)
function transfer_fa12(
  const sender_ : address;
  const receiver : address;
  const amount_ : nat;
  const contract_address : address) : operation is
  Tezos.transaction(
    wrap_fa12_transfer_trx(
      sender_,
      receiver,
      amount_),
    0mutez,
    get_fa12_token_contract(contract_address)
  );

function get_bal_fa12_a(const self : address) : contract(nat) is
  case (Tezos.get_entrypoint_opt("%balanceAFA12", self) : option(contract(nat))) of
  | Some(contr) -> contr
  | None -> (failwith("Dex/balanceAFa12") : contract(nat))
  end
function get_bal_fa12_b(const self : address) : contract(nat) is
  case (Tezos.get_entrypoint_opt("%balanceBFA12", self) : option(contract(nat))) of
  | Some(contr) -> contr
  | None -> (failwith("Dex/balanceBFa12") : contract(nat))
  end

function get_bal_fa2_a(const self : address) : contract(list(balance_of_response)) is
  case (Tezos.get_entrypoint_opt("%balanceAFA2", self) : option(contract(list(balance_of_response)))) of
  | Some(contr) -> contr
  | None -> (failwith("Dex/balanceAFa2") : contract(list(balance_of_response)))
  end

function get_bal_fa2_b(const self : address) : contract(list(balance_of_response)) is
  case (Tezos.get_entrypoint_opt("%balanceBFA2", self) : option(contract(list(balance_of_response)))) of
  | Some(contr) -> contr
  | None -> (failwith("Dex/balanceBFa2") : contract(list(balance_of_response)))
  end

function get_fa12_balance_entrypoint(const token : address) : contract(balance_of_fa12_params) is
  case (Tezos.get_entrypoint_opt("%getBalance", token): option(contract(balance_of_fa12_params))) of
  | Some(contr) -> contr
  | None -> (failwith("Dex/balance-of-ep") : contract(balance_of_fa12_params))
  end

function get_fa2_balance_entrypoint(const token : address): contract(balance_params) is
  case (Tezos.get_entrypoint_opt("%balance_of", token): option(contract(balance_params))) of
  | Some(contr) -> contr
  | None -> (failwith("Dex/balance-of-ep") : contract(balance_params))
  end

function get_ensured_initialize_entrypoint(const token : address): contract(ensured_add_params) is
  case (Tezos.get_entrypoint_opt("%ensuredAddPair", token): option(contract(ensured_add_params))) of
  | Some(contr) -> contr
  | None -> (failwith("Dex/no-entrypoint") : contract(ensured_add_params))
  end

function get_ensured_invest_entrypoint(const token : address): contract(ensured_invest_params) is
  case (Tezos.get_entrypoint_opt("%ensuredInvest", token): option(contract(ensured_invest_params))) of
  | Some(contr) -> contr
  | None -> (failwith("Dex/no-entrypoint") : contract(ensured_invest_params))
  end

function get_ensured_swap_entrypoint(const token : address): contract(ensured_route_params) is
  case (Tezos.get_entrypoint_opt("%ensuredSwap", token): option(contract(ensured_route_params))) of
  | Some(contr) -> contr
  | None -> (failwith("Dex/no-entrypoint") : contract(ensured_route_params))
  end

(* Helper function to transfer fa2 tokens *)
function get_balance_fa2(
  const user : address;
  const token_id : nat;
  const contract_address : address;
  const callback : contract(list(balance_of_response))) : operation is
  Tezos.transaction(
    record [
      requests = list [
        record [
          owner    = user;
          token_id = token_id;
        ]
      ];
      callback = callback
    ],
    0mutez,
    get_fa2_balance_entrypoint(contract_address)
  );

(* Helper function to transfer fa1.2 tokens *)
function get_balance_fa12(
  const user : address;
  const contract_address : address;
  const callback : contract(nat)) : operation is
  Tezos.transaction(
    (user, callback),
    0mutez,
    get_fa12_balance_entrypoint(contract_address)
  );

(* Helper function to transfer the asset based on its standard *)
function typed_transfer(
  const sender_ : address;
  const receiver : address;
  const amount_ : nat;
  const token_id : nat;
  const contract_address : address;
  const standard: token_type) : operation is
    case standard of
      Fa12 -> transfer_fa12(
        sender_,
        receiver,
        amount_,
        contract_address)
    | Fa2 -> transfer_fa2(
        sender_,
        receiver,
        amount_,
        token_id,
        contract_address)
    end;

(* Helper function to transfer the asset based on its standard *)
function typed_get_balance(
  const account : address;
  const token_id : nat;
  const contract_address : address;
  const standard: token_type;
  const name : token_name) : operation is
  block {
    var op : option(operation) := (None : option(operation));
    case standard of
      Fa12 -> {
        const callback : contract(nat) = case name of
        | A -> get_bal_fa12_a(account)
        | B -> get_bal_fa12_b(account)
        end;
        op := Some(get_balance_fa12(
          account,
          contract_address,
          callback));
        }
    | Fa2 -> {
        const callback : contract(list(balance_of_response)) = case name of
        | A -> get_bal_fa2_a(account)
        | B -> get_bal_fa2_b(account)
        end;
        op := Some(get_balance_fa2(
          account,
          token_id,
          contract_address,
          callback));
      }
    end;
  } with case op of
  | Some(o) -> o
  | None -> (failwith("Dex/no-balance") : operation)
  end

(* Helper function to transfer the asset based on its standard *)
function check_token_id(
  const token_id : nat;
  const standard: token_type) : unit is
    case standard of
      Fa12 -> if token_id = 0n
        then unit
        else (failwith("Dex/non-zero-token-id") : unit)
    | Fa2 -> unit
    end;

#include "../partials/TTMethodFA2.ligo"

(* Initialize exchange after the previous liquidity was drained *)
function ensured_initialize_exchange(
  const p : dex_action;
  const s : dex_storage;
  const this: address) :  return is
  block {
    var operations: list(operation) := list[];
    case p of
      EnsuredAddPair(params) -> {
        if Tezos.sender =/= this
        then failwith("Dex/not-self")
        else skip;

        (* check preconditions *)
        if params.pair.token_a_address = params.pair.token_b_address
        and params.pair.token_a_id >= params.pair.token_b_id
        then failwith("Dex/wrong-token-id") else skip;
        if params.pair.token_a_address > params.pair.token_b_address
        then failwith("Dex/wrong-pair") else skip;

        (* check fa1.2 token ids *)
        check_token_id(params.pair.token_a_id, params.pair.token_a_type);
        check_token_id(params.pair.token_b_id, params.pair.token_b_type);

        (* read pair info*)
        const res : (pair_info * nat) = get_pair(params.pair, s);
        const pair : pair_info = res.0;
        const token_id : nat = res.1;

        (* update counter if needed *)
        if s.pairs_count = token_id then {
          s.token_to_id[Bytes.pack(params.pair)] := token_id;
          s.pairs_count := s.pairs_count + 1n;
        } else skip;

        var token_a_in : nat := 0n;
        var token_b_in : nat := 0n;
        case s.tmp.balance_a of
        | Some(balance_a) -> token_a_in := balance_a
        | None -> failwith("Dex/balanca-a-not-updated")
        end;
        case s.tmp.balance_b of
        | Some(balance_b) -> token_b_in := balance_b
        | None -> failwith("Dex/balanca-b-not-updated")
        end;

        (* check preconditions *)
        if pair.token_a_pool * pair.token_b_pool =/= 0n (* no reserves *)
        then failwith("Dex/non-zero-reserves") else skip;
        if pair.total_supply =/= 0n  (* no shares owned *)
        then failwith("Dex/non-zero-shares") else skip;
        if token_a_in < 1n (* no token A invested *)
        then failwith("Dex/no-token-a") else skip;
        if token_b_in < 1n (* no token B invested *)
        then failwith("Dex/no-token-b") else skip;

        (* update pool reserves *)
        pair.token_a_pool := token_a_in;
        pair.token_b_pool := token_b_in;

        (* calculate initial shares *)
        const init_shares : nat =
          if token_a_in < token_b_in then
            token_a_in
          else token_b_in;

        (* distribute initial shares *)
        s.ledger[(params.receiver, token_id)] := record [
            balance    = init_shares;
            allowances = (set [] : set(address));
          ];
        pair.total_supply := init_shares;

        (* update storage *)
        s.pairs[token_id] := pair;
        s.tokens[token_id] := params.pair;

        (* prepare operations to get change if any *)
        // operations :=
        //   typed_transfer(
        //     Tezos.sender,
        //     this,
        //     params.token_a_in,
        //     params.pair.token_a_id,
        //     params.pair.token_a_address,
        //     params.pair.token_a_type
        //   ) # operations;
        // operations :=
        //   typed_transfer(
        //     Tezos.sender,
        //     this,
        //     params.token_b_in,
        //     params.pair.token_b_id,
        //     params.pair.token_b_address,
        //     params.pair.token_b_type
        //   ) # operations;
      }
    | AddPair(n) -> skip
    | Swap(n) -> skip
    | EnsuredSwap(n) -> skip
    | Invest(n) -> skip
    | EnsuredInvest(n) -> skip
    | Divest(n) -> skip
    end
} with (operations, s)

(* Initialize exchange after the previous liquidity was drained *)
function initialize_exchange(
  const p : dex_action;
  const s : dex_storage;
  const this: address) :  return is
  block {
    var operations: list(operation) := list[];
    case p of
      AddPair(params) -> {
        if s.entered
        then failwith("Dex/reentrancy")
        else s.entered := True;

        s.tmp := record [
          balance_a = (None : option(nat));
          balance_b = (None : option(nat));
        ];

        (* prepare operations to get initial liquidity *)
        operations := list [
          typed_get_balance(
            this,
            params.pair.token_a_id,
            params.pair.token_a_address,
            params.pair.token_a_type,
            A(unit)
          );
          typed_get_balance(
            this,
            params.pair.token_b_id,
            params.pair.token_b_address,
            params.pair.token_b_type,
            B(unit)
          );
          typed_transfer(
            Tezos.sender,
            this,
            params.token_a_in,
            params.pair.token_a_id,
            params.pair.token_a_address,
            params.pair.token_a_type
          );
          typed_transfer(
            Tezos.sender,
            this,
            params.token_b_in,
            params.pair.token_b_id,
            params.pair.token_b_address,
            params.pair.token_b_type
          );
          typed_get_balance(
            this,
            params.pair.token_a_id,
            params.pair.token_a_address,
            params.pair.token_a_type,
            A(unit)
          );
          typed_get_balance(
            this,
            params.pair.token_b_id,
            params.pair.token_b_address,
            params.pair.token_b_type,
            B(unit)
          );
          Tezos.transaction(
            record [
              pair=params.pair;
              receiver=Tezos.sender;
            ],
            0mutez,
            get_ensured_initialize_entrypoint(this)
          );
        ];
      }
    | EnsuredAddPair(n) -> skip
    | Swap(n) -> skip
    | EnsuredSwap(n) -> skip
    | Invest(n) -> skip
    | EnsuredInvest(n) -> skip
    | Divest(n) -> skip
    end
} with (operations, s)

(* Intrenal functions for swap hops *)
function internal_token_to_token_swap(
  const tmp : internal_swap_type;
  const params : swap_slice_type ) : internal_swap_type is
  block {
    (* check preconditions *)
    if params.pair.token_a_address = params.pair.token_b_address
    and params.pair.token_a_id >= params.pair.token_b_id
    then failwith("Dex/wrong-token-id") else skip;
    if params.pair.token_a_address > params.pair.token_b_address
    then failwith("Dex/wrong-pair") else skip;

    (* get pair info*)
    const res : (pair_info * nat) = get_pair(params.pair, tmp.s);
    const pair : pair_info = res.0;
    const token_id : nat = res.1;
    const swap: swap_data = form_swap_data(pair, params.pair, params.operation);

    (* ensure there is liquidity *)
    if pair.token_a_pool * pair.token_b_pool = 0n
    then failwith("Dex/not-launched") else skip;
    if tmp.amount_in = 0n (* non-zero amount of tokens exchanged *)
    then failwith ("Dex/zero-amount-in") else skip;
    (* ensure the route is corresponding *)
    if swap.from_.token =/= tmp.token_address_in
    or swap.from_.id =/= tmp.token_id_in
    then failwith("Dex/wrong-route") else skip;

    (* calculate amount out *)
    const from_in_with_fee : nat = tmp.amount_in * 997n;
    const numerator : nat = from_in_with_fee * swap.to_.pool;
    const denominator : nat = swap.from_.pool * 1000n + from_in_with_fee;

    (* calculate swapped token amount *)
    const out : nat = numerator / denominator;

    (* ensure the price impact isn't too high *)
    if out > swap.to_.pool / 3n
    then failwith("Dex/high-out") else skip;

    (* update pools amounts *)
    swap.to_.pool := abs(swap.to_.pool - out);
    swap.from_.pool := swap.from_.pool + tmp.amount_in;

    (* update info for the next hop *)
    tmp.amount_in := out;
    tmp.token_address_in := swap.to_.token;
    tmp.token_id_in := swap.to_.id;

    (* update storage *)
    const updated_pair : pair_info = form_pools(
      swap.from_.pool,
      swap.to_.pool,
      pair.total_supply,
      params.operation);
    tmp.s.pairs[token_id] := updated_pair;

    (* prepare operations to withdraw user's tokens *)
    tmp.operation := Some(
      typed_transfer(tmp.sender, tmp.receiver, out,
        swap.to_.id,
        swap.to_.token,
        swap.to_.standard
      ));
  } with tmp

(* Exchange tokens to tokens with multiple hops,
note: tokens should be approved before the operation *)
function token_to_token_route(
  const p : dex_action;
  const s : dex_storage;
  const this : address) : return is
  block {
    var operations: list(operation) := list[];
    case p of
    | AddPair(n) -> skip
    | Swap(params) -> {
        if s.entered
        then failwith("Dex/reentrancy")
        else s.entered := True;

        (* validate input params *)
        if List.size(params.swaps) < 1n (* the route is empty *)
        then failwith ("Dex/too-few-swaps") else skip;
        if params.amount_in = 0n (* non-zero amount of tokens exchanged *)
        then failwith ("Dex/zero-amount-in") else skip;
        if params.min_amount_out = 0n (* non-zero amount of tokens to receive *)
        then failwith ("Dex/zero-min-amount-out") else skip;

        s.tmp := record [
          balance_a = (None : option(nat));
          balance_b = (None : option(nat));
        ];

        (* get the first exchange info *)
        const first_swap : swap_slice_type = case List.head_opt(params.swaps) of
          Some(swap) -> swap
        | None -> (failwith("Dex/zero-swaps") : swap_slice_type)
        end;

        (* prepare operation to withdraw user's tokens *)
        case first_swap.operation of
        | Sell -> {
          operations := list [
              (* from *)
              typed_get_balance(
                this,
                first_swap.pair.token_a_id,
                first_swap.pair.token_a_address,
                first_swap.pair.token_a_type,
                A(unit)
              );
              typed_transfer(Tezos.sender,
                this,
                params.amount_in,
                first_swap.pair.token_a_id,
                first_swap.pair.token_a_address,
                first_swap.pair.token_a_type
              ) ;
              typed_get_balance(
                this,
                first_swap.pair.token_a_id,
                first_swap.pair.token_a_address,
                first_swap.pair.token_a_type,
                A(unit)
              );
              Tezos.transaction(
                record [
                  swaps=params.swaps;
                  min_amount_out=params.min_amount_out;
                  receiver=Tezos.sender;
                ],
                0mutez,
                get_ensured_swap_entrypoint(this)
              );
            ];
            (* TODO : add continue *)
          }
        | Buy -> {
          operations := list [
              (* from *)
              typed_get_balance(
                this,
                first_swap.pair.token_b_id,
                first_swap.pair.token_b_address,
                first_swap.pair.token_b_type,
                B(unit)
              );
              typed_transfer(Tezos.sender,
                this,
                params.amount_in,
                first_swap.pair.token_b_id,
                first_swap.pair.token_b_address,
                first_swap.pair.token_b_type
              );
              typed_get_balance(
                this,
                first_swap.pair.token_b_id,
                first_swap.pair.token_b_address,
                first_swap.pair.token_b_type,
                B(unit)
              );
              Tezos.transaction(
                record [
                  swaps=params.swaps;
                  min_amount_out=params.min_amount_out;
                  receiver=Tezos.sender;
                ],
                0mutez,
                get_ensured_swap_entrypoint(this)
              );
            ];
          }
        end;
      }
    | EnsuredAddPair(n) -> skip
    | EnsuredSwap(n) -> skip
    | Invest(n) -> skip
    | EnsuredInvest(n) -> skip
    | Divest(n) -> skip
    end
  } with (operations, s)

(* Exchange tokens to tokens with multiple hops,
note: tokens should be approved before the operation *)
function ensured_route(
  const p : dex_action;
  const s : dex_storage;
  const this : address) : return is
  block {
    var operations: list(operation) := list[];
    case p of
    | AddPair(n) -> skip
    | EnsuredSwap(params) -> {
        if Tezos.sender =/= this
        then failwith("Dex/not-self")
        else skip;

        (* get the first exchange info *)
        const first_swap : swap_slice_type = case List.head_opt(params.swaps) of
          Some(swap) -> swap
        | None -> (failwith("Dex/zero-swaps") : swap_slice_type)
        end;

        (* declare helper variables *)
        var token_id_in : nat := first_swap.pair.token_a_id;
        var token_address_in : address := first_swap.pair.token_a_address;
        var amount_in : nat := 0n;

        (* prepare operation to withdraw user's tokens *)
        case first_swap.operation of
        | Sell -> {
          case s.tmp.balance_a of
          | Some(balance_a) -> amount_in := balance_a
          | None -> failwith("Dex/balanca-a-not-updated")
          end;
          }
        | Buy -> {
          token_id_in := first_swap.pair.token_b_id;
          token_address_in := first_swap.pair.token_b_address;
          case s.tmp.balance_b of
          | Some(balance_b) -> amount_in := balance_b
          | None -> failwith("Dex/balanca-b-not-updated")
          end;
          }
        end;

        (* perform internal swaps *)
        const tmp : internal_swap_type = List.fold(
          internal_token_to_token_swap,
          params.swaps,
          record [
            s = s;
            amount_in = amount_in;
            operation = (None : option(operation));
            sender = this;
            receiver = params.receiver;
            token_id_in = token_id_in;
            token_address_in = token_address_in;
          ]
        );

        (* check the amount of tokens is sufficient *)
        if tmp.amount_in < params.min_amount_out
        then failwith ("Dex/wrong-min-out") else skip;

        (* update storage*)
        s := tmp.s;

        (* add token transfer to user's account to operations *)
        const last_operation : operation = case tmp.operation of
          Some(o) -> o
        | None -> (failwith("Dex/too-few-swaps") : operation)
        end;
        operations := last_operation # operations;
      }
    | EnsuredAddPair(n) -> skip
    | Swap(n) -> skip
    | Invest(n) -> skip
    | EnsuredInvest(n) -> skip
    | Divest(n) -> skip
    end
  } with (operations, s)

(* Provide liquidity (both tokens) to the pool,
note: tokens should be approved before the operation *)
function invest_liquidity(
  const p : dex_action;
  const s : dex_storage;
  const this: address) : return is
  block {
    var operations: list(operation) := list[];
    case p of
    | AddPair(n) -> skip
    | Swap(n) -> skip
    | Invest(params) -> {
        if s.entered
        then failwith("Dex/reentrancy")
        else s.entered := True;

        s.tmp := record [
          balance_a = (None : option(nat));
          balance_b = (None : option(nat));
        ];

        (* prepare operations to get initial liquidity *)
        operations := list [
          typed_get_balance(
            this,
            params.pair.token_a_id,
            params.pair.token_a_address,
            params.pair.token_a_type,
            A(unit)
          );
          typed_get_balance(
            this,
            params.pair.token_b_id,
            params.pair.token_b_address,
            params.pair.token_b_type,
            B(unit)
          );
          typed_transfer(
            Tezos.sender,
            this,
            params.token_a_in,
            params.pair.token_a_id,
            params.pair.token_a_address,
            params.pair.token_a_type
          );
          typed_transfer(
            Tezos.sender,
            this,
            params.token_b_in,
            params.pair.token_b_id,
            params.pair.token_b_address,
            params.pair.token_b_type
          );
          typed_get_balance(
            this,
            params.pair.token_a_id,
            params.pair.token_a_address,
            params.pair.token_a_type,
            A(unit)
          );
          typed_get_balance(
            this,
            params.pair.token_b_id,
            params.pair.token_b_address,
            params.pair.token_b_type,
            B(unit)
          );
          Tezos.transaction(
            record [
              pair=params.pair;
              shares=params.shares;
              receiver=Tezos.sender;
            ],
            0mutez,
            get_ensured_invest_entrypoint(this)
          );
        ];
      }
    | EnsuredAddPair(n) -> skip
    | EnsuredSwap(n) -> skip
    | EnsuredInvest(n) -> skip
    | Divest(n) -> skip
    end
  } with (operations, s)

(* Provide liquidity (both tokens) to the pool,
note: tokens should be approved before the operation *)
function ensured_invest(
  const p : dex_action;
  const s : dex_storage;
  const this: address) : return is
  block {
    var operations: list(operation) := list[];
    case p of
    | AddPair(n) -> skip
    | Swap(n) -> skip
    | EnsuredInvest(params) -> {
        if Tezos.sender =/= this
        then failwith("Dex/not-self")
        else skip;

        (* check preconditions *)
        if params.pair.token_a_address = params.pair.token_b_address
        and params.pair.token_a_id >= params.pair.token_b_id
        then failwith("Dex/wrong-token-id") else skip;
        if params.pair.token_a_address > params.pair.token_b_address
        then failwith("Dex/wrong-pair") else skip;

        (* read pair info*)
        const res : (pair_info * nat) = get_pair(params.pair, s);
        const pair : pair_info = res.0;
        const token_id : nat = res.1;

        (* ensure there is liquidity *)
        if pair.token_a_pool * pair.token_b_pool = 0n
        then failwith("Dex/not-launched") else skip;

        (* ensure purchsed shares satisfy required minimum *)
        if params.shares = 0n
        then failwith("Dex/wrong-params") else skip;

        (* calculate tokens to be withdrawn *)
        const tokens_a_required : nat =
          params.shares * pair.token_a_pool / pair.total_supply;
        if params.shares * pair.token_a_pool >
          tokens_a_required * pair.total_supply
        then tokens_a_required := tokens_a_required + 1n else skip;
        const tokens_b_required : nat =
          params.shares * pair.token_b_pool / pair.total_supply;
        if params.shares * pair.token_b_pool >
          tokens_b_required * pair.total_supply
        then tokens_b_required := tokens_b_required + 1n else skip;

        (* update pool reserves *)
        const token_a_in : nat = 0n;
        const token_b_in : nat = 0n;
        case s.tmp.balance_a of
        | Some(balance_a) -> token_a_in := balance_a
        | None -> failwith("Dex/balanca-a-not-updated")
        end;
        case s.tmp.balance_b of
        | Some(balance_b) -> token_b_in := balance_b
        | None -> failwith("Dex/balanca-b-not-updated")
        end;

        (* ensure *)
        if tokens_a_required = 0n  (* providing liquidity won't impact on price *)
        then failwith("Dex/zero-token-a-in") else skip;
        if tokens_b_required = 0n (* providing liquidity won't impact on price *)
        then failwith("Dex/zero-token-b-in") else skip;
        if tokens_a_required > token_a_in (* required tokens doesn't exceed max allowed by user *)
        then failwith("Dex/low-max-token-a-in") else skip;
        if tokens_b_required > token_b_in (* required tez doesn't exceed max allowed by user *)
        then failwith("Dex/low-max-token-b-in") else skip;

        var account : account_info := get_account((params.receiver, token_id), s);
        const share : nat = account.balance;

        (* update user's shares *)
        account.balance := share + params.shares;
        s.ledger[(params.receiver, token_id)] := account;

        (* update reserves *)
        pair.token_a_pool := pair.token_a_pool + tokens_a_required;
        pair.token_b_pool := pair.token_b_pool + tokens_b_required;

        (* update total number of shares *)
        pair.total_supply := pair.total_supply + params.shares;
        s.pairs[token_id] := pair;

        (* prepare operations to get initial liquidity *)
        (* TODO: send change if any *)
        // operations :=
        //   typed_transfer(
        //     Tezos.sender,
        //     this,
        //     tokens_a_required,
        //     params.pair.token_a_id,
        //     params.pair.token_a_address,
        //     params.pair.token_a_type
        //   ) # operations;
        // operations :=
        //   typed_transfer(
        //     Tezos.sender,
        //     this,
        //     tokens_b_required,
        //     params.pair.token_b_id,
        //     params.pair.token_b_address,
        //     params.pair.token_b_type
        //   ) # operations;
      }
    | EnsuredAddPair(n) -> skip
    | EnsuredSwap(n) -> skip
    | Invest(n) -> skip
    | Divest(n) -> skip
    end
  } with (operations, s)

(* Remove liquidity (both tokens) from the pool by burning shares *)
function divest_liquidity(
  const p : dex_action;
  const s : dex_storage;
  const this: address) :  return is
  block {
    var operations: list(operation) := list[];
    case p of
    | AddPair(token_amount) -> skip
    | EnsuredAddPair(n) -> skip
    | Swap(n) -> skip
    | EnsuredSwap(n) -> skip
    | Invest(n) -> skip
    | EnsuredInvest(n) -> skip
    | Divest(params) -> {
        if s.entered
        then failwith("Dex/reentrancy")
        else s.entered := True;

        (* check preconditions *)
        if params.pair.token_a_address = params.pair.token_b_address
        and params.pair.token_a_id >= params.pair.token_b_id
        then failwith("Dex/wrong-token-id") else skip;
        if params.pair.token_a_address > params.pair.token_b_address
        then failwith("Dex/wrong-pair") else skip;

        (* read pair info*)
        const res : (pair_info * nat) = get_pair(params.pair, s);
        const pair : pair_info = res.0;
        const token_id : nat = res.1;

        (* ensure pair exist *)
        if s.pairs_count = token_id
        then failwith("Dex/pair-not-exist") else skip;
        if pair.token_a_pool * pair.token_b_pool = 0n
        then failwith("Dex/not-launched") else skip;

        var account : account_info := get_account((Tezos.sender, token_id), s);
        const share : nat = account.balance;

        (* ensure *)
        if params.shares = 0n (* minimal burn's shares are non-zero *)
        then failwith("Dex/zero-burn-shares") else skip;
        if params.shares > share (* burnt shares are lower than balance *)
        then failwith("Dex/insufficient-shares") else skip;

        (* update users shares *)
        account.balance := abs(share - params.shares);
        s.ledger[(Tezos.sender, token_id)] := account;

        (* calculate amount of token's sent to user *)
        const token_a_divested : nat =
          pair.token_a_pool * params.shares / pair.total_supply;
        const token_b_divested : nat =
          pair.token_b_pool * params.shares / pair.total_supply;

        (* ensure minimal amounts out are non-zero *)
        if params.min_token_a_out = 0n or params.min_token_b_out = 0n
        then failwith("Dex/dust-output") else skip;

        (* ensure minimal amounts are satisfied *)
        if token_a_divested < params.min_token_a_out
        or token_b_divested < params.min_token_b_out
        then failwith("Dex/high-expectation") else skip;

        (* update total shares *)
        pair.total_supply := abs(pair.total_supply - params.shares);

        (* update reserves *)
        pair.token_a_pool := abs(pair.token_a_pool - token_a_divested);
        pair.token_b_pool := abs(pair.token_b_pool - token_b_divested);

        (* update storage *)
        s.pairs[token_id] := pair;

        (* prepare operations with tokens to user *)
        operations :=
          typed_transfer(
            this,
            Tezos.sender,
            token_a_divested,
            params.pair.token_a_id,
            params.pair.token_a_address,
            params.pair.token_a_type
          ) # operations;
        operations :=
          typed_transfer(
            this,
            Tezos.sender,
            token_b_divested,
            params.pair.token_b_id,
            params.pair.token_b_address,
            params.pair.token_b_type
          ) # operations;
      }
    end
  } with (operations, s)

(* Remove liquidity (both tokens) from the pool by burning shares *)
function update_balance_fa_12_a(
  const p : balance_action;
  const s : dex_storage;
  const this: address) :  return is
  block {
    var operations: list(operation) := list[];
    case p of
    | IBalanceAFA12(new_balance) -> {
      s.tmp.balance_a := Some(case s.tmp.balance_a of
      | Some(prev_balance) ->
        if prev_balance > new_balance
        then (failwith("Dex/balance-decremented") : nat)
        else abs(new_balance - prev_balance)
      | None -> new_balance
      end);
    }
    | IBalanceBFA12(n) -> skip
    | IBalanceAFA2(n) -> skip
    | IBalanceBFA2(n) -> skip
    end
  } with (operations, s)

(* Remove liquidity (both tokens) from the pool by burning shares *)
function update_balance_fa_12_b(
  const p : balance_action;
  const s : dex_storage;
  const this: address) :  return is
  block {
    var operations: list(operation) := list[];
    case p of
    | IBalanceAFA12(n) -> skip
    | IBalanceBFA12(new_balance) -> {
      s.tmp.balance_b := Some(case s.tmp.balance_b of
      | Some(prev_balance) ->
        if prev_balance > new_balance
        then (failwith("Dex/balance-decremented") : nat)
        else abs(new_balance - prev_balance)
      | None -> new_balance
      end);
    }
    | IBalanceAFA2(n) -> skip
    | IBalanceBFA2(n) -> skip
    end
  } with (operations, s)

(* Remove liquidity (both tokens) from the pool by burning shares *)
function update_balance_fa_2_a(
  const p : balance_action;
  const s : dex_storage;
  const this: address) :  return is
  block {
    var operations: list(operation) := list[];
    case p of
    | IBalanceAFA12(n) -> skip
    | IBalanceBFA12(n) -> skip
    | IBalanceAFA2(responses) -> {
      const response : balance_of_response =
        case List.head_opt(responses) of
        | Some(head) -> head
        | None -> (failwith("Dex/no-balance-response") : balance_of_response)
        end;

      if response.request.owner =/= this
      then failwith("Dex/wrong-balance-owner")
      else skip;

      s.tmp.balance_a := Some(case s.tmp.balance_a of
      | Some(prev_balance) ->
        if prev_balance > response.balance
        then (failwith("Dex/balance-decremented") : nat)
        else abs(response.balance - prev_balance)
      | None -> response.balance
      end);
    }
    | IBalanceBFA2(n) -> skip
    end
  } with (operations, s)

(* Remove liquidity (both tokens) from the pool by burning shares *)
function update_balance_fa_2_b(
  const p : balance_action;
  const s : dex_storage;
  const this: address) :  return is
  block {
    var operations: list(operation) := list[];
    case p of
    | IBalanceAFA12(n) -> skip
    | IBalanceBFA12(n) -> skip
    | IBalanceAFA2(n) -> skip
    | IBalanceBFA2(responses) -> {
      const response : balance_of_response =
        case List.head_opt(responses) of
        | Some(head) -> head
        | None -> (failwith("Dex/no-balance-response") : balance_of_response)
        end;

      if response.request.owner =/= this
      then failwith("Dex/wrong-balance-owner")
      else skip;

      s.tmp.balance_b := Some(case s.tmp.balance_b of
      | Some(prev_balance) ->
        if prev_balance > response.balance
        then (failwith("Dex/balance-decremented") : nat)
        else abs(response.balance - prev_balance)
      | None -> response.balance
      end);
    }
    end
  } with (operations, s)
