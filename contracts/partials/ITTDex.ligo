#include "./TypesFA2.ligo"

(* Storage types *)

(* record that represents account shares *)
type account_info is record [
  balance           : nat; (* liquid tokens *)
  allowances        : set (address); (* accounts allowed to act on behalf of the user *)
]

#if FA2_STANDARD_ENABLED
type token_transfer_params is list (transfer_param)
type token_identifier is record [
    token_address     : address;
    token_id          : nat;
  ]
#if FA2FA12_STANDARD_ENABLED
type token_transfer_params_fa12 is michelson_pair(address, "from", michelson_pair(address, "to", nat, "value"), "")
type token_identifier_fa12 is address
type transfer_type_fa12 is TransferTypeFA12 of token_transfer_params_fa12
#endif
#else
type token_transfer_params is michelson_pair(address, "from", michelson_pair(address, "to", nat, "value"), "")
type token_identifier is address
#endif

type pair_info is record [
  token_a_pool        : nat; (* tez reserves in the pool *)
  token_b_pool        : nat; (* token reserves in the pool *)
  total_supply        : nat; (* total shares count *)
]

type tokens_info is record [
  token_a_address        : address;
  token_b_address        : address;
#if FA2_STANDARD_ENABLED
  token_a_id             : nat;
#if FA2FA12_STANDARD_ENABLED
#else
  token_b_id             : nat;
#endif
#endif
]

type token_pair is bytes

(* record for the dex storage *)
type dex_storage is record [
  pairs_count         : nat; (* total shares count *)
  tokens              : big_map(nat, tokens_info); (* all the tokens list *)
  token_to_id         : big_map(token_pair, nat); (* all the tokens list *)
  pairs               : big_map(nat, pair_info); (* account info per address *)
  ledger              : big_map((address * nat), account_info); (* account info per address *)
]
type swap_type is Buy | Sell

(* Entrypoint arguments *)
type token_to_token_payment_params is
  [@layout:comb]
  record [
    pair                  : tokens_info;
    operation             : swap_type;
    amount_in             : nat; (* amount of tokens to be exchanged *)
    min_amount_out        : nat; (* min amount of XTZ received to accept exchange *)
    receiver              : address; (* tokens receiver *)
  ]

type initialize_exchange_params is
  [@layout:comb]
  record [
    pair            : tokens_info;
    token_a_in      : nat; (* min amount of XTZ received to accept the divestment *)
    token_b_in      : nat; (* min amount of tokens received to accept the divestment *)
  ]

type invest_liquidity_params is
  [@layout:comb]
  record [
    pair            : tokens_info;
    token_a_in      : nat; (* min amount of XTZ received to accept the divestment *)
    token_b_in      : nat; (* min amount of tokens received to accept the divestment *)
    shares          : nat; (* amount of shares to be burnt *)
  ]

type divest_liquidity_params is
  [@layout:comb]
  record [
    pair                 : tokens_info;
    min_token_a_out      : nat; (* min amount of XTZ received to accept the divestment *)
    min_token_b_out      : nat; (* min amount of tokens received to accept the divestment *)
    shares               : nat; (* amount of shares to be burnt *)
  ]

type dex_action is
| InitializeExchange      of initialize_exchange_params  (* sets initial liquidity *)
| TokenToTokenPayment     of token_to_token_payment_params  (* exchanges XTZ to tokens and sends them to receiver *)
| InvestLiquidity         of invest_liquidity_params  (* mints min shares after investing tokens and XTZ *)
| DivestLiquidity         of divest_liquidity_params  (* burns shares and sends tokens and XTZ to the owner *)

type use_params is dex_action
type get_reserves_params is record [
  receiver        : contract(nat * nat);
  token_id        : nat;
]

(* Main function parameter types specific for FA2 standard*)
type transfer_params is list (transfer_param)
type update_operator_params is list (update_operator_param)

type token_action is
| ITransfer                of transfer_params
| IBalance_of              of balance_params
| IUpdate_operators        of update_operator_params

type return is list (operation) * dex_storage
type dex_func is (dex_action * dex_storage * address) -> return
type token_func is (token_action * dex_storage * address) -> return

type set_token_function_params is record [
  func    : token_func; (* code of the function *)
  index   : nat; (* the key in functions map *)
]

type set_dex_function_params is record [
  func    : dex_func; (* code of the function *)
  index   : nat; (* the key in functions map *)
]

type full_action is
| Use                     of use_params
| Transfer                of transfer_params
| Balance_of              of balance_params
| Update_operators        of update_operator_params
| Get_reserves            of get_reserves_params
| SetDexFunction          of set_dex_function_params (* sets the dex specific function. Is used before the whole system is launched *)
| SetTokenFunction        of set_token_function_params (* sets the FA function, is used before the whole system is launched *)

(* real dex storage *)
type full_dex_storage is record
  storage             : dex_storage;
  metadata            : big_map(string, bytes); (* metadata storage according to TZIP-016 *)
  dex_lambdas         : big_map(nat, dex_func); (* map with exchange-related functions code *)
  token_lambdas       : big_map(nat, token_func); (* map with token-related functions code *)
end

type full_return is list (operation) * full_dex_storage

const fee_rate : nat = 333n; (* exchange fee rate distributed among the liquidity providers *)

type transfer_type is TransferType of token_transfer_params
const token_func_count : nat = 2n;
