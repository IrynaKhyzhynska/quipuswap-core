(* Implimentation of the FA1.2 specification in PascaLIGO *)

(* Define types *)
type trusted is address
type amt is nat

type account is
  record [
    balance         : amt;
    allowances      : map (trusted, amt);
  ]

(* contract storage *)
type storage is
  record [
    total_supply     : amt;
    ledger          : big_map (address, account);
  ]

(* define return for readability *)
type return is list (operation) * storage

(* define noop for readability *)
const noOperations : list (operation) = nil;

(* Inputs *)
type transferParams is michelson_pair(address, "from", michelson_pair(address, "to", amt, "value"), "")
type approveParams is michelson_pair(trusted, "spender", amt, "value")
type balanceParams is michelson_pair(address, "owner", contract(amt), "")
type allowanceParams is michelson_pair(michelson_pair(address, "owner", trusted, "spender"), "", contract(amt), "")
type totalSupplyParams is (unit * contract(amt))

(* Valid entry points *)
type tokenAction is
| Transfe         of transferParams
| Approve         of approveParams
| GetBalance      of balanceParams
| GetAllowance    of allowanceParams
| GetTotalSupply  of totalSupplyParams
